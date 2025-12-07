import Foundation
import CoreGraphics

struct FlowchartDto: Codable {
    let projectId: String
    let nodes: [NodeDto]
    let updatedAt: Int64
    
    func toFlowchartState() -> FlowchartState {
        let flowNodes = nodes.map { nodeDto -> FlowNode in
            FlowNode(
                id: nodeDto.id,
                type: NodeType(rawValue: nodeDto.type) ?? .story,
                text: nodeDto.text,
                position: CGPoint(x: CGFloat(nodeDto.positionX), y: CGFloat(nodeDto.positionY)),
                outs: nodeDto.connections,
                imageData: nodeDto.imageData ?? ""
            )
        }
        return FlowchartState(nodes: flowNodes)
    }
}
