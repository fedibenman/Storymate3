import SwiftUI

// MARK: - Constants
enum NodeConstants {
    static let width: CGFloat = 100
    static let height: CGFloat = 55
    static let handleSize: CGFloat = 24
    static let handleOffset: CGFloat = 8
    static let inputX: CGFloat = -(width / 2 + handleOffset)
    static let outputX: CGFloat = width / 2 + handleOffset
    static let pixelSize: CGFloat = 4 // Base pixel unit
}

// MARK: - Main View
struct FlowchartEditorView: View {
    @ObservedObject var state: FlowchartState
    let projectId: String
    @ObservedObject var viewModel: StoryProjectViewModel
    
    @StateObject private var editorViewModel = FlowchartEditorViewModel()
    @State private var showEditDialog = false
    @State private var nodeToEdit: FlowNode?
    
    var body: some View {
        VStack(spacing: 0) {
            TopToolbar(
                viewModel: editorViewModel,
                state: state,
                projectId: projectId,
                storyViewModel: viewModel,
                onEditNode: {
                    if let selectedId = editorViewModel.selectedNodeId,
                       let node = state.findNode(id: selectedId) {
                        // Make a copy to ensure we have fresh data
                        let nodeCopy = FlowNode(
                            id: node.id,
                            type: node.type,
                            text: node.text,
                            position: node.position,
                            outs: node.outs,
                            imageData: node.imageData
                        )
                        nodeToEdit = nodeCopy
                    }
                }
            )
            
            if editorViewModel.isPreviewMode {
                PreviewModeView(state: state, viewModel: editorViewModel)
            } else {
                GeometryReader { geometry in
                    CanvasView(
                        viewModel: editorViewModel,
                        state: state,
                        canvasSize: geometry.size,
                        projectId: projectId,
                        storyViewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            print("appearing here in flowchart editor")
            loadFlowchartData()
        }
        .alert("Flowchart Saved", isPresented: $editorViewModel.showSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your flowchart has been saved successfully!")
        }
        .sheet(item: $nodeToEdit) { node in
            EditNodeView(node: node, state: state, isPresented: .init(
                get: { nodeToEdit != nil },
                set: { if !$0 { nodeToEdit = nil } }
            ))
        }
    }
    
    private func loadFlowchartData() {
         print("📞 Calling loadFlowchartData()")
         viewModel.loadFlowchart(projectId: projectId) { flowchartState in
             print("📊 loadFlowchart callback received: \(flowchartState != nil ? "Has data" : "No data")")
             if let flowchartState = flowchartState {
                 print("📦 Setting \(flowchartState.nodes.count) nodes")
                 state.nodes = flowchartState.nodes
                 editorViewModel.loadInitialState(state: state)
             } else {
                 print("📭 No saved flowchart, loading initial state")
                 editorViewModel.loadInitialState(state: state)
             }
         }
     }
}

// MARK: - Pixel Art Border Shape
struct PixelBorder: Shape {
    let cornerSize: CGFloat = 8
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Top left corner
        path.move(to: CGPoint(x: cornerSize, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX - cornerSize, y: 0))
        
        // Top right corner
        path.addLine(to: CGPoint(x: rect.maxX - cornerSize, y: cornerSize))
        path.addLine(to: CGPoint(x: rect.maxX, y: cornerSize))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerSize))
        
        // Bottom right corner
        path.addLine(to: CGPoint(x: rect.maxX - cornerSize, y: rect.maxY - cornerSize))
        path.addLine(to: CGPoint(x: rect.maxX - cornerSize, y: rect.maxY))
        path.addLine(to: CGPoint(x: cornerSize, y: rect.maxY))
        
        // Bottom left corner
        path.addLine(to: CGPoint(x: cornerSize, y: rect.maxY - cornerSize))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY - cornerSize))
        path.addLine(to: CGPoint(x: 0, y: cornerSize))
        
        // Back to start
        path.addLine(to: CGPoint(x: cornerSize, y: cornerSize))
        path.addLine(to: CGPoint(x: cornerSize, y: 0))
        
        return path
    }
}

// MARK: - Pixel Button Style
struct PixelButtonStyle: ButtonStyle {
    let color: Color
    let isEnabled: Bool
    
    init(color: Color, isEnabled: Bool = true) {
        self.color = color
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Courier", size: 14).weight(.bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Base
                    PixelBorder()
                        .fill(isEnabled ? color : Color.gray)
                    
                    // Shadow/3D effect
                    PixelBorder()
                        .stroke(Color.black.opacity(0.3), lineWidth: 2)
                    
                    // Highlight
                    if !configuration.isPressed {
                        PixelBorder()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .offset(x: -2, y: -2)
                    }
                }
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .shadow(color: Color.black.opacity(0.4), radius: 0, x: 4, y: 4)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Top Toolbar
struct TopToolbar: View {
    @ObservedObject var viewModel: FlowchartEditorViewModel
    @ObservedObject var state: FlowchartState
    let projectId: String
    @ObservedObject var storyViewModel: StoryProjectViewModel
    let onEditNode: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                addStoryButton
                addDecisionButton
                
                Divider()
                    .frame(height: 40)
                    .overlay(Color.white.opacity(0.3))
                
                if viewModel.selectedNodeId != nil {
                    editNodeButton
                    deleteNodeButton
                }
                
                if viewModel.selectedConnectionId != nil {
                    cutConnectionButton
                }
                
