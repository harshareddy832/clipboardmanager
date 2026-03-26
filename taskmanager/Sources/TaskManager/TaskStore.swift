import SwiftUI

private enum Keys {
    static let active    = "activeTasks"
    static let completed = "completedTasks"
}

class TaskStore: ObservableObject {
    @Published var active: [Task] = []
    @Published var completed: [Task] = []

    var grouped: [(Priority, [Task])] {
        Priority.allCases.compactMap { priority in
            let tasks = active.filter { $0.priority == priority }
            return tasks.isEmpty ? nil : (priority, tasks)
        }
    }

    // Completed tasks grouped by calendar day
    var completedByDay: [(String, [Task])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: completed.sorted { ($0.completedAt ?? .now) > ($1.completedAt ?? .now) }) { task -> String in
            let date = task.completedAt ?? task.createdAt
            if calendar.isDateInToday(date)     { return "Today" }
            if calendar.isDateInYesterday(date) { return "Yesterday" }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
        // Preserve day order
        let order = ["Today", "Yesterday"]
        let keys = grouped.keys.sorted { a, b in
            let ai = order.firstIndex(of: a) ?? 999
            let bi = order.firstIndex(of: b) ?? 999
            return ai < bi
        }
        return keys.compactMap { key in
            guard let tasks = grouped[key] else { return nil }
            return (key, tasks)
        }
    }

    init() {
        active    = load(key: Keys.active)
        completed = load(key: Keys.completed)
    }

    // MARK: - Actions

    func add(title: String, priority: Priority) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        active.append(Task(title: title, priority: priority))
        active.sort { $0.priority.sortOrder < $1.priority.sortOrder }
        save()
    }

    func complete(_ task: Task) {
        guard let idx = active.firstIndex(where: { $0.id == task.id }) else { return }
        var done = active.remove(at: idx)
        done.completedAt = .now
        completed.insert(done, at: 0)
        save()
    }

    func delete(_ task: Task) {
        active.removeAll { $0.id == task.id }
        save()
    }

    func deleteCompleted(_ task: Task) {
        completed.removeAll { $0.id == task.id }
        save()
    }

    func clearCompleted() {
        completed.removeAll()
        save()
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(active)    { UserDefaults.standard.set(data, forKey: Keys.active) }
        if let data = try? JSONEncoder().encode(completed) { UserDefaults.standard.set(data, forKey: Keys.completed) }
    }

    private func load(key: String) -> [Task] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Task].self, from: data)
        else { return [] }
        return decoded
    }
}
