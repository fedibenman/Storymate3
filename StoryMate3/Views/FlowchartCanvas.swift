import SwiftUI

// MARK: - Constants

private let NODE_WIDTH: CGFloat = 140
private let NODE_HEIGHT: CGFloat = 70
private let CONNECTION_SNAP_DISTANCE: CGFloat = 30

// MARK: - Flowchart Canvas

struct FlowchartCanvas: View {
    let state: FlowchartState
    let onSaveGraph: (FlowchartState) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var selectedNodeId: String?
    @State private var selectedConnection: (String, String)?
    @State private var previewMode = false
    @State private var showEditDialog = false
    @State private var connectingFromNodeId: String?
    @State private var connectionLineEnd: CGPoint?
    @State private var hoveredTargetNodeId: String?
    @State private var showSaveSuccess = false
    
    var body: some View {
        ZStack {
            Color.pixelDarkBlue.ignoresSafeArea()
            
            // Canvas area
            ZStack {
                Color.pixelMidBlue
                
                // Nodes
                ForEach(state.nodes) { node in
                    NodeView(
                        node: node,
                        scale: scale,
                        offset: offset,
                        isSelected: selectedNodeId == node.id,
                        isHoveredForConnection: hoveredTargetNodeId == node.id,
                        onNodeClick: {
                            if connectingFromNodeId == nil {
                                selectedNodeId = node.id
                                selectedConnection = nil
                            }
                        },
                        onStartConnection: {
                            connectingFromNodeId = node.id
                        }
                    )
                }
                
                // Connection lines overlay
                ConnectionLinesView(
                    state: state,
                    scale: scale,
                    offset: offset,
                    selectedConnection: selectedConnection,
                    connectingFromNodeId: connectingFromNodeId,
                    connectionLineEnd: connectionLineEnd,
                    hoveredTargetNodeId: hoveredTargetNodeId,
                    onSelectConnection: { fromId, toId in
                        selectedConnection = (fromId, toId)
                        selectedNodeId = nil
                    }
                )
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = min(max(value, 0.3), 3.0)
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if connectingFromNodeId == nil {
                            offset = value.translation
                        } else {
                            // Handle connection dragging
                            connectionLineEnd = value.location
                            updateHoveredTarget(at: value.location)
                        }
                    }
                    .onEnded { value in
                        if let fromId = connectingFromNodeId,
                           let toId = hoveredTargetNodeId {
                            connectNodes(fromId: fromId, toId: toId)
                        }
                        connectingFromNodeId = nil
                        connectionLineEnd = nil
                        hoveredTargetNodeId = nil
                    }
            )
            
            // Bottom toolbar
            VStack {
                Spacer()
                BottomToolbar(
                    scale: scale,
                    offset: offset,
                    selectedNodeId: selectedNodeId,
                    selectedNodeType: selectedNodeId.flatMap { state.findNode($0)?.type },
                    selectedConnection: selectedConnection,
                    onAddStory: addStoryNode,
                    onAddDecision: addDecisionNode,
                    onEditNode: { showEditDialog = true },
                    onDeleteNode: deleteSelectedNode,
                    onDeleteConnection: deleteSelectedConnection,
                    onTogglePreview: { previewMode.toggle() },
                    onSave: saveGraph
                )
            }
            
            // Preview overlay
            if previewMode {
                PreviewOverlay(state: state) {
                    previewMode = false
                }
            }
            
            // Edit dialog
            if showEditDialog, let nodeId = selectedNodeId, let node = state.findNode(nodeId) {
                EditNodeDialog(node: node) { newText in
                    node.text = newText
                    showEditDialog = false
                }
            }
            
            // Save success notification
            if showSaveSuccess {
                VStack {
                    HStack(spacing: 8) {
                        Text("✓")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                        Text("PROJECT SAVED!")
                            .font(.system(size: 14, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .tracking(1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "00FF00"))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "00CC00"), lineWidth: 2)
                    )
                    Spacer()
                }
                .padding(.top, 16)
                .transition(.move(edge: .top))
                .animation(.easeInOut, value: showSaveSuccess)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateHoveredTarget(at location: CGPoint) {
        var foundTarget: String?
        
        for node in state.nodes {
            if node.type == .start { continue }
            
            let nodeScreenPosition = CGPoint(
                x: CGFloat(node.position.x) * scale + offset.width,
                y: CGFloat(node.position.y) * scale + offset.height
            )
            
            let distance = hypot(
                location.x - nodeScreenPosition.x,
                location.y - (nodeScreenPosition.y + NODE_HEIGHT / 2)
            )
            
            if distance <= CONNECTION_SNAP_DISTANCE {
                foundTarget = node.id
                break
            }
        }
        
        hoveredTargetNodeId = foundTarget
    }
    
    private func connectNodes(fromId: String, toId: String) {
        guard let fromNode = state.findNode(fromId),
              let toNode = state.findNode(toId) else { return }
        
        // Connection logic based on node types
        if fromNode.type == .story && toNode.type == .decision {
            if !fromNode.outs.contains(toId) {
                fromNode.outs.append(toId)
            }
        } else if fromNode.type == .story {
            fromNode.outs.removeAll()
            fromNode.outs.append(toId)
        } else if !fromNode.outs.contains(toId) {
            fromNode.outs.append(toId)
        }
    }
    
    private func addStoryNode() {
        let rightMostX = state.nodes.map { $0.position.x }.max() ?? 0
        let newNode = FlowNode(
            type: .story,
            text: "Story",
            position: CGPoint(x: rightMostX + 200, y: 150)
        )
        state.nodes.append(newNode)
    }
    
    private func addDecisionNode() {
        let rightMostX = state.nodes.map { $0.position.x }.max() ?? 0
        let newNode = FlowNode(
            type: .decision,
            text: "Choice",
            position: CGPoint(x: rightMostX + 200, y: 150)
        )
        state.nodes.append(newNode)
    }
    
    private func deleteSelectedNode() {
        guard let nodeId = selectedNodeId,
              let node = state.findNode(nodeId),
              node.type != .start && node.type != .end else { return }
        
        state.nodes.removeAll { $0.id == nodeId }
        state.nodes.forEach { $0.outs.removeAll { $0 == nodeId } }
        selectedNodeId = nil
    }
    
    private func deleteSelectedConnection() {
        guard let (fromId, toId) = selectedConnection else { return }
        state.findNode(fromId)?.outs.removeAll { $0 == toId }
        selectedConnection = nil
    }
    
    private func saveGraph() {
        onSaveGraph(state)
        showSaveSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSaveSuccess = false
        }
    }
}

