import Foundation
import Combine
import OSLog

private struct StoryProjectEmptyResponse: Codable {}

// MARK: - Story Project Repository

class StoryProjectRepository {
    private let baseURL = "\(APIClient.baseURL)/projects"
    private let communityBaseURL = "\(APIClient.baseURL)/community-projects"
    private static let logger = Logger(subsystem: "com.storymate", category: "StoryProjectRepo")
    
    func getAllProjects() async throws -> [ProjectDto] {
        do {
            Self.logger.info("getAllProjects - Request URL: \(self.baseURL)")
            let result: [ProjectDto] = try await APIClient.shared.request(endpoint: "/projects")
            Self.logger.info("getAllProjects - Response: \(result.count) projects")
            return result
        } catch {
            Self.logger.error("getAllProjects - Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getProject(id: String) async throws -> ProjectDto? {
        do {
            let url = "/projects/\(id)"
            Self.logger.info("getProject - Request URL: \(url)")
            Self.logger.info("getProject - Project ID: \(id)")
            
            let result: ProjectDto = try await APIClient.shared.request(endpoint: url)
            Self.logger.info("getProject - Response: Success")
            return result
        } catch {
            Self.logger.error("getProject - Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func createProject(dto: CreateProjectDto) async throws -> ProjectDto {
        Self.logger.info("createProject - Request URL: \(self.baseURL)")
        Self.logger.info("createProject - Request Body: title=\(dto.title), description=\(dto.description)")
        
        let result: ProjectDto = try await APIClient.shared.request(
            endpoint: "/projects",
            method: "POST",
            body: dto
        )
        
        Self.logger.info("createProject - Response: Success")
        return result
    }
    
    func saveProject(project: ProjectDto) async throws {
        let url = "/projects/\(project.id)"
        Self.logger.info("saveProject - Request URL: \(url)")
        Self.logger.info("saveProject - Request Body: id=\(project.id), title=\(project.title)")
        
        let _: StoryProjectEmptyResponse = try await APIClient.shared.request(
            endpoint: url,
            method: "PUT",
            body: project
        )
        
        Self.logger.info("saveProject - Response: Success")
    }
    
    func deleteProject(projectId: String) async throws {
        let url = "/projects/\(projectId)"
        Self.logger.info("deleteProject - Request URL: \(url)")
        Self.logger.info("deleteProject - Project ID: \(projectId)")
        
        let _: StoryProjectEmptyResponse = try await APIClient.shared.request(
            endpoint: url,
            method: "DELETE"
        )
        
        Self.logger.info("deleteProject - Response: Success")
    }
    
    func getFlowchart(projectId: String) async throws -> FlowchartDto? {
        do {
            let url = "/projects/\(projectId)/flowchart"
            Self.logger.info("getFlowchart - Request URL: \(url)")
            Self.logger.info("getFlowchart - Project ID: \(projectId)")
            
            let result: FlowchartDto = try await APIClient.shared.request(endpoint: url)
            Self.logger.info("getFlowchart - Response: Success")
            return result
        } catch {
            Self.logger.error("getFlowchart - Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func saveFlowchart(flowchart: FlowchartDto) async throws {
        let url = "/projects/\(flowchart.projectId)/flowchart"
        Self.logger.info("saveFlowchart - Request URL: \(url)")
        Self.logger.info("saveFlowchart - Project ID: \(flowchart.projectId)")
        Self.logger.info("saveFlowchart - Nodes Count: \(flowchart.nodes.count)")
        
        let _: StoryProjectEmptyResponse = try await APIClient.shared.request(
            endpoint: url,
            method: "POST",
            body: flowchart
        )
        
        Self.logger.info("saveFlowchart - Response: Success")
    }
    
    func publishProject(projectId: String) async throws -> CommunityProjectDto {
        let url = "/community-projects/publish"
        Self.logger.info("publishProject - Request URL: \(url)")
        Self.logger.info("publishProject - Request Body: projectId=\(projectId)")
        
        let dto = PublishProjectDto(projectId: projectId)
        let result: CommunityProjectDto = try await APIClient.shared.request(
            endpoint: url,
            method: "POST",
            body: dto
        )
        
        Self.logger.info("publishProject - Response: Success")
        return result
    }
}
