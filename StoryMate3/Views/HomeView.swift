import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var authManager = AuthManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Background
            if themeManager.isDarkMode {
                DarkThemeBackground()
            } else {
                Image("background_land")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(themeManager.isDarkMode ? .white : .gray)
                        TextField("Search games...", text: $viewModel.searchText)
                            .font(.custom("PressStart2P-Regular", size: 12))
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            .onSubmit {
                                viewModel.performSearch()
                            }
                    }
                    .padding(10)
                    .background(themeManager.isDarkMode ? Color.black.opacity(0.6) : Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeManager.isDarkMode ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeManager.isDarkMode ? .white : .gray)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60) // Increased top padding for Dynamic Island
                .padding(.bottom, 20)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        if viewModel.isSearching {
                            Text("Search Results")
                                .font(.custom("PressStart2P-Regular", size: 16))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                                ForEach(viewModel.searchResults) { game in
                                    NavigationLink(destination: GameDetailsView(gameId: game.id)) {
                                        GamePosterView(game: game)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Sections
                            ForEach(viewModel.sections, id: \.self) { section in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(section)
                                        .font(.custom("PressStart2P-Regular", size: 16))
                                        .foregroundColor(themeManager.isDarkMode ? .white : .white)
                                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            if section == "Popular Games" {
                                                ForEach(viewModel.popularGames) { game in
                                                    NavigationLink(destination: GameDetailsView(gameId: game.id)) {
                                                        GamePosterView(game: game)
                                                    }
                                                }
                                            } else {
                                                ForEach(viewModel.genreGames[section] ?? []) { game in
                                                    NavigationLink(destination: GameDetailsView(gameId: game.id)) {
                                                        GamePosterView(game: game)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 140) // Increase bottom padding for floating tab bar
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadData()
        }
    }
}

struct GamePosterView: View {
    let game: Game
    
    var body: some View {
        VStack {
            // Game Poster with caching
            CachedAsyncImage(url: game.coverUrl) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(0.75, contentMode: .fit) // 3:4 aspect ratio
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 2)
                    )
            } placeholder: {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .aspectRatio(0.75, contentMode: .fit)
                        .cornerRadius(10)
                    ProgressView()
                }
            }
            
            Text(game.name)
                .font(.custom("PressStart2P-Regular", size: 10))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
