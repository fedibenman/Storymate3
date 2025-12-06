//
//  SplashScreen.swift
//  StoryMates
//
//  Created by mac on 11/10/25.
//


import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @StateObject private var authManager = AuthManager.shared
    @State private var navController = UINavigationController()
    
    var body: some View {
        Group {
            if isActive {
                if authManager.isAuthenticated {
                    MainTabView()
                } else {
                    LoginScreen()
                }
            } else {
                VStack {
                    // Image for splash s#imageLiteral(resourceName: "background_land.png")creen
                    Image("splashscreen") // Ensure the logo image is added to your assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 1920, height: 880)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]), startPoint: .top, endPoint: .bottom)
                )
                .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            // Show splash screen for 2 seconds then navigate
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isActive = true
                }
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
