import SwiftUI

struct NotesDashboardView: View {
    @StateObject private var notesManager = NotesManager.shared
    @State private var showingNewNotebookAlert = false
    @State private var newNotebookName = ""
    @State private var selectedNotebook: Notebook?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if notesManager.notebooks.isEmpty {
                    VStack {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding()
                        Text("Your Workspace is Empty")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("Create a notebook to start organizing your thoughts.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { showingNewNotebookAlert = true }) {
                            Text("New Notebook")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 200)
                                .background(Color.accentColor)
                                .cornerRadius(12)
                        }
                        .padding(.top, 24)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(notesManager.notebooks) { notebook in
                                NotebookCardView(notebook: notebook, notesManager: notesManager)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
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

struct NotebookCardView: View {
    let notebook: Notebook
    @ObservedObject var notesManager: NotesManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(Color(hex: notebook.colorHex ?? "8E8E93") ?? .gray)
                        .font(.title2)
                    
                    Text(notebook.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(notebook.notes.count) Notes")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.3))
            }
            
            // Notes List
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(notebook.notes) { note in
                        NavigationLink(destination: NoteEditorView(notebookId: notebook.id, noteId: note.id)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title.isEmpty ? "Untitled Note" : note.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text(note.content)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6).opacity(0.1))
                        }
                        Divider().background(Color.white.opacity(0.1))
                    }
                    
                    NavigationLink(destination: NoteEditorView(notebookId: notebook.id, noteId: nil)) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Note")
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6).opacity(0.1))
                    }
                }
            }
        }
        .background(Color(.systemGray6).opacity(0.2))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
