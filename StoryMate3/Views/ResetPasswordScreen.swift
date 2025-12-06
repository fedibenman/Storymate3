//
//  ResetPasswordScreen.swift
//  StoryMates
//
//  Created by mac on 11/10/25.
//


import SwiftUI

struct ResetPasswordScreen: View {
    let email: String
    @StateObject private var networkManager = NetworkManager()
    @State private var token = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var showLoginScreen = false
    
    init(email: String) {
        self.email = email
    }
    
    var body: some View {
        ZStack {
            // Background with gradient and land images
            Image("background_land") // Replace with your land image name
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            // Cloud animation that fits the screen
            AnimatedClouds()
            
            VStack {
                HStack {
                    // Back button
                    Button(action: {
                        showLoginScreen = true
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.black)
                    }
                    .padding(.top, 40)
                    .padding(.leading, 20)
                    
                    Spacer()
                }
                
                // Title
                Text("Reset Password")
                    .font(.custom("PressStart2P-Regular", size: 37))
                    .foregroundColor(.black)
                Text("Enter reset code and new password")
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                // Token field (4-digit code)
                CustomTextField(placeholder: "RESET CODE", text: $token)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 20)
                    .keyboardType(.numberPad)
                
                // New Password field
                CustomTextField(placeholder: "NEW PASSWORD", text: $newPassword, isSecure: true)
                    .padding(.top, 10)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 20)
                
                // Confirm Password field
                CustomTextField(placeholder: "CONFIRM PASSWORD", text: $confirmPassword, isSecure: true)
                    .padding(.top, 10)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 20)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.red)
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                }
                
                // Reset Password button with custom image background
                Button(action: {
                    Task {
                        await handleResetPassword()
                    }
                }) {
                    Image("button") // Replace with your custom button image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 100) // Adjust size as needed
                        .overlay(
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Reset")
                                        .font(.custom("PressStart2P-Regular", size: 20))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
                .padding(.top, 20)
                .disabled(isLoading)
                
                // Social login buttons (optional)
                SocialLoginButtons()
                    .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full screen use
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                showLoginScreen = true
            }
        } message: {
            Text("Password reset successfully! Please login with your new password.")
        }
        .fullScreenCover(isPresented: $showLoginScreen) {
            LoginScreen()
        }
    }
    
    private func handleResetPassword() async {
        // Reset error message
        errorMessage = nil
        
        // Validate inputs
        guard !token.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        guard !token.isEmpty && token.allSatisfy({ $0.isNumber }) else {
            errorMessage = "Please enter a valid reset code"
            return
        }
        
        isLoading = true
        
        do {
            try await networkManager.resetPassword(token: token, newPassword: newPassword, email: email)
            isLoading = false
            showSuccessAlert = true
        } catch let error as NetworkError {
            isLoading = false
            errorMessage = error.errorDescription
        } catch {
            isLoading = false
            errorMessage = "An unexpected error occurred"
        }
    }
}



struct ResetPasswordScreen_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordScreen(email: "test@example.com")
            .previewDevice("iPhone 14 Pro") // Change the preview device if needed
    }
}
