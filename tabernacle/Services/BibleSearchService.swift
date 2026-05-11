import Foundation

struct SearchResult: Identifiable {
    let id = UUID()
    let translation: String
    let book: String
    let chapter: Int
    let verse: String
    let text: String
}

class BibleSearchService {
    static let shared = BibleSearchService()
    private let dataService = BibleDataService.shared
    
    // A simple mapping for common abbreviations
    private let bookAbbreviations: [String: String] = [
        "gen": "Genesis", "ex": "Exodus", "lev": "Leviticus", "num": "Numbers", "deut": "Deuteronomy",
        "josh": "Joshua", "judg": "Judges", "ruth": "Ruth", "1sam": "1 Samuel", "2sam": "2 Samuel",
        "1kgs": "1 Kings", "2kgs": "2 Kings", "1chron": "1 Chronicles", "2chron": "2 Chronicles",
        "ezra": "Ezra", "neh": "Nehemiah", "est": "Esther", "job": "Job", "ps": "Psalms", "prov": "Proverbs",
        "eccl": "Ecclesiastes", "song": "Song of Solomon", "isa": "Isaiah", "jer": "Jeremiah", "lam": "Lamentations",
        "ezek": "Ezekiel", "dan": "Daniel", "hos": "Hosea", "joel": "Joel", "amos": "Amos", "obad": "Obadiah",
        "jon": "Jonah", "mic": "Micah", "nah": "Nahum", "hab": "Habakkuk", "zeph": "Zephaniah", "hag": "Haggai",
        "zech": "Zechariah", "mal": "Malachi",
        "mt": "Matthew", "mk": "Mark", "lk": "Luke", "jn": "John", "acts": "Acts", "rom": "Romans",
        "1cor": "1 Corinthians", "2cor": "2 Corinthians", "gal": "Galatians", "eph": "Ephesians",
        "phil": "Philippians", "col": "Colossians", "1thess": "1 Thessalonians", "2thess": "2 Thessalonians",
        "1tim": "1 Timothy", "2tim": "2 Timothy", "titus": "Titus", "philem": "Philemon", "heb": "Hebrews",
        "jas": "James", "1pet": "1 Peter", "2pet": "2 Peter", "1jn": "1 John", "2jn": "2 John", "3jn": "3 John",
        "jude": "Jude", "rev": "Revelation"
    ]
    
    func search(query: String, translation: String, completion: @escaping ([SearchResult]) -> Void) {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            completion([])
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var results: [SearchResult] = []
            
            // Check for smart reference (e.g., "jn 3 16" or "rom 8:28")
            if let refResult = self.parseSmartReference(query: q, translation: translation) {
                results.append(refResult)
                // If it's an exact reference, maybe we just return it or keep searching?
                // Returning it instantly gives that "instant route" feel
                DispatchQueue.main.async {
                    completion(results)
                }
                return
            }
            
            // Normal / Fuzzy Search
            let searchTerms = q.split(separator: " ").map { String($0) }
            
            for bookName in self.dataService.allBookNames {
                if let book = self.dataService.getBook(name: bookName, translation: translation) {
                    for chapter in book.chapters {
                        guard let chapterNum = Int(chapter.chapter) else { continue }
                        for verse in chapter.verses {
                            let textLower = verse.text.lowercased()
                            
                            // Check if ALL search terms match the verse (simple fuzzy)
                            var matchesAll = true
                            for term in searchTerms {
                                if !textLower.contains(term) && !self.isFuzzyMatch(text: textLower, pattern: term) {
                                    matchesAll = false
                                    break
                                }
                            }
                            
                            if matchesAll {
                                let res = SearchResult(
                                    translation: translation,
                                    book: book.book,
                                    chapter: chapterNum,
                                    verse: verse.verse,
                                    text: verse.text
                                )
                                results.append(res)
                                
                                if results.count >= 200 {
                                    DispatchQueue.main.async {
                                        completion(results)
                                    }
                                    return
                                }
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
    
    private func parseSmartReference(query: String, translation: String) -> SearchResult? {
        // Simple regex or manual parsing for `<book> <chapter>[: ]<verse>`
        // e.g., "jn 3 16" or "1jn 3:16" or "john 3 16"
        let pattern = "^([1-3]?[a-z]+)\\s+(\\d+)[\\s:]+(\\d+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        
        let nsString = query as NSString
        let matches = regex.matches(in: query, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if let match = matches.first, match.numberOfRanges == 4 {
            let bookStr = nsString.substring(with: match.range(at: 1))
            let chapterStr = nsString.substring(with: match.range(at: 2))
            let verseStr = nsString.substring(with: match.range(at: 3))
            
            // Resolve book name
            let fullBookName = bookAbbreviations[bookStr] ?? dataService.allBookNames.first { $0.lowercased() == bookStr || $0.lowercased().replacingOccurrences(of: " ", with: "") == bookStr }
            
            if let resolvedBook = fullBookName,
               let chapterNum = Int(chapterStr),
               let book = dataService.getBook(name: resolvedBook, translation: translation),
               let chapter = book.chapters.first(where: { $0.chapter == chapterStr }),
               let verse = chapter.verses.first(where: { $0.verse == verseStr }) {
                
                return SearchResult(
                    translation: translation,
                    book: book.book,
                    chapter: chapterNum,
                    verse: verse.verse,
                    text: verse.text
                )
            }
        }
        return nil
    }
    
    private func isFuzzyMatch(text: String, pattern: String) -> Bool {
        // A very simple Levenshtein or just checking if characters appear in order
        // For performance, we'll do a simple subsequence match or allow 1 char difference for short terms.
        // For now, doing a basic subsequence match:
        var textIndex = text.startIndex
        for char in pattern {
            guard let matchIndex = text[textIndex...].firstIndex(of: char) else {
                return false
            }
            textIndex = text.index(after: matchIndex)
        }
        return true
    }
}
