import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var notesManager = NotesManager.shared
    let notebookId: UUID
    let noteId: UUID?
    
    @State private var title: String = ""
    @State private var content: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Note Title", text: $title)
                .font(.system(size: 24, weight: .bold))
                .padding()
                .background(Color(.systemBackground))
            
            Divider()
            
            TextEditor(text: $content)
                .font(.body)
                .padding()
                .background(Color(.systemBackground))
        }
        .navigationTitle(noteId == nil ? "New Note" : "Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    if let id = noteId {
                        notesManager.updateNote(notebookId: notebookId, noteId: id, title: title, content: content)
                    } else {
                        notesManager.createNote(in: notebookId, title: title, content: content)
                    }
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
        .onAppear {
            if let noteId = noteId,
               let notebook = notesManager.notebooks.first(where: { $0.id == notebookId }),
               let note = notebook.notes.first(where: { $0.id == noteId }) {
                title = note.title
                content = note.content
            }
        }
    }
}
