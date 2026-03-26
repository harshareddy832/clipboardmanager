import SwiftUI

struct SettingsView: View {
    @Binding var showSettings: Bool
    @EnvironmentObject var store: ClipboardStore

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    historySection
                    starredSection
                }
                .padding(16)
            }
        }
        .frame(width: 320, height: 480)
    }

    // MARK: - Header

    var header: some View {
        HStack {
            Button(action: { withAnimation { showSettings = false } }) {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 13))
                }
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            // Mirror of back button width for centering
            Color.clear.frame(width: 44, height: 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - History Section

    var historySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("HISTORY")

            VStack(spacing: 0) {
                // Row: History Limit
                settingRow(
                    icon: "clock",
                    iconColor: Color.blue,
                    title: "Keep Last",
                    subtitle: "Items remembered"
                ) {
                    Picker("", selection: $store.historyLimit) {
                        ForEach(HistoryLimit.allCases) { limit in
                            Text(limit.label == "Unlimited" ? "Unlimited" : "\(limit.label) items")
                                .tag(limit)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }

                rowDivider

                // Row: Auto-Clear
                settingRow(
                    icon: "timer",
                    iconColor: Color.orange,
                    title: "Auto-Clear",
                    subtitle: "Remove items older than"
                ) {
                    Picker("", selection: $store.autoClearInterval) {
                        ForEach(AutoClearInterval.allCases) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Starred Section

    var starredSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("STARRED ITEMS")

            VStack(spacing: 0) {
                // Status row
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.yellow.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.yellow)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(store.starredItems.count) item\(store.starredItems.count == 1 ? "" : "s") saved")
                            .font(.system(size: 13))
                        Text("Saved to disk · survives restarts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                rowDivider

                // Info row
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.purple.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                            .foregroundColor(.purple)
                    }

                    Text("Starred items are never affected by Clear All, auto-clear, or the history limit.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 1)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                if !store.starredItems.isEmpty {
                    rowDivider

                    // Remove all row
                    Button(action: { store.clearAllStarred() }) {
                        HStack {
                            Image(systemName: "star.slash")
                                .font(.system(size: 13))
                            Text("Remove All Starred")
                                .font(.system(size: 13))
                            Spacer()
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Helpers

    var rowDivider: some View {
        Divider()
            .padding(.leading, 52)
    }

    func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.leading, 4)
    }

    func settingRow<Control: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            control()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
