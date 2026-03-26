import Foundation

enum HistoryLimit: Int, CaseIterable, Identifiable {
    case fifty = 50
    case hundred = 100
    case twoHundred = 200
    case fiveHundred = 500
    case unlimited = -1

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .fifty:      return "50"
        case .hundred:    return "100"
        case .twoHundred: return "200"
        case .fiveHundred: return "500"
        case .unlimited:  return "Unlimited"
        }
    }
}

enum AutoClearInterval: String, CaseIterable, Identifiable {
    case never     = "Never"
    case oneHour   = "1 Hour"
    case sixHours  = "6 Hours"
    case oneDay    = "24 Hours"
    case oneWeek   = "1 Week"
    case oneMonth  = "30 Days"

    var id: String { rawValue }

    var seconds: TimeInterval? {
        switch self {
        case .never:     return nil
        case .oneHour:   return 3_600
        case .sixHours:  return 21_600
        case .oneDay:    return 86_400
        case .oneWeek:   return 604_800
        case .oneMonth:  return 2_592_000
        }
    }
}