                Divider()
                    .frame(height: 40)
                    .overlay(Color.white.opacity(0.3))
                
                previewButton
                saveButton
            }
            .padding()
        }
        .background(
            ZStack {
                Color(red: 0.2, green: 0.2, blue: 0.3)
                
                // Pixel pattern overlay
                GeometryReader { geometry in
                    Path { path in
                        let spacing: CGFloat = 8
                        for x in stride(from: 0, to: geometry.size.width, by: spacing) {
                            for y in stride(from: 0, to: geometry.size.height, by: spacing) {
                                path.addRect(CGRect(x: x, y: y, width: 2, height: 2))
                            }
                        }
                    }
                    .fill(Color.white.opacity(0.05))
                }
            }
        )
        .overlay(
            Rectangle()
                .frame(height: 4)
                .foregroundColor(Color.black.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private var addStoryButton: some View {
        Button(action: {
            viewModel.addStoryNode(state: state)
        }) {
            HStack(spacing: 6) {
                Text("📖")
                Text("Story")
            }
        }
        .buttonStyle(PixelButtonStyle(color: Color.blue))
    }
    
    private var addDecisionButton: some View {
        Button(action: {
            viewModel.addDecisionNode(state: state)
        }) {
            HStack(spacing: 6) {
                Text("🔀")
                Text("Choice")
            }
        }
        .buttonStyle(PixelButtonStyle(color: Color.purple))
    }
    
    private var editNodeButton: some View {
        Button(action: {
            onEditNode()
        }) {
            HStack(spacing: 6) {
                Text("✏️")
                Text("Edit")
            }
        }
        .buttonStyle(PixelButtonStyle(color: Color.orange))
    }
    
    private var deleteNodeButton: some View {
        Button(action: {
            viewModel.deleteSelectedNode(state: state)
        }) {
            HStack(spacing: 6) {
                Text("🗑")
                Text("Delete")
            }
        }
        .buttonStyle(PixelButtonStyle(color: Color.red))
    }
    
    private var cutConnectionButton: some View {
        Button(action: {
            viewModel.deleteSelectedConnection(state: state)
        }) {
            HStack(spacing: 6) {
                Text("✂️")
                Text("Cut")
            }
        }
        .buttonStyle(PixelButtonStyle(color: Color.orange))
    }
    
    private var previewButton: some View {
        Button(action: {
            viewModel.togglePreview()
        }) {
            HStack(spacing: 6) {
                Text(viewModel.isPreviewMode ? "👁" : "▶️")
                Text(viewModel.isPreviewMode ? "Exit" : "Preview")
            }
        }
        .buttonStyle(PixelButtonStyle(color: Color.green))
    }
    
    private var saveButton: some View {
        Button(action: {
            viewModel.saveFlowchart(state: state, projectId: projectId, storyViewModel: storyViewModel)
        }) {
            HStack(spacing: 6) {
                Text("💾")
                Text("Save")
            }
        }
        .buttonStyle(PixelButtonStyle(color: Color.blue))
    }
}

// MARK: - Canvas View
struct CanvasView: View {
    @ObservedObject var viewModel: FlowchartEditorViewModel
    @ObservedObject var state: FlowchartState
    let canvasSize: CGSize
    let projectId: String
    @ObservedObject var storyViewModel: StoryProjectViewModel
    
    var body: some View {
        ZStack {
            // Pixel grid background
            PixelGridBackground()
                .onTapGesture {
                    viewModel.deselectAll()
                }
                .gesture(canvasDragGesture)
            
            connectionLayer
            connectionHitAreas
            cutButtonLayer
            nodesLayer
        }
    }
    
    private var connectionLayer: some View {
        Canvas { context, size in
            for connection in viewModel.connections {
                if let path = viewModel.getConnectionPath(
                    connection: connection,
                    nodes: state.nodes,
                    canvasOffset: viewModel.canvasOffset
                ) {
                    let isSelected = viewModel.selectedConnectionId == connection.id
                    
                    if isSelected {
                        context.stroke(
                            path,
                            with: .color(Color.yellow.opacity(0.3)),
                            style: StrokeStyle(lineWidth: 10, lineCap: .square, lineJoin: .miter)
                        )
                    }
                    
                    // Outer black border
                    context.stroke(
                        path,
                        with: .color(.black),
                        style: StrokeStyle(lineWidth: isSelected ? 6 : 5, lineCap: .square, lineJoin: .miter)
                    )
                    
                    // Inner color line
                    context.stroke(
                        path,
                        with: .color(isSelected ? .yellow : Color(red: 0.8, green: 0.8, blue: 0.9)),
                        style: StrokeStyle(lineWidth: isSelected ? 4 : 3, lineCap: .square, lineJoin: .miter)
                    )
                }
            }
            
            if let dragPath = viewModel.getDraggingConnectionPath() {
                context.stroke(
                    dragPath,
                    with: .color(.black),
                    style: StrokeStyle(lineWidth: 5, lineCap: .square, lineJoin: .miter, dash: [8, 8])
                )
                context.stroke(
                    dragPath,
                    with: .color(.yellow),
                    style: StrokeStyle(lineWidth: 3, lineCap: .square, lineJoin: .miter, dash: [8, 8])
                )
            }
        }
        .allowsHitTesting(false)
    }
    
    private var connectionHitAreas: some View {
        ForEach(viewModel.connections) { connection in
            if let path = viewModel.getConnectionPath(
                connection: connection,
                nodes: state.nodes,
                canvasOffset: viewModel.canvasOffset
            ) {
                ConnectionHitArea(
                    path: path,
                    isSelected: viewModel.selectedConnectionId == connection.id,
                    onTap: {
                        viewModel.selectConnection(connection.id)
                    }
                )
            }
        }
    }
    
    private var cutButtonLayer: some View {
        Group {
            if let selectedConnection = viewModel.connections.first(where: { $0.id == viewModel.selectedConnectionId }),
               let midpoint = viewModel.getConnectionMidpoint(
                connection: selectedConnection,
                nodes: state.nodes,
                canvasOffset: viewModel.canvasOffset
               ) {
                
                PixelCutButton()
                    .position(
                        x: midpoint.x,
                        y: midpoint.y - 40
                    )
                    .onTapGesture {
                        viewModel.deleteSelectedConnection(state: state)
                    }
            }
        }
    }
    
    private var nodesLayer: some View {
        ForEach(state.nodes) { node in
            NodeDisplayView(
                node: node,
                isSelected: viewModel.selectedNodeId == node.id,
                isHovered: viewModel.hoveredNodeId == node.id,
                canvasOffset: viewModel.canvasOffset,
                onNodeDragChanged: { translation in
                    viewModel.handleNodeDrag(nodeId: node.id, translation: translation, state: state)
                },
                onNodeDragEnded: {
                    viewModel.endNodeDrag()
                },
                onNodeTap: {
                    viewModel.selectNode(node.id)
                },
                onOutputDragStarted: { globalPosition in
                    viewModel.startConnectionDrag(from: node.id, at: globalPosition)
                },
                onOutputDragChanged: { location in
                    viewModel.updateConnectionDrag(to: location, nodes: state.nodes)
                },
                onOutputDragEnded: {
                    viewModel.endOutputDrag(state: state)
                }
            )
            .position(
                x: node.position.x + viewModel.canvasOffset.width,
                y: node.position.y + viewModel.canvasOffset.height
            )
        }
    }
    
    private var canvasDragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                viewModel.handleCanvasDrag(translation: value.translation)
            }
            .onEnded { _ in
                viewModel.endCanvasDrag()
            }
    }
}

