import SwiftUI

struct AnimatedThemeToggle: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    // Animation states
    @State private var sunOffset: CGFloat = -150
    @State private var moonOffset: CGFloat = -150
    
    var body: some View {
        Button(action: {
            themeManager.toggleTheme()
        }) {
            ZStack {
                // Sun Image
                Image("sun")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .offset(y: sunOffset)
                    .opacity(themeManager.isDarkMode ? 0 : 1)
                
                // Moon Image
                Image(systemName: "moon.fill") // Using system image to ensure visibility
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .shadow(color: .white.opacity(0.8), radius: 10, x: 0, y: 0) // Glow effect
                    .offset(y: moonOffset)
                    .opacity(themeManager.isDarkMode ? 1 : 0)
            }
            .frame(width: 60, height: 120) // Taller frame
            // .clipped() // Removed clipping to debug visibility
        }
        .onAppear {
            // Initial animation: Sun springs from top if in light mode
            if !themeManager.isDarkMode {
                sunOffset = -150
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0)) {
                    sunOffset = 0
                }
            } else {
                // If starting in dark mode, moon should be visible
                moonOffset = 0
                sunOffset = 150
            }
        }
        .onChange(of: themeManager.isDarkMode) { isDark in
            if isDark {
                // Switch to Dark: Sun springs down, Moon falls in from top
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    sunOffset = 150
                }
                
                moonOffset = -150
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1)) {
                    moonOffset = 0
                }
            } else {
                // Switch to Light: Moon springs up (or down?), Sun springs in from top
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    moonOffset = -150
                }
                
                sunOffset = -150
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1)) {
                    sunOffset = 0
                }
            }
        }
    }
}

#Preview {
    AnimatedThemeToggle()
        .environmentObject(ThemeManager.shared)
}
