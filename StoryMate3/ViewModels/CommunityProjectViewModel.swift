//
//  CommunityProjectViewModel.swift
//  StoryMate3
//
//  Created by Mac Mini 7 on 7/12/2025.
//

import Foundation
@MainActor          
final class CommunityProjectViewModel: ObservableObject {
    @Published var communityProjects: [CommunityProjectDto] = []
    @Published var isLoading = false
    @Published var currentUserId: String?
    
    private let repository = CommunityProjectRepository()
  
    
    init() {
        loadCommunityProjects()
        currentUserId = AuthManager.shared.userId
    }
    
    // MARK: - Set Current User ID
    func setCurrentUserId(userId: String?) {
        currentUserId = userId
    }
    
    // MARK: - Load Community Projects
    func loadCommunityProjects() {
        isLoading = true
        Task {
            do {
                let projects = try await repository.getAllCommunityProjects()
                await MainActor.run {
                    self.communityProjects = projects
                    self.isLoading = false
                }
            } catch {
                print("Error loading community projects: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Filter Projects
    func filterProjects(filter: String) {
        isLoading = true
        Task {
            do {
                let projects: [CommunityProjectDto]
                switch filter {
                case "All":
                    projects = try await repository.getAllCommunityProjects()
                case "Popular":
                    projects = try await repository.getFilteredProjects(filter: "popular")
                case "Recent":
                    projects = try await repository.getFilteredProjects(filter: "recent")
                case "Starred":
                    projects = try await repository.getFilteredProjects(filter: "starred")
                default:
                    projects = try await repository.getAllCommunityProjects()
                }
                
                await MainActor.run {
                    self.communityProjects = projects
                    self.isLoading = false
                }
            } catch {
                print("Error filtering projects: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Toggle Star
    func toggleStar(projectId: String) {
        Task {
            do {
                let success = try await repository.toggleStar(projectId: projectId)
                if success {
                    await MainActor.run {
                        // Update local state
                        if let index = communityProjects.firstIndex(where: { $0.id == projectId }) {
                            var project = communityProjects[index]
                            let newStarCount = project.isStarredByUser ? project.starCount - 1 : project.starCount + 1
                            
                            communityProjects[index] = CommunityProjectDto(
                                id: project.id,
                                title: project.title,
                                description: project.description,
                                authorId: project.authorId,
                                authorName: project.authorName,
                                starCount: newStarCount,
                                forkCount: project.forkCount,
                                isStarredByUser: !project.isStarredByUser,
                                createdAt: project.createdAt,
                                updatedAt: project.updatedAt
                            )
                        }
                    }
                }
            } catch {
                print("Error toggling star: \(error)")
            }
        }
    }
    
    // MARK: - Fork Project
    func forkProject(projectId: String) {
        Task {
            do {
                _ = try await repository.forkProject(projectId: projectId)
                await MainActor.run {
                    // Update fork count locally
                    if let index = communityProjects.firstIndex(where: { $0.id == projectId }) {
                        var project = communityProjects[index]
                        communityProjects[index] = CommunityProjectDto(
                            id: project.id,
                            title: project.title,
                            description: project.description,
                            authorId: project.authorId,
                            authorName: project.authorName,
                            starCount: project.starCount,
                            forkCount: project.forkCount + 1,
                            isStarredByUser: project.isStarredByUser,
                            createdAt: project.createdAt,
                            updatedAt: project.updatedAt
                        )
                    }
                }
            } catch {
                print("Error forking project: \(error)")
            }
        }
    }
    
    // MARK: - Load Project Flowchart
    func loadProjectFlowchart(projectId: String, onLoaded: @escaping (FlowchartState?) -> Void) {
        Task {
            do {
                if let flowchartDto = try await repository.getProjectFlowchart(projectId: projectId) {
                    let flowchartState = flowchartDto.toFlowchartState()
                    await MainActor.run {
                        onLoaded(flowchartState)
                    }
                } else {
                    await MainActor.run {
                        onLoaded(nil)
                    }
                }
            } catch {
                print("Error loading project flowchart: \(error)")
                await MainActor.run {
                    onLoaded(nil)
                }
            }
        }
    }
}
