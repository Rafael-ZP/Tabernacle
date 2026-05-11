import Foundation
import Combine
import SwiftUI

class NavState: ObservableObject {
    static let shared = NavState()
    
    @Published var isHidden: Bool = false
    
    private init() {}
    
    func hide() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isHidden = true
        }
    }
    
    func show() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isHidden = false
        }
    }
}
