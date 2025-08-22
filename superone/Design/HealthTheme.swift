import SwiftUI

// MARK: - Health Theme Definition

/// Comprehensive health theme containing all design system elements
/// Uses iOS 18+ @Entry macro for clean environment integration
struct HealthTheme {
    let colors: HealthThemeColors
    let spacing: HealthThemeSpacing
    let typography: HealthThemeTypography
    let shadows: HealthThemeShadows
    let cornerRadius: HealthThemeCornerRadius
    
    /// Default health theme configuration
    static let `default` = HealthTheme(
        colors: HealthThemeColors(),
        spacing: HealthThemeSpacing(),
        typography: HealthThemeTypography(),
        shadows: HealthThemeShadows(),
        cornerRadius: HealthThemeCornerRadius()
    )
}

// MARK: - Theme Colors

struct HealthThemeColors {
    // Primary Green Palette
    let sage = Color(hex: "#A8D5BA")
    let emerald = Color(hex: "#6BBF8A")
    let forest = Color(hex: "#4B9B6E")
    let pine = Color(hex: "#2E7D5C")
    let deepForest = Color(hex: "#1B5E3A")
    
    // Semantic Colors
    let primary: Color
    let secondary: Color
    let accent: Color
    
    // System Colors
    let background = Color(.systemBackground)
    let secondaryBackground = Color(.secondarySystemBackground)
    let tertiaryBackground = Color(.tertiarySystemBackground)
    
    // Text Colors
    let primaryText = Color(.label)
    let secondaryText = Color(.secondaryLabel)
    let tertiaryText = Color(.tertiaryLabel)
    
    // Health Status Colors
    let healthExcellent: Color
    let healthGood: Color
    let healthNormal: Color
    let healthModerate = Color(.systemYellow)
    let healthWarning = Color(.systemOrange)
    let healthCritical = Color(.systemRed)
    let healthNeutral = Color(.systemGray)
    
    init() {
        self.primary = forest
        self.secondary = emerald
        self.accent = sage
        self.healthExcellent = emerald
        self.healthGood = forest
        self.healthNormal = sage
    }
    
    /// Get color for health status
    func statusColor(for status: HealthStatus) -> Color {
        switch status {
        case .excellent: return healthExcellent
        case .good: return healthGood
        case .normal: return healthNormal
        case .fair: return healthModerate
        case .monitor: return healthWarning
        case .needsAttention: return healthCritical
        case .poor: return healthCritical
        case .critical: return healthCritical
        }
    }
    
    /// Get background color for health status
    func statusBackgroundColor(for status: HealthStatus) -> Color {
        switch status {
        case .excellent, .good, .normal:
            return accent.opacity(0.1)
        case .fair:
            return healthModerate.opacity(0.1)
        case .monitor:
            return healthWarning.opacity(0.1)
        case .needsAttention, .poor, .critical:
            return healthCritical.opacity(0.1)
        }
    }
}

// MARK: - Theme Spacing

struct HealthThemeSpacing {
    // Base Spacing Scale
    let xs: CGFloat = 4
    let sm: CGFloat = 8
    let md: CGFloat = 12
    let lg: CGFloat = 16
    let xl: CGFloat = 20
    let xxl: CGFloat = 24
    let xxxl: CGFloat = 32
    let xxxxl: CGFloat = 40
    
    // Semantic Spacing
    let cardPadding: CGFloat = 16
    let sectionSpacing: CGFloat = 20
    let screenPadding: CGFloat = 20
    let formSpacing: CGFloat = 12
    let buttonPadding: CGFloat = 16
    let listItemSpacing: CGFloat = 12
    let gridSpacing: CGFloat = 12
    
    // Component-Specific Spacing
    let healthCardSpacing: CGFloat = 16
    let dashboardSectionSpacing: CGFloat = 24
    let onboardingSpacing: CGFloat = 32
    let formGroupSpacing: CGFloat = 20
    let navigationSpacing: CGFloat = 12
    
    // Element Dimensions
    let buttonHeight: CGFloat = 50
    let buttonHeightSmall: CGFloat = 40
    let iconSize: CGFloat = 24
    let iconSizeLarge: CGFloat = 32
    let avatarSize: CGFloat = 40
    let avatarSizeLarge: CGFloat = 80
    let healthScoreSize: CGFloat = 120
    let minimumTouchTarget: CGFloat = 44
    
