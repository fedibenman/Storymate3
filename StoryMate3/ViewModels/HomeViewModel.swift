import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var popularGames: [Game] = []
    @Published var genreGames: [String: [Game]] = [:]
    @Published var searchResults: [Game] = []
    @Published var isSearching = false
    @Published var isLoading = false
    
    private var networkManager = NetworkManager()
    private var cacheManager = GameCacheManager.shared
    let sections = ["Popular Games", "Action", "Adventure", "RPG", "Strategy", "Puzzle"]
    
    func loadData() async {
        isLoading = true
        
        // Try to load from cache first
        if let cachedPopular = cacheManager.getCachedPopularGames() {
            print("📦 Loaded \(cachedPopular.count) popular games from cache")
            self.popularGames = cachedPopular
        }
        
        // Load genre games from cache
        var allGenresCached = true
        for section in sections where section != "Popular Games" {
            if let cachedGames = cacheManager.getCachedGenreGames(for: section) {
                print("📦 Loaded \(cachedGames.count) \(section) games from cache")
                self.genreGames[section] = cachedGames
            } else {
                allGenresCached = false
            }
        }
        
        // If all data is cached, we're done
        if popularGames.count > 0 && allGenresCached {
            print("✅ All games loaded from cache")
            isLoading = false
            return
        }
        
        // Otherwise, fetch from network
        print("🌐 Fetching games from network...")
        do {
            // Fetch popular games if not cached
            if popularGames.isEmpty {
                let popular = try await networkManager.fetchPopularGames()
                self.popularGames = popular
                cacheManager.cachePopularGames(popular)
                print("💾 Cached \(popular.count) popular games")
            }
            
            // Fetch genre games if not cached
            for section in sections where section != "Popular Games" {
                if genreGames[section] == nil {
                    let games = try await networkManager.fetchGamesByGenre(genre: section)
                    self.genreGames[section] = games
                    cacheManager.cacheGenreGames(games, for: section)
                    print("💾 Cached \(games.count) \(section) games")
                }
            }
        } catch {
            print("Error fetching games: \(error)")
        }
        
        isLoading = false
    }
    
    func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        Task {
            do {
                let results = try await networkManager.searchGames(query: searchText)
                self.searchResults = results
            } catch {
                print("Error searching games: \(error)")
            }
        }
    }
    
    func clearSearch() {
        searchText = ""
        isSearching = false
        searchResults = []
    }
    
    func refreshData() async {
        // Clear cache and reload
        cacheManager.clearAllCache()
        for section in sections where section != "Popular Games" {
            cacheManager.clearGenreCache(for: section)
        }
        popularGames = []
        genreGames = [:]
        await loadData()
    }
}
