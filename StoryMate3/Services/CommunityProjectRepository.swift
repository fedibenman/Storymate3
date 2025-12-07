import Foundation
import Combine
import OSLog

private struct CommunityProjectEmptyResponse: Codable {}

class CommunityProjectRepository {
    private let baseURL = "\(APIClient.baseURL)/community-projects"
    private static let logger = Logger(subsystem: "com.storymate", category: "CommunityProjectRepo")
    
    func getAllCommunityProjects() async throws -> [CommunityProjectDto] {
        do {
            Self.logger.info("getAllCommunityProjects - Request URL: \(self.baseURL)")
            let result: [CommunityProjectDto] = try await APIClient.shared.request(endpoint: "/community-projects")
            Self.logger.info("getAllCommunityProjects - Response: \(result.count) projects")
            return result
        } catch {
            Self.logger.error("getAllCommunityProjects - Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getFilteredProjects(filter: String) async throws -> [CommunityProjectDto] {
        do {
            let url = "/community-projects?filter=\(filter)"
            Self.logger.info("getFilteredProjects - Request URL: \(url)")
            Self.logger.info("getFilteredProjects - Filter: \(filter)")
            
            let result: [CommunityProjectDto] = try await APIClient.shared.request(endpoint: url)
            Self.logger.info("getFilteredProjects - Response: \(result.count) projects")
            return result
        } catch {
            Self.logger.error("getFilteredProjects - Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func toggleStar(projectId: String) async throws -> Bool {
        do {
            let url = "/community-projects/\(projectId)/star"
            Self.logger.info("toggleStar - Request URL: \(url)")
            Self.logger.info("toggleStar - Project ID: \(projectId)")
            
            let _: CommunityProjectEmptyResponse = try await APIClient.shared.request(
                endpoint: url,
                method: "POST"
            )
            
            Self.logger.info("toggleStar - Success: true")
            return true
        } catch {
            Self.logger.error("toggleStar - Error: \(error.localizedDescription)")
            return false
        }
    }
    
    func forkProject(projectId: String) async throws -> ProjectDto {
        let url = "/community-projects/\(projectId)/fork"
        Self.logger.info("forkProject - Request URL: \(url)")
        Self.logger.info("forkProject - Project ID: \(projectId)")
        
        let result: ProjectDto = try await APIClient.shared.request(
            endpoint: url,
            method: "POST"
        )
        
        Self.logger.info("forkProject - Response: Success")
        return result
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
    
    func getProjectFlowchart(projectId: String) async throws -> FlowchartDto? {
        do {
            let url = "/community-projects/\(projectId)/flowchart"
            Self.logger.info("getProjectFlowchart - Request URL: \(url)")
            Self.logger.info("getProjectFlowchart - Project ID: \(projectId)")
            
            let result: FlowchartDto = try await APIClient.shared.request(endpoint: url)
            Self.logger.info("getProjectFlowchart - Response: Success")
            return result
        } catch {
            Self.logger.error("getProjectFlowchart - Error: \(error.localizedDescription)")
            return nil
        }
    }
}

