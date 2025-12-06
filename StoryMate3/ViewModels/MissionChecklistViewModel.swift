import Foundation
import SwiftUI
import Combine

@MainActor
class MissionChecklistViewModel: ObservableObject {
    @Published var missions: [Mission] = []
    @Published var progress: MissionProgress?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager()
    private let gameId: Int
    private let gameName: String
    
    init(gameId: Int, gameName: String) {
        self.gameId = gameId
        self.gameName = gameName
    }
    
    func loadMissions() async {
        print("🚀 loadMissions called for game: \(gameName) (ID: \(gameId))")
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch missions from backend
            print("⏳ Calling networkManager.fetchMissions...")
            let gameMissions = try await networkManager.fetchMissions(gameId: gameId, gameName: gameName)
            print("✅ Fetched \(gameMissions.missions.count) missions")
            missions = gameMissions.missions
            
            // Fetch progress
            if let userId = AuthManager.shared.userId {
                print("👤 Fetching progress for user: \(userId)")
                do {
                    progress = try await networkManager.getMissionProgress(userId: userId, gameId: gameId)
                    print("✅ Progress fetched: \(progress?.completedMissions.count ?? 0) completed")
                    updateMissionsWithProgress()
                } catch {
                    print("⚠️ Failed to fetch progress (using empty): \(error)")
                    // If no progress exists yet, initialize empty
                    progress = MissionProgress(
                        completedMissions: [],
                        totalMissions: missions.count,
                        lastUpdated: Date()
                    )
                }
            } else {
                print("⚠️ No userId found, skipping progress fetch")
            }
            
            isLoading = false
        } catch {
            print("❌ loadMissions failed: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func toggleMission(_ mission: Mission) {
        guard let userId = AuthManager.shared.userId else { return }
        
        Task {
            do {
                let newProgress = try await networkManager.toggleMission(
                    userId: userId,
                    gameId: gameId,
                    missionNumber: mission.number,
                    totalMissions: missions.count
                )
                
                progress = newProgress
                updateMissionsWithProgress()
            } catch {
                errorMessage = "Failed to update mission: \(error.localizedDescription)"
            }
        }
    }
    
    private func updateMissionsWithProgress() {
        guard let progress = progress else { return }
        
        for index in missions.indices {
            missions[index].isCompleted = progress.completedMissions.contains(missions[index].number)
        }
    }
}
