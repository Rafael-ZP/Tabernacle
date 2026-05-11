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
                        onSelect: { tabManager.activeTabId = tab.id },
                        onClose: {
                            if tab.isLocked {
                                tabToClose = tab
                            } else {
                                tabManager.closeTab(id: tab.id)
                            }
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
        }
        .background(Color(.systemBackground).shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2))
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
        .alert("Close Locked Tab", isPresented: Binding<Bool>(
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
            Text("This tab is locked. Do you really want to close it?")
        }
    }
}

struct TabItemView: View {
    let tab: ScriptureTab
    let isActive: Bool
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
        .padding(.horizontal, tab.isPinned && !isActive ? 12 : 12)
        .padding(.vertical, 8)
        .background(isActive ? (tab.colorTheme != nil ? tabColor.opacity(0.3) : Color(.systemGray6)) : (tab.colorTheme != nil ? tabColor.opacity(0.1) : Color.clear))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tabColor != .clear ? tabColor.opacity(0.5) : Color(.systemGray4), lineWidth: isActive ? 1.5 : 0)
        )
        .onTapGesture {
            withAnimation { onSelect() }
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
            } label: {
                Label("Color Code", systemImage: "paintpalette")
            }
        }
    }
}
