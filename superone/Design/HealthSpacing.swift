import SwiftUI

/// Design system spacing constants for consistent layout
struct HealthSpacing {
    
    // MARK: - Base Spacing Scale
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let xxxxl: CGFloat = 40
    
    // MARK: - Semantic Spacing
    /// Standard padding for cards and containers
    static let cardPadding = lg
    
    /// Spacing between major sections
    static let sectionSpacing = xl
    
    /// Screen edge padding
    static let screenPadding = xl
    
    /// Form field spacing
    static let formSpacing = md
    
    /// Button internal padding
    static let buttonPadding = lg
    
    /// List item spacing
    static let listItemSpacing = md
    
    /// Grid spacing
    static let gridSpacing = md
    
    // MARK: - Component-Specific Spacing
    /// Health metric card internal spacing
    static let healthCardSpacing = lg
    
    /// Dashboard section spacing
    static let dashboardSectionSpacing = xxl
    
    /// Onboarding step spacing
    static let onboardingSpacing = xxxl
    
    /// Form group spacing
    static let formGroupSpacing = xl
    
    /// Navigation spacing
    static let navigationSpacing = md
    
    // MARK: - Element Dimensions
    /// Standard button height
    static let buttonHeight: CGFloat = 50
    
    /// Small button height
    static let buttonHeightSmall: CGFloat = 40
    
    /// Icon size for buttons and cards
    static let iconSize: CGFloat = 24
    
    /// Large icon size for features
    static let iconSizeLarge: CGFloat = 32
    
    /// Profile avatar size
    static let avatarSize: CGFloat = 40
    
    /// Large avatar size
    static let avatarSizeLarge: CGFloat = 80
    
    /// Health score circle size
    static let healthScoreSize: CGFloat = 120
    
    /// Minimum touch target size (accessibility)
    static let minimumTouchTarget: CGFloat = 44
    
    // MARK: - Layout Constants
    /// Maximum content width for large screens
    static let maxContentWidth: CGFloat = 400
    
    /// Tab bar height
    static let tabBarHeight: CGFloat = 83
    
    /// Navigation bar height
    static let navigationBarHeight: CGFloat = 44
    
    /// Status bar height (approximate)
    static let statusBarHeight: CGFloat = 47
    
}

// MARK: - Corner Radius System
struct HealthCornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 20
    static let xxxl: CGFloat = 24
    
    /// Circular/pill shape
    static let round: CGFloat = 50
    
    // MARK: - Component-Specific Radii
    static let button = lg
    static let card = xl
    static let sheet = xxl
    static let image = md
}

// MARK: - Shadow System
struct HealthShadows {
    
    // Shadow Colors
    static let light = Color.black.opacity(0.04)
    static let medium = Color.black.opacity(0.08)
    static let heavy = Color.black.opacity(0.12)
    static let intense = Color.black.opacity(0.16)
    
    // Shadow Configurations
    struct ShadowConfig {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    /// Light shadow for subtle elevation
    static let lightShadow = ShadowConfig(
        color: light,
        radius: 2,
        x: 0,
        y: 1
    )
    
    /// Medium shadow for cards
    static let cardShadow = ShadowConfig(
        color: medium,
        radius: 4,
        x: 0,
        y: 2
    )
    
    /// Heavy shadow for modals and floating elements
    static let modalShadow = ShadowConfig(
        color: heavy,
        radius: 8,
        x: 0,
        y: 4
    )
    
    /// Intense shadow for central upload button
    static let floatingButtonShadow = ShadowConfig(
        color: intense,
        radius: 12,
        x: 0,
        y: 6
    )
}

// MARK: - Layout Helpers
extension HealthSpacing {
    
    /// Get appropriate spacing for different screen sizes
    static func adaptiveSpacing(compact: CGFloat, regular: CGFloat) -> CGFloat {
        // This would be enhanced with actual screen size detection
        return regular
    }
    
    /// Get spacing based on content size category for accessibility
    static func accessibleSpacing(base: CGFloat, category: ContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall, .small, .medium:
            return base * 0.9
        case .large:
            return base
        case .extraLarge:
            return base * 1.1
        case .extraExtraLarge:
            return base * 1.2
        case .extraExtraExtraLarge:
            return base * 1.3
        case .accessibilityMedium:
            return base * 1.4
        case .accessibilityLarge:
            return base * 1.5
        case .accessibilityExtraLarge:
            return base * 1.6
        case .accessibilityExtraExtraLarge:
            return base * 1.7
        case .accessibilityExtraExtraExtraLarge:
            return base * 1.8
        @unknown default:
            return base
        }
    }
}

// MARK: - View Extensions for Spacing
extension View {
    
    /// Apply standard card padding
    func cardPadding() -> some View {
        self.padding(HealthSpacing.cardPadding)
    }
    
    /// Apply screen edge padding
    func screenPadding() -> some View {
        self.padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    /// Apply section spacing
    func sectionSpacing() -> some View {
        self.padding(.vertical, HealthSpacing.sectionSpacing)
    }
    
    /// Apply health card shadow
    func healthCardShadow() -> some View {
        let shadow = HealthShadows.cardShadow
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// Apply floating button shadow
    func floatingButtonShadow() -> some View {
        let shadow = HealthShadows.floatingButtonShadow
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}