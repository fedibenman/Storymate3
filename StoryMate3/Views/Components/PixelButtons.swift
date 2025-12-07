import SwiftUI

struct PixelTextButton: View {
    let text: String
    let action: () -> Void
    let hexColor: String
    let fontSize: CGFloat
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.custom("PressStart2P-Regular", size: fontSize))
                .foregroundColor(Color(hex: hexColor))
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: hexColor), lineWidth: 2)
                )
        }
    }
}

struct PixelButton: View {
    let text: String
    let action: () -> Void
    let hexColor: String
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.custom("PressStart2P-Regular", size: 12))
                .foregroundColor(Color(hex: hexColor))
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: hexColor), lineWidth: 2)
                )
        }
    }
}

struct PixelButtons_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PixelTextButton(text: "Click Me", action: {}, hexColor: "#FFD700", fontSize: 14)
            PixelButton(text: "Click Me", action: {}, hexColor: "#FFD700")
        }
        .padding()
    }
}
