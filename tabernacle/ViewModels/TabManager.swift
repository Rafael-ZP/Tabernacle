import Foundation
import SwiftUI
import Combine

class TabManager: ObservableObject {
    @Published var tabs: [ScriptureTab] = [] {
        didSet {
            saveTabs()
        }
    }
    
    @Published var activeTabId: UUID? {
        didSet {
            saveActiveTab()
        }
    }
    
    private let tabsKey = "saved_tabs"
    private let activeTabKey = "active_tab_id"
    
    init() {
        loadTabs()
        
        if tabs.isEmpty {
            // Default tab if none exist
            let defaultTab = ScriptureTab(book: "Genesis", chapter: 1)
            tabs.append(defaultTab)
            activeTabId = defaultTab.id
        } else if activeTabId == nil {
            activeTabId = tabs.first?.id
        }
    }
    
    // MARK: - Tab Operations
    func addTab(translation: String? = nil, book: String = "Genesis", chapter: Int = 1) {
        // Inherit translation from current active tab if not specified
        let defaultTrans = tabs.first(where: { $0.id == activeTabId })?.translation ?? "NIV"
        let newTab = ScriptureTab(translation: translation ?? defaultTrans, book: book, chapter: chapter)
        tabs.append(newTab)
        activeTabId = newTab.id
    }
    
    func closeTab(id: UUID, force: Bool = false) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        
        if tabs[index].isLocked && !force {
            return
        }
        
        tabs.remove(at: index)
        
        if tabs.isEmpty {
            // Prevent having zero tabs by adding a default one
            addTab()
        } else if activeTabId == id {
            // If closing active tab, switch to the adjacent one
            let newIndex = max(0, index - 1)
            activeTabId = tabs[newIndex].id
        }
    }
    
    func updateActiveTab(book: String, chapter: Int) {
        guard let id = activeTabId,
              let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        
        tabs[index].book = book
        tabs[index].chapter = chapter
        tabs[index].scrollPosition = nil // Reset scroll when changing chapter
    }
    
    // MARK: - Advanced Tab Features
    func togglePin(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[index].isPinned.toggle()
        sortTabs()
    }
    
    func toggleLock(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[index].isLocked.toggle()
    }
    
    func renameTab(id: UUID, name: String?) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[index].customName = name?.isEmpty == false ? name : nil
    }
    
    func setTabColor(id: UUID, colorHex: String?) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[index].colorTheme = colorHex
    }
    
    private func sortTabs() {
        // Pinned tabs go first
        tabs.sort { $0.isPinned && !$1.isPinned }
    }
    
    func updateActiveTab(translation: String) {
        guard let id = activeTabId,
              let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        
        tabs[index].translation = translation
    }
    
    func updateScrollPosition(for id: UUID, verseId: String) {
        if let index = tabs.firstIndex(where: { $0.id == id }) {
            tabs[index].scrollPosition = verseId
        }
    }
    
    // MARK: - Persistence
    private func saveTabs() {
        if let encoded = try? JSONEncoder().encode(tabs) {
            UserDefaults.standard.set(encoded, forKey: tabsKey)
        }
    }
    
    private func saveActiveTab() {
        if let id = activeTabId {
            UserDefaults.standard.set(id.uuidString, forKey: activeTabKey)
        }
    }
    
    private func loadTabs() {
        if let data = UserDefaults.standard.data(forKey: tabsKey),
           let decoded = try? JSONDecoder().decode([ScriptureTab].self, from: data) {
            self.tabs = decoded
        }
        
        if let activeIdString = UserDefaults.standard.string(forKey: activeTabKey),
           let uuid = UUID(uuidString: activeIdString) {
            self.activeTabId = uuid
        }
    }
}
