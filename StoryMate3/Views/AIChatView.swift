import SwiftUI

struct AIChatView: View {
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
            
            VStack {
                Text("AI Chat")
                    .font(.custom("PressStart2P-Regular", size: 24))
                    .foregroundColor(.white)
                Text("Coming Soon")
                    .font(.custom("PressStart2P-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}
