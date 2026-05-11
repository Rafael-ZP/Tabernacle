import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var notesManager = NotesManager.shared
    let notebookId: UUID
    let noteId: UUID?
    
    @State private var title: String = ""
    @State private var content: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("Note Title", text: $title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Text(Date().formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                TextEditor(text: $content)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.primary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    if let id = noteId {
                        notesManager.updateNote(notebookId: notebookId, noteId: id, title: title, content: content)
                    } else {
                        if !title.isEmpty || !content.isEmpty {
                            notesManager.createNote(in: notebookId, title: title, content: content)
                        }
                    }
                    dismiss()
                }
                .fontWeight(.bold)
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
