import Foundation
import SwiftUI
import Combine

struct StudyItem: Codable, Identifiable {
    var id = UUID()
    var translation: String
    var book: String
    var chapter: Int
    var verseId: String // "1", "2"
    var colorHex: String?
    var noteText: String?
    var tags: [String] = []
    var timestamp: Date = Date()
}

class StudyManager: ObservableObject {
    static let shared = StudyManager()
    
    @Published var items: [StudyItem] = [] {
        didSet {
            save()
        }
    }
    
    private let key = "study_items_data"
    
    private init() {
        load()
    }
    
    func getItems(for book: String, chapter: Int) -> [StudyItem] {
        items.filter { $0.book == book && $0.chapter == chapter }
    }
    
    func addHighlight(translation: String, book: String, chapter: Int, verseId: String, colorHex: String) {
        if let index = items.firstIndex(where: { $0.book == book && $0.chapter == chapter && $0.verseId == verseId }) {
            items[index].colorHex = colorHex
        } else {
            items.append(StudyItem(translation: translation, book: book, chapter: chapter, verseId: verseId, colorHex: colorHex))
        }
    }
    
    func removeHighlight(book: String, chapter: Int, verseId: String) {
        if let index = items.firstIndex(where: { $0.book == book && $0.chapter == chapter && $0.verseId == verseId }) {
            items[index].colorHex = nil
            if items[index].noteText == nil {
                items.remove(at: index)
            }
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([StudyItem].self, from: data) {
            self.items = decoded
        }
    }
}
