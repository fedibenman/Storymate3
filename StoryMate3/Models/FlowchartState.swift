import Foundation
import Combine

class FlowchartState: ObservableObject {
    @Published var nodes: [FlowNode]
    
    init(nodes: [FlowNode] = []) {
        self.nodes = nodes
    }
    
    func findNode(id: String) -> FlowNode? {
        return nodes.first { $0.id == id }
    }
    
    func addNode(_ node: FlowNode) {
        nodes.append(node)
    }
    
    func updateNode(_ node: FlowNode) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
        }
    }
    
    func removeNode(id: String) {
        nodes.removeAll { $0.id == id }
    }
}
