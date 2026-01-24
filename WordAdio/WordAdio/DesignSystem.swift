import SwiftUI

// MARK: - Design System
// Centralized design tokens for consistent, responsive UI across all device sizes

/// Layout metrics that adapt to screen size
enum LayoutMetrics {
    
    // MARK: - Screen Reference
    
    private static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    private static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    private static var isCompactWidth: Bool {
        screenWidth < 400
    }
    
    private static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // MARK: - Letter Wheel
    
    /// Wheel radius - scales with screen width
    static var wheelRadius: CGFloat {
        if isIPad {
            return min(screenWidth * 0.18, 180)
        }
        return min(screenWidth * 0.28, 130)
    }
    
    /// Letter button radius in the wheel
    static var letterButtonRadius: CGFloat {
        if isIPad {
            return min(screenWidth * 0.055, 48)
        }
        return isCompactWidth ? 28 : 32
    }
    
    /// Maximum height for the wheel container
    static var wheelMaxHeight: CGFloat {
        if isIPad {
            return screenHeight * 0.4
        }
        return min(screenHeight * 0.35, 300)
    }
    
    // MARK: - Action Buttons
    
    /// Size for circular action buttons (hint, shuffle, etc.)
    static var actionButtonSize: CGFloat {
        if isIPad {
            return 52
        }
        return isCompactWidth ? 34 : 40
    }
    
    /// Badge size for notification indicators
    static var badgeSize: CGFloat {
        isCompactWidth ? 14 : 16
    }
    
    // MARK: - Puzzle Grid
    
    /// Minimum cell size for puzzle tiles
    static var minPuzzleCellSize: CGFloat {
        isIPad ? 44 : 32
    }
    
    /// Corner radius for puzzle cells
    static var puzzleCellCornerRadius: CGFloat {
        isIPad ? 6 : 4
    }
    
    // MARK: - Spacing
    
    /// Standard horizontal padding
    static var horizontalPadding: CGFloat {
        if isIPad {
            return 32
        }
        return isCompactWidth ? 12 : 16
    }
    
    /// Standard vertical spacing between sections
    static var sectionSpacing: CGFloat {
        if isIPad {
            return 16
        }
        return isCompactWidth ? 4 : 8
    }
    
    /// Spacing between action buttons
    static var actionButtonSpacing: CGFloat {
        if isIPad {
            return 16
        }
        return 10
    }
    
}

// MARK: - Typography

/// Responsive typography that scales with device
enum Typography {
    
    private static var isCompactWidth: Bool {
        UIScreen.main.bounds.width < 400
    }
    
    private static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // MARK: - Letter Wheel
    
    /// Font for letters in the wheel
    static var letterButton: Font {
        let size: CGFloat
        if isIPad {
            size = 32
        } else {
            size = isCompactWidth ? 22 : 24
        }
        return .system(size: size, weight: .bold, design: .rounded)
    }
    
    /// Font for current word display in wheel center
    static var currentWord: Font {
        let size: CGFloat
        if isIPad {
            size = 28
        } else {
            size = isCompactWidth ? 18 : 20
        }
        return .system(size: size, weight: .bold, design: .rounded)
    }
    
    /// Font for letter count caption
    static var letterCount: Font {
        isIPad ? .subheadline : .caption
    }
    
    // MARK: - Puzzle Grid
    
    /// Font size multiplier for puzzle cell letters (relative to cell size)
    static var puzzleCellFontMultiplier: CGFloat {
        0.5
    }
    
    /// Font size multiplier for solution hints
    static var puzzleSolutionFontMultiplier: CGFloat {
        0.4
    }
    
    // MARK: - Header
    
    /// Font for header labels
    static var headerLabel: Font {
        isIPad ? .subheadline : .caption
    }
    
    /// Font for header values
    static var headerValue: Font {
        isIPad ? .headline : .subheadline.bold()
    }
    
    // MARK: - Messages
    
    /// Font for message overlay text
    static var messageText: Font {
        isIPad ? .body.weight(.medium) : .subheadline.weight(.medium)
    }
    
    // MARK: - Level Complete
    
    /// Font for "Complete!" text
    static var levelCompleteTitle: Font {
        let size: CGFloat = isIPad ? 52 : 42
        return .system(size: size, weight: .bold, design: .rounded)
    }
    
    /// Font for level number
    static var levelNumber: Font {
        isIPad ? .title2 : .title3
    }
    
    // MARK: - Action Buttons
    
    /// Font for action button icons
    static var actionButtonIcon: Font {
        if isIPad {
            return .body
        }
        return .callout
    }
    
    /// Font for badge numbers
    static var badge: Font {
        .system(size: isIPad ? 12 : 10, weight: .bold)
    }
}

// MARK: - Colors

/// App color palette
enum AppColors {
    // Primary accent colors
    static let primaryGradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let coinGradient = LinearGradient(
        colors: [.yellow, .orange],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let successGradient = LinearGradient(
        colors: [.green, .mint],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Button gradients
    static let shuffleButtonGradient = LinearGradient(
        colors: [.purple, .blue.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let bonusButtonGradient = LinearGradient(
        colors: [.orange, .yellow.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let muteButtonGradient = LinearGradient(
        colors: [.gray, .gray.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let hintButtonGradient = LinearGradient(
        colors: [.orange, .yellow.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Tile colors
    static let filledTileColor = Color(red: 0.98, green: 0.95, blue: 0.88)
    static let emptyTileColor = Color.white
    
    // Connecting line colors
    static let lineGradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Animation Constants

enum AnimationDurations {
    static let quick: Double = 0.15
    static let standard: Double = 0.3
    static let slow: Double = 0.5
    static let message: UInt64 = 2_000_000_000  // 2 seconds in nanoseconds
    static let coinsAnimation: UInt64 = 1_500_000_000
}

enum AnimationSprings {
    static let bouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)
    static let smooth = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8)
}

// MARK: - Shadows

enum AppShadows {
    static func button(color: Color = .black.opacity(0.3)) -> some View {
        EmptyView().shadow(color: color, radius: 4, y: 2)
    }
    
    static let cardShadow = (color: Color.black.opacity(0.15), radius: CGFloat(10), x: CGFloat(0), y: CGFloat(4))
    static let tileShadow = (color: Color.black.opacity(0.2), radius: CGFloat(2), x: CGFloat(1), y: CGFloat(2))
}
