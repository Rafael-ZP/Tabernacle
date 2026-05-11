import SwiftUI

struct SearchView: View {
    @ObservedObject var tabManager: TabManager
    let activeTranslation: String
    @Binding var isPresented: Bool
    
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search \(activeTranslation)...", text: $query, onCommit: performSearch)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !query.isEmpty {
                        Button(action: {
                            query = ""
                            results = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if isSearching {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if results.isEmpty && !query.isEmpty {
                    Spacer()
                    Text("No results found.")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(results) { result in
                        Button(action: {
                            // Open result in active tab or new tab
                            tabManager.updateActiveTab(book: result.book, chapter: result.chapter)
                            tabManager.updateActiveTab(translation: result.translation)
                            // We would also update scroll position to the verse here
                            tabManager.updateScrollPosition(for: tabManager.activeTabId!, verseId: result.verse)
                            isPresented = false
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(result.book) \(result.chapter):\(result.verse)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.accentColor)
                                
                                Text(result.text)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .lineLimit(3)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
            .onChange(of: query) { oldValue, newValue in
                searchTask?.cancel()
                
                if newValue.isEmpty {
                    results = []
                    isSearching = false
                    return
                }
                
                let task = Task {
                    do {
                        try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                        if !Task.isCancelled {
                            await performSearchAsync(q: newValue)
                        }
                    } catch {
                        // Task cancelled
                    }
                }
                searchTask = task
            }
        }
    }
    
    @State private var searchTask: Task<Void, Never>? = nil
    
    private func performSearch() {
        guard !query.isEmpty else { return }
        isSearching = true
        BibleSearchService.shared.search(query: query, translation: activeTranslation) { res in
            self.results = res
            self.isSearching = false
        }
    }
    
    @MainActor
    private func performSearchAsync(q: String) async {
        isSearching = true
        BibleSearchService.shared.search(query: q, translation: activeTranslation) { res in
            self.results = res
            self.isSearching = false
        }
    }
}
