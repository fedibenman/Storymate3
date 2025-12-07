import SwiftUI

// MARK: - Pixel Button (Icon Button)

struct PixelButton: View {
    let icon: String
    let action: () -> Void
    var enabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(icon)
                .font(.system(size: 20))
                .foregroundColor(enabled ? .white : Color(hex: "666666"))
                .frame(width: 40, height: 40)
                .background(enabled ? Color(hex: "4A4A4A") : Color(hex: "2A2A2A"))
                .overlay(
                    Rectangle()
                        .stroke(
                            enabled ? Color(hex: "6A6A6A") : Color(hex: "3A3A3A"),
                            lineWidth: 2
                        )
                )
        }
        .disabled(!enabled)
    }
}

// MARK: - Pixel Text Button (Label Button)

struct PixelTextButton: View {
    let text: String
    let action: () -> Void
    var enabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(enabled ? .white : Color(hex: "666666"))
                .tracking(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(height: 36)
                .frame(maxWidth: .infinity)
                .background(enabled ? Color(hex: "4A4A4A") : Color(hex: "2A2A2A"))
                .overlay(
                    Rectangle()
                        .stroke(
                            enabled ? Color(hex: "6A6A6A") : Color(hex: "3A3A3A"),
                            lineWidth: 2
                        )
                )
        }
        .disabled(!enabled)
    }
}

// MARK: - Preview

#if DEBUG
struct PixelButtons_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.pixelDarkBlue
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Icon buttons
                Text("Icon Buttons:")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    PixelButton(icon: "✏️", action: {})
                    PixelButton(icon: "🗑️", action: {})
                    PixelButton(icon: "✂️", action: {})
                    PixelButton(icon: "▶️", action: {})
                    PixelButton(icon: "💾", action: {})
                }
                
                Text("Disabled:")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    PixelButton(icon: "✏️", action: {}, enabled: false)
                    PixelButton(icon: "🗑️", action: {}, enabled: false)
                    PixelButton(icon: "✂️", action: {}, enabled: false)
                }
                
                Divider()
                    .background(Color.white)
                    .padding(.vertical)
                
                // Text buttons
                Text("Text Buttons:")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white)
                
                PixelTextButton(text: "+ STORY", action: {})
                    .frame(width: 120)
                
                PixelTextButton(text: "+ CHOICE", action: {})
                    .frame(width: 120)
                
                PixelTextButton(text: "→ CONTINUE", action: {})
                    .padding(.horizontal, 20)
                
                Text("Disabled:")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white)
                
                PixelTextButton(text: "DISABLED", action: {}, enabled: false)
                    .frame(width: 120)
                
                Divider()
                    .background(Color.white)
                    .padding(.vertical)
                
                // Combined example (like toolbar)
                Text("Toolbar Example:")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white)
                
                HStack(spacing: 10) {
                    PixelTextButton(text: "+ STORY", action: {})
                        .frame(width: 100)
                    
                    PixelTextButton(text: "+ CHOICE", action: {})
                        .frame(width: 100)
                    
                    Rectangle()
                        .fill(Color(hex: "4A4A4A"))
                        .frame(width: 2, height: 30)
                    
                    PixelButton(icon: "✏️", action: {})
                    PixelButton(icon: "🗑️", action: {}, enabled: false)
                    PixelButton(icon: "✂️", action: {}, enabled: false)
                    
                    Spacer()
                    
                    PixelButton(icon: "▶️", action: {})
                    PixelButton(icon: "💾", action: {})
                }
                .padding(12)
                .background(Color(hex: "1A1A1A"))
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
            }
            .padding()
        }
    }
}
#endif
