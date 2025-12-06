import SwiftUI

struct GameDetailsView: View {
    @StateObject private var viewModel: GameDetailsViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    init(gameId: Int) {
        _viewModel = StateObject(wrappedValue: GameDetailsViewModel(gameId: gameId))
    }
    
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
                
                // Cloud animation
                AnimatedClouds()
            }
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                PixelatedNavigationBar(title: "Game Details", showBackButton: true) {
                    dismiss()
                }
                .padding(.top, 40)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if let game = viewModel.gameDetails {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Cover Image
                            AsyncImage(url: game.coverUrl) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 250)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .cornerRadius(15)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.white, lineWidth: 3)
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
                                default:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(height: 250)
                                        .cornerRadius(15)
                                        .overlay(
                                            Image(systemName: "gamecontroller.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(alignment: .leading, spacing: 15) {
                                // Title
                                Text(game.name)
                                    .font(.custom("PressStart2P-Regular", size: 18))
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                    .lineLimit(3)
                                
                                // Rating
                                if let rating = game.rating {
                                    HStack(spacing: 8) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 16))
                                        Text(String(format: "%.1f/100", rating))
                                            .font(.custom("PressStart2P-Regular", size: 12))
                                            .foregroundColor(.white)
                                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(8)
                                }
                                
                                // Add to Collection Section
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Add to Collection")
                                        .font(.custom("PressStart2P-Regular", size: 14))
                                        .foregroundColor(.yellow)
                                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                                    
                                    HStack(spacing: 10) {
                                        Picker("Status", selection: $viewModel.selectedStatus) {
                                            ForEach(viewModel.statuses, id: \.0) { status in
                                                Text(status.1).tag(status.0)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .font(.custom("PressStart2P-Regular", size: 10))
                                        .accentColor(.black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(8)
                                        
                                        Button(action: {
                                            viewModel.addToCollection()
                                        }) {
                                            Image("button")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 120, height: 50)
                                                .overlay(
                                                    Text("Save")
                                                        .font(.custom("PressStart2P-Regular", size: 12))
                                                        .foregroundColor(.white)
                                                )
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                
                                // Description
                                if let description = game.description {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("About")
                                            .font(.custom("PressStart2P-Regular", size: 14))
                                            .foregroundColor(.yellow)
                                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        
                                        Text(description)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .shadow(color: .black, radius: 1, x: 1, y: 1)
                                            .lineLimit(nil)
                                            .padding()
                                            .background(Color.black.opacity(0.4))
                                            .cornerRadius(10)
                                    }
                                }
                                
                                // Screenshots
                                if let screenshots = game.screenshots, !screenshots.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Screenshots")
                                            .font(.custom("PressStart2P-Regular", size: 14))
                                            .foregroundColor(.yellow)
                                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 15) {
                                                ForEach(screenshots, id: \.self) { urlString in
                                                    AsyncImage(url: URL(string: urlString)) { image in
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 220, height: 130)
                                                            .cornerRadius(10)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 10)
                                                                    .stroke(Color.white, lineWidth: 2)
                                                            )
                                                    } placeholder: {
                                                        Rectangle()
                                                            .fill(Color.gray.opacity(0.5))
                                                            .frame(width: 220, height: 130)
                                                            .cornerRadius(10)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                } else {
                    Spacer()
                    Text("Failed to load game details")
                        .font(.custom("PressStart2P-Regular", size: 12))
                        .foregroundColor(.red)
                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadDetails()
        }
        .alert("Success", isPresented: $viewModel.showingStatusAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Game added to collection!")
        }
    }
}
