import Foundation

public enum NodeType: String, Codable {
    case start = "Start"
    case story = "Story"
    case decision = "Decision"
    case end = "End"
}
