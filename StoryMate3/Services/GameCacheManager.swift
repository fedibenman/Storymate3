import Foundation

class GameCacheManager {
    static let shared = GameCacheManager()
    
    private let userDefaults = UserDefaults.standard
    private let cacheExpirationInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    
    // Keys for caching
    private enum CacheKey: String {
        case popularGames = "cached_popular_games"
        case popularGamesTimestamp = "cached_popular_games_timestamp"
        case genreGames = "cached_genre_games_"
        case genreGamesTimestamp = "cached_genre_games_timestamp_"
    }
    
    private init() {}
    
    // MARK: - Popular Games
    
    func cachePopularGames(_ games: [Game]) {
        if let encoded = try? JSONEncoder().encode(games) {
            userDefaults.set(encoded, forKey: CacheKey.popularGames.rawValue)
            userDefaults.set(Date(), forKey: CacheKey.popularGamesTimestamp.rawValue)
        }
    }
    
    func getCachedPopularGames() -> [Game]? {
        guard let timestamp = userDefaults.object(forKey: CacheKey.popularGamesTimestamp.rawValue) as? Date,
              !isCacheExpired(timestamp: timestamp),
              let data = userDefaults.data(forKey: CacheKey.popularGames.rawValue),
              let games = try? JSONDecoder().decode([Game].self, from: data) else {
            return nil
        }
        return games
    }
    
    // MARK: - Genre Games
    
    func cacheGenreGames(_ games: [Game], for genre: String) {
        if let encoded = try? JSONEncoder().encode(games) {
            userDefaults.set(encoded, forKey: CacheKey.genreGames.rawValue + genre)
            userDefaults.set(Date(), forKey: CacheKey.genreGamesTimestamp.rawValue + genre)
        }
    }
    
    func getCachedGenreGames(for genre: String) -> [Game]? {
        guard let timestamp = userDefaults.object(forKey: CacheKey.genreGamesTimestamp.rawValue + genre) as? Date,
              !isCacheExpired(timestamp: timestamp),
              let data = userDefaults.data(forKey: CacheKey.genreGames.rawValue + genre),
              let games = try? JSONDecoder().decode([Game].self, from: data) else {
            return nil
        }
        return games
    }
    
    // MARK: - Cache Expiration
    
    private func isCacheExpired(timestamp: Date) -> Bool {
        return Date().timeIntervalSince(timestamp) > cacheExpirationInterval
    }
    
    // MARK: - Clear Cache
    
    func clearAllCache() {
        let keys = [
            CacheKey.popularGames.rawValue,
            CacheKey.popularGamesTimestamp.rawValue
        ]
        keys.forEach { userDefaults.removeObject(forKey: $0) }
    }
    
    func clearGenreCache(for genre: String) {
        userDefaults.removeObject(forKey: CacheKey.genreGames.rawValue + genre)
        userDefaults.removeObject(forKey: CacheKey.genreGamesTimestamp.rawValue + genre)
    }
}
