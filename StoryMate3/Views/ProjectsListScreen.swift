import SwiftUI

// MARK: - Projects List Screen

struct ProjectsListScreen: View {
    @StateObject private var viewModel = StoryProjectViewModel()
    @State private var showCreateDialog = false
    @State private var projectToDelete: ProjectDto?
    @State private var projectToShare: ProjectDto?
    @State private var selectedProjectId: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.pixelDarkBlue.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with create button
                    createButtonBar
                    
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.projects.isEmpty {
                        emptyStateView
                    } else {
                        projectsGrid
                    }
                }
            }
            .sheet(isPresented: $showCreateDialog) {
                CreateProjectDialog { title, description in
                    viewModel.createNewProject(title: title, description: description) { projectId in
                        selectedProjectId = projectId
                    }
                }
            }
            .sheet(item: $projectToDelete) { project in
                DeleteConfirmationDialog(projectTitle: project.title) {
                    viewModel.deleteProject(projectId: project.id)
                    projectToDelete = nil
                }
            }
            .sheet(item: $projectToShare) { project in
                ShareConfirmationDialog(
                    projectTitle: project.title,
                    isLoading: viewModel.publishState == .loading
                ) {
                    viewModel.publishProject(projectId: project.id) {
                        projectToShare = nil
                    }
                } onDismiss: {
                    projectToShare = nil
                }
            }
        }
    }
    
    private var createButtonBar: some View {
        HStack {
            Spacer()
            Button(action: { showCreateDialog = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.pixelHighlight)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
        }
        .padding()
        .background(Color(hex: "1A1A1A"))
        .overlay(Rectangle().stroke(Color(hex: "2A2A2A"), lineWidth: 2))
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .pixelGold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("📝")
                .font(.system(size: 64))
            Text("No projects yet")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.gray)
            Text("Click the + button to create your first story!")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var projectsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                ForEach(viewModel.projects) { project in
                    ProjectCard(
                        project: project,
                        onClick: { selectedProjectId = project.id },
                        onDelete: { projectToDelete = project },
                        onShare: { projectToShare = project }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Project Card

struct ProjectCard: View {
    let project: ProjectDto
    let onClick: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            VStack(alignment: .leading, spacing: 0) {
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(project.title)
                            .font(.system(size: 16, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.pixelGold)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        if project.isFork {
                            HStack(spacing: 2) {
                                Text("🔱 FORK")
                                    .font(.system(size: 8, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.pixelCyan)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.pixelCyan.opacity(0.3))
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.pixelCyan, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    
                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: "D3D3D3"))
                            .lineLimit(2)
                    }
                    
                    if project.isFork, let authorName = project.originalAuthorName {
                        Text("Forked from \(authorName)")
                            .font(.system(size: 10, design: .monospaced))
                            .italic()
                            .foregroundColor(.pixelCyan)
                    }
                }
                .padding(16)
                
                Spacer()
                
                // Footer
                HStack {
                    Text("Updated: \(formatTimestamp(project.updatedAt))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.pixelGold)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.pixelHighlight)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(16)
            }
            .frame(height: 180)
            .background(Color.pixelMidBlue)
            .overlay(
                Rectangle()
                    .stroke(Color.pixelAccent, lineWidth: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTimestamp(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Create Project Dialog

struct CreateProjectDialog: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var description = ""
    let onCreate: (String, String) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("✨ CREATE NEW STORY")
                    .font(.system(size: 16, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.pixelGold)
                    .tracking(1)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title *")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.pixelCyan)
                    
                    TextField("Enter project title...", text: $title)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description (Optional)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.pixelCyan)
                    
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .padding(4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 12) {
                    PixelTextButton(text: "✕ CANCEL", action: {
                        dismiss()
                    })
                    
                    PixelTextButton(text: "✓ CREATE", action: {
                        onCreate(title.trimmingCharacters(in: .whitespaces),
                                description.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }, enabled: !title.isEmpty)
                }
            }
            .padding(24)
            .frame(width: 500)
            .background(Color.pixelDarkBlue)
            .overlay(
                Rectangle()
                    .stroke(Color.pixelHighlight, lineWidth: 3)
            )
        }
    }
}

// MARK: - Delete Confirmation Dialog

struct DeleteConfirmationDialog: View {
    @Environment(\.dismiss) var dismiss
    let projectTitle: String
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("⚠️ DELETE PROJECT?")
                    .font(.system(size: 16, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.pixelHighlight)
                    .tracking(1)
                
                Text("Are you sure you want to delete \"\(projectTitle)\"? This action cannot be undone.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    PixelTextButton(text: "CANCEL", action: {
                        dismiss()
                    })
                    
                    PixelTextButton(text: "DELETE", action: {
                        onConfirm()
                        dismiss()
                    })
                }
            }
            .padding(24)
            .frame(width: 400)
            .background(Color.pixelDarkBlue)
            .overlay(
                Rectangle()
                    .stroke(Color.pixelHighlight, lineWidth: 3)
            )
        }
    }
}

// MARK: - Share Confirmation Dialog

struct ShareConfirmationDialog: View {
    @Environment(\.dismiss) var dismiss
    let projectTitle: String
    let isLoading: Bool
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("🌍 SHARE TO COMMUNITY")
                    .font(.system(size: 16, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.pixelGold)
                    .tracking(1)
                
                Text("Share \"\(projectTitle)\" with the community?")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Other users will be able to view and fork your project.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .pixelGold))
                } else {
                    HStack(spacing: 12) {
                        PixelTextButton(text: "✕ CANCEL", action: {
                            dismiss()
                            onDismiss()
                        })
                        
                        PixelTextButton(text: "✓ SHARE", action: {
                            onConfirm()
                        })
                    }
                }
            }
            .padding(24)
            .frame(width: 400)
            .background(Color.pixelDarkBlue)
            .overlay(
                Rectangle()
                    .stroke(Color.pixelHighlight, lineWidth: 3)
            )
        }
    }
}
