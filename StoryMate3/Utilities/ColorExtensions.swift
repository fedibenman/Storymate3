import SwiftUI

extension Color {
    static let pixelGold = Color(hex: "#FFD700")
    static let pixelDarkBlue = Color(hex: "#1E3A8A")
    static let pixelCyan = Color(hex: "#00FFFF")
    static let pixelHighlight = Color(hex: "#FFFF00")
    static let pixelMidBlue = Color(hex: "#2B4B7F")
    static let pixelAccent = Color(hex: "#FF69B4")

        // Node type specific colors
        static let startColor = Color(hex: "90EE90") // Light green
        static let storyColor = Color(hex: "FFD700") // Gold
        static let decisionColor = Color(hex: "87CEEB") // Light blue
        static let endColor = Color(hex: "FF6B6B") // Light red
        

        // Additional UI colors
        static let pixelGray1 = Color(hex: "1A1A1A")
        static let pixelGray2 = Color(hex: "2A2A2A")
        static let pixelGray3 = Color(hex: "3A3A3A")
        static let pixelGray4 = Color(hex: "4A4A4A")
        static let pixelGray5 = Color(hex: "6A6A6A")
        static let pixelGray6 = Color(hex: "666666")
        static let pixelGreen = Color(hex: "00FF00")
        static let pixelDarkGreen = Color(hex: "00CC00")
        static let pixelOrange = Color(hex: "FFAA00")
        static let pixelRed = Color(hex: "FF6B6B")
        static let pixelDarkRed = Color(hex: "3A1A1A")
        static let pixelDarkOrange = Color(hex: "3A2A1A")
        static let pixelDarkGreen2 = Color(hex: "1A3A1A")
        static let pixelGray = Color(hex: "808080")
        static let pixelLightGray = Color(hex: "AAAAAA")
        static let pixelBlack = Color(hex: "000000")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