// MARK: - Pixel Grid Background
struct PixelGridBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.15, green: 0.15, blue: 0.2)
            
            GeometryReader { geometry in
                Path { path in
                    let spacing: CGFloat = 32
                    
                    // Vertical lines
                    for x in stride(from: 0, to: geometry.size.width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }
                    
                    // Horizontal lines
                    for y in stride(from: 0, to: geometry.size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                
                // Accent pixels
                Path { path in
                    let spacing: CGFloat = 64
                    for x in stride(from: 0, to: geometry.size.width, by: spacing) {
                        for y in stride(from: 0, to: geometry.size.height, by: spacing) {
                            path.addRect(CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
                        }
                    }
                }
                .fill(Color.cyan.opacity(0.3))
            }
        }
    }
}

// MARK: - Connection Hit Area
struct ConnectionHitArea: View {
    let path: Path
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        path
            .stroke(Color.clear, lineWidth: 20)
            .contentShape(path.stroke(lineWidth: 20))
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Pixel Cut Button View
struct PixelCutButton: View {
    var body: some View {
        ZStack {
            // Shadow
            PixelBorder()
                .fill(Color.black.opacity(0.5))
                .frame(width: 48, height: 48)
                .offset(x: 2, y: 2)
            
            // Main button
            PixelBorder()
                .fill(Color.orange)
                .frame(width: 48, height: 48)
            
            // Border
            PixelBorder()
                .stroke(Color.black, lineWidth: 3)
                .frame(width: 48, height: 48)
            
            // Highlight
            PixelBorder()
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                .frame(width: 44, height: 44)
                .offset(x: -2, y: -2)
            
            Text("✂️")
                .font(.system(size: 24))
        }
    }
}

// MARK: - Node Display View
struct NodeDisplayView: View {
    let node: FlowNode
    let isSelected: Bool
    let isHovered: Bool
    let canvasOffset: CGSize
    let onNodeDragChanged: (CGSize) -> Void
    let onNodeDragEnded: () -> Void
    let onNodeTap: () -> Void
    let onOutputDragStarted: (CGPoint) -> Void
    let onOutputDragChanged: (CGPoint) -> Void
    let onOutputDragEnded: () -> Void
    
    @State private var nodeDragTranslation: CGSize = .zero
    @State private var isNodeDragging = false
    
    var body: some View {
        ZStack {
            nodeBody
                .gesture(nodeDragGesture)
                .onTapGesture {
                    if !isNodeDragging {
                        onNodeTap()
                    }
                }
            
            nodeTitle
            
            if node.type != .start {
                inputCircle
            }
            
            if node.type != .end {
                outputCircle
            }
        }
        .frame(width: NodeConstants.width, height: NodeConstants.height)
    }
    
