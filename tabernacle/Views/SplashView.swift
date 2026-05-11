import SwiftUI

extension Bundle {
    var appIcon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let icon = files.last {
            return UIImage(named: icon)
        }
        return nil
    }
}

struct SplashView: View {
    @ObservedObject var dbManager: BibleDatabaseManager
    
    @State private var logoScale: CGFloat = 10.0 // Start extremely large (zoomed in)
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 20
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 30) {
                if let icon = Bundle.main.appIcon {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                } else {
                    // Fallback if AppIcon cannot be extracted natively
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.blue)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                
                Text("Living Word of GOD")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                    
                if dbManager.isImporting {
                    VStack(spacing: 8) {
                        ProgressView(value: dbManager.importProgress)
                            .progressViewStyle(.linear)
                            .padding(.horizontal, 60)
                        
                        Text("Optimizing for lightning-fast search...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .opacity(textOpacity)
                }
            }
        }
        .onAppear {
            // Logo Zoom Out
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.5)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Text fade in gracefully
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                textOpacity = 1.0
                textOffset = 0
            }
        }
    }
}
