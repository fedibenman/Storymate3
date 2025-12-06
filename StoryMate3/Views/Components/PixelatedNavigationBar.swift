import SwiftUI

struct PixelatedNavigationBar: View {
    let title: String
    let showBackButton: Bool
    let onBack: (() -> Void)?
    
    init(title: String, showBackButton: Bool = true, onBack: (() -> Void)? = nil) {
        self.title = title
        self.showBackButton = showBackButton
        self.onBack = onBack
    }
    
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: {
                    onBack?()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrowtriangle.left.fill")
                            .font(.system(size: 12))
                        Text("Back")
                            .font(.custom("PressStart2P-Regular", size: 10))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                }
            } else {
                Spacer()
                    .frame(width: 80)
            }
            
            Spacer()
            
            Text(title)
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2, x: 1, y: 1)
            
            Spacer()
            
            // Placeholder for trailing button if needed
            Spacer()
                .frame(width: 80)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}