// MARK: - Node View

struct NodeView: View {
    @ObservedObject var node: FlowNode
    let scale: CGFloat
    let offset: CGSize
    let isSelected: Bool
    let isHoveredForConnection: Bool
    let onNodeClick: () -> Void
    let onStartConnection: () -> Void
    
    @State private var showImage = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        let screenPosition = CGPoint(
            x: CGFloat(node.position.x) * scale + offset.width,
            y: CGFloat(node.position.y) * scale + offset.height
        )
        
        ZStack(alignment: .topLeading) {
            // Shadow
            Rectangle()
                .fill(Color(hex: "808080"))
                .frame(width: NODE_WIDTH, height: NODE_HEIGHT)
                .offset(x: 3, y: 3)
                .overlay(
                    Rectangle()
                        .stroke(Color(hex: "606060"), lineWidth: isSelected ? 4 : 3)
                        .offset(x: 3, y: 3)
                )
            
            // Main node
            ZStack {
                Rectangle()
                    .fill(nodeColor)
                    .frame(width: NODE_WIDTH, height: NODE_HEIGHT)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: isSelected ? 4 : 3)
                    )
                
                if showImage, let imageData = node.imageData, !imageData.isEmpty {
                    Base64Image(base64String: imageData, contentMode: .fit)
                        .frame(width: NODE_WIDTH - 8, height: NODE_HEIGHT - 8)
                } else {
                    Text(nodeText)
                        .font(.system(size: 10, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(8)
                }
                
                // Toggle image/text button
                if let imageData = node.imageData, !imageData.isEmpty {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showImage.toggle() }) {
                                Image(systemName: showImage ? "textformat" : "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.black)
                            }
                            .padding(6)
                        }
                        Spacer()
                    }
                }
                
                // Connection points
                if node.type != .end {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: NODE_WIDTH / 2 + 10, y: NODE_HEIGHT / 2 - 10)
                        .gesture(
                            DragGesture()
                                .onChanged { _ in
                                    onStartConnection()
                                }
                        )
                }
                
                if node.type != .start {
                    Circle()
                        .fill(isHoveredForConnection ? Color.green : Color.black)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: -NODE_WIDTH / 2 - 10, y: NODE_HEIGHT / 2 - 10)
                }
            }
            .onTapGesture {
                onNodeClick()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        node.position = CGPoint(
                            x: node.position.x + value.translation.width / scale,
                            y: node.position.y + value.translation.height / scale
                        )
                        dragOffset = .zero
                    }
            )
        }
        .offset(x: screenPosition.x + dragOffset.width, y: screenPosition.y + dragOffset.height)
    }
    
    private var nodeColor: Color {
        switch node.type {
        case .start: return Color(hex: "90EE90")
        case .story: return Color(hex: "FFD700")
        case .decision: return Color(hex: "87CEEB")
        case .end: return Color(hex: "FF6B6B")
        }
    }
    
    private var nodeText: String {
        if node.text.isEmpty {
            switch node.type {
            case .start: return "START"
            case .story: return "Story"
            case .decision: return "Choice"
            case .end: return "END"
            }
        }
        return node.text
    }
}

