import Foundation

struct CommunityProjectDto: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let authorId: String
    let authorName: String
    let starCount: Int
    let forkCount: Int
    let isStarredByUser: Bool
    let createdAt: Int64
    let updatedAt: Int64
}
