//
//  RegisterScreen.swift
//  StoryMates
//
//  Created by mac on 11/10/25.
//


import SwiftUI

struct RegisterScreen: View {
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) var dismiss
    
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
                        dismiss()
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
                Text("Creation")
                    .font(.custom("PressStart2P-Regular", size: 37))
                    .foregroundColor(.black)
                Text("join the adventurers")
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                // Name field
                CustomTextField(placeholder: "NAME", text: $viewModel.name)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 20)
                
                // Email field
                CustomTextField(placeholder: "EMAIL", text: $viewModel.email)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                
                // Password field
                CustomTextField(placeholder: "PASSWORD", text: $viewModel.password, isSecure: true)
                    .padding(.top, 10)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 20)
                
                // Confirm Password field
                CustomTextField(placeholder: "CONFIRM PASSWORD", text: $viewModel.confirmPassword, isSecure: true)
                    .padding(.top, 10)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .padding(.horizontal, 20)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(.red)
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                }
                
                // Create Account button with custom image background
                Button(action: {
                    Task {
                        await viewModel.handleSignup()
                    }
                }) {
                    Image("button") // Replace with your custom button image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 100) // Adjust size as needed
                        .overlay(
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Create")
                                        .font(.custom("PressStart2P-Regular", size: 20))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
                .padding(.top, 20)
                .disabled(viewModel.isLoading)
                
                // Social login buttons (if needed)
                SocialLoginButtons()
                    .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full screen use
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Account created successfully! Please login.")
        }
    }
}

struct SocialLoginButtons: View {
    var body: some View {
        ZStack {
            // Background image for the social buttons
            Image("bg") // Replace with your background image name
                .resizable()
                .frame(maxWidth: 300, maxHeight: 120)
                            
            Text("or login with")
                .font(.custom("PressStart2P-Regular", size: 10))
                .padding(.bottom,80)
            
            // Social buttons on top of the image
            HStack {
                Spacer()
                
                // Facebook button
                Button(action: {
                    // Handle Facebook login action
                }) {
                    Image("Facebook") // Replace with your Facebook icon image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }
                
                // Reddit button
                Button(action: {
                    // Handle Reddit login action
                }) {
                    Image("Reddit") // Replace with your Reddit icon image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }
                
                // Steam button
                Button(action: {
                    // Handle Steam login action
                }) {
                    Image("Steam") // Replace with your Steam icon image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20) // Add horizontal padding for spacing
    }
}

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Custom background image for the input field
            Image("input") // Replace with your image name in Assets
                .resizable()
                .scaledToFill()
                .frame(height: 50) // Set the height of the input field
                .cornerRadius(15)
            
            // TextField with placeholder
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.leading, 10)
            }
            
            // Actual TextField or SecureField
            if isSecure {
                SecureField("", text: $text)
                    .padding(10)
                    .foregroundColor(.black)
                    .padding(.leading, 10)
            } else {
                TextField("", text: $text)
                    .padding(10)
                    .foregroundColor(.black)
                    .padding(.leading, 10)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct AnimatedClouds: View {
    @State private var cloudOffset = CGFloat(0)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Cloud images repeated to cover the width of the screen
                Image("clouds") // Replace with your cloud image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height / 1.5) // Adjust the height as needed
                    .offset(x: cloudOffset, y: 0)
                
                Image("clouds") // Clone the image to create a seamless effect
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height / 3) // Adjust the height as needed
                    .offset(x: cloudOffset + geometry.size.width, y: 0)
            }
            .onAppear {
                withAnimation(Animation.linear(duration: 30).repeatForever(autoreverses: false)) {
                    cloudOffset = -geometry.size.width
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct RegisterScreen_Previews: PreviewProvider {
    static var previews: some View {
        RegisterScreen()
            .previewDevice("iPhone 14 Pro") // Change the preview device if needed
    }
}
