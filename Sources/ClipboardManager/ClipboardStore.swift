import SwiftUI
import AppKit

private enum Keys {
    static let historyLimit       = "historyLimit"
    static let autoClearInterval  = "autoClearInterval"
    static let starredItems       = "starredItems"
}

class ClipboardStore: ObservableObject {

    // MARK: - Settings (persisted)

    @Published var historyLimit: HistoryLimit {
        didSet {
            UserDefaults.standard.set(historyLimit.rawValue, forKey: Keys.historyLimit)
            enforceLimit()
        }
    }

    @Published var autoClearInterval: AutoClearInterval {
        didSet {
            UserDefaults.standard.set(autoClearInterval.rawValue, forKey: Keys.autoClearInterval)
        }
    }

    // MARK: - Data

    @Published var items: [ClipboardItem] = []

    @Published var starredItems: [ClipboardItem] = [] {
        didSet { saveStarred() }
    }

    @Published var searchText: String = ""

    // MARK: - Computed

    var filteredItems: [ClipboardItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredStarred: [ClipboardItem] {
        guard !searchText.isEmpty else { return starredItems }
        return starredItems.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Private

    private var lastChangeCount: Int = 0
    private var clipboardTimer: Timer?
    private var clearTimer: Timer?

    // MARK: - Init

    init() {
        let limitRaw = UserDefaults.standard.integer(forKey: Keys.historyLimit)
        self.historyLimit = HistoryLimit(rawValue: limitRaw == 0 ? 50 : limitRaw) ?? .fifty

        let intervalRaw = UserDefaults.standard.string(forKey: Keys.autoClearInterval) ?? AutoClearInterval.never.rawValue
        self.autoClearInterval = AutoClearInterval(rawValue: intervalRaw) ?? .never

        self.starredItems = Self.loadStarred()

        lastChangeCount = NSPasteboard.general.changeCount
        startTimers()
    }

    // MARK: - Monitoring

    private func startTimers() {
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        // Auto-clear check runs every 60s
        clearTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.autoClearOldItems()
        }
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let string = pasteboard.string(forType: .string), !string.isEmpty else { return }
        guard items.first?.content != string else { return }

        DispatchQueue.main.async {
            self.items.insert(ClipboardItem(content: string), at: 0)
            self.enforceLimit()
        }
    }

    private func enforceLimit() {
        guard historyLimit != .unlimited else { return }
        if items.count > historyLimit.rawValue {
            items = Array(items.prefix(historyLimit.rawValue))
        }
    }

    private func autoClearOldItems() {
        guard let cutoff = autoClearInterval.seconds.map({ Date().addingTimeInterval(-$0) }) else { return }
        DispatchQueue.main.async {
            self.items.removeAll { $0.timestamp < cutoff }
        }
    }

    // MARK: - Actions

    func copy(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }

    func clearAll() {
        items.removeAll()
    }

    // MARK: - Starred

    func isStarred(_ item: ClipboardItem) -> Bool {
        starredItems.contains { $0.content == item.content }
    }

    func toggleStar(_ item: ClipboardItem) {
        if let idx = starredItems.firstIndex(where: { $0.content == item.content }) {
            starredItems.remove(at: idx)
        } else {
            starredItems.insert(ClipboardItem(content: item.content, timestamp: item.timestamp), at: 0)
        }
    }

    func deleteStarred(_ item: ClipboardItem) {
        starredItems.removeAll { $0.id == item.id }
    }

    func clearAllStarred() {
        starredItems.removeAll()
    }

    // MARK: - Persistence

    private func saveStarred() {
        if let data = try? JSONEncoder().encode(starredItems) {
            UserDefaults.standard.set(data, forKey: Keys.starredItems)
        }
    }

    private static func loadStarred() -> [ClipboardItem] {
        guard let data = UserDefaults.standard.data(forKey: Keys.starredItems),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data)
        else { return [] }
        return decoded
    }

    deinit {
        clipboardTimer?.invalidate()
        clearTimer?.invalidate()
    }
}
