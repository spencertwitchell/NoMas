import SwiftUI

// MARK: - App Colors

extension Color {
    
    // MARK: - Background Gradient
    
    /// Background gradient top color (#231740)
    static let backgroundGradientStart = Color(hex: "231740")
    
    /// Background gradient bottom color (#0a0419)
    static let backgroundGradientEnd = Color(hex: "0a0419")
    
    // MARK: - Accent Gradient (Buttons, Progress, etc.)
    
    /// Accent gradient top color (#754ed2)
    static let accentGradientStart = Color(hex: "754ed2")
    
    /// Accent gradient bottom color (#5e37bb)
    static let accentGradientEnd = Color(hex: "5e37bb")
    
    // MARK: - Semantic Colors
    
    /// Primary text color
    static let textPrimary = Color.white
    
    /// Secondary text color
    static let textSecondary = Color.white.opacity(0.7)
    
    /// Tertiary text color
    static let textTertiary = Color.white.opacity(0.5)
    
    /// Card/Surface background
    static let surfaceBackground = Color.white.opacity(0.12)
    
    /// Border color
    static let borderColor = Color.white.opacity(0.1)
    
    // MARK: - Milestone Gradient Colors
    
    // Bronze
    static let bronzeGradientStart = Color(hex: "ad6b2b")
    static let bronzeGradientEnd = Color(hex: "ce8b4a")
    
    // Silver
    static let silverGradientStart = Color(hex: "c0c0c0")
    static let silverGradientEnd = Color(hex: "d4d4d4")
    
    // Gold
    static let goldGradientStart = Color(hex: "e7c46a")
    static let goldGradientEnd = Color(hex: "f2de9b")
    
    // Platinum
    static let platinumGradientStart = Color(hex: "e5f2f5")
    static let platinumGradientEnd = Color(hex: "cfdde2")
    
    // Diamond
    static let diamondGradientStart = Color(hex: "46d8e5")
    static let diamondGradientEnd = Color(hex: "84edf6")
    
    // Ruby
    static let rubyGradientStart = Color(hex: "9b112e")
    static let rubyGradientEnd = Color(hex: "a6324a")
    
    // Elite
    static let eliteGradientStart = Color(hex: "178668")
    static let eliteGradientEnd = Color(hex: "1fbf8f")
    
    // Master
    static let masterGradientStart = Color(hex: "7f45e5")
    static let masterGradientEnd = Color(hex: "a656f6")
    
    // Grandmaster (3 colors)
    static let grandmasterGradientStart = Color(hex: "51eac4")
    static let grandmasterGradientMid = Color(hex: "9bbcff")
    static let grandmasterGradientEnd = Color(hex: "cdb7ff")

}

// MARK: - Hex Color Initializer

extension Color {
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Presets

extension LinearGradient {
    
    /// Standard background gradient (top to bottom)
    static let appBackground = LinearGradient(
        gradient: Gradient(colors: [Color.backgroundGradientStart, Color.backgroundGradientEnd]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Accent gradient for buttons and interactive elements
    static let accent = LinearGradient(
        gradient: Gradient(colors: [Color.accentGradientStart, Color.accentGradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Accent gradient (vertical)
    static let accentVertical = LinearGradient(
        gradient: Gradient(colors: [Color.accentGradientStart, Color.accentGradientEnd]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Milestone Gradients (top-left to bottom-right)
    
    static let bronze = LinearGradient(
        gradient: Gradient(colors: [Color.bronzeGradientStart, Color.bronzeGradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let silver = LinearGradient(
        gradient: Gradient(colors: [Color.silverGradientStart, Color.silverGradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gold = LinearGradient(
        gradient: Gradient(colors: [Color.goldGradientStart, Color.goldGradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let platinum = LinearGradient(
        gradient: Gradient(colors: [Color.platinumGradientStart, Color.platinumGradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let diamond = LinearGradient(
        gradient: Gradient(colors: [Color.diamondGradientStart, Color.diamondGradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let ruby = LinearGradient(
        gradient: Gradient(colors: [Color.rubyGradientStart, Color.rubyGradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let elite = LinearGradient(
        gradient: Gradient(colors: [Color.eliteGradientStart, Color.eliteGradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let master = LinearGradient(
        gradient: Gradient(colors: [Color.masterGradientStart, Color.masterGradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let grandmaster = LinearGradient(
        gradient: Gradient(colors: [Color.grandmasterGradientStart, Color.grandmasterGradientMid, Color.grandmasterGradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Background View

struct AppBackground: View {
    var body: some View {
        LinearGradient.appBackground
            .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview("Colors") {
    VStack(spacing: 20) {
        // Background preview
        RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient.appBackground)
            .frame(height: 100)
            .overlay(
                Text("Background Gradient")
                    .foregroundColor(.white)
            )
        
        // Accent preview
        RoundedRectangle(cornerRadius: 16)
            .fill(LinearGradient.accent)
            .frame(height: 60)
            .overlay(
                Text("Accent Gradient")
                    .foregroundColor(.white)
            )
        
        // Surface preview
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.surfaceBackground)
            .frame(height: 60)
            .overlay(
                Text("Surface Background")
                    .foregroundColor(.white)
            )
    }
    .padding()
    .background(LinearGradient.appBackground)
}
