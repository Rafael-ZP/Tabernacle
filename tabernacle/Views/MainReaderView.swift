import SwiftUI

struct MainReaderView: View {
    @StateObject private var tabManager = TabManager()
    
    var body: some View {
        VStack(spacing: 0) {
            TabBarView(tabManager: tabManager)
            
            // Rendering the active tab
            if let activeId = tabManager.activeTabId,
               let activeTab = tabManager.tabs.first(where: { $0.id == activeId }) {
                ReaderView(
                    tabManager: tabManager,
                    tabId: activeTab.id,
                    translation: activeTab.translation,
                    book: activeTab.book,
                    chapter: activeTab.chapter
                )
                // We use .id(activeTab.id) so SwiftUI recreates/updates the view 
                // properly when switching tabs if needed, or we just rely on onChange.
                // Actually, relying on onChange is smoother for not losing internal state
                // unless we truly switch completely. Let's id it by the tab id.
                .id(activeTab.id)
            } else {
                // Empty state if somehow all tabs are closed
                VStack {
                    Spacer()
                    Text("No open tabs")
                        .foregroundColor(.secondary)
                    Button("Open Scripture") {
                        tabManager.addTab()
                    }
                    .padding()
                    Spacer()
                }
            }
        }
        // Force dark mode or use system
        // .preferredColorScheme(.dark)
    }
}