    private var nodeBody: some View {
        ZStack {
            // Shadow
            PixelBorder()
                .fill(Color.black.opacity(0.4))
                .frame(width: NodeConstants.width, height: NodeConstants.height)
                .offset(x: 4, y: 4)
            
            // Main body
            PixelBorder()
                .fill(nodeTypeColor)
                .frame(width: NodeConstants.width, height: NodeConstants.height)
            
            // Dark border
            PixelBorder()
                .stroke(Color.black, lineWidth: isSelected ? 4 : 3)
                .frame(width: NodeConstants.width, height: NodeConstants.height)
            
            // Selection glow
            if isSelected {
                PixelBorder()
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: NodeConstants.width + 4, height: NodeConstants.height + 4)
                    .opacity(0.8)
            }
            
            // Highlight
            PixelBorder()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: NodeConstants.width - 6, height: NodeConstants.height - 6)
                .offset(x: -2, y: -2)
        }
    }
    
    private var nodeTypeColor: Color {
        switch node.type {
        case .start: return Color(red: 0.3, green: 0.8, blue: 0.3)
        case .story: return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .decision: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .end: return Color(red: 0.9, green: 0.3, blue: 0.3)
        }
    }
    
    private var nodeTitle: some View {
        VStack(spacing: 4) {
            Text(node.type.emoji)
                .font(.system(size: 24))
                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
            
            Text(node.text.isEmpty ? defaultTitle : node.text)
                .font(.custom("Courier", size: 12).weight(.bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 12)
                .shadow(color: .black.opacity(0.7), radius: 0, x: 1, y: 1)
        }
        .allowsHitTesting(false)
    }
    
    private var defaultTitle: String {
        switch node.type {
        case .start: return "START"
        case .story: return "Story"
        case .decision: return "Choice"
        case .end: return "END"
        }
    }
    
    private var inputCircle: some View {
        PixelHandle(color: isHovered ? .green : .cyan)
            .offset(x: NodeConstants.inputX, y: 0)
            .allowsHitTesting(false)
    }
    
    private var outputCircle: some View {
        let outputCircleGlobalCenter = CGPoint(
            x: node.position.x + NodeConstants.outputX + canvasOffset.width,
            y: node.position.y + canvasOffset.height
        )
        return PixelHandle(color: .orange)
            .position(
                x: NodeConstants.width / 2 + NodeConstants.outputX,
                y: NodeConstants.height / 2
            )
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if value.translation == .zero {
                            onOutputDragStarted(outputCircleGlobalCenter)
                        }
                        onOutputDragChanged(CGPoint(
                            x: value.location.x + outputCircleGlobalCenter.x - value.startLocation.x,
                            y: value.location.y + outputCircleGlobalCenter.y - value.startLocation.y
                        ))
                    }
                    .onEnded { _ in
                        onOutputDragEnded()
                    }
            )
    }
    
    private var nodeDragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                isNodeDragging = true
                nodeDragTranslation = value.translation
                onNodeDragChanged(value.translation)
            }
            .onEnded { _ in
                nodeDragTranslation = .zero
                onNodeDragEnded()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isNodeDragging = false
                }
            }
    }
}

// MARK: - Pixel Handle
struct PixelHandle: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // Shadow
            PixelBorder()
                .fill(Color.black.opacity(0.5))
                .frame(width: NodeConstants.handleSize, height: NodeConstants.handleSize)
                .offset(x: 2, y: 2)
            
            // Main circle
            PixelBorder()
                .fill(color)
                .frame(width: NodeConstants.handleSize, height: NodeConstants.handleSize)
            
            // Black border
            PixelBorder()
                .stroke(Color.black, lineWidth: 2)
                .frame(width: NodeConstants.handleSize, height: NodeConstants.handleSize)
            
            // White highlight
            PixelBorder()
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: NodeConstants.handleSize - 4, height: NodeConstants.handleSize - 4)
                .offset(x: -1, y: -1)
        }
    }
}

// MARK: - Connection Model
struct FlowConnection: Identifiable, Equatable {
    let id = UUID()
    let fromNodeId: String
    let toNodeId: String
    
    static func == (lhs: FlowConnection, rhs: FlowConnection) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - View Model
class FlowchartEditorViewModel: ObservableObject {
    @Published var connections: [FlowConnection] = []
    @Published var selectedNodeId: String?
    @Published var selectedConnectionId: UUID?
    @Published var hoveredNodeId: String?
    @Published var canvasOffset: CGSize = .zero
    @Published var isPreviewMode = false
    @Published var showSaveSuccess = false
    
    private var draggedNodeId: String?
    private var nodeDragStartPosition: CGPoint?
    private var canvasDragStartOffset: CGSize = .zero
    private var isCreatingConnection = false
    private var connectionDragStart: CGPoint?
    private var connectionDragCurrent: CGPoint?
    private var connectionDragFromNodeId: String?
    
    func loadInitialState(state: FlowchartState) {
        connections.removeAll()
        for node in state.nodes {
            for targetId in node.outs {
                let connection = FlowConnection(fromNodeId: node.id, toNodeId: targetId)
                connections.append(connection)
            }
        }
        
        if state.nodes.isEmpty {
            let startNode = FlowNode(
                type: .start,
                text: "You awake",
                position: CGPoint(x: 100, y: 100)
            )
            
            let endNode = FlowNode(
                type: .end,
                text: "End of route",
                position: CGPoint(x: 400, y: 150)
            )
            
            state.nodes.append(contentsOf: [startNode, endNode])
        }
    }
    
    func addStoryNode(state: FlowchartState) {
        let rightMostX = state.nodes.map { $0.position.x }.max() ?? 0
        let storyNode = FlowNode(
            type: .story,
            text: "Story",
            position: CGPoint(x: rightMostX + 200, y: 150)
        )
        state.nodes.append(storyNode)
        selectedNodeId = storyNode.id
        selectedConnectionId = nil
    }
    
