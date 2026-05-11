import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .bible
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            Group {
                switch selectedTab {
                case .bible:
                    MainReaderView()
                case .bookmarks:
                    BookmarksView()
                case .analytics:
                    AnalyticsView()
                case .notes:
                    NotesDashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Navigation
            BottomNavView(selectedTab: $selectedTab)
        }
        .preferredColorScheme(.dark)
    }
}
