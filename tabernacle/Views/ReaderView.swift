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
    @State private var lastScrollY: CGFloat = 0
    @State private var swipeOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Button(action: { isShowingBookPicker = true }) {
                        HStack {
                            Text("\(book) \(chapter)")
                                .font(.system(size: 20, weight: .bold))
                                .contentTransition(.numericText())
                                .animation(.easeInOut, value: chapter)
                                .animation(.easeInOut, value: book)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Menu {
                        ForEach(BibleDataService.shared.availableTranslations, id: \.self) { trans in
                            Button(trans) {
                                // Defer the state change slightly to allow the Menu to close natively.
                                // This prevents the "_UIReparentingView" console warning spam.
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    tabManager.updateActiveTab(translation: trans)
                                }
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
                
                // Search Icon Only
                HStack(spacing: 16) {
                    Button(action: { isShowingSearch = true }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .font(.system(size: 18))
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Reader content
            if let chapterData = viewModel.currentChapter {
                ZStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                let chapterNum = Int(chapterData.chapter) ?? chapter
                                ForEach(chapterData.verses) { verse in
                                    VerseRowView(
                                        verse: verse,
                                        book: book,
                                        chapterNum: chapterNum,
                                        translation: translation,
                                        studyManager: studyManager
                                    )
                                }
                            }
                            .padding()
                            .background(GeometryReader { geo -> Color in
                                let currentY = geo.frame(in: .global).minY
                                DispatchQueue.main.async {
                                    if currentY < self.lastScrollY - 20 {
                                        // Scrolling down
                                        NavState.shared.hide()
                                    } else if currentY > self.lastScrollY + 20 {
                                        // Scrolling up
                                        NavState.shared.show()
                                    }
                                    self.lastScrollY = currentY
                                }
                                return Color.clear
                            })
                        }
                        .offset(x: swipeOffset)
                        .opacity(1.0 - Double(abs(swipeOffset) / 200.0))
                        .gesture(
                            DragGesture(minimumDistance: 40)
                                .onChanged { value in
                                    // Only swipe horizontally if vertical scroll isn't dominating
                                    if abs(value.translation.width) > abs(value.translation.height) * 1.5 {
                                        withAnimation(.interactiveSpring()) {
                                            swipeOffset = value.translation.width
                                        }
                                    }
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 80
                                    if value.translation.width < -threshold {
                                        // Swipe Left -> Next Chapter
                                        HapticsManager.shared.playImpact(style: .medium)
                                        navigate(forward: true)
                                    } else if value.translation.width > threshold {
                                        // Swipe Right -> Previous Chapter
                                        HapticsManager.shared.playImpact(style: .medium)
                                        navigate(forward: false)
                                    } else {
                                        withAnimation(.spring()) {
                                            swipeOffset = 0
                                        }
                                    }
                                }
                        )
                        .onAppear {
                            // Restore scroll position
                            if let tab = tabManager.tabs.first(where: { $0.id == tabId }),
                               let verseId = tab.scrollPosition {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    proxy.scrollTo(verseId, anchor: .top)
                                }
                            }
                        }
                        .onChange(of: chapter) { _, _ in
                            if let firstVerse = chapterData.verses.first {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    proxy.scrollTo(firstVerse.id, anchor: .top)
                                }
                            }
                        }
                        .onChange(of: book) { _, _ in
                            if let firstVerse = chapterData.verses.first {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    proxy.scrollTo(firstVerse.id, anchor: .top)
                                }
                            }
                        }
                    }
                    
                    // Navigation Arrows Overlay
                    HStack {
                        Button(action: {
                            HapticsManager.shared.playImpact(style: .medium)
                            navigate(forward: false)
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Color(.systemBackground).opacity(0.4))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            HapticsManager.shared.playImpact(style: .medium)
                            navigate(forward: true)
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Color(.systemBackground).opacity(0.4))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 4) // Moved arrows closer to the edge
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
    
    private func navigate(forward: Bool) {
        let allBooks = viewModel.allBookNames
        guard let currentBookIndex = allBooks.firstIndex(of: book) else { return }
        
        var newBook = book
        var newChapter = chapter
        
        if forward {
            if chapter < viewModel.totalChapters {
                newChapter += 1
            } else if currentBookIndex < allBooks.count - 1 {
                newBook = allBooks[currentBookIndex + 1]
                newChapter = 1
            }
        } else {
            if chapter > 1 {
                newChapter -= 1
            } else if currentBookIndex > 0 {
                newBook = allBooks[currentBookIndex - 1]
                let previousChapters = viewModel.getChapterNumbers(for: newBook)
                newChapter = previousChapters.last ?? 1
            }
        }
        
        if newBook != book || newChapter != chapter {
            withAnimation(.spring()) {
                swipeOffset = forward ? -500 : 500
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                tabManager.updateActiveTab(book: newBook, chapter: newChapter)
                swipeOffset = forward ? 500 : -500
                withAnimation(.spring()) {
                    swipeOffset = 0
                }
            }
        } else {
            withAnimation(.spring()) {
                swipeOffset = 0
            }
        }
    }
    
    // Helper to convert hex string to color
    private func hexToColor(_ hex: String) -> Color {
        switch hex {
        case "yellow": return Color.yellow.opacity(0.3)
        case "green": return Color.green.opacity(0.3)
        case "blue": return Color.blue.opacity(0.3)
        case "pink": return Color.pink.opacity(0.3)
        case "orange": return Color.orange.opacity(0.3)
        case "purple": return Color.purple.opacity(0.3)
        default: return Color.clear
        }
    }
}

