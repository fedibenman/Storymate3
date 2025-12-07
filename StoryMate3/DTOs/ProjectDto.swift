import Foundation

struct ProjectDto: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let createdAt: Int64
    let updatedAt: Int64
    let isFork: Bool
    let originalProjectId: String?
    let originalAuthorName: String?
    
    init(id: String, title: String, description: String, createdAt: Int64, updatedAt: Int64, isFork: Bool = false, originalProjectId: String? = nil, originalAuthorName: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFork = isFork
        self.originalProjectId = originalProjectId
        self.originalAuthorName = originalAuthorName
    }
}
