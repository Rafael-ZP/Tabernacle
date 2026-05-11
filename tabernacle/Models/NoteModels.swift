import Foundation

struct Notebook: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var colorHex: String?
    var createdAt: Date = Date()
    var notes: [StudyNote]
}

struct StudyNote: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var content: String
    var linkedVerses: [VerseReference] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct VerseReference: Codable, Identifiable, Hashable {
    var id = UUID()
    var translation: String
    var book: String
    var chapter: Int
    var verse: String
}
