import SwiftUI

struct BookmarksView: View {
    @StateObject private var studyManager = StudyManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if studyManager.items.isEmpty {
                    VStack {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                            .padding()
                        Text("No highlights or bookmarks yet")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(studyManager.items) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(item.book) \(item.chapter):\(item.verseId)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                if let note = item.noteText, !note.isEmpty {
                                    Text(note)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                } else if let color = item.colorHex {
                                    HStack {
                                        Circle()
                                            .fill(hexToColor(color))
                                            .frame(width: 10, height: 10)
                                        Text("Highlighted")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Highlights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func hexToColor(_ hex: String) -> Color {
        switch hex {
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        default: return .gray
        }
    }
}
