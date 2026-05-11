import SwiftUI

struct NotesDashboardView: View {
    @StateObject private var notesManager = NotesManager.shared
    @State private var showingNewNotebookAlert = false
    @State private var newNotebookName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if notesManager.notebooks.isEmpty {
                    VStack {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                            .padding()
                        Text("No notebooks yet")
                            .foregroundColor(.secondary)
                        
                        Button("Create Notebook") {
                            showingNewNotebookAlert = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top)
                    }
                } else {
                    List {
                        ForEach(notesManager.notebooks) { notebook in
                            Section(header: Text(notebook.name).font(.headline).foregroundColor(.white)) {
                                ForEach(notebook.notes) { note in
                                    NavigationLink(destination: NoteEditorView(notebookId: notebook.id, noteId: note.id)) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(note.title)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            Text(note.content)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        notesManager.deleteNote(notebookId: notebook.id, noteId: notebook.notes[index].id)
                                    }
                                }
                                
                                NavigationLink(destination: NoteEditorView(notebookId: notebook.id, noteId: nil)) {
                                    Label("New Note", systemImage: "plus")
                                        .foregroundColor(.blue)
                                }
                            }
                            .listRowBackground(Color(.systemGray6).opacity(0.3))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewNotebookAlert = true }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .alert("New Notebook", isPresented: $showingNewNotebookAlert) {
                TextField("Notebook Name", text: $newNotebookName)
                Button("Create") {
                    if !newNotebookName.isEmpty {
                        notesManager.createNotebook(name: newNotebookName)
                        newNotebookName = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    newNotebookName = ""
                }
            }
        }
    }
}
