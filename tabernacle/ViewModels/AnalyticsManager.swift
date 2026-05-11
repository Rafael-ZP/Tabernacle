import Foundation
import SwiftUI
import Combine

struct ReadingSession: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let book: String
    let chaptersRead: Int
    let durationSeconds: Int
}

class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    @Published var sessions: [ReadingSession] = [] {
        didSet {
            saveSessions()
            calculateStats()
        }
    }
    
    @Published var currentStreak: Int = 0
    @Published var totalBooksRead: Int = 0
    @Published var mostReadBook: String = "None"
    
    private let sessionsKey = "analytics_sessions"
    
    private init() {
        loadSessions()
        calculateStats()
    }
    
    func logSession(book: String, chapters: Int, duration: Int) {
        // Only log if meaningful reading occurred (e.g., > 10 seconds)
        guard duration > 10 else { return }
        
        let session = ReadingSession(date: Date(), book: book, chaptersRead: chapters, durationSeconds: duration)
        sessions.append(session)
    }
    
    private func calculateStats() {
        // Calculate Streak
        let sortedDates = sessions.map { Calendar.current.startOfDay(for: $0.date) }.sorted(by: >)
        let uniqueDates = Array(Set(sortedDates)).sorted(by: >)
        
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        for date in uniqueDates {
            if date == currentDate {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else if date == Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) && streak == 0 {
                // If they didn't read today but read yesterday, streak is still active
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -2, to: Calendar.current.startOfDay(for: Date()))!
            } else {
                break
            }
        }
        self.currentStreak = streak
        
        // Calculate Most Read
        var bookCounts: [String: Int] = [:]
        for session in sessions {
            bookCounts[session.book, default: 0] += session.chaptersRead
        }
        
        self.totalBooksRead = bookCounts.keys.count
        self.mostReadBook = bookCounts.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([ReadingSession].self, from: data) {
            self.sessions = decoded
        }
    }
}
