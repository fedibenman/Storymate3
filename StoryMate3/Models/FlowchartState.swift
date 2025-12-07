import Foundation

struct FlowchartState {
    var nodes: [FlowNode]
    
    init(nodes: [FlowNode] = []) {
        self.nodes = nodes
    }
    
    func findNode(id: String) -> FlowNode? {
        return nodes.first { $0.id == id }
    }
    
    mutating func addNode(_ node: FlowNode) {
        nodes.append(node)
    }
    
    mutating func updateNode(_ node: FlowNode) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
        }
    }
    
    mutating func removeNode(id: String) {
        nodes.removeAll { $0.id == id }
    }
}
