import SwiftUI

struct ThemeToggleButton: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            themeManager.toggleTheme()
        }) {
            Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                .font(.title2)
                .foregroundColor(themeManager.isDarkMode ? .yellow : .orange)
                .padding(10)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                )
        }
    }
}

#Preview {
    ThemeToggleButton()
}