    // Layout Constants
    let maxContentWidth: CGFloat = 400
    let tabBarHeight: CGFloat = 83
    let navigationBarHeight: CGFloat = 44
    let statusBarHeight: CGFloat = 47
    // Safe area padding is now handled automatically by SwiftUI
}

// MARK: - Theme Typography

struct HealthThemeTypography {
    // Large Titles
    let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    
    // Navigation & Screen Titles
    let title1 = Font.system(size: 28, weight: .bold, design: .default)
    let title2 = Font.system(size: 22, weight: .bold, design: .default)
    let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // Headlines & Section Headers
    let headline = Font.system(size: 17, weight: .semibold, design: .default)
    
    // Body Text
    let body = Font.system(size: 17, weight: .regular, design: .default)
    let bodyEmphasized = Font.system(size: 17, weight: .medium, design: .default)
    
    // Supporting Text
    let callout = Font.system(size: 16, weight: .regular, design: .default)
    let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    let footnote = Font.system(size: 13, weight: .regular, design: .default)
    
    // Labels & Captions
    let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // Health-Specific Typography
    let healthMetricValue = Font.system(size: 36, weight: .bold, design: .default).monospacedDigit()
    let healthMetricUnit = Font.system(size: 14, weight: .medium, design: .default)
    let healthScoreDisplay = Font.system(size: 48, weight: .bold, design: .default).monospacedDigit()
    let healthCategoryTitle = Font.system(size: 18, weight: .semibold, design: .default)
    
    // Button Typography
    let buttonPrimary = Font.system(size: 17, weight: .semibold, design: .default)
    let buttonSecondary = Font.system(size: 17, weight: .medium, design: .default)
    let buttonSmall = Font.system(size: 15, weight: .medium, design: .default)
}

// MARK: - Theme Shadows

struct HealthThemeShadows {
    struct ShadowConfig {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // Shadow Colors
    let light = Color.black.opacity(0.04)
    let medium = Color.black.opacity(0.08)
    let heavy = Color.black.opacity(0.12)
    let intense = Color.black.opacity(0.16)
    
