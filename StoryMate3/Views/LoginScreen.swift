import SwiftUI

struct LoginScreen: View {
    @StateObject private var viewModel = LoginViewModel()
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
            
            VStack(spacing: 15) {
                
                // Title
                Text("Login")
                    .font(.custom("PressStart2P-Regular", size: 37))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .shadow(color: themeManager.isDarkMode ? .purple : .clear, radius: 2)
                
                Text("enter the realm")
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(themeManager.isDarkMode ? .gray : .gray)
                    .padding(.bottom, 20)
                
                // Email field
                CustomTextField(placeholder: "EMAIL", text: $viewModel.email)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 40)
                
                // Password field
                CustomTextField(placeholder: "PASSWORD", text: $viewModel.password, isSecure: true)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 40)
                
                // Forgot password text
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.showForgotPasswordScreen = true
                    }) {
                        Text("forgot password?")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.red)
                    }
                    Spacer()
                }
                .padding(.top, 5)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Login button
                Button(action: {
                    Task {
                        await viewModel.handleLogin()
                    }
                }) {
                    Image("button")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300) // Max width constraint instead of fixed
                        .frame(height: 80)
                        .overlay(
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Login")
                                        .font(.custom("PressStart2P-Regular", size: 20))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
                .padding(.top, 10)
                .disabled(viewModel.isLoading)
                
                // New adventurer text
                HStack {
                    Text("New adventurer?")
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    Button(action: {
                        viewModel.showRegisterScreen = true
                    }) {
                        Text("CREATE ACCOUNT")
                            .foregroundColor(.yellow)
                            .font(Font.custom("PressStart2P-Regular", size: 10))
                    }
                }
                .padding(.top, 10)
                
                // Social Login
                ZStack {
                    Image("bg")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300)
                    
                    VStack {
                        Text("or login with")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.black)
                            .padding(.bottom, 10)
                        
                        HStack(spacing: 20) {
                            SocialButton(imageName: "Facebook")
                            SocialButton(imageName: "Reddit")
                            SocialButton(imageName: "Steam")
                        }
                    }
                    .padding(.bottom, 10)
                }
                .padding(.top, 20)
            }
            .padding(.bottom, 50) // Push content up slightly
        }
        .sheet(isPresented: $viewModel.showRegisterScreen) {
            RegisterScreen()
        }
        .sheet(isPresented: $viewModel.showForgotPasswordScreen) {
            ForgotPasswordScreen()
        }
        .fullScreenCover(isPresented: $viewModel.showHomeView) {
            HomeView()
        }
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK", role: .cancel) {
                viewModel.showHomeView = true
            }
        } message: {
            Text("Login successful!")
        }
    }
}

struct SocialButton: View {
    let imageName: String
    
    var body: some View {
        Button(action: {}) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        }
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
            .environmentObject(ThemeManager.shared)
    }
}