// MARK: - Connection Lines View

struct ConnectionLinesView: View {
    let state: FlowchartState
    let scale: CGFloat
    let offset: CGSize
    let selectedConnection: (String, String)?
    let connectingFromNodeId: String?
    let connectionLineEnd: CGPoint?
    let hoveredTargetNodeId: String?
    let onSelectConnection: (String, String) -> Void
    
    var body: some View {
        Canvas { context, size in
            // Draw existing connections
            for node in state.nodes {
                let fromPoint = CGPoint(
                    x: CGFloat(node.position.x) * scale + offset.width + NODE_WIDTH,
                    y: CGFloat(node.position.y) * scale + offset.height + NODE_HEIGHT / 2
                )
                
                for targetId in node.outs {
                    guard let target = state.findNode(targetId) else { continue }
                    
                    let toPoint = CGPoint(
                        x: CGFloat(target.position.x) * scale + offset.width,
                        y: CGFloat(target.position.y) * scale + offset.height + NODE_HEIGHT / 2
                    )
                    
                    let isSelected = selectedConnection?.0 == node.id && selectedConnection?.1 == targetId
                    let color = isSelected ? Color(hex: "FF6B00") : Color.black
                    let lineWidth: CGFloat = isSelected ? 6 : 4
                    
                    drawConnection(context: context, from: fromPoint, to: toPoint, color: color, lineWidth: lineWidth)
                }
            }
            
            // Draw temporary connection while dragging
            if let fromId = connectingFromNodeId,
               let fromNode = state.findNode(fromId),
               let endPoint = connectionLineEnd {
                let fromPoint = CGPoint(
                    x: CGFloat(fromNode.position.x) * scale + offset.width + NODE_WIDTH,
                    y: CGFloat(fromNode.position.y) * scale + offset.height + NODE_HEIGHT / 2
                )
                
                let color = hoveredTargetNodeId != nil ? Color.green : Color.gray
                drawConnection(context: context, from: fromPoint, to: endPoint, color: color, lineWidth: 3)
            }
        }
    }
    
    private func drawConnection(context: GraphicsContext, from: CGPoint, to: CGPoint, color: Color, lineWidth: CGFloat) {
        let midX = (from.x + to.x) / 2
        
        var path = Path()
        path.move(to: from)
        path.addLine(to: CGPoint(x: midX, y: from.y))
        path.addLine(to: CGPoint(x: midX, y: to.y))
        path.addLine(to: to)
        
        context.stroke(path, with: .color(color), lineWidth: lineWidth)
        
        // Draw arrow
        let arrowSize: CGFloat = 8
        var arrowPath = Path()
        arrowPath.move(to: to)
        arrowPath.addLine(to: CGPoint(x: to.x - arrowSize, y: to.y - arrowSize / 2))
        arrowPath.addLine(to: CGPoint(x: to.x - arrowSize, y: to.y + arrowSize / 2))
        arrowPath.closeSubpath()
        
        context.fill(arrowPath, with: .color(color))
    }
}

// MARK: - Bottom Toolbar

struct BottomToolbar: View {
    let scale: CGFloat
    let offset: CGSize
    let selectedNodeId: String?
    let selectedNodeType: NodeType?
    let selectedConnection: (String, String)?
    let onAddStory: () -> Void
    let onAddDecision: () -> Void
    let onEditNode: () -> Void
    let onDeleteNode: () -> Void
    let onDeleteConnection: () -> Void
    let onTogglePreview: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            PixelTextButton(text: "+ STORY", action: onAddStory)
                .frame(width: 100)
            
            PixelTextButton(text: "+ CHOICE", action: onAddDecision)
                .frame(width: 100)
            
            Rectangle()
                .fill(Color(hex: "4A4A4A"))
                .frame(width: 2, height: 30)
            
            PixelButton(icon: "✏️", action: onEditNode, isEnabled: selectedNodeId != nil)
            
            PixelButton(
                icon: "🗑️",
                action: onDeleteNode,
                isEnabled: selectedNodeId != nil &&
                          selectedNodeType != .start &&
                          selectedNodeType != .end
            )
            
            PixelButton(icon: "✂️", action: onDeleteConnection, isEnabled: selectedConnection != nil)
            
