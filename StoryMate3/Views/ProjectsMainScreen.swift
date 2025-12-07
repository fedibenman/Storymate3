import SwiftUI

// MARK: - Projects Main Screen with Tabs

struct ProjectsMainScreen: View {
    @State private var selectedTab = 0
    @StateObject private var storyProjectViewModel = StoryProjectViewModel()
    @StateObject private var communityProjectViewModel = CommunityProjectViewModel()
    
    let tabs = ["📚 My Projects", "🌍 Community"]
    
var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar
            customTabBar
            
            // Content based on selected tab
            TabView(selection: $selectedTab) {
                ProjectsListScreenWithNavigation()
                    .tag(0)
                
                CommunityProjectsScreen(
                    viewModel: communityProjectViewModel,
                    storyViewModel: storyProjectViewModel,
                    onProjectClick: { _ in },
                    onForkSuccess: {
                        // Switch to My Projects tab after forking
                        selectedTab = 0
                    }
                )
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.pixelDarkBlue)
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 16, design: .monospaced))
                            .fontWeight(selectedTab == index ? .bold : .regular)
                            .foregroundColor(selectedTab == index ? .pixelGold : .gray)
                            .tracking(1)
                            .padding(.vertical, 8)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.pixelHighlight : Color.clear)
                            .frame(height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 12)
        .background(Color(hex: "1A1A1A"))
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 3),
            alignment: .bottom
        )
    }
}



// MARK: - Projects List Screen with Navigation

struct ProjectsListScreenWithNavigation: View {
    @StateObject private var viewModel = StoryProjectViewModel()
    @State private var showCreateDialog = false
    @State private var projectToDelete: ProjectDto?
    @State private var projectToShare: ProjectDto?
    @State private var selectedProjectId: String?
    @State private var showFlowBuilder = false
    
    var body: some View {
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
        .fullScreenCover(isPresented: $showFlowBuilder) {
            if let projectId = selectedProjectId {
                FlowBuilderScreenWrapper(projectId: projectId) {
                    showFlowBuilder = false
                    selectedProjectId = nil
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
                        onClick: {
                            selectedProjectId = project.id
                            showFlowBuilder = true
                        },
                        onDelete: { projectToDelete = project },
                        onShare: { projectToShare = project }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Flow Builder Screen Wrapper

struct FlowBuilderScreenWrapper: View {
    let projectId: String
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            FlowBuilderScreen(projectId: projectId)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: onDismiss) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Projects")
                            }
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.pixelGold)
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Text("✏️ FLOW BUILDER")
                            .font(.system(size: 16, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.pixelGold)
                            .tracking(1)
                        }
                    }
                }
        }
    }

// MARK: - Preview

#if DEBUG
struct ProjectsMainScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProjectsMainScreen()
                .environmentObject(ThemeManager.shared)
                .preferredColorScheme(.dark)
            
            ProjectsListScreenWithNavigation()
                .environmentObject(ThemeManager.shared)
                .preferredColorScheme(.dark)
        }
    }
}
#endif
