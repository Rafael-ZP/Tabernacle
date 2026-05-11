import Foundation
import Combine

class NotesManager: ObservableObject {
    static let shared = NotesManager()
    
    @Published var notebooks: [Notebook] = [] {
        didSet {
            saveNotebooks()
        }
    }
    
    private let notebooksKey = "notes_notebooks"
    
    private init() {
        loadNotebooks()
        
        if notebooks.isEmpty {
            // Default Notebook
            notebooks.append(Notebook(name: "My Devotions", notes: []))
        }
    }
    
    // MARK: - Notebooks
    func createNotebook(name: String, colorHex: String? = nil) {
        let notebook = Notebook(name: name, colorHex: colorHex, notes: [])
        notebooks.append(notebook)
    }
    
    func deleteNotebook(id: UUID) {
        notebooks.removeAll { $0.id == id }
    }
    
    // MARK: - Notes
    func createNote(in notebookId: UUID, title: String, content: String) {
        guard let index = notebooks.firstIndex(where: { $0.id == notebookId }) else { return }
        
        let note = StudyNote(title: title, content: content)
        notebooks[index].notes.append(note)
    }
    
    func updateNote(notebookId: UUID, noteId: UUID, title: String, content: String) {
        guard let nbIndex = notebooks.firstIndex(where: { $0.id == notebookId }),
              let noteIndex = notebooks[nbIndex].notes.firstIndex(where: { $0.id == noteId }) else { return }
        
        notebooks[nbIndex].notes[noteIndex].title = title
        notebooks[nbIndex].notes[noteIndex].content = content
        notebooks[nbIndex].notes[noteIndex].updatedAt = Date()
    }
    
    func deleteNote(notebookId: UUID, noteId: UUID) {
        guard let nbIndex = notebooks.firstIndex(where: { $0.id == notebookId }) else { return }
        notebooks[nbIndex].notes.removeAll { $0.id == noteId }
    }
    
    // MARK: - Persistence
    private func saveNotebooks() {
        if let encoded = try? JSONEncoder().encode(notebooks) {
            UserDefaults.standard.set(encoded, forKey: notebooksKey)
        }
    }
    
    private func loadNotebooks() {
        if let data = UserDefaults.standard.data(forKey: notebooksKey),
           let decoded = try? JSONDecoder().decode([Notebook].self, from: data) {
            self.notebooks = decoded
        }
    }
}
