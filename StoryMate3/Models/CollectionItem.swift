import Foundation

struct CollectionItem: Codable, Identifiable {
    var id: Int { gameId }
    let gameId: Int
    let status: String
    let missionProgress: MissionProgress?
}
