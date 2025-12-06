import SwiftUI
import PhotosUI

struct ChatView: View {
    @StateObject private var vm = ConversationViewModel()
    let userId: String
    @State private var showDrawer: Bool = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack(alignment: .leading) {
            // Main chat area
            VStack(spacing: 0) {
                TopBar(title: vm.selectedConversation?.title ?? "NEW QUEST") {
                    withAnimation { showDrawer.toggle() }
                }

                if let err = vm.error {
                    Text(err)
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundColor(.red)
                        .padding(8)
                }

                ChatScrollView(vm: vm, userId: userId)
                    .environmentObject(vm)

                InputBar(userId: userId)
                    .environmentObject(vm)
            }
            .background(
                Group {
                    if themeManager.isDarkMode {
                        DarkThemeBackground()
                    } else {
                        Image("background_land")
                            .resizable()
                            .scaledToFill()
                            .edgesIgnoringSafeArea(.all)
                    }
                }
            )


            // Drawer overlay
            if showDrawer {
                ZStack(alignment: .leading) {
                    // Semi-transparent background
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { showDrawer = false }
                        }

                    // Drawer content
                    DrawerContent(
                        vm: vm,
                        userId: userId,
                        conversations: vm.conversations,
                        onConversationClick: { conv in
                            vm.selectConversation(conv, userId: userId)
                            withAnimation { showDrawer = false }
                        },
                        onClose: { withAnimation { showDrawer = false } },
                        onCreateNewConversation: {
                            Task {
                                await vm.createNewConversation(title: "New Conversation", userId: userId)
                                withAnimation { showDrawer = false }
                            }
                        }
                    )
                    .frame(width: 260)
                    .transition(.move(edge: .leading))
                   
                }
                .zIndex(1)
            }
        }
        .animation(.easeInOut, value: showDrawer)
        .onAppear { 
            vm.loadConversations(userId: userId)
        }
    }
}

// MARK: - Top Bar
struct TopBar: View {
    let title: String
    let onMenuClick: () -> Void

    var body: some View {
        HStack {
            Button(action: onMenuClick) {
                Image("burger_icon")
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            Spacer()
            Text(title)
                .font(.custom("PressStart2P-Regular", size: 18))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(12)
        .background(Color(red: 0.16, green: 0.16, blue: 0.16))
    }
}

// MARK: - Chat Scroll View
struct ChatScrollView: View {
    @ObservedObject var vm: ConversationViewModel
    let userId: String

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(vm.messages) { msg in
                        if msg.sender == "user" {
                            userBubble(msg)
                        } else {
                            aiBubble(msg)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: vm.messages.count) { _ in
                if let last = vm.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func userBubble(_ msg: Message) -> some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                // Display images above message
                if let images = msg.images, !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(images, id: \.id) { imgData in
                                if let base64String = imgData.base64,
                                   let data = Data(base64Encoded: base64String),
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                }
                
                Text(msg.content)
                    .font(.custom("PressStart2P-Regular", size: 9))
                    .padding(12)
                    .background(
                        Image("container")
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)

                Menu {
                    Button("Edit") {
                        vm.messageInput = msg.content
                        vm.editingMessageId = msg.id
                        vm.isEditingMode = true
                        // Load existing images for editing
                        if let images = msg.images {
                            vm.selectedImages = images.compactMap { imgData in
                                if let base64String = imgData.base64,
                                   let data = Data(base64Encoded: base64String) {
                                    return UIImage(data: data)
                                }
                                return nil
                            }
                        }
                    }
                    Button("Delete", role: .destructive) {
                        vm.deleteMessage(conversationId:msg.conversationId , messageId: msg.id, userId: userId)
                    }
                } label: {
                    Image("drop_down_icon")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(.horizontal, 8).zIndex(3)
    }

    @ViewBuilder
    private func aiBubble(_ msg: Message) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(msg.content)
                    .font(.custom("PressStart2P-Regular", size: 9))
                    .padding(12)
                    .background(
                        Image("container")
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}


struct InputBar: View {
    @EnvironmentObject var viewModel: ConversationViewModel
    let userId: String
    @State private var showImagePicker = false
    @State private var selectedImageItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(spacing: 8) {
            // Image preview section (shown when images are selected)
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedImages.indices, id: \.self) { idx in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: viewModel.selectedImages[idx])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                // Remove image button
                                Button(action: {
                                    viewModel.selectedImages.remove(at: idx)
                                }) {
                                    Image("x_icon")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(.red)
                                        .padding(4)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(maxWidth: .infinity)
            }

            // Input controls container
            HStack(spacing: 12) {
                // Add image button
                PhotosPicker(selection: $selectedImageItems, matching: .images) {
                    Image("add_image_button")
                        .resizable()
                        .frame(width: 28, height: 28)
                }
                .onChange(of: selectedImageItems) { newItems in
                    Task {
                        var loadedImages: [UIImage] = []
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                loadedImages.append(uiImage)
                            }
                        }
                        await MainActor.run {
                            self.viewModel.selectedImages.append(contentsOf: loadedImages)
                            self.selectedImageItems.removeAll()
                        }
                    }
                }

                TextField("Type your message…", text: $viewModel.messageInput)
                    .font(.custom("PressStart2P-Regular", size: 12))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.45), lineWidth: 1)
                    )
                    .foregroundColor(.black)

                Button(action: {
                    viewModel.sendOrEditMessage(userId: userId)
                }) {
                    Image("send")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Image("container")
                    .resizable()
                    .scaledToFill()
                    .clipped()
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .zIndex(3)
    }
}
// MARK: - Drawer Content
struct DrawerContent: View {
    @ObservedObject var vm: ConversationViewModel
    let userId: String
    let conversations: [Conversation]
    let onConversationClick: (Conversation) -> Void
    let onClose: () -> Void
    let onCreateNewConversation: () -> Void