    func addDecisionNode(state: FlowchartState) {
        let rightMostX = state.nodes.map { $0.position.x }.max() ?? 0
        let decisionNode = FlowNode(
            type: .decision,
            text: "Choice",
            position: CGPoint(x: rightMostX + 200, y: 150)
        )
        state.nodes.append(decisionNode)
        selectedNodeId = decisionNode.id
        selectedConnectionId = nil
    }
    
    func deleteSelectedNode(state: FlowchartState) {
        guard let selectedId = selectedNodeId else { return }
        
        if let node = state.findNode(id: selectedId) {
            if node.type == .start || node.type == .end {
                return
            }
        }
        
        state.removeNode(id: selectedId)
        
        connections.removeAll { connection in
            connection.fromNodeId == selectedId || connection.toNodeId == selectedId
        }
        
        for otherNode in state.nodes {
            otherNode.outs.removeAll { $0 == selectedId }
        }
        
        selectedNodeId = nil
    }
    
    func deleteSelectedConnection(state: FlowchartState) {
        guard let selectedId = selectedConnectionId else { return }
        
        if let connection = connections.first(where: { $0.id == selectedId }) {
            if let fromNode = state.findNode(id: connection.fromNodeId) {
                fromNode.outs.removeAll { $0 == connection.toNodeId }
            }
        }
        
        connections.removeAll { $0.id == selectedId }
        selectedConnectionId = nil
    }
    
    func selectNode(_ nodeId: String) {
        selectedNodeId = nodeId
        selectedConnectionId = nil
    }
    
    func selectConnection(_ connectionId: UUID) {
        selectedConnectionId = connectionId
        selectedNodeId = nil
    }
    
    func deselectAll() {
        selectedNodeId = nil
        selectedConnectionId = nil
    }
    
    func handleNodeDrag(nodeId: String, translation: CGSize, state: FlowchartState) {
        if draggedNodeId == nil {
            draggedNodeId = nodeId
            if let node = state.findNode(id: nodeId) {
                nodeDragStartPosition = node.position
            }
        }
        
        guard let startPosition = nodeDragStartPosition,
              let node = state.findNode(id: nodeId) else {
            return
        }
        
        node.position = CGPoint(
            x: startPosition.x + translation.width,
            y: startPosition.y + translation.height
        )
        
        state.updateNode(node)
    }
    
    func endNodeDrag() {
        draggedNodeId = nil
        nodeDragStartPosition = nil
    }
    
    func handleCanvasDrag(translation: CGSize) {
        if canvasDragStartOffset == .zero {
            canvasDragStartOffset = canvasOffset
        }
        
        canvasOffset = CGSize(
            width: canvasDragStartOffset.width + translation.width,
            height: canvasDragStartOffset.height + translation.height
        )
    }
    
    func endCanvasDrag() {
        canvasDragStartOffset = .zero
    }
    
    func startConnectionDrag(from nodeId: String, at globalPosition: CGPoint) {
        isCreatingConnection = true
        connectionDragFromNodeId = nodeId
        connectionDragStart = globalPosition
        connectionDragCurrent = globalPosition
    }
    
    func updateConnectionDrag(to location: CGPoint, nodes: [FlowNode]) {
        connectionDragCurrent = location
        
        hoveredNodeId = nil
        for node in nodes {
            guard node.id != connectionDragFromNodeId else { continue }
            
            let inputHandleCenter = CGPoint(
                x: node.position.x + NodeConstants.inputX + canvasOffset.width,
                y: node.position.y + canvasOffset.height
            )
            
            let distance = hypot(location.x - inputHandleCenter.x, location.y - inputHandleCenter.y)
            if distance < NodeConstants.handleSize + 10 {
                hoveredNodeId = node.id
                break
            }
        }
    }
    
