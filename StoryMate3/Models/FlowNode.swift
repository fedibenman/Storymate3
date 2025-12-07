import Foundation
import CoreGraphics
import Combine

class FlowNode: Identifiable, ObservableObject {
    let id: String
    let type: NodeType
    var text: String
    var position: CGPoint
    var outs: [String]
    var imageData: String
    
    init(id: String = UUID().uuidString, 
         type: NodeType, 
         text: String = "", 
         position: CGPoint = CGPoint(x: 100, y: 100), 
         outs: [String] = [], 
         imageData: String = "") {
        self.id = id
        self.type = type
        self.text = text
        self.position = position
        self.outs = outs
        self.imageData = imageData
    }
    
    func toDto() -> NodeDto {
        NodeDto(
            id: id,
            type: type.rawValue,
            text: text,
            positionX: Float(position.x),
            positionY: Float(position.y),
            imageData: imageData.isEmpty ? nil : imageData,
            connections: outs
        )
    }
}
