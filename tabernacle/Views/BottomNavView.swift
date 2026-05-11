import SwiftUI

enum AppTab: String, CaseIterable {
    case bible = "Bible"
    case bookmarks = "Bookmarks"
    case analytics = "Analytics"
    case notes = "Notes"
    
    var icon: String {
        switch self {
        case .bible: return "book.fill"
        case .bookmarks: return "bookmark.fill"
        case .analytics: return "chart.bar.fill"
        case .notes: return "note.text"
        }
    }
}

struct BottomNavView: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .bold : .regular))
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                            .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .background {
            // Liquid Glass effect
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.black.opacity(0.3)) // Dark tint
                
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            // Drop shadow
            .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 0)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
