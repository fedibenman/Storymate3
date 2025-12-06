import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
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
            
            // Theme Toggle Button
            VStack {
                HStack {
                    Spacer()
                    AnimatedThemeToggle()
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
            .zIndex(100)
            
            VStack(spacing: 0) {
                // Title at top
                Text("Profile")
                    .font(.custom("PressStart2P-Regular", size: 20))
                    .foregroundColor(themeManager.isDarkMode ? .white : .white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Profile Info
                        VStack(spacing: 15) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3, x: 2, y: 2)
                            
                            Text("User Profile")
                                .font(.custom("PressStart2P-Regular", size: 18))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                            
                            Button(action: {
                                viewModel.showingEditProfile = true
                            }) {
                                Image("button")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 200)
                                    .frame(height: 60)
                                    .overlay(
                                        Text("Edit Profile")
                                            .font(.custom("PressStart2P-Regular", size: 12))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .padding(25)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .padding(.horizontal, 20)
                        
                        // Stats Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Stats")
                                .font(.custom("PressStart2P-Regular", size: 16))
                                .foregroundColor(.yellow)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                            
                            HStack(spacing: 12) {
                                StatView(title: "Played", value: "0")
                                StatView(title: "Playing", value: "0")
                                StatView(title: "Wishlist", value: "0")
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Logout Button
                        Button(action: {
                            viewModel.logout()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16))
                                Text("Logout")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                            .frame(minHeight: 100) // Extra space at bottom
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingEditProfile) {
            EditProfileView()
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.custom("PressStart2P-Regular", size: 18))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 2, x: 1, y: 1)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(title)
                .font(.custom("PressStart2P-Regular", size: 10))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .padding(.horizontal, 5)
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Image("background_land")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            AnimatedClouds()
            
            VStack(spacing: 20) {
                Text("Edit Profile")
                    .font(.custom("PressStart2P-Regular", size: 20))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                    .padding(.top, 60)
                
                Spacer()
                
                Text("Feature coming soon")
                    .font(.custom("PressStart2P-Regular", size: 14))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 1, x: 1, y: 1)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image("button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 70)
                        .overlay(
                            Text("Close")
                                .font(.custom("PressStart2P-Regular", size: 14))
                                .foregroundColor(.white)
                        )
                }
                .padding(.bottom, 40)
            }
        }
    }
}
