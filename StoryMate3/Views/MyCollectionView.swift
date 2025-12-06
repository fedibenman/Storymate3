import SwiftUI

struct MyCollectionView: View {
    @StateObject private var viewModel = MyCollectionViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            if themeManager.isDarkMode {
                DarkThemeBackground()
            } else {
                Image("background_land")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                AnimatedClouds()
            }
            
            VStack(spacing: 0) {
                // Title
                Text("My Collection")
                    .font(.custom("PressStart2P-Regular", size: 20))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                
                if viewModel.collection.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 3, x: 2, y: 2)
                        
                        Text("No games in collection")
                            .font(.custom("PressStart2P-Regular", size: 14))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                        
                        Text("Add games from the home screen")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100), spacing: 15)
                        ], spacing: 20) {
                            ForEach(viewModel.collection) { item in
                                if let game = viewModel.games[item.gameId] {
                                    // Navigate to MissionChecklistView for "playing" games
                                    if item.status == "playing" {
                                        NavigationLink(destination: MissionChecklistView(gameId: game.id, gameName: game.name)) {
                                            CollectionGameCard(game: game, status: item.status, missionProgress: item.missionProgress)
                                        }
                                    } else {
                                        NavigationLink(destination: GameDetailsView(gameId: game.id)) {
                                            CollectionGameCard(game: game, status: item.status, missionProgress: item.missionProgress)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 140) // Increase bottom padding for floating tab bar
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadCollection()
        }
    }
}

struct CollectionGameCard: View {
    let game: Game
    let status: String
    let missionProgress: MissionProgress?
    
    var body: some View {
        VStack(spacing: 8) {
            CachedAsyncImage(url: game.coverUrl) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(0.71, contentMode: .fit) // ~100/140 ratio
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 2)
                    )
            } placeholder: {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .aspectRatio(0.71, contentMode: .fit)
                        .cornerRadius(10)
                    ProgressView()
                }
            }
            
            Text(game.name)
                .font(.custom("PressStart2P-Regular", size: 9))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            
            // Show progress bar for playing games
            if status == "playing", let progress = missionProgress {
                VStack(spacing: 4) {
                    ProgressView(value: progress.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    Text("\(Int(progress.progressPercentage * 100))%")
                        .font(.custom("PressStart2P-Regular", size: 8))
                        .foregroundColor(.green)
                        .shadow(color: .black, radius: 1, x: 1, y: 1)
                }
            } else {
                Text(statusEmoji(for: status))
                    .font(.system(size: 16))
            }
        }
    }
    
    private func statusEmoji(for status: String) -> String {
        switch status {
        case "playing": return "🎮"
        case "played": return "✅"
        case "want_to_play": return "⭐"
        default: return "📋"
        }
    }
}
