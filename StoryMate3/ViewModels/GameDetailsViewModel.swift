import SwiftUI
import Combine

@MainActor
class GameDetailsViewModel: ObservableObject {
    @Published var gameDetails: Game?
    @Published var isLoading = true
    @Published var selectedStatus = "want_to_play"
    @Published var showingStatusAlert = false
    
    let gameId: Int
    private var networkManager = NetworkManager()
    
    let statuses = [
        ("want_to_play", "Want to Play"),
        ("playing", "Playing"),
        ("played", "Played")
    ]
    
    init(gameId: Int) {
        self.gameId = gameId
    }
    
    func loadDetails() async {
        do {
            let details = try await networkManager.getGameDetails(id: gameId)
            self.gameDetails = details
            self.isLoading = false
        } catch {
            print("Error loading details: \(error)")
            self.isLoading = false
        }
    }
    
    func addToCollection() {
        guard let userId = AuthManager.shared.userId else { return }
        Task {
            do {
                try await networkManager.addToCollection(userId: userId, gameId: gameId, status: selectedStatus)
                self.showingStatusAlert = true
            } catch {
                print("Error adding to collection: \(error)")
            }
        }
    }
}
