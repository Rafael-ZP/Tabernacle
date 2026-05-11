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
                VStack(spacing: 20) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Preparing Bible Library...")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if dbManager.isImporting {
                        ProgressView(value: dbManager.importProgress)
                            .progressViewStyle(.linear)
                            .padding(.horizontal, 40)
                        
                        Text("Optimizing for lightning-fast offline search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .onAppear {
                    dbManager.setupDatabaseIfNeeded {
                        withAnimation {
                            isDatabaseReady = true
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
        .preferredColorScheme(.dark)
    }
}
