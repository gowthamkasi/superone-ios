import SwiftUI

/// Health-focused typography system optimized for iOS 18+
struct HealthTypography {
    
    // MARK: - Large Titles (iOS 18 optimized)
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    
    // MARK: - Navigation & Screen Titles
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    
    static let title2 = Font.system(size: 22, weight: .bold, design: .default)
    
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Headlines & Section Headers
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    
    // MARK: - Body Text
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    
    static let bodyRegular = Font.system(size: 17, weight: .regular, design: .default)
    
    static let bodyEmphasized = Font.system(size: 17, weight: .medium, design: .default)
    
    static let bodyMedium = Font.system(size: 17, weight: .medium, design: .default)
    
    // MARK: - Supporting Text
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    
    // MARK: - Labels & Captions
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
    
    static let captionRegular = Font.system(size: 12, weight: .regular, design: .default)
    
    static let captionSmall = Font.system(size: 10, weight: .regular, design: .default)
    
    // MARK: - Health-Specific Typography
    static let healthMetricValue = Font.system(size: 36, weight: .bold, design: .default)
        .monospacedDigit()
    
    static let healthMetricUnit = Font.system(size: 14, weight: .medium, design: .default)
    
    static let healthScoreDisplay = Font.system(size: 48, weight: .bold, design: .default)
        .monospacedDigit()
    
    static let healthCategoryTitle = Font.system(size: 18, weight: .semibold, design: .default)
    
    // MARK: - Button Typography
    static let buttonPrimary = Font.system(size: 17, weight: .semibold, design: .default)
    
    static let buttonSecondary = Font.system(size: 17, weight: .medium, design: .default)
    
    static let buttonSmall = Font.system(size: 15, weight: .medium, design: .default)
    
    // MARK: - Additional Heading Styles for Components
    static let headingLarge = Font.system(size: 28, weight: .bold, design: .default)
    
    static let headingMedium = Font.system(size: 22, weight: .semibold, design: .default)
    
    static let headingSmall = Font.system(size: 18, weight: .semibold, design: .default)
}

// MARK: - Typography Styles Enum
enum TypographyStyle {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case bodyRegular
    case bodyEmphasized
    case bodyMedium
    case callout
    case subheadline
    case footnote
    case caption1
    case caption2
    case captionMedium
    case captionRegular
    case healthMetricValue
    case healthMetricUnit
    case healthScoreDisplay
    case healthCategoryTitle
    case buttonPrimary
    case buttonSecondary
    case buttonSmall
    case headingLarge
    case headingMedium
    case headingSmall
    
    var font: Font {
        switch self {
        case .largeTitle: return HealthTypography.largeTitle
        case .title1: return HealthTypography.title1
        case .title2: return HealthTypography.title2
        case .title3: return HealthTypography.title3
        case .headline: return HealthTypography.headline
        case .body: return HealthTypography.body
        case .bodyRegular: return HealthTypography.bodyRegular
        case .bodyEmphasized: return HealthTypography.bodyEmphasized
        case .bodyMedium: return HealthTypography.bodyMedium
        case .callout: return HealthTypography.callout
        case .subheadline: return HealthTypography.subheadline
        case .footnote: return HealthTypography.footnote
        case .caption1: return HealthTypography.caption1
        case .caption2: return HealthTypography.caption2
        case .captionMedium: return HealthTypography.captionMedium
        case .captionRegular: return HealthTypography.captionRegular
        case .healthMetricValue: return HealthTypography.healthMetricValue
        case .healthMetricUnit: return HealthTypography.healthMetricUnit
        case .healthScoreDisplay: return HealthTypography.healthScoreDisplay
        case .healthCategoryTitle: return HealthTypography.healthCategoryTitle
        case .buttonPrimary: return HealthTypography.buttonPrimary
        case .buttonSecondary: return HealthTypography.buttonSecondary
        case .buttonSmall: return HealthTypography.buttonSmall
        case .headingLarge: return HealthTypography.headingLarge
        case .headingMedium: return HealthTypography.headingMedium
        case .headingSmall: return HealthTypography.headingSmall
        }
    }
}

// MARK: - Text Style View Modifier
struct HealthTextStyle: ViewModifier {
    let style: TypographyStyle
    let color: Color
    let alignment: TextAlignment
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(color)
            .multilineTextAlignment(alignment)
    }
}

extension View {
    /// Apply health text style
    func healthTextStyle(
        _ style: TypographyStyle,
        color: Color = HealthColors.primaryText,
        alignment: TextAlignment = .leading
    ) -> some View {
        modifier(HealthTextStyle(style: style, color: color, alignment: alignment))
    }
}

// MARK: - Dynamic Type Support
extension Font {
    /// Create scaled font for accessibility
    static func scaledHealthFont(_ style: TypographyStyle) -> Font {
        return style.font
    }
}

// MARK: - Accessibility Helpers
struct AccessibilityTypography {
    /// Get dynamic font size based on content size category
    static func dynamicSize(base: CGFloat, category: ContentSizeCategory) -> CGFloat {
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
    
    /// Check if text should be bold for accessibility
    static func shouldUseBoldText(_ category: ContentSizeCategory) -> Bool {
        switch category {
        case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
}