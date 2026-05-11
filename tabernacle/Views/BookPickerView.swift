import SwiftUI

struct BookPickerView: View {
    @ObservedObject var tabManager: TabManager
    let currentBook: String
    @Binding var isPresented: Bool
    
    @State private var selectedBook: String?
    let allBooks = BibleDataService.shared.allBookNames
    
    // For the chapter grid
    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                if let book = selectedBook {
                    // Chapter selection
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            let chapterCount = BibleDataService.shared.getBook(name: book)?.count ?? 1
                            ForEach(1...chapterCount, id: \.self) { chapter in
                                Button(action: {
                                    tabManager.updateActiveTab(book: book, chapter: chapter)
                                    isPresented = false
                                }) {
                                    Text("\(chapter)")
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(width: 60, height: 60)
                                        .background(Color(.systemGray6))
                                        .foregroundColor(.primary)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                    }
                    .navigationTitle(book)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(leading: Button("Back") {
                        selectedBook = nil
                    })
                } else {
                    // Book selection
                    List(allBooks, id: \.self) { book in
                        Button(action: {
                            selectedBook = book
                        }) {
                            HStack {
                                Text(book)
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                                Spacer()
                                if book == currentBook {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .navigationTitle("Books")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button("Cancel") {
                        isPresented = false
                    })
                }
            }
        }
        .onAppear {
            if selectedBook == nil {
                // Pre-scroll to current book could be implemented here
            }
        }
    }
}
