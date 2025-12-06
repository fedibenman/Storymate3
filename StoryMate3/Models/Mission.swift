import Foundation

struct Mission: Codable, Identifiable, Equatable {
    var id: Int { number }
    let number: Int
    let title: String
    let description: String
    let objectives: [String]
    var isCompleted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case number, title, description, objectives, isCompleted
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        objectives = try container.decode([String].self, forKey: .objectives)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
    }
}

struct GameMissions: Codable {
    let gameName: String
    let missions: [Mission]
    let sourceUrl: String?
}

struct MissionProgress: Codable {
    let completedMissions: [Int]
    let totalMissions: Int
    let lastUpdated: Date
    
    var progressPercentage: Double {
        guard totalMissions > 0 else { return 0 }
        return Double(completedMissions.count) / Double(totalMissions)
    }
    
    var completedCount: Int {
        return completedMissions.count
    }
}
