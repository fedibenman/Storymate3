import SwiftUI

struct MissionChecklistView: View {
    @StateObject private var viewModel: MissionChecklistViewModel
    @Environment(\.dismiss) var dismiss
    
    init(gameId: Int, gameName: String) {
        _viewModel = StateObject(wrappedValue: MissionChecklistViewModel(gameId: gameId, gameName: gameName))
    }
    
    var body: some View {
        ZStack {
            // Background
            Image("background_land")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            AnimatedClouds()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                PixelatedNavigationBar(title: "Missions", showBackButton: true) {
                    dismiss()
                }
                .padding(.top, 40)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Loading missions...")
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    
                    if errorMessage.contains("No walkthrough found") {
                        // Specific UI for missing walkthroughs
                        VStack(spacing: 20) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                                .shadow(color: .black, radius: 3, x: 2, y: 2)
                            
                            Text("No Walkthrough Found")
                                .font(.custom("PressStart2P-Regular", size: 14))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                            
                            Text("This game doesn't have a walkthrough on IGN yet")
                                .font(.custom("PressStart2P-Regular", size: 9))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .shadow(color: .black, radius: 1, x: 1, y: 1)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Try these games:")
                                    .font(.custom("PressStart2P-Regular", size: 10))
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black, radius: 1, x: 1, y: 1)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Assassin's Creed Mirage")
                                    Text("• God of War Ragnarok")
                                    Text("• Elden Ring")
                                    Text("• Spider-Man 2")
                                }
                                .font(.custom("PressStart2P-Regular", size: 8))
                                .foregroundColor(.white.opacity(0.8))
                                .shadow(color: .black, radius: 1, x: 1, y: 1)
                            }
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .padding(.horizontal, 30)
                        }
                    } else {
                        // Generic Error UI
                        VStack(spacing: 15) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                            
                            Text("Error Loading Missions")
                                .font(.custom("PressStart2P-Regular", size: 12))
                                .foregroundColor(.white)
                            
                            Text(errorMessage)
                                .font(.custom("PressStart2P-Regular", size: 10))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                    }
                    Spacer()
                } else {
                    // Progress Bar Section
                    if let progress = viewModel.progress {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Progress")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                                    .foregroundColor(.yellow)
                                
                                Spacer()
                                
                                Text("\(progress.completedCount)/\(progress.totalMissions)")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                                    .foregroundColor(.white)
                            }
                            
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 30)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                    
                                    // Progress Fill
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.green, Color.green.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * progress.progressPercentage, height: 30)
                                        .cornerRadius(8)
                                    
                                    // Percentage Text
                                    Text("\(Int(progress.progressPercentage * 100))%")
                                        .font(.custom("PressStart2P-Regular", size: 12))
                                        .foregroundColor(.white)
                                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 30)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    
                    // Mission List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.missions) { mission in
                                GameMissionRow(mission: mission) {
                                    viewModel.toggleMission(mission)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadMissions()
        }
    }
}

struct GameMissionRow: View {
    let mission: Mission
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 15) {
                // Checkbox
                Image(systemName: mission.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24))
                    .foregroundColor(mission.isCompleted ? .green : .white)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Mission Number and Title
                    HStack {
                        Text("#\(mission.number)")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.yellow)
                        
                        Text(mission.title)
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    
                    // Description
                    if !mission.description.isEmpty {
                        Text(mission.description)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                    
                    // Objectives
                    if !mission.objectives.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(mission.objectives.prefix(3), id: \.self) { objective in
                                HStack(spacing: 6) {
                                    Text("•")
                                        .foregroundColor(.yellow)
                                    Text(objective)
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(15)
            .background(
                mission.isCompleted
                    ? Color.green.opacity(0.2)
                    : Color.white.opacity(0.1)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        mission.isCompleted ? Color.green : Color.white,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
