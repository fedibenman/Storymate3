import SwiftUI

struct DarkThemeBackground: View {
    @State private var opacity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Base night background
            Image("night")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Stars overlay with pulsing animation
            Image("stars")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        opacity = 0.8
                    }
                }
        }
    }
}

#Preview {
    DarkThemeBackground()
}
