import SwiftUI

struct Theme {
    struct Colors {
        // Primary color
        static let primary = Color(red: 0x18/255.0, green: 0x2D/255.0, blue: 0x38/255.0) // #182D38
        
        // Background colors - adapt to dark mode
        static var background: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? 
                    UIColor(red: 0x18/255.0, green: 0x2D/255.0, blue: 0x38/255.0, alpha: 1.0) : // Primary color for dark mode
                    UIColor.systemBackground
            })
        }
        
        static var secondaryBackground: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? 
                    UIColor(red: 0x10/255.0, green: 0x20/255.0, blue: 0x28/255.0, alpha: 1.0) : // Darker shade of primary for dark mode
                    UIColor.secondarySystemBackground
            })
        }
        
        // Status Colors - More vibrant, inspired by Yandex Lavka
        static let critical = Color(red: 0.95, green: 0.2, blue: 0.2) // Bright red
        static let warning = Color(red: 1.0, green: 0.6, blue: 0.0) // Vibrant orange
        static let attention = Color(red: 1.0, green: 0.85, blue: 0.0) // Bright yellow
        static let safe = Color(red: 0.2, green: 0.8, blue: 0.4) // Fresh green
        static let neutral = Color.gray
        
        // Accent - Yandex Lavka style green
        static let accent = Color(red: 0.0, green: 0.7, blue: 0.3) // Yandex green
        
        // Card colors for variety
        static let cardBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
        static let cardPurple = Color(red: 0.6, green: 0.4, blue: 0.9)
        static let cardPink = Color(red: 1.0, green: 0.4, blue: 0.6)
        static let cardTeal = Color(red: 0.2, green: 0.8, blue: 0.8)
        
        // Text - always adapts to theme
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        
        // Dark mode specific adjustments
        static func cardBackground(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? primary : Color(white: 0.98)
        }
        
        static func buttonBackground(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? accent : accent
        }
        
        // Helper for white color that adapts to dark mode
        static func adaptiveWhite(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? primary : Color.white
        }
    }
    
    struct Layout {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
    }
    
    struct Fonts {
        static func header(_ size: CGFloat = 34) -> Font {
            .system(size: size, weight: .bold, design: .default)
        }
        
        static func title(_ size: CGFloat = 20) -> Font {
            .system(size: size, weight: .semibold, design: .default)
        }
        
        static func body(_ size: CGFloat = 17) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }
        
        static func date(_ size: CGFloat = 15) -> Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }
    }
}

