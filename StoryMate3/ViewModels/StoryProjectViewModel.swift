// MARK: - Story Project ViewModel

import Foundation
import Combine

class StoryProjectViewModel: ObservableObject {
    @Published var projects: [ProjectDto] = []
    @Published var isLoading = false
    @Published var currentProject: ProjectDto?
    @Published var publishState: PublishState = .idle
    
    private let repository = StoryProjectRepository()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadProjects()
    }
    
    // MARK: - Load Projects
    func loadProjects() {
        isLoading = true
        Task {
            do {
                let fetchedProjects = try await repository.getAllProjects()
                await MainActor.run {
                    self.projects = fetchedProjects
                    self.isLoading = false
                }
            } catch {
                print("Error loading projects: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Create New Project
    func createNewProject(title: String, description: String = "", onSuccess: @escaping (String) -> Void) {
        Task {
            do {
                let dto = CreateProjectDto(title: title, description: description)
                let project = try await repository.createProject(dto: dto)
                loadProjects()
                await MainActor.run {
                    onSuccess(project.id)
                }
            } catch {
                print("Error creating project: \(error)")
            }
        }
    }
    
    // MARK: - Delete Project
    func deleteProject(projectId: String) {
        Task {
            do {
                try await repository.deleteProject(projectId: projectId)
                loadProjects()
            } catch {
                print("Error deleting project: \(error)")
            }
        }
    }
    
    // MARK: - Load Flowchart
    func loadFlowchart(projectId: String, callback: @escaping (FlowchartState?) -> Void) {
        Task {
            do {
                if let flowchartDto = try await repository.getFlowchart(projectId: projectId) {
                    let state = flowchartDto.toFlowchartState()
                    await MainActor.run {
                        callback(state)
                    }
                } else {
                    await MainActor.run {
                        callback(nil)
                    }
                }
            } catch {
                print("Error loading flowchart: \(error)")
                await MainActor.run {
                    callback(nil)
                }
            }
        }
    }
    
    // MARK: - Save Flowchart
    func saveFlowchart(projectId: String, state: FlowchartState) {
        Task {
            do {
                let nodeDtos = state.nodes.map { $0.toDto() }
                let flowchartDto = FlowchartDto(
                    projectId: projectId,
                    nodes: nodeDtos,
                    updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
                )
                try await repository.saveFlowchart(flowchart: flowchartDto)
                loadProjects()
            } catch {
                print("Error saving flowchart: \(error)")
            }
        }
    }
    
    // MARK: - Set Current Project
    func setCurrentProject(projectId: String) {
        currentProject = projects.first { $0.id == projectId }
    }
    
    // MARK: - Publish Project
    func publishProject(projectId: String, onSuccess: @escaping () -> Void = {}) {
        publishState = .loading
        Task {
            do {
                _ = try await repository.publishProject(projectId: projectId)
                await MainActor.run {
                    self.publishState = .success
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    self.publishState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Reset Publish State
    func resetPublishState() {
        publishState = .idle
    }
}
