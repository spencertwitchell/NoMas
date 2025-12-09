import SwiftUI

// MARK: - App Typography

extension Font {
    
    // MARK: - Titles (Helvetica Neue Medium)
    
    /// Extra large title - 34pt
    static let titleXL = Font.custom("HelveticaNeue-Medium", size: 34)
    
    /// Large title - 28pt
    static let titleLarge = Font.custom("HelveticaNeue-Medium", size: 28)
    
    /// Standard title - 26pt
    static let title = Font.custom("HelveticaNeue-Medium", size: 26)
    
    /// Medium title - 22pt
    static let titleMedium = Font.custom("HelveticaNeue-Medium", size: 22)
    
    /// Small title - 18pt
    static let titleSmall = Font.custom("HelveticaNeue-Medium", size: 18)
    
    // MARK: - Body (Helvetica Neue Light)
    
    /// Large body text - 18pt
    static let bodyLarge = Font.custom("HelveticaNeue-Light", size: 18)
    
    /// Standard body text - 17pt
    static let body = Font.custom("HelveticaNeue-Light", size: 17)
    
    /// Small body text - 15pt
    static let bodySmall = Font.custom("HelveticaNeue-Light", size: 15)
    
    // MARK: - Captions (Helvetica Neue Light)
    
    /// Standard caption - 14pt
    static let caption = Font.custom("HelveticaNeue-Light", size: 14)
    
    /// Small caption - 12pt
    static let captionSmall = Font.custom("HelveticaNeue-Light", size: 12)
    
    // MARK: - Buttons (Helvetica Neue Medium)
    
    /// Large button text - 18pt
    static let buttonLarge = Font.custom("HelveticaNeue-Medium", size: 18)
    
    /// Standard button text - 17pt
    static let button = Font.custom("HelveticaNeue-Medium", size: 17)
    
    /// Small button text - 16pt
    static let buttonSmall = Font.custom("HelveticaNeue-Medium", size: 16)
    
    // MARK: - Custom Sizes
    
    /// Custom title size (Medium weight)
    static func titleCustom(size: CGFloat) -> Font {
        Font.custom("HelveticaNeue-Medium", size: size)
    }
    
    /// Custom body size (Light weight)
    static func bodyCustom(size: CGFloat) -> Font {
        Font.custom("HelveticaNeue-Light", size: size)
    }
}

// MARK: - Preview

#Preview("Typography") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // Titles
            Group {
                Text("Title XL (34pt)")
                    .font(.titleXL)
                Text("Title Large (28pt)")
                    .font(.titleLarge)
                Text("Title (26pt)")
                    .font(.title)
                Text("Title Medium (22pt)")
                    .font(.titleMedium)
                Text("Title Small (18pt)")
                    .font(.titleSmall)
                Text("System Default for comparison")
                            .font(.system(size: 24))
            }
            
            Divider()
            
            // Body
            Group {
                Text("Body Large (18pt)")
                    .font(.bodyLarge)
                Text("Body (17pt)")
                    .font(.body)
                Text("Body Small (15pt)")
                    .font(.bodySmall)
            }
            
            Divider()
            
            // Captions
            Group {
                Text("Caption (14pt)")
                    .font(.caption)
                Text("Caption Small (12pt)")
                    .font(.captionSmall)
            }
            
            Divider()
            
            // Buttons
            Group {
                Text("Button Large (18pt)")
                    .font(.buttonLarge)
                Text("Button (17pt)")
                    .font(.button)
                Text("Button Small (16pt)")
                    .font(.buttonSmall)
            }
        }
        .foregroundColor(.white)
        .padding()
    }
    .background(Color.black)
}