    var body: some View {
            VStack {
                // Close icon
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image("x_icon")
                            .resizable()
                            .frame(width: 28, height: 28)
                    }
                }
                .padding(.bottom, 12)

                // HISTORY + ADD BUTTON
                HStack {
                    Text("HISTORY")
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .padding(6)
                    Spacer()
                    Button(action: {
                        Task {
                            await vm.createNewConversation(title: "New Conversation", userId: userId)
                        }
                    }) {
                        Image("icon_plus")
                            .resizable()
                            .frame(width: 22, height: 22)
                    }
                }
                .padding(.vertical, 8)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(vm.conversations) { conv in
                            ConversationRow(conv: conv, vm: vm, userId: userId, onSelect: {
                                vm.selectConversation(conv, userId: userId)
                                onClose()
                            })
                        }
                    }
                }
            }
            .frame(width: 260)
            .padding(16)
            .background(Color(red: 254/255, green: 238/255, blue: 176/255))
        .zIndex(2) // ensure drawer is tappable above overlay
    }
}

struct ConversationRow: View {
    let conv: Conversation
    @ObservedObject var vm: ConversationViewModel
    let userId: String
    let onSelect: () -> Void

    @State private var isEditing = false
    @State private var editText: String = ""

    var body: some View {
        HStack {
            if isEditing {
                TextField("Title", text: $editText)
                    .font(.custom("PressStart2P-Regular", size: 12))
                    .textFieldStyle(.roundedBorder)

                Button(action: {
                    Task {
                        await vm.editConversationTitle(conversationId: conv.id, newTitle: editText)
                        isEditing = false
                    }
                }) {
                    Image("send")
                        .resizable()
                        .frame(width: 24, height: 24)
                }

                Button(action: {
                    isEditing = false
                    editText = conv.title
                }) {
                    Image("x_icon")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            } else {
                Text(conv.title)
                    .font(.custom("PressStart2P-Regular", size: 12))
                    .lineLimit(2)
                    .onTapGesture { onSelect() }

                Spacer()

                Button(action: {
                    editText = conv.title
                    isEditing = true
                }) {
                    Image("update_ic")
                        .resizable()
                        .frame(width: 24, height: 24).foregroundColor(.white)
                }

                Button(action: {
                    Task {
                        await vm.deleteConversation(conversationId: conv.id)
                        }
                }) {
                    Image("delete_ic")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(8)
        .background(
            Image("container")
                .resizable()
                .scaledToFill()
                .clipped()
        )
        .cornerRadius(8)
    }
}
