import SwiftUI
import AppKit

enum TaskTab { case active, completed }

struct TaskView: View {
    @EnvironmentObject var store: TaskStore
    @State private var tab: TaskTab = .active
    @State private var newTitle = ""
    @State private var newPriority: Priority = .medium

    var body: some View {
        VStack(spacing: 0) {
            header
            addBar
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 320, height: 480)
    }

    // MARK: - Header

    var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                tabButton("Tasks", tab: .active)
                tabButton("Done", tab: .completed)
            }
            .padding(3)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            if tab == .completed && !store.completed.isEmpty {
                Button("Clear") { store.clearCompleted() }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    func tabButton(_ title: String, tab: TaskTab) -> some View {
        let active = self.tab == tab
        return Button(action: { self.tab = tab }) {
            Text(title)
                .font(.system(size: 12, weight: active ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(active ? Color.accentColor.opacity(0.12) : Color.clear)
                .cornerRadius(6)
                .foregroundColor(active ? .accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Bar

    var addBar: some View {
        HStack(spacing: 8) {
            TextField("Add a task...", text: $newTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit { submitTask() }

            // Priority picker
            Menu {
                ForEach(Priority.allCases) { p in
                    Button(action: { newPriority = p }) {
                        Label(p.rawValue, systemImage: p.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: newPriority.icon)
                        .font(.system(size: 11))
                    Text(newPriority.rawValue)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(newPriority.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(newPriority.color.opacity(0.1))
                .cornerRadius(6)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Button(action: submitTask) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(newTitle.isEmpty ? .secondary.opacity(0.4) : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(newTitle.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    private func submitTask() {
        store.add(title: newTitle, priority: newPriority)
        newTitle = ""
    }

    // MARK: - Content

    @ViewBuilder
    var content: some View {
        if tab == .active {
            activeList
        } else {
            completedList
        }
    }

    var activeList: some View {
        Group {
            if store.active.isEmpty {
                emptyState(icon: "checklist", message: "No tasks yet\nAdd one above")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(store.grouped, id: \.0) { priority, tasks in
                            // Section header
                            HStack(spacing: 5) {
                                Image(systemName: priority.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(priority.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(priority.color)
                            .padding(.horizontal, 14)
                            .padding(.top, 10)
                            .padding(.bottom, 4)

                            ForEach(tasks) { task in
                                ActiveTaskRow(task: task)
                                    .environmentObject(store)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }

    var completedList: some View {
        Group {
            if store.completed.isEmpty {
                emptyState(icon: "checkmark.seal", message: "No completed tasks yet")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(store.completedByDay, id: \.0) { day, tasks in
                            Text(day.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 14)
                                .padding(.top, 10)
                                .padding(.bottom, 4)

                            ForEach(tasks) { task in
                                CompletedTaskRow(task: task)
                                    .environmentObject(store)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }

    func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.secondary.opacity(0.35))
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Footer

    var footer: some View {
        HStack {
            if tab == .active {
                Text("\(store.active.count) task\(store.active.count == 1 ? "" : "s")")
            } else {
                Text("\(store.completed.count) completed")
            }
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }
}

// MARK: - Active Row

struct ActiveTaskRow: View {
    let task: Task
    @EnvironmentObject var store: TaskStore
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Complete button
            Button(action: { store.complete(task) }) {
                Image(systemName: isHovered ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isHovered ? .green : .secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 13))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Priority badge
            Text(task.priority.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(task.priority.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(task.priority.color.opacity(0.1))
                .cornerRadius(4)

            if isHovered {
                Button(action: { store.delete(task) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .padding(.horizontal, 6)
    }
}

// MARK: - Completed Row

struct CompletedTaskRow: View {
    let task: Task
    @EnvironmentObject var store: TaskStore
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green.opacity(0.7))

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 13))
                    .strikethrough(true, color: .secondary)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if let completedAt = task.completedAt {
                    Text(completedAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(task.priority.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(task.priority.color.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(task.priority.color.opacity(0.07))
                .cornerRadius(4)

            if isHovered {
                Button(action: { store.deleteCompleted(task) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .padding(.horizontal, 6)
    }
}
