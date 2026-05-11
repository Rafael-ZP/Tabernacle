import Foundation
import Combine

class BibleViewModel: ObservableObject {
    @Published var currentBook: BibleBook?
    @Published var currentChapter: BibleChapter?
    
    let dataService = BibleDataService.shared
    
    var allBookNames: [String] {
        dataService.allBookNames
    }
    
    func load(bookName: String, chapterNumber: Int, translation: String = "NIV") {
        if let book = dataService.getBook(name: bookName, translation: translation) {
            self.currentBook = book
            
            // The JSON chapter number is stored as a string
            if let chapter = book.chapters.first(where: { $0.chapter == String(chapterNumber) }) {
                self.currentChapter = chapter
            } else {
                // Fallback to first chapter if invalid
                self.currentChapter = book.chapters.first
            }
        } else {
            self.currentBook = nil
            self.currentChapter = nil
        }
    }
    
    func getChapterNumbers(for bookName: String) -> [Int] {
        guard let book = dataService.getBook(name: bookName) else { return [] }
        return book.chapters.compactMap { Int($0.chapter) }.sorted()
    }
}
