import Foundation

struct Game: Codable, Identifiable {
    let id: Int
    let name: String
    let summary: String?
    let rating: Double?
    let cover: GameCover?
    let genres: [GameGenre]?
    let description: String?
    let screenshots: [String]?
    let trailers: [String]?
    
    struct GameCover: Codable {
        let id: Int
        let url: String
    }
    
    struct GameGenre: Codable {
        let id: Int
        let name: String
    }
    
    var coverUrl: URL? {
        guard let urlString = cover?.url else { return nil }
        // IGDB URLs often start with //, need to add https:
        let formattedString = urlString.hasPrefix("//") ? "https:\(urlString)" : urlString
        // Replace t_thumb with t_cover_big for better quality
        let highQualityString = formattedString.replacingOccurrences(of: "t_thumb", with: "t_cover_big")
        return URL(string: highQualityString)
    }
}
