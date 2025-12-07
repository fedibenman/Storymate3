import Foundation
import CoreGraphics

struct NodeDto: Codable {
    let id: String
    let type: String // "Start", "Story", "Decision", "End"
    let text: String
    let positionX: Float
    let positionY: Float
    let imageData: String?
    let connections: [String]
}
extension NodeDto {
    func toFlowNode() -> FlowNode {
        FlowNode(
            id: id,
            type: NodeType(rawValue: type) ?? .story,
            text: text,
            position: CGPoint(x: CGFloat(positionX), y: CGFloat(positionY)),
            outs: connections,
            imageData: imageData ?? ""
        )
    }
}