            Spacer()
            
            Text("ZOOM: \(String(format: "%.1f", scale))x | PAN: (\(Int(offset.width)), \(Int(offset.height)))")
                .font(.system(size: 9, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "00FF00"))
                .tracking(0.5)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "2A2A2A"))
                .overlay(
                    Rectangle()
                        .stroke(Color(hex: "4A4A4A"), lineWidth: 2)
                )
            
            Spacer()
            
            PixelButton(icon: "▶️", action: onTogglePreview)
            PixelButton(icon: "💾", action: onSave)
        }
        .padding(12)
        .background(Color(hex: "1A1A1A"))
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 3)
        )
    }
}

// MARK: - Edit Node Dialog

struct EditNodeDialog: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var node: FlowNode
    let onSave: (String) -> Void
    
    @State private var textValue: String
    @State private var showImagePicker = false
    
    init(node: FlowNode, onSave: @escaping (String) -> Void) {
        self.node = node
        self.onSave = onSave
        _textValue = State(initialValue: node.text)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    Text("✎ EDIT \(node.type.rawValue.uppercased()) NODE")
                        .font(.system(size: 14, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.pixelGold)
                        .tracking(1)
                    
                    TextEditor(text: $textValue)
                        .frame(height: 120)
                        .padding(12)
                        .background(Color.pixelMidBlue)
                        .foregroundColor(.white)
                        .overlay(
                            Rectangle()
                                .stroke(Color.pixelAccent, lineWidth: 2)
                        )
                    
                    Text("📷 ADD IMAGE (OPTIONAL)")
                        .font(.system(size: 11, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.pixelCyan)
                        .tracking(0.5)
                    
                    HStack(spacing: 10) {
                        PixelTextButton(text: "📁 UPLOAD") {
                            showImagePicker = true
                        }
                        
                        PixelTextButton(text: "✏️ SKETCH") {
                            // Sketch functionality would go here
                        }
                    }
                    
                    if let imageData = node.imageData, !imageData.isEmpty {
                        Base64Image(base64String: imageData, contentMode: .fit)
                            .frame(height: 150)
                            .background(Color.pixelMidBlue)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.pixelAccent, lineWidth: 2)
                            )
                    }
                    
                    Rectangle()
                        .fill(Color.pixelAccent)
                        .frame(height: 2)
                    
                    HStack(spacing: 10) {
                        PixelTextButton(text: "✕ CANCEL") {
                            dismiss()
                        }
                        
                        PixelTextButton(text: "💾 SAVE") {
                            onSave(textValue)
                            dismiss()
                        }
                    }
                }
                .padding(16)
            }
            .frame(width: 600, height: 700)
            .background(Color.pixelDarkBlue)
            .overlay(
                Rectangle()
                    .stroke(Color.pixelHighlight, lineWidth: 3)
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(imageData: $node.imageData)
        }
    }
}

// MARK: - Image Picker (Placeholder)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: String?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.pngData() {
                let base64String = "data:image/png;base64," + imageData.base64EncodedString()
                parent.imageData = base64String
            }
            parent.dismiss()
        }
    }
}

// MARK: - Flow Builder Screen

struct FlowBuilderScreen: View {
    let projectId: String?
    @StateObject private var viewModel = StoryProjectViewModel()
    @State private var flowchartState: FlowchartState?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pixelGold))
            } else if let state = flowchartState {
                FlowchartCanvas(state: state) { updatedState in
                    if let projectId = projectId {
                        viewModel.saveFlowchart(projectId: projectId, state: updatedState)
                    }
                }
            }
        }
        .onAppear {
            loadFlowchart()
        }
    }
    
    private func loadFlowchart() {
        if let projectId = projectId {
            viewModel.loadFlowchart(projectId: projectId) { state in
                if let state = state {
                    flowchartState = state
                } else {
                    // Create empty flowchart with start and end nodes
                    let startNode = FlowNode(
                        type: .start,
                        text: "You awake",
                        position: CGPoint(x: 60, y: 40)
                    )
                    let endNode = FlowNode(
                        type: .end,
                        text: "End of route",
                        position: CGPoint(x: 860, y: 140)
                    )
                    flowchartState = FlowchartState(nodes: [startNode, endNode])
                }
                isLoading = false
            }
        } else {
            // Preview mode - create example nodes
            let startNode = FlowNode(
                type: .start,
                text: "You awake",
                position: CGPoint(x: 60, y: 40)
            )
            let endNode = FlowNode(
                type: .end,
                text: "End of route",
                position: CGPoint(x: 860, y: 140)
            )
            flowchartState = FlowchartState(nodes: [startNode, endNode])
            isLoading = false
        }
    }
}