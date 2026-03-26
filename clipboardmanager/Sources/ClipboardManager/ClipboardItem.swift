import Foundation

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date

    init(content: String, timestamp: Date = .now) {
        self.id = UUID()
        self.content = content
        self.timestamp = timestamp
    }

    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(120))
    }
}
