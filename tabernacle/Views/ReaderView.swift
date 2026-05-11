import SwiftUI

struct ReaderView: View {
    @StateObject private var viewModel = BibleViewModel()
    @ObservedObject var tabManager: TabManager
    @ObservedObject var studyManager = StudyManager.shared
    let tabId: UUID
    let translation: String
    let book: String
    let chapter: Int
    
    @State private var isShowingBookPicker = false
    @State private var isShowingSearch = false
    @State private var readingStartDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Button(action: { isShowingBookPicker = true }) {
                        HStack {
                            Text("\(book) \(chapter)")
                                .font(.system(size: 20, weight: .bold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Menu {
                        ForEach(BibleDataService.shared.availableTranslations, id: \.self) { trans in
                            Button(trans) {
                                tabManager.updateActiveTab(translation: trans)
                            }
                        }
                    } label: {
                        Text(translation)
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Future feature placeholders
                HStack(spacing: 16) {
                    Button(action: { isShowingSearch = true }) {
                        Image(systemName: "magnifyingglass")
                    }
                    Image(systemName: "bookmark")
                    Image(systemName: "slider.horizontal.3")
                }
                .font(.system(size: 18))
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Reader content
            if let chapterData = viewModel.currentChapter {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            let chapterNum = Int(chapterData.chapter) ?? chapter
                            ForEach(chapterData.verses) { verse in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(verse.verse)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                    
                                    Text(verse.text)
                                        .font(.system(size: 18, weight: .regular))
                                        .lineSpacing(6)
                                        .foregroundColor(.primary)
                                        .background(
                                            StudyManager.shared.getItems(for: book, chapter: chapterNum).first(where: { $0.verseId == verse.verse })?.colorHex.map { hexToColor($0) } ?? Color.clear
                                        )
                                }
                                .id(verse.id)
                                .contextMenu {
                                    Button("Highlight Yellow") { StudyManager.shared.addHighlight(translation: translation, book: book, chapter: chapterNum, verseId: verse.verse, colorHex: "yellow") }
                                    Button("Highlight Green") { StudyManager.shared.addHighlight(translation: translation, book: book, chapter: chapterNum, verseId: verse.verse, colorHex: "green") }
                                    Button("Remove Highlight") { StudyManager.shared.removeHighlight(book: book, chapter: chapterNum, verseId: verse.verse) }
                                }
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        // Restore scroll position
                        if let tab = tabManager.tabs.first(where: { $0.id == tabId }),
                           let verseId = tab.scrollPosition {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                proxy.scrollTo(verseId, anchor: .top)
                            }
                        }
                    }
                }
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
        .onAppear {
            readingStartDate = Date()
            viewModel.load(bookName: book, chapterNumber: chapter, translation: translation)
        }
        .onDisappear {
            logSession()
        }
        .onChange(of: book) { oldBook, newBook in
            logSession()
            readingStartDate = Date()
            viewModel.load(bookName: newBook, chapterNumber: chapter, translation: translation)
        }
        .onChange(of: chapter) { oldChapter, newChapter in
            logSession()
            readingStartDate = Date()
            viewModel.load(bookName: book, chapterNumber: newChapter, translation: translation)
        }
        .onChange(of: translation) { oldTrans, newTrans in
            logSession()
            readingStartDate = Date()
            viewModel.load(bookName: book, chapterNumber: chapter, translation: newTrans)
        }
        .sheet(isPresented: $isShowingBookPicker) {
            BookPickerView(
                tabManager: tabManager,
                currentBook: book,
                isPresented: $isShowingBookPicker
            )
        }
        .sheet(isPresented: $isShowingSearch) {
            SearchView(
                tabManager: tabManager,
                activeTranslation: translation,
                isPresented: $isShowingSearch
            )
        }
    }
    
    private func logSession() {
        let duration = Int(Date().timeIntervalSince(readingStartDate))
        AnalyticsManager.shared.logSession(book: book, chapters: 1, duration: duration)
    }
    
    // Helper to convert hex string to color
    private func hexToColor(_ hex: String) -> Color {
        switch hex {
        case "yellow": return Color.yellow.opacity(0.3)
        case "green": return Color.green.opacity(0.3)
        default: return Color.clear
        }
    }
}
