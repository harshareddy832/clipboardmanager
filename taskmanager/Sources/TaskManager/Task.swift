import SwiftUI

enum Priority: String, CaseIterable, Codable, Identifiable {
    case high   = "High"
    case medium = "Medium"
    case low    = "Low"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return Color(red: 0.2, green: 0.5, blue: 1.0)
        }
    }

    var icon: String {
        switch self {
        case .high:   return "flame.fill"
        case .medium: return "minus.circle.fill"
        case .low:    return "arrow.down.circle.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high:   return 0
        case .medium: return 1
        case .low:    return 2
        }
    }
}

struct Task: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var priority: Priority
    let createdAt: Date
    var completedAt: Date?

    init(title: String, priority: Priority) {
        self.id = UUID()
        self.title = title
        self.priority = priority
        self.createdAt = .now
        self.completedAt = nil
    }
}
