import Foundation
import SQLite3
import Combine
class BibleDatabaseManager: ObservableObject {
    static let shared = BibleDatabaseManager()
    
    private var db: OpaquePointer?
    
    // Status to track import progress if needed
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    
    private let dbName = "bible.sqlite"
    
    private init() {
        openDatabase()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    private func getDatabaseURL() -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0]
        return documentDirectory.appendingPathComponent(dbName)
    }
    
    private func openDatabase() {
        let dbURL = getDatabaseURL()
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }
    
    func setupDatabaseIfNeeded(completion: @escaping () -> Void) {
        let dbURL = getDatabaseURL()
        let fileManager = FileManager.default
        
        // If DB exists and has data, we can skip.
        // We can do a quick check by querying the count.
        if fileManager.fileExists(atPath: dbURL.path) && hasData() {
            DispatchQueue.main.async {
                completion()
            }
            return
        }
        
        isImporting = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.createTables()
            self.importData()
            
            DispatchQueue.main.async {
                self.isImporting = false
                completion()
            }
        }
    }
    
    private func hasData() -> Bool {
        let query = "SELECT COUNT(*) FROM verses LIMIT 1;"
        var statement: OpaquePointer?
        var count: Int32 = 0
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                count = sqlite3_column_int(statement, 0)
            }
        }
        sqlite3_finalize(statement)
        return count > 0
    }
    
    private func createTables() {
        let createVersesTable = """
        CREATE TABLE IF NOT EXISTS verses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            translation TEXT,
            book TEXT,
            chapter INTEGER,
            verse TEXT,
            text TEXT
        );
        """
        
        let createFtsTable = """
        CREATE VIRTUAL TABLE IF NOT EXISTS verses_fts USING fts5(
            translation UNINDEXED,
            book UNINDEXED,
            chapter UNINDEXED,
            verse UNINDEXED,
            text,
            tokenize='unicode61'
        );
        """
        
        execute(sql: createVersesTable)
        execute(sql: createFtsTable)
    }
    
    private func execute(sql: String) {
        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            let errorString = String(cString: errorMessage!)
            print("Error executing SQL: \(sql)\n\(errorString)")
            sqlite3_free(errorMessage)
        }
    }
    
    private func importData() {
        let dataService = BibleDataService.shared
        let translations = dataService.availableTranslations
        let books = dataService.allBookNames
        
        let totalFiles = Double(translations.count * books.count)
        var processedFiles = 0.0
        
        // Use transactions for fast bulk inserts
        execute(sql: "BEGIN TRANSACTION;")
        
        let insertSql = "INSERT INTO verses (translation, book, chapter, verse, text) VALUES (?, ?, ?, ?, ?);"
        let ftsInsertSql = "INSERT INTO verses_fts (translation, book, chapter, verse, text) VALUES (?, ?, ?, ?, ?);"
        
        var stmt: OpaquePointer?
        var ftsStmt: OpaquePointer?
        
        sqlite3_prepare_v2(db, insertSql, -1, &stmt, nil)
        sqlite3_prepare_v2(db, ftsInsertSql, -1, &ftsStmt, nil)
        
        for translation in translations {
            for bookName in books {
                if let book = dataService.getBook(name: bookName, translation: translation) {
                    for chapter in book.chapters {
                        guard let chapterNum = Int32(chapter.chapter) else { continue }
                        for verse in chapter.verses {
                            
                            // Insert into standard table
                            sqlite3_bind_text(stmt, 1, (translation as NSString).utf8String, -1, nil)
                            sqlite3_bind_text(stmt, 2, (book.book as NSString).utf8String, -1, nil)
                            sqlite3_bind_int(stmt, 3, chapterNum)
                            sqlite3_bind_text(stmt, 4, (verse.verse as NSString).utf8String, -1, nil)
                            sqlite3_bind_text(stmt, 5, (verse.text as NSString).utf8String, -1, nil)
                            sqlite3_step(stmt)
                            sqlite3_reset(stmt)
                            
                            // Insert into FTS table
                            sqlite3_bind_text(ftsStmt, 1, (translation as NSString).utf8String, -1, nil)
                            sqlite3_bind_text(ftsStmt, 2, (book.book as NSString).utf8String, -1, nil)
                            sqlite3_bind_int(ftsStmt, 3, chapterNum)
                            sqlite3_bind_text(ftsStmt, 4, (verse.verse as NSString).utf8String, -1, nil)
                            
                            // Normalize text slightly for better FTS if needed, though unicode61 handles a lot.
                            let cleanText = verse.text.replacingOccurrences(of: "—", with: " ")
                            sqlite3_bind_text(ftsStmt, 5, (cleanText as NSString).utf8String, -1, nil)
                            
                            sqlite3_step(ftsStmt)
                            sqlite3_reset(ftsStmt)
                        }
                    }
                }
                
                processedFiles += 1
                DispatchQueue.main.async {
                    self.importProgress = processedFiles / totalFiles
                }
            }
        }
        
        sqlite3_finalize(stmt)
        sqlite3_finalize(ftsStmt)
        
        execute(sql: "COMMIT TRANSACTION;")
    }
    
    func searchFTS(query: String, translation: String) -> [SearchResult] {
        var results: [SearchResult] = []
        
        // Basic match logic: surround each term with * for prefix matching
        let terms = query.split(separator: " ")
        var matchQuery = ""
        for term in terms {
            let cleanTerm = String(term).replacingOccurrences(of: "'", with: "''")
            if matchQuery.isEmpty {
                matchQuery = "\"\(cleanTerm)\"*"
            } else {
                matchQuery += " AND \"\(cleanTerm)\"*"
            }
        }
        
        // We use BM25 ranking built-in to FTS5
        let sql = """
        SELECT translation, book, chapter, verse, text
        FROM verses_fts
        WHERE translation = ? AND verses_fts MATCH ?
        ORDER BY rank
        LIMIT 200;
        """
        
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (translation as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (matchQuery as NSString).utf8String, -1, nil)
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                let transStr = String(cString: sqlite3_column_text(stmt, 0))
                let bookStr = String(cString: sqlite3_column_text(stmt, 1))
                let chapterNum = Int(sqlite3_column_int(stmt, 2))
                let verseStr = String(cString: sqlite3_column_text(stmt, 3))
                let textStr = String(cString: sqlite3_column_text(stmt, 4))
                
                let res = SearchResult(
                    translation: transStr,
                    book: bookStr,
                    chapter: chapterNum,
                    verse: verseStr,
                    text: textStr
                )
                results.append(res)
            }
        } else {
            print("Failed to prepare FTS search statement")
        }
        
        sqlite3_finalize(stmt)
        return results
    }
}
