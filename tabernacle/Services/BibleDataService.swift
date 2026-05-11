import Foundation

class BibleDataService {
    static let shared = BibleDataService()
    
    // Cache structure: Translation -> Book Name -> BibleBook
    private var loadedBooks: [String: [String: BibleBook]] = [:]
    
    // List of all book names (we can use NIV's Books.json as the master list since names are standard)
    var allBookNames: [String] = []
    
    let availableTranslations = ["NIV", "KJV", "Tamil"]
    
    private init() {
        loadBookNames()
    }
    
    private func loadBookNames() {
        if let url = Bundle.main.url(forResource: "Bible-niv-main/Books", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let names = try JSONDecoder().decode([String].self, from: data)
                self.allBookNames = names
            } catch {
                print("Error loading Books.json: \(error)")
            }
        }
    }
    
    func getFolderFor(translation: String) -> String {
        switch translation.uppercased() {
        case "KJV": return "Bible-kjv-master"
        case "TAMIL": return "Bible-tamil-main"
        default: return "Bible-niv-main"
        }
    }
    
    func getFilenameFor(translation: String, bookName: String) -> String {
        if translation.uppercased() == "KJV" {
            // KJV filenames remove spaces (e.g. "1 Chronicles" -> "1Chronicles.json")
            // Except Song of Solomon which is SongofSolomon
            return bookName.replacingOccurrences(of: " ", with: "")
        }
        return bookName
    }
    
    func getBook(name: String, translation: String = "NIV") -> BibleBook? {
        let transKey = translation.uppercased()
        
        // Return cached if available
        if let cached = loadedBooks[transKey]?[name] {
            return cached
        }
        
        let folder = getFolderFor(translation: transKey)
        let filename = getFilenameFor(translation: transKey, bookName: name)
        
        // Attempt to load
        if let url = Bundle.main.url(forResource: "\(folder)/\(filename)", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let book = try JSONDecoder().decode(BibleBook.self, from: data)
                
                if loadedBooks[transKey] == nil {
                    loadedBooks[transKey] = [:]
                }
                loadedBooks[transKey]?[name] = book
                return book
            } catch {
                print("Error decoding \(filename).json for \(transKey): \(error)")
            }
        } else {
            print("Could not find \(filename).json in \(folder)")
        }
        
        return nil
    }
}
