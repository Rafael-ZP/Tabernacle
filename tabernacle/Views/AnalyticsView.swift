import SwiftUI

struct AnalyticsView: View {
    @StateObject private var analyticsManager = AnalyticsManager.shared
    
    // Format time spent to readable string
    var formattedTime: String {
        let totalSeconds = analyticsManager.totalTimeSpentSeconds
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        Text("Reading Insights")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        // Main Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(
                                title: "Current Streak",
                                value: "\(analyticsManager.currentStreak)",
                                subtitle: "Days",
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            StatCard(
                                title: "Time Spent",
                                value: formattedTime,
                                subtitle: "Reading",
                                icon: "clock.fill",
                                color: .cyan
                            )
                            
                            StatCard(
                                title: "Chapters",
                                value: "\(analyticsManager.totalChaptersRead)",
                                subtitle: "Completed",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Books",
                                value: "\(analyticsManager.totalBooksRead)",
                                subtitle: "Explored",
                                icon: "books.vertical.fill",
                                color: .blue
                            )
                        }
                        .padding(.horizontal)
                        
                        // Most Read
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Most Read Book")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                
                                Text(analyticsManager.mostReadBook)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6).opacity(0.2))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
