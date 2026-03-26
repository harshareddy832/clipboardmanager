import SwiftUI
import AppKit

enum ClipboardTab { case history, starred }

struct ClipboardView: View {
    @EnvironmentObject var store: ClipboardStore
    @State private var copiedID: UUID? = nil
    @State private var selectedTab: ClipboardTab = .history
    @State private var showSettings = false

    var body: some View {
        ZStack {
            if showSettings {
                SettingsView(showSettings: $showSettings)
                    .environmentObject(store)
                    .transition(.move(edge: .trailing))
            } else {
                mainView
                    .transition(.move(edge: .leading))
            }
        }
        .frame(width: 320, height: 480)
        .animation(.easeInOut(duration: 0.2), value: showSettings)
    }

    // MARK: - Main

    var mainView: some View {
        VStack(spacing: 0) {
            headerView
            searchBar
            Divider()
            contentView
            Divider()
            footerView
        }
    }

    var headerView: some View {
        HStack(spacing: 8) {
            // Tabs
            HStack(spacing: 2) {
                tabButton("History", tab: .history)
                tabButton("Starred", tab: .starred, icon: "star.fill")
            }
            .padding(3)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            if selectedTab == .history && !store.items.isEmpty {
                Button("Clear") { store.clearAll() }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: { withAnimation { showSettings = true } }) {
                Image(systemName: "gear")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    func tabButton(_ title: String, tab: ClipboardTab, icon: String? = nil) -> some View {
        let active = selectedTab == tab
        return Button(action: { selectedTab = tab }) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(active ? .yellow : .secondary)
                }
                Text(title)
                    .font(.system(size: 12, weight: active ? .semibold : .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(active ? Color.accentColor.opacity(0.12) : Color.clear)
            .cornerRadius(6)
            .foregroundColor(active ? .accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }

    var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 13))
            TextField("Search...", text: $store.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            if !store.searchText.isEmpty {
                Button(action: { store.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    var contentView: some View {
        let displayItems = selectedTab == .history ? store.filteredItems : store.filteredStarred
        if displayItems.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(displayItems) { item in
                        ClipboardItemRow(
                            item: item,
                            copiedID: $copiedID,
                            isStarred: store.isStarred(item),
                            inStarredTab: selectedTab == .starred
                        )
                        .environmentObject(store)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: selectedTab == .starred ? "star" : "clipboard")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.4))
            Text(emptyMessage)
                .foregroundColor(.secondary)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    var emptyMessage: String {
        if !store.searchText.isEmpty { return "No results for \"\(store.searchText)\"" }
        return selectedTab == .history
            ? "Nothing copied yet"
            : "No starred items yet\nHover any item and tap ★ to save it"
    }

    var footerView: some View {
        HStack {
            let count = selectedTab == .history ? store.items.count : store.starredItems.count
            Text("\(count) item\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }
}

// MARK: - Row

struct ClipboardItemRow: View {
    let item: ClipboardItem
    @Binding var copiedID: UUID?
    let isStarred: Bool
    let inStarredTab: Bool
    @EnvironmentObject var store: ClipboardStore
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.preview)
                    .lineLimit(3)
                    .font(.system(size: 12))
                Text(item.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 4)

            if isHovered || copiedID == item.id {
                HStack(spacing: 6) {
                    // Star / Unstar
                    Button(action: {
                        inStarredTab ? store.deleteStarred(item) : store.toggleStar(item)
                    }) {
                        Image(systemName: isStarred ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(isStarred ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)

                    // Copy
                    Button(action: doCopy) {
                        Image(systemName: copiedID == item.id ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(copiedID == item.id ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    // Delete (history only)
                    if !inStarredTab {
                        Button(action: { store.delete(item) }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else if isStarred && !inStarredTab {
                // Subtle star indicator when not hovering
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.25) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(perform: doCopy)
        .padding(.horizontal, 6)
    }

    private func doCopy() {
        store.copy(item)
        withAnimation { copiedID = item.id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedID == item.id { withAnimation { copiedID = nil } }
        }
    }
}
