//import SwiftUI
//
//// MARK: - Preview Overlay (Interactive Story Mode)
//
//struct PreviewOverlay: View {
//    let state: FlowchartState
//    let onClose: () -> Void
//    
//    @State private var currentNodeId: String?
//    
//    init(state: FlowchartState, onClose: @escaping () -> Void) {
//        self.state = state
//        self.onClose = onClose
//        // Initialize with start node
//        let startNode = state.nodes.first { $0.type == .start } ?? state.nodes.first
//        _currentNodeId = State(initialValue: startNode?.id)
//    }
//    
//    var body: some View {
//        ZStack {
//            Color.black.opacity(0.95)
//                .ignoresSafeArea()
//            
//            VStack(spacing: 0) {
//                // Header
//                headerBar
//                
//                // Content area
//                ScrollView {
//                    if let nodeId = currentNodeId,
//                       let node = state.findNode(id: nodeId) {
//                        nodeContent(node: node)
//                    }
//                }
//                .background(Color(hex: "2A2A2A"))
//            }
//        }
//    }
//    
//    private var headerBar: some View {
//        HStack {
//            Text("📖 STORY MODE")
//                .font(.system(size: 16, design: .monospaced))
//                .fontWeight(.bold)
//                .foregroundColor(Color(hex: "00FF00"))
//                .tracking(1)
//            
//            Spacer()
//            
//            Button(action: onClose) {
//                Image(systemName: "xmark.circle.fill")
//                    .font(.system(size: 24))
//                    .foregroundColor(.white)
//            }
//        }
//        .padding()
//        .background(Color(hex: "1A1A1A"))
//        .overlay(
//            Rectangle()
//                .stroke(Color.black, lineWidth: 3),
//            alignment: .bottom
//        )
//    }
//    
//    private func nodeContent(node: FlowNode) -> some View {
//        VStack(alignment: .leading, spacing: 16) {
//            // Node type badge
//            HStack(spacing: 8) {
//                Text(nodeTypeIcon(node.type))
//                    .font(.system(size: 16))
//                Text(nodeTypeLabel(node.type))
//                    .font(.system(size: 12, design: .monospaced))
//                    .fontWeight(.bold)
//                    .foregroundColor(Color(hex: "00FF00"))
//                    .tracking(0.5)
//            }
//            .padding(.horizontal, 12)
//            .padding(.vertical, 6)
//            .background(Color(hex: "1A1A1A"))
//            .overlay(
//                Rectangle()
//                    .stroke(Color(hex: "4A4A4A"), lineWidth: 2)
//            )
//            
//            // Image if exists
//            if !node.imageData.isEmpty {
//                Base64Image(base64String: node.imageData, placeholder: "photo")
//                    .frame(height: 300)
//                    .frame(maxWidth: .infinity)
//                    .background(Color(hex: "1A1A1A"))
//                    .overlay(
//                        Rectangle()
//                            .stroke(Color.black, lineWidth: 3)
//                    )
//            }
//            
//            // Text content
//            Text(node.text.isEmpty ? "No text provided." : node.text)
//                .font(.system(size: 14, design: .monospaced))
//                .foregroundColor(.white)
//                .padding(16)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .background(Color(hex: "1A1A1A"))
//                .overlay(
//                    Rectangle()
//                        .stroke(Color.black, lineWidth: 3)
//                )
//            
//            Spacer().frame(height: 20)
//            
//            // Navigation options
//            navigationOptions(for: node)
//        }
//        .padding(16)
//    }
//    
//    @ViewBuilder
//    private func navigationOptions(for node: FlowNode) -> some View {
//        VStack(alignment: .leading, spacing: 12) {
//            switch node.type {
//            case .start, .story:
//                let connectedDecisions = node.outs.compactMap { outId in
//                    state.findNode(id: outId)
//                }.filter { $0.type == .decision }
//                
//                if !connectedDecisions.isEmpty {
//                    Text("⚔ CHOOSE YOUR PATH:")
//                        .font(.system(size: 12, design: .monospaced))
//                        .fontWeight(.bold)
//                        .foregroundColor(Color(hex: "00FF00"))
//                        .tracking(0.5)
//                    
//                    ForEach(connectedDecisions) { decision in
//                        storyButton(
//                            text: "→ \(decision.text.isEmpty ? "Choice" : decision.text)",
//                            action: { currentNodeId = decision.id }
//                        )
//                    }
//                } else if let nextNode = node.outs.compactMap({ state.findNode(id: $0) }).first {
//                    storyButton(
//                        text: "→ CONTINUE",
//                        action: { currentNodeId = nextNode.id }
//                    )
//                } else {
//                    warningBox(message: "⚠ No follow-up connected.", color: Color(hex: "FFAA00"))
//                }
//                
//            case .decision:
//                let options = node.outs.compactMap { state.findNode(id: $0) }
//                
//                if options.isEmpty {
//                    warningBox(message: "⚠ No choices connected.", color: Color(hex: "FF6B6B"))
//                } else {
//                    Text("⚔ CHOOSE YOUR PATH:")
//                        .font(.system(size: 12, design: .monospaced))
//                        .fontWeight(.bold)
//                        .foregroundColor(Color(hex: "00FF00"))
//                        .tracking(0.5)
//                    
//                    ForEach(options) { option in
//                        storyButton(
//                            text: "→ \(option.text.isEmpty ? "Option" : option.text)",
//                            action: { currentNodeId = option.id }
//                        )
//                    }
//                }
//                
//            case .end:
//                VStack(spacing: 16) {
//                    Text("★ THE END ★")
//                        .font(.system(size: 20, design: .monospaced))
//                        .fontWeight(.bold)
//                        .foregroundColor(Color(hex: "00FF00"))
//                        .tracking(2)
//                        .frame(maxWidth: .infinity)
//                        .padding(20)
//                        .background(Color(hex: "1A3A1A"))
//                        .overlay(
//                            Rectangle()
//                                .stroke(Color.black, lineWidth: 3)
//                        )
//                    
//                    storyButton(
//                        text: "↻ RESTART STORY",
//                        action: {
//                            currentNodeId = state.nodes.first { $0.type == .start }?.id
//                        }
//                    )
//                }
//            }
//        }
//    }
//    
//    private func storyButton(text: String, action: @escaping () -> Void) -> some View {
//        Button(action: action) {
//            Text(text)
//                .font(.system(size: 11, design: .monospaced))
//                .fontWeight(.bold)
//                .foregroundColor(.white)
//                .tracking(1)
//                .frame(maxWidth: .infinity)
//                .padding(.horizontal, 12)
//                .padding(.vertical, 10)
//                .background(Color(hex: "4A4A4A"))
//                .overlay(
//                    Rectangle()
//                        .stroke(Color(hex: "6A6A6A"), lineWidth: 2)
//                )
//        }
//    }
//    
//    private func warningBox(message: String, color: Color) -> some View {
//        Text(message)
//            .font(.system(size: 12, design: .monospaced))
//            .foregroundColor(color)
//            .frame(maxWidth: .infinity)
//            .padding(12)
//            .background(Color(hex: "3A2A1A"))
//            .overlay(
//                Rectangle()
//                    .stroke(Color(hex: "4A4A4A"), lineWidth: 2)
//            )
//    }
//    
//    private func nodeTypeIcon(_ type: NodeType) -> String {
//        switch type {
//        case .start: return "🔴"
//        case .story: return "📝"
//        case .decision: return "❓"
//        case .end: return "🔚"
//        }
//    }
//    
//    private func nodeTypeLabel(_ type: NodeType) -> String {
//        switch type {
//        case .start: return "START"
//        case .story: return "STORY"
//        case .decision: return "CHOICE"
//        case .end: return "END"
//        }
//    }
//}
//
//// MARK: - Preview Overlay with History (for Community Projects)
//
