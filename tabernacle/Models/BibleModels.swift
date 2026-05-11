import Foundation

// MARK: - Bible JSON Models
struct BibleBook: Codable, Identifiable, Hashable {
    var id: String { book }
    let book: String
    let count: Int?
    let chapters: [BibleChapter]
    
    enum CodingKeys: String, CodingKey {
        case book
        case count
        case chapters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle 'book' which can be a String or a Dictionary
        if let bookString = try? container.decode(String.self, forKey: .book) {
            self.book = bookString
        } else if let bookDict = try? container.decode([String: String].self, forKey: .book),
                  let englishName = bookDict["english"] {
            self.book = englishName
        } else {
            self.book = "Unknown"
        }
        
        // Handle 'count' which can be an Int, a String, or missing
        if let countInt = try? container.decode(Int.self, forKey: .count) {
            self.count = countInt
        } else if let countString = try? container.decode(String.self, forKey: .count),
                  let countInt = Int(countString) {
            self.count = countInt
        } else {
            self.count = nil
        }
        
        self.chapters = try container.decode([BibleChapter].self, forKey: .chapters)
    }
}

struct BibleChapter: Codable, Identifiable, Hashable {
    var id: String { chapter }
    let chapter: String
    let verses: [BibleVerse]
}

struct BibleVerse: Codable, Identifiable, Hashable {
    var id: String { verse }
    let verse: String
    let text: String
}

// MARK: - Scripture Tab Model
struct ScriptureTab: Codable, Identifiable, Hashable {
    var id = UUID()
    var translation: String = "NIV"
    var book: String
    var chapter: Int
    var verse: Int?
    var scrollPosition: String?
    
    // New Features
    var customName: String?
    var colorTheme: String? // Store color hex or pre-defined palette ID
    var isPinned: Bool = false
    var isLocked: Bool = false
    
    var title: String {
        customName ?? "\(book) \(chapter)"
    }
}