    func endOutputDrag(state: FlowchartState) {
        if let fromId = connectionDragFromNodeId, let toId = hoveredNodeId {
            guard let fromNode = state.findNode(id: fromId),
                  let toNode = state.findNode(id: toId) else {
                resetConnectionDrag()
                return
            }
            
            let canConnect = validateConnection(from: fromNode, to: toNode, state: state)
            
            if canConnect {
                let exists = connections.contains { connection in
                    connection.fromNodeId == fromId && connection.toNodeId == toId
                }
                
                if !exists {
                    if fromNode.type == .story {
                        let oldConnections = connections.filter { $0.fromNodeId == fromId }
                        for oldConn in oldConnections {
                            connections.removeAll { $0.id == oldConn.id }
                            fromNode.outs.removeAll { $0 == oldConn.toNodeId }
                        }
                        
                        if toNode.type == .story {
                            state.nodes.forEach { node in
                                if node.id != fromId && node.type == .story {
                                    if let index = node.outs.firstIndex(of: toId) {
                                        node.outs.remove(at: index)
                                        connections.removeAll {
                                            $0.fromNodeId == node.id && $0.toNodeId == toId
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    let newConnection = FlowConnection(fromNodeId: fromId, toNodeId: toId)
                    connections.append(newConnection)
                    
                    if !fromNode.outs.contains(toId) {
                        fromNode.outs.append(toId)
                        state.updateNode(fromNode)
                    }
                }
            }
        }
        
        resetConnectionDrag()
    }
    
    private func resetConnectionDrag() {
        isCreatingConnection = false
        connectionDragStart = nil
        connectionDragCurrent = nil
        connectionDragFromNodeId = nil
        hoveredNodeId = nil
    }
    
    private func validateConnection(from: FlowNode, to: FlowNode, state: FlowchartState) -> Bool {
        if from.id == to.id { return false }
        if to.type == .start { return false }
        if from.type == .end { return false }
        
        switch from.type {
        case .story:
            return to.type == .story || to.type == .decision || to.type == .end
        case .decision:
            return to.type == .story || to.type == .end
        case .start:
            return to.type == .story || to.type == .decision
        case .end:
            return false
        }
    }
    
    func togglePreview() {
        isPreviewMode.toggle()
        if isPreviewMode {
            selectedNodeId = nil
            selectedConnectionId = nil
        }
    }
    
    func saveFlowchart(state: FlowchartState, projectId: String, storyViewModel: StoryProjectViewModel) {
        storyViewModel.saveFlowchart(projectId: projectId, state: state)
        showSaveSuccess = true
    }
    
    func getDraggingConnectionPath() -> Path? {
        guard let start = connectionDragStart, let end = connectionDragCurrent else {
            return nil
        }
            
        return Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
    }
    
    func getConnectionPath(connection: FlowConnection, nodes: [FlowNode], canvasOffset: CGSize) -> Path? {
        guard let fromNode = nodes.first(where: { $0.id == connection.fromNodeId }),
              let toNode = nodes.first(where: { $0.id == connection.toNodeId }) else {
            return nil
        }
        
        let startPoint = CGPoint(
            x: fromNode.position.x + NodeConstants.outputX + canvasOffset.width,
            y: fromNode.position.y + canvasOffset.height
        )
        
        let endPoint = CGPoint(
            x: toNode.position.x + NodeConstants.inputX + canvasOffset.width,
            y: toNode.position.y + canvasOffset.height
        )
        
        return Path { path in
            path.move(to: startPoint)
            
            let distance = abs(endPoint.x - startPoint.x)
            let controlOffset = min(distance * 0.5, 100)
            
            let control1 = CGPoint(x: startPoint.x + controlOffset, y: startPoint.y)
            let control2 = CGPoint(x: endPoint.x - controlOffset, y: endPoint.y)
            
            path.addCurve(to: endPoint, control1: control1, control2: control2)
        }
    }
    
    func getConnectionMidpoint(connection: FlowConnection, nodes: [FlowNode], canvasOffset: CGSize) -> CGPoint? {
        guard let fromNode = nodes.first(where: { $0.id == connection.fromNodeId }),
              let toNode = nodes.first(where: { $0.id == connection.toNodeId }) else {
            return nil
        }
        
        let startPoint = CGPoint(
            x: fromNode.position.x + NodeConstants.outputX + canvasOffset.width,
            y: fromNode.position.y + canvasOffset.height
        )
        
        let endPoint = CGPoint(
            x: toNode.position.x + NodeConstants.inputX + canvasOffset.width,
            y: toNode.position.y + canvasOffset.height
        )
        
        let distance = abs(endPoint.x - startPoint.x)
        let controlOffset = min(distance * 0.5, 100)
        
        let control1 = CGPoint(x: startPoint.x + controlOffset, y: startPoint.y)
        let control2 = CGPoint(x: endPoint.x - controlOffset, y: endPoint.y)
        
        let t: CGFloat = 0.5
        let x = pow(1 - t, 3) * startPoint.x +
                3 * pow(1 - t, 2) * t * control1.x +
                3 * (1 - t) * pow(t, 2) * control2.x +
                pow(t, 3) * endPoint.x
        
        let y = pow(1 - t, 3) * startPoint.y +
                3 * pow(1 - t, 2) * t * control1.y +
                3 * (1 - t) * pow(t, 2) * control2.y +
                pow(t, 3) * endPoint.y
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Preview Mode View
struct PreviewModeView: View {
    @ObservedObject var state: FlowchartState
    @ObservedObject var viewModel: FlowchartEditorViewModel
    @State private var currentNodeId: String?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PixelGridBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        let node = getCurrentNode()
                        
                        if let node = node {
                            nodeHeader(for: node)
                            nodeContent(for: node)
                            navigationButtons(for: node)
                        } else {
                            errorMessage
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: geometry.size.height)
                    .padding(24)
                }
                .background(Color.clear)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.clear)
        .onAppear {
            currentNodeId = state.nodes.first(where: { $0.type == .start })?.id
        }
    }
    
    private func getCurrentNode() -> FlowNode? {
        if let nodeId = currentNodeId {
            return state.findNode(id: nodeId)
        }
        return state.nodes.first(where: { $0.type == .start })
    }
    
    private func nodeHeader(for node: FlowNode) -> some View {
        HStack(spacing: 12) {
            Text(node.type.emoji)
                .font(.system(size: 32))
                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
            
            Text(nodeTitle(for: node.type))
                .font(.custom("Courier", size: 20).weight(.bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 0, x: 2, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            ZStack {
                PixelBorder()
                    .fill(nodeColor(for: node.type))
                
                PixelBorder()
                    .stroke(Color.black, lineWidth: 3)
            }
        )
    }
    
    private func nodeContent(for node: FlowNode) -> some View {
        Group {
            if !node.text.isEmpty {
                Text(node.text)
                    .font(.custom("Courier", size: 16))
                    .foregroundColor(.white)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        ZStack {
                            PixelBorder()
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                            
                            PixelBorder()
                                .stroke(Color.black, lineWidth: 3)
                            
                            PixelBorder()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                .offset(x: -2, y: -2)
                        }
                    )
            }
        }
    }
    
    private var errorMessage: some View {
        Text("⚠️ No starting node found")
            .font(.custom("Courier", size: 18).weight(.bold))
            .foregroundColor(.white)
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    PixelBorder()
                        .fill(Color.red.opacity(0.3))
                    
                    PixelBorder()
                        .stroke(Color.red, lineWidth: 3)
                }
            )
    }
    
    @ViewBuilder
    private func navigationButtons(for node: FlowNode) -> some View {
        VStack(spacing: 16) {
            switch node.type {
            case .story, .start:
                let connectedDecisions = node.outs.compactMap { outId in
                    state.findNode(id: outId)
                }.filter { $0.type == .decision }
                
                if !connectedDecisions.isEmpty {
                    choicesHeader
                    ForEach(connectedDecisions) { decision in
                        choiceButton(decision: decision)
                    }
                } else if let nextNode = node.outs.compactMap({ state.findNode(id: $0) }).first {
                    continueButton(nextNode: nextNode)
                } else {
                    warningMessage(text: "⚠️ No follow-up connected")
                }
                
            case .decision:
                let options = node.outs.compactMap { state.findNode(id: $0) }
                if options.isEmpty {
                    warningMessage(text: "⚠️ No choices connected")
                } else {
                    choicesHeader
                    ForEach(options) { option in
                        optionButton(option: option)
                    }
                }
                
            case .end:
                endScreen
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var choicesHeader: some View {
        Text("Choose your path:")
            .font(.custom("Courier", size: 16).weight(.bold))
            .foregroundColor(Color.cyan)
            .shadow(color: .black.opacity(0.7), radius: 0, x: 1, y: 1)
    }
    
    private func choiceButton(decision: FlowNode) -> some View {
        Button(action: {
            currentNodeId = decision.id
        }) {
            HStack {
                Text(decision.text.isEmpty ? "Choice" : decision.text)
                    .font(.custom("Courier", size: 14).weight(.bold))
                Spacer()
                Text("→")
                    .font(.system(size: 20, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    PixelBorder()
                        .fill(Color.blue)
                    PixelBorder()
                        .stroke(Color.black, lineWidth: 3)
                    PixelBorder()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .offset(x: -2, y: -2)
                }
            )
            .shadow(color: Color.black.opacity(0.4), radius: 0, x: 4, y: 4)
        }
    }
    
    private func continueButton(nextNode: FlowNode) -> some View {
        Button(action: {
            currentNodeId = nextNode.id
        }) {
            HStack {
                Text("Continue")
                    .font(.custom("Courier", size: 16).weight(.bold))
                Spacer()
                Text("▶")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    PixelBorder()
                        .fill(Color.green)
                    PixelBorder()
                        .stroke(Color.black, lineWidth: 3)
                    PixelBorder()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .offset(x: -2, y: -2)
                }
            )
            .shadow(color: Color.black.opacity(0.4), radius: 0, x: 4, y: 4)
        }
    }
    
    private func optionButton(option: FlowNode) -> some View {
        Button(action: {
            currentNodeId = option.id
        }) {
            HStack {
                Text(option.text.isEmpty ? "Option" : option.text)
                    .font(.custom("Courier", size: 14).weight(.bold))
                Spacer()
                Text("→")
                    .font(.system(size: 20, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    PixelBorder()
                        .fill(Color.purple)
                    PixelBorder()
                        .stroke(Color.black, lineWidth: 3)
                    PixelBorder()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .offset(x: -2, y: -2)
                }
            )
            .shadow(color: Color.black.opacity(0.4), radius: 0, x: 4, y: 4)
        }
    }
    
    private func warningMessage(text: String) -> some View {
        Text(text)
            .font(.custom("Courier", size: 14).weight(.bold))
            .foregroundColor(.orange)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    PixelBorder()
                        .fill(Color.orange.opacity(0.2))
                    
                    PixelBorder()
                        .stroke(Color.orange, lineWidth: 3)
                }
            )
    }
    
    private var endScreen: some View {
        VStack(spacing: 20) {
            Text("★ THE END ★")
                .font(.custom("Courier", size: 28).weight(.bold))
                .foregroundColor(.yellow)
                .shadow(color: .black.opacity(0.7), radius: 0, x: 2, y: 2)
                .padding(24)
                .background(
                    ZStack {
                        PixelBorder()
                            .fill(Color.green.opacity(0.3))
                        
                        PixelBorder()
                            .stroke(Color.yellow, lineWidth: 4)
                    }
                )
            
            Button(action: {
                currentNodeId = state.nodes.first(where: { $0.type == .start })?.id
            }) {
                HStack(spacing: 8) {
                    Text("🔄")
                        .font(.system(size: 20))
                    Text("Restart Story")
                        .font(.custom("Courier", size: 16).weight(.bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        PixelBorder()
                            .fill(Color.blue)
                        PixelBorder()
                            .stroke(Color.black, lineWidth: 3)
                        PixelBorder()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .offset(x: -2, y: -2)
                    }
                )
                .shadow(color: Color.black.opacity(0.4), radius: 0, x: 4, y: 4)
            }
        }
    }
    
    private func nodeTitle(for type: NodeType) -> String {
        switch type {
        case .start: return "START"
        case .story: return "STORY"
        case .decision: return "CHOICE"
        case .end: return "END"
        }
    }
    
    private func nodeColor(for type: NodeType) -> Color {
        switch type {
        case .start: return Color(red: 0.3, green: 0.8, blue: 0.3)
        case .story: return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .decision: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .end: return Color(red: 0.9, green: 0.3, blue: 0.3)
        }
    }
}

// MARK: - Edit Node View with Pixel Art Style
struct EditNodeView: View {
    let node: FlowNode
    @ObservedObject var state: FlowchartState
    @Binding var isPresented: Bool
    
    @State private var nodeText: String
    @State private var nodeImageData: String
    @State private var showImagePicker = false
    @State private var showImageOptions = false
    
    init(node: FlowNode, state: FlowchartState, isPresented: Binding<Bool>) {
        self.node = node
        self.state = state
        self._isPresented = isPresented
        self._nodeText = State(initialValue: node.text)
        self._nodeImageData = State(initialValue: node.imageData ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: sectionHeader("Node Type")) {
                    HStack(spacing: 12) {
                        Text(node.type.emoji)
                            .font(.system(size: 32))
                        Text(nodeTypeTitle)
                            .font(.custom("Courier", size: 18).weight(.bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color(red: 0.2, green: 0.2, blue: 0.3))
                }
                
                Section(header: sectionHeader("Text Content")) {
                    TextEditor(text: $nodeText)
                        .font(.custom("Courier", size: 14))
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
                        )
                    .listRowBackground(Color(red: 0.2, green: 0.2, blue: 0.3))
                }
                
                Section(header: sectionHeader("Image (Optional)")) {
                    imageSection
                        .listRowBackground(Color(red: 0.2, green: 0.2, blue: 0.3))
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                Color(red: 0.15, green: 0.15, blue: 0.2)
                    .ignoresSafeArea()
            )
            .navigationTitle("Edit Node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.2, green: 0.2, blue: 0.3), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.custom("Courier", size: 14).weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                PixelBorder()
                                    .fill(Color.gray)
                            )
                            .overlay(
                                PixelBorder()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        saveChanges()
                    }) {
                        Text("Save")
                            .font(.custom("Courier", size: 14).weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                PixelBorder()
                                    .fill(Color.green)
                            )
                            .overlay(
                                PixelBorder()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                    }
                }
            }
            .actionSheet(isPresented: $showImageOptions) {
                ActionSheet(
                    title: Text("Add Image"),
                    message: Text("Choose an option"),
                    buttons: [
                        .default(Text("Choose from Library")) {
                            showImagePicker = true
                        },
                        .default(Text("Use Sample Image")) {
                            nodeImageData = createSampleImageBase64()
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(imageData: $nodeImageData)
            }
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.custom("Courier", size: 12).weight(.bold))
            .foregroundColor(.cyan)
    }
    
    @ViewBuilder
    private var imageSection: some View {
        if !nodeImageData.isEmpty {
            VStack(spacing: 12) {
                if let uiImage = decodeBase64Image(nodeImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cyan, lineWidth: 3)
                        )
                } else {
                    Text("Invalid image data")
                        .foregroundColor(.red)
                        .font(.custom("Courier", size: 12).weight(.bold))
                        .padding()
                }
                
                Button(action: {
                    nodeImageData = ""
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Remove Image")
                            .font(.custom("Courier", size: 14).weight(.bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 2)
                    )
                }
            }
            .padding(.vertical, 8)
        } else {
            Button(action: {
                showImageOptions = true
            }) {
                HStack {
                    Image(systemName: "photo.fill")
                    Text("Add Image")
                        .font(.custom("Courier", size: 14).weight(.bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 2)
                )
            }
            .padding(.vertical, 8)
        }
    }
    
    private var nodeTypeTitle: String {
        switch node.type {
        case .start: return "START NODE"
        case .story: return "STORY NODE"
        case .decision: return "CHOICE NODE"
        case .end: return "END NODE"
        }
    }
    
    private func saveChanges() {
        node.text = nodeText
        node.imageData = nodeImageData.isEmpty ? "" : nodeImageData
        state.updateNode(node)
        isPresented = false
    }
    
    private func decodeBase64Image(_ base64String: String) -> UIImage? {
        let cleanBase64 = base64String
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpg;base64,", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let imageData = Data(base64Encoded: cleanBase64) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    private func createSampleImageBase64() -> String {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.white.setStroke()
            context.cgContext.setLineWidth(4)
            
            let rect = CGRect(x: 50, y: 50, width: 100, height: 100)
            context.cgContext.strokeEllipse(in: rect)
        }
        
        guard let imageData = image.pngData() else {
            return ""
        }
        
        return "data:image/png;base64," + imageData.base64EncodedString()
    }
}

// MARK: - Image Picker View
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var imageData: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    parent.imageData = "data:image/jpeg;base64," + imageData.base64EncodedString()
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview
struct FlowchartEditorView_Previews: PreviewProvider {
    static var previews: some View {
        FlowchartEditorView(
            state: FlowchartState(),
            projectId: "test",
            viewModel: StoryProjectViewModel()
        )
    }
}
