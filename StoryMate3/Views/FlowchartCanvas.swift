import SwiftUI

// MARK: - Constants

private let NODE_WIDTH: CGFloat = 140
private let NODE_HEIGHT: CGFloat = 70
private let CONNECTION_SNAP_DISTANCE: CGFloat = 30

// MARK: - Flowchart Canvas

struct FlowchartCanvas: View {
    @StateObject var state: FlowchartState
    let onSaveGraph: (FlowchartState) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var canvasDragOffset: CGSize = .zero
    @State private var selectedNodeId: String?
    @State private var selectedConnection: (String, String)?
    @State private var previewMode = false
    @State private var showEditDialog = false
    @State private var connectingFromNodeId: String?
    @GestureState private var connectionLineEnd: CGPoint?
    @State private var hoveredTargetNodeId: String?
    @State private var showSaveSuccess = false
    
    var body: some View {
        ZStack {
            Color.pixelDarkBlue.ignoresSafeArea()
            
            // Canvas area
            GeometryReader { geometry in
                ZStack {
                    Color.pixelMidBlue
                    
                    // Connection lines overlay
                    ConnectionLinesView(
                        state: state,
                        scale: scale,
                        offset: CGSize(
                            width: offset.width + canvasDragOffset.width,
                            height: offset.height + canvasDragOffset.height
                        ),
                        selectedConnection: selectedConnection,
                        connectingFromNodeId: connectingFromNodeId,
                        connectionLineEnd: connectionLineEnd,
                        hoveredTargetNodeId: hoveredTargetNodeId,
                        onSelectConnection: { fromId, toId in
                            selectedConnection = (fromId, toId)
                            selectedNodeId = nil
                        }
                    )
                    
                    // Nodes
                    ForEach(state.nodes) { node in
                        NodeView(
                            node: node,
                            scale: scale,
                            offset: CGSize(
                                width: offset.width + canvasDragOffset.width,
                                height: offset.height + canvasDragOffset.height
                            ),
                            isSelected: selectedNodeId == node.id,
                            isHoveredForConnection: hoveredTargetNodeId == node.id,
                            isConnecting: connectingFromNodeId != nil,
                            connectingFromNodeId: connectingFromNodeId,
                            onNodeClick: {
                                if connectingFromNodeId == nil {
                                    selectedNodeId = node.id
                                    selectedConnection = nil
                                }
                            },
                            onNodeDrag: { newPosition in
                                node.position = newPosition
                            },
                            onStartConnection: {
                                connectingFromNodeId = node.id
                            }
                        )
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = min(max(value, 0.3), 3.0)
                        }
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($canvasDragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onChanged { value in
                            if connectingFromNodeId != nil {
                                // Handle connection dragging in real-time
                                updateHoveredTarget(at: value.location)
                            }
                        }
                        .onEnded { value in
                            if connectingFromNodeId != nil {
                                if let fromId = connectingFromNodeId,
                                   let toId = hoveredTargetNodeId {
                                    connectNodes(fromId: fromId, toId: toId)
                                }
                                connectingFromNodeId = nil
                                hoveredTargetNodeId = nil
                            } else {
                                // Commit canvas pan
                                offset = CGSize(
                                    width: offset.width + value.translation.width,
                                    height: offset.height + value.translation.height
                                )
                            }
                        }
                )
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            // Deselect when tapping canvas
                            if connectingFromNodeId == nil {
                                selectedNodeId = nil
                                selectedConnection = nil
                            }
                        }
                )
            }
            
            // Bottom toolbar
            VStack {
                Spacer()
                BottomToolbar(
                    scale: scale,
                    offset: offset,
                    selectedNodeId: selectedNodeId,
                    selectedNodeType: selectedNodeId.flatMap { state.findNode(id: $0)?.type },
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
            if showEditDialog, let nodeId = selectedNodeId, let node = state.findNode(id: nodeId) {
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
        guard let fromNode = state.findNode(id: fromId),
              let toNode = state.findNode(id: toId) else { return }
        
        // Prevent self-connections
        if fromId == toId { return }
        
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
        state.addNode(newNode)
        selectedNodeId = newNode.id
    }
    
    private func addDecisionNode() {
        let rightMostX = state.nodes.map { $0.position.x }.max() ?? 0
        let newNode = FlowNode(
            type: .decision,
            text: "Choice",
            position: CGPoint(x: rightMostX + 200, y: 150)
        )
        state.addNode(newNode)
        selectedNodeId = newNode.id
    }
    
    private func deleteSelectedNode() {
        guard let nodeId = selectedNodeId,
              let node = state.findNode(id: nodeId),
              node.type != .start && node.type != .end else { return }
        
        state.removeNode(id: nodeId)
        state.nodes.forEach { $0.outs.removeAll { $0 == nodeId } }
        selectedNodeId = nil
    }
    
    private func deleteSelectedConnection() {
        guard let (fromId, toId) = selectedConnection else { return }
        state.findNode(id: fromId)?.outs.removeAll { $0 == toId }
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
    let isConnecting: Bool
    let connectingFromNodeId: String?
    let onNodeClick: () -> Void
    let onNodeDrag: (CGPoint) -> Void
    let onStartConnection: () -> Void
    
    @State private var showImage = false
    @State private var initialPosition: CGPoint?
    @State private var dragStart: CGPoint?
    @GestureState private var nodeDragOffset: CGSize = .zero
    
    var body: some View {
        let screenPosition = CGPoint(
            x: CGFloat(node.position.x) * scale + offset.width + nodeDragOffset.width,
            y: CGFloat(node.position.y) * scale + offset.height + nodeDragOffset.height
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
                
                if showImage && !node.imageData.isEmpty {
                    Base64Image(base64String: node.imageData, placeholder: "photo")
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
                if !node.imageData.isEmpty {
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
                
                // Output connection point (right side, vertically centered)
                if node.type != .end {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: NODE_WIDTH / 2 + 10, y: 0)
                        .contentShape(Circle())
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if connectingFromNodeId == nil {
                                        onStartConnection()
                                    }
                                }
                        )
                }
                
                // Input connection point (left side, vertically centered)
                if node.type != .start {
                    Circle()
                        .fill(isHoveredForConnection ? Color.green : Color.black)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: -NODE_WIDTH / 2 - 10, y: 0)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onNodeClick()
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($nodeDragOffset) { value, state, _ in
                        if dragStart == nil {
                            dragStart = value.startLocation
                            initialPosition = node.position
                            onNodeClick()
                        }
                        
                        if let start = dragStart, let initial = initialPosition {
                            let dx = (value.location.x - start.x) / scale
                            let dy = (value.location.y - start.y) / scale
                            state = CGSize(width: dx, height: dy)
                            
                            // Update actual position in real-time
                            onNodeDrag(CGPoint(
                                x: initial.x + dx,
                                y: initial.y + dy
                            ))
                        }
                    }
                    .onEnded { value in
                        dragStart = nil
                        initialPosition = nil
                    }
            )
        }
        .offset(x: screenPosition.x, y: screenPosition.y)
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
                    guard let target = state.findNode(id: targetId) else { continue }
                    
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
               let fromNode = state.findNode(id: fromId),
               let endPoint = connectionLineEnd {
                let fromPoint = CGPoint(
                    x: CGFloat(fromNode.position.x) * scale + offset.width + NODE_WIDTH,
                    y: CGFloat(fromNode.position.y) * scale + offset.height + NODE_HEIGHT / 2
                )
                
                let color = hoveredTargetNodeId != nil ? Color.green : Color.gray
                drawConnection(context: context, from: fromPoint, to: endPoint, color: color, lineWidth: 3)
            }
        }
        .allowsHitTesting(true)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    // Tap gesture for connection selection handled here
                }
        )
        .onTapGesture { location in
            // Check if tap is near a connection
            let tapPoint = location
            
            for node in state.nodes {
                let fromPoint = CGPoint(
                    x: CGFloat(node.position.x) * scale + offset.width + NODE_WIDTH,
                    y: CGFloat(node.position.y) * scale + offset.height + NODE_HEIGHT / 2
                )
                
                for targetId in node.outs {
                    guard let target = state.findNode(id: targetId) else { continue }
                    
                    let toPoint = CGPoint(
                        x: CGFloat(target.position.x) * scale + offset.width,
                        y: CGFloat(target.position.y) * scale + offset.height + NODE_HEIGHT / 2
                    )
                    
                    if isPointNearConnection(tapPoint, from: fromPoint, to: toPoint) {
                        onSelectConnection(node.id, targetId)
                        return
                    }
                }
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
    
    private func isPointNearConnection(_ point: CGPoint, from: CGPoint, to: CGPoint) -> Bool {
        let midX = (from.x + to.x) / 2
        let tolerance: CGFloat = 15
        
        // Check horizontal segment 1
        if abs(point.y - from.y) < tolerance &&
           point.x >= min(from.x, midX) - tolerance &&
           point.x <= max(from.x, midX) + tolerance {
            return true
        }
        
        // Check vertical segment
        if abs(point.x - midX) < tolerance &&
           point.y >= min(from.y, to.y) - tolerance &&
           point.y <= max(from.y, to.y) + tolerance {
            return true
        }
        
        // Check horizontal segment 2
        if abs(point.y - to.y) < tolerance &&
           point.x >= min(midX, to.x) - tolerance &&
           point.x <= max(midX, to.x) + tolerance {
            return true
        }
        
        return false
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
            
            // Edit button
            Button(action: onEditNode) {
                Text("✏️")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(selectedNodeId != nil ? Color.pixelHighlight : Color(hex: "2A2A2A"))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .disabled(selectedNodeId == nil)
            
            // Delete node button
            Button(action: onDeleteNode) {
                Text("🗑️")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background((selectedNodeId != nil && selectedNodeType != .start && selectedNodeType != .end) ? Color.pixelHighlight : Color(hex: "2A2A2A"))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .disabled(selectedNodeId == nil || selectedNodeType == .start || selectedNodeType == .end)
            
            // Delete connection button
            Button(action: onDeleteConnection) {
                Text("✂️")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(selectedConnection != nil ? Color.pixelHighlight : Color(hex: "2A2A2A"))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .disabled(selectedConnection == nil)
            
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
            
            Button(action: onTogglePreview) {
                Text("▶️")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(Color.pixelHighlight)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            Button(action: onSave) {
                Text("💾")
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(Color.pixelHighlight)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
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
                    
                    if !node.imageData.isEmpty {
                        Base64Image(base64String: node.imageData, placeholder: "photo")
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

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: String
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
    let projectId: String
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
                    viewModel.saveFlowchart(projectId: projectId, state: updatedState)
                }
            }
        }
        .onAppear {
            loadFlowchart()
        }
    }
    
    private func loadFlowchart() {
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
    }
}
