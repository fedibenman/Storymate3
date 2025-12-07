import Foundation

public enum NodeType: String, Codable {
    case start = "Start"
    case story = "Story"
    case decision = "Decision"
    case end = "End"
    
    var emoji: String {
        switch self {
        case .start:
            return "▶️"
        case .story:
            return "📖"
        case .decision:
            return "🔀"
        case .end:
            return "🏁"
        }
    }
}
