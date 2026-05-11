import SwiftUI

struct TabBarView: View {
    @ObservedObject var tabManager: TabManager
    
    @State private var tabToRename: ScriptureTab? = nil
    @State private var newName = ""
    
    @State private var tabToClose: ScriptureTab? = nil
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabManager.tabs) { tab in
                    TabItemView(
                        tab: tab,
                        isActive: tabManager.activeTabId == tab.id,
                        canClose: tabManager.tabs.count > 1,
                        onSelect: { tabManager.activeTabId = tab.id },
                        onClose: {
                            HapticsManager.shared.playImpact(style: .rigid)
                            tabToClose = tab
                        },
                        onRename: {
                            newName = tab.customName ?? ""
                            tabToRename = tab
                        },
                        tabManager: tabManager
                    )
                }
                
                Button(action: {
                    withAnimation {
                        HapticsManager.shared.playImpact(style: .light)
                        tabManager.addTab()
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .padding(.leading, 4)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: tabManager.tabs)
            .animation(.easeInOut(duration: 0.2), value: tabManager.activeTabId)
        }
        .background(Color(.systemBackground).shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2))
        .background(
            Group {
                Color.clear.frame(width: 0, height: 0)
                    .alert("Rename Tab", isPresented: Binding<Bool>(
                        get: { tabToRename != nil },
                        set: { if !$0 { tabToRename = nil } }
                    )) {
                        TextField("Tab Name", text: $newName)
                        Button("Save") {
                            if let tab = tabToRename {
                                tabManager.renameTab(id: tab.id, name: newName)
                            }
                            tabToRename = nil
                        }
                        Button("Cancel", role: .cancel) { tabToRename = nil }
                    }
                
                Color.clear.frame(width: 0, height: 0)
                    .alert("Close Tab", isPresented: Binding<Bool>(
                        get: { tabToClose != nil },
                        set: { if !$0 { tabToClose = nil } }
                    )) {
                        Button("Close Tab", role: .destructive) {
                            if let tab = tabToClose {
                                tabManager.closeTab(id: tab.id, force: true)
                            }
                            tabToClose = nil
                        }
                        Button("Cancel", role: .cancel) { tabToClose = nil }
                    } message: {
                        Text("Do you really want to close this Tab?")
                    }
            }
        )
    }
}

struct TabItemView: View {
    let tab: ScriptureTab
    let isActive: Bool
    let canClose: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onRename: () -> Void
    @ObservedObject var tabManager: TabManager
    
    var tabColor: Color {
        if let hex = tab.colorTheme {
            switch hex {
            case "red": return .red
            case "blue": return .blue
            case "green": return .green
            case "orange": return .orange
            case "purple": return .purple
            case "pink": return .pink
            case "teal": return .teal
            case "indigo": return .indigo
            case "cyan": return .cyan
            case "brown": return .brown
            default: return .clear
            }
        }
        return .clear
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if tab.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(isActive ? .primary : .secondary)
            }
            
            if tab.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(isActive ? .primary : .secondary)
            }
            
            if !tab.isPinned || isActive {
                Text(tab.title)
                    .font(.system(size: 14, weight: isActive ? .semibold : .medium))
                    .foregroundColor(isActive ? .primary : .secondary)
                    .lineLimit(1)
            }
            
            if canClose && !tab.isLocked {
                Button(action: {
                    withAnimation { onClose() }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isActive ? .primary : .secondary)
                        .padding(4)
                        .background(isActive ? Color(.systemGray4) : Color.clear)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, tab.isPinned && !isActive ? 12 : 12)
        .padding(.vertical, 8)
        .background(isActive ? (tab.colorTheme != nil ? tabColor.opacity(0.3) : Color(.systemGray6)) : (tab.colorTheme != nil ? tabColor.opacity(0.1) : Color.clear))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tabColor != .clear ? tabColor.opacity(0.5) : Color(.systemGray4), lineWidth: isActive ? 1.5 : 0)
        )
        .onTapGesture {
            withAnimation { 
                HapticsManager.shared.playSelection()
                onSelect() 
            }
        }
        .contextMenu {
            Button(action: { tabManager.togglePin(id: tab.id) }) {
                Label(tab.isPinned ? "Unpin Tab" : "Pin Tab", systemImage: tab.isPinned ? "pin.slash" : "pin")
            }
            
            Button(action: { tabManager.toggleLock(id: tab.id) }) {
                Label(tab.isLocked ? "Unlock Tab" : "Lock Tab", systemImage: tab.isLocked ? "lock.open" : "lock")
            }
            
            Button(action: onRename) {
                Label("Rename Tab", systemImage: "pencil")
            }
            
            Menu {
                Button("Default") { tabManager.setTabColor(id: tab.id, colorHex: nil) }
                Button("Red") { tabManager.setTabColor(id: tab.id, colorHex: "red") }
                Button("Blue") { tabManager.setTabColor(id: tab.id, colorHex: "blue") }
                Button("Green") { tabManager.setTabColor(id: tab.id, colorHex: "green") }
                Button("Orange") { tabManager.setTabColor(id: tab.id, colorHex: "orange") }
                Button("Purple") { tabManager.setTabColor(id: tab.id, colorHex: "purple") }
                Button("Pink") { tabManager.setTabColor(id: tab.id, colorHex: "pink") }
                Button("Teal") { tabManager.setTabColor(id: tab.id, colorHex: "teal") }
                Button("Indigo") { tabManager.setTabColor(id: tab.id, colorHex: "indigo") }
                Button("Cyan") { tabManager.setTabColor(id: tab.id, colorHex: "cyan") }
                Button("Brown") { tabManager.setTabColor(id: tab.id, colorHex: "brown") }
            } label: {
                Label("Color Code", systemImage: "paintpalette")
            }
        }
    }
}