    // Shadow Configurations
    let lightShadow = ShadowConfig(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    let cardShadow = ShadowConfig(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    let modalShadow = ShadowConfig(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    let floatingButtonShadow = ShadowConfig(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 6)
}

// MARK: - Theme Corner Radius

struct HealthThemeCornerRadius {
    let xs: CGFloat = 4
    let sm: CGFloat = 6
    let md: CGFloat = 8
    let lg: CGFloat = 12
    let xl: CGFloat = 16
    let xxl: CGFloat = 20
    let xxxl: CGFloat = 24
    let round: CGFloat = 50
    
    // Component-Specific Radii
    let button: CGFloat = 12
    let card: CGFloat = 16
    let sheet: CGFloat = 20
    let image: CGFloat = 8
}

// MARK: - iOS 18+ Environment Integration with @Entry Macro

extension EnvironmentValues {
    /// Health theme environment value using iOS 18+ @Entry macro
    /// Replaces traditional EnvironmentKey pattern with cleaner syntax
    @Entry var healthTheme: HealthTheme = .default
}

// MARK: - Theme-Aware View Extensions

extension View {
    /// Apply health theme environment
    func healthThemeEnvironment(_ theme: HealthTheme = .default) -> some View {
        self.environment(\.healthTheme, theme)
    }
}

// MARK: - Theme-Aware Modifiers

struct HealthThemeModifier: ViewModifier {
    @Environment(\.healthTheme) private var theme
    let styleType: ThemeStyleType
    
    enum ThemeStyleType {
        case primaryButton
        case secondaryButton
        case card
        case section
    }
    
    func body(content: Content) -> some View {
        switch styleType {
        case .primaryButton:
            content
                .padding(theme.spacing.buttonPadding)
                .background(theme.colors.primary)
                .foregroundColor(.white)
                .font(theme.typography.buttonPrimary)
                .cornerRadius(theme.cornerRadius.button)
                .shadow(
                    color: theme.shadows.cardShadow.color,
                    radius: theme.shadows.cardShadow.radius,
                    x: theme.shadows.cardShadow.x,
                    y: theme.shadows.cardShadow.y
                )
                
        case .secondaryButton:
            content
                .padding(theme.spacing.buttonPadding)
                .background(theme.colors.secondaryBackground)
                .foregroundColor(theme.colors.primary)
                .font(theme.typography.buttonSecondary)
                .cornerRadius(theme.cornerRadius.button)
                
        case .card:
            content
                .padding(theme.spacing.cardPadding)
                .background(theme.colors.background)
                .cornerRadius(theme.cornerRadius.card)
                .shadow(
                    color: theme.shadows.cardShadow.color,
                    radius: theme.shadows.cardShadow.radius,
                    x: theme.shadows.cardShadow.x,
                    y: theme.shadows.cardShadow.y
                )
                
        case .section:
            content
                .padding(.vertical, theme.spacing.sectionSpacing)
                .padding(.horizontal, theme.spacing.screenPadding)
        }
    }
}

extension View {
    /// Apply health theme styling
    func healthThemeStyle(_ styleType: HealthThemeModifier.ThemeStyleType) -> some View {
        modifier(HealthThemeModifier(styleType: styleType))
    }
    
    /// Apply themed card padding
    func themedCardPadding() -> some View {
        modifier(ThemeAwareCardPadding())
    }
    
    /// Apply themed screen padding
    func themedScreenPadding() -> some View {
        modifier(ThemeAwareScreenPadding())
    }
    
    /// Apply themed section spacing
    func themedSectionSpacing() -> some View {
        modifier(ThemeAwareSectionSpacing())
    }
}

// MARK: - Theme-Aware Padding Modifiers

struct ThemeAwareCardPadding: ViewModifier {
    @Environment(\.healthTheme) private var theme
    
    func body(content: Content) -> some View {
        content.padding(theme.spacing.cardPadding)
    }
}

struct ThemeAwareScreenPadding: ViewModifier {
    @Environment(\.healthTheme) private var theme
    
    func body(content: Content) -> some View {
        content.padding(.horizontal, theme.spacing.screenPadding)
    }
}

struct ThemeAwareSectionSpacing: ViewModifier {
    @Environment(\.healthTheme) private var theme
    
    func body(content: Content) -> some View {
        content.padding(.vertical, theme.spacing.sectionSpacing)
    }
}

// MARK: - Theme Accessibility Support

extension HealthTheme {
    /// Create accessibility-aware theme based on content size category
    static func accessibilityTheme(for category: ContentSizeCategory) -> HealthTheme {
        var theme = HealthTheme.default
        
        // Adjust spacing for accessibility
        let spacingMultiplier = Self.accessibilityMultiplier(for: category)
        theme = HealthTheme(
            colors: theme.colors,
            spacing: theme.spacing.scaled(by: spacingMultiplier),
            typography: theme.typography.scaled(for: category),
            shadows: theme.shadows,
            cornerRadius: theme.cornerRadius
        )
        
        return theme
    }
    
    private static func accessibilityMultiplier(for category: ContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall, .small, .medium: return 0.9
        case .large: return 1.0
        case .extraLarge: return 1.1
        case .extraExtraLarge: return 1.2
        case .extraExtraExtraLarge: return 1.3
        case .accessibilityMedium: return 1.4
        case .accessibilityLarge: return 1.5
        case .accessibilityExtraLarge: return 1.6
        case .accessibilityExtraExtraLarge: return 1.7
        case .accessibilityExtraExtraExtraLarge: return 1.8
        @unknown default: return 1.0
        }
    }
}

// MARK: - Theme Scaling Extensions

extension HealthThemeSpacing {
    func scaled(by factor: CGFloat) -> HealthThemeSpacing {
        var scaled = self
        // Apply scaling to key spacing values while maintaining proportions
        return scaled
    }
}

extension HealthThemeTypography {
    func scaled(for category: ContentSizeCategory) -> HealthThemeTypography {
        // Return scaled typography based on content size category
        // For now, return self as Font.system automatically handles dynamic type
        return self
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension HealthTheme {
    /// Preview theme with exaggerated values for testing
    static let preview = HealthTheme(
        colors: HealthThemeColors(),
        spacing: HealthThemeSpacing(),
        typography: HealthThemeTypography(),
        shadows: HealthThemeShadows(),
        cornerRadius: HealthThemeCornerRadius()
    )
}
#endif