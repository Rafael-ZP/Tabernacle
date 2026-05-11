import SwiftUI
import Combine
struct ContentView: View {
    @State private var selectedTab: AppTab = .bible
    @StateObject private var navState = NavState.shared
    @StateObject private var dbManager = BibleDatabaseManager.shared
    @State private var isDatabaseReady = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if !isDatabaseReady {
                SplashView(dbManager: dbManager)
                    .transition(.scale(scale: 1.2).combined(with: .opacity))
                    .zIndex(200)
                    .onAppear {
                        dbManager.setupDatabaseIfNeeded {
                            // Adding a slight minimum delay to ensure the cinematic animation completes nicely
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    isDatabaseReady = true
                                }
                            }
                        }
                    }
            } else {
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
                if !navState.isHidden {
                    BottomNavView(selectedTab: $selectedTab)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(100)
                }
            }
        }
    }
}