struct VerseRowView: View {
    let verse: BibleVerse
    let book: String
    let chapterNum: Int
    let translation: String
    @ObservedObject var studyManager: StudyManager
    
    // Helper to convert hex string to color
    private func hexToColor(_ hex: String) -> Color {
        switch hex {
        case "yellow": return Color.yellow.opacity(0.3)
        case "green": return Color.green.opacity(0.3)
        case "blue": return Color.blue.opacity(0.3)
        case "pink": return Color.pink.opacity(0.3)
        case "orange": return Color.orange.opacity(0.3)
        case "purple": return Color.purple.opacity(0.3)
        default: return Color.clear
        }
    }
    
    var body: some View {
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
                    studyManager.getItems(for: book, chapter: chapterNum).first(where: { $0.verseId == verse.verse })?.colorHex.map { hexToColor($0) } ?? Color.clear
                )
        }
        .id(verse.id)
        .contextMenu {
            Button {
                HapticsManager.shared.playImpact(style: .light)
                studyManager.addHighlight(translation: translation, book: book, chapter: chapterNum, verseId: verse.verse, colorHex: "yellow")
            } label: {
                Label("Yellow", systemImage: "circle.fill")
            }
            .tint(.yellow)
            
            Button {
                HapticsManager.shared.playImpact(style: .light)
                studyManager.addHighlight(translation: translation, book: book, chapter: chapterNum, verseId: verse.verse, colorHex: "green")
            } label: {
                Label("Green", systemImage: "circle.fill")
            }
            .tint(.green)
            
            Button {
                HapticsManager.shared.playImpact(style: .light)
                studyManager.addHighlight(translation: translation, book: book, chapter: chapterNum, verseId: verse.verse, colorHex: "blue")
            } label: {
                Label("Blue", systemImage: "circle.fill")
            }
            .tint(.blue)
            
            Button {
                HapticsManager.shared.playImpact(style: .light)
                studyManager.addHighlight(translation: translation, book: book, chapter: chapterNum, verseId: verse.verse, colorHex: "pink")
            } label: {
                Label("Pink", systemImage: "circle.fill")
            }
            .tint(.pink)
            
            Button {
                HapticsManager.shared.playImpact(style: .light)
                studyManager.addHighlight(translation: translation, book: book, chapter: chapterNum, verseId: verse.verse, colorHex: "orange")
            } label: {
                Label("Orange", systemImage: "circle.fill")
            }
            .tint(.orange)
            
            Button {
                HapticsManager.shared.playImpact(style: .light)
                studyManager.addHighlight(translation: translation, book: book, chapter: chapterNum, verseId: verse.verse, colorHex: "purple")
            } label: {
                Label("Purple", systemImage: "circle.fill")
            }
            .tint(.purple)
            
            Button(role: .destructive) {
                HapticsManager.shared.playImpact(style: .light)
                studyManager.removeHighlight(book: book, chapter: chapterNum, verseId: verse.verse)
            } label: {
                Label("Remove Highlight", systemImage: "xmark.circle.fill")
            }
        }
    }
}
