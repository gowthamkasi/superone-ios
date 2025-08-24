import SwiftUI
import Foundation

/// Reusable card component for displaying informational content sections
/// Supports various content types including text, lists, categories, and structured information
@MainActor
struct InfoCard<Content: View>: View {
    
    // MARK: - Properties
    let title: String
    let subtitle: String?
    let icon: String?
    let accentColor: Color
    let backgroundStyle: InfoCardBackgroundStyle
    let content: Content
    
    // MARK: - Initializers
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        accentColor: Color = HealthColors.primary,
        backgroundStyle: InfoCardBackgroundStyle = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
        self.backgroundStyle = backgroundStyle
        self.content = content()
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Header
            headerSection
            
            // Divider
            Divider()
                .background(HealthColors.border)
            
            // Content
            content
        }
        .cardPadding()
        .background(backgroundStyle.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
        .overlay(
            RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                .stroke(backgroundStyle.borderColor, lineWidth: backgroundStyle.borderWidth)
        )
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: HealthSpacing.sm) {
            // Icon if provided
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(accentColor)
                    .frame(width: 28, height: 28)
            }
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Background Styles
enum InfoCardBackgroundStyle {
    case standard
    case highlighted
    case warning
    case success
    case info
    case custom(backgroundColor: Color, borderColor: Color, borderWidth: CGFloat)
    
    var backgroundColor: Color {
        switch self {
        case .standard:
            return HealthColors.primaryBackground
        case .highlighted:
            return HealthColors.accent.opacity(0.05)
        case .warning:
            return Color.orange.opacity(0.05)
        case .success:
            return HealthColors.healthGood.opacity(0.05)
        case .info:
            return Color.blue.opacity(0.05)
        case .custom(let backgroundColor, _, _):
            return backgroundColor
        }
    }
    
    var borderColor: Color {
        switch self {
        case .standard, .highlighted:
            return Color.clear
        case .warning:
            return Color.orange.opacity(0.2)
        case .success:
            return HealthColors.healthGood.opacity(0.2)
        case .info:
            return Color.blue.opacity(0.2)
        case .custom(_, let borderColor, _):
            return borderColor
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .standard, .highlighted:
            return 0
        case .warning, .success, .info:
            return 1
        case .custom(_, _, let borderWidth):
            return borderWidth
        }
    }
}

// MARK: - Info List Component
/// Component for displaying bullet point lists within InfoCard
struct InfoList: View {
    let items: [String]
    let bulletColor: Color
    let textColor: Color
    
    init(
        items: [String],
        bulletColor: Color = HealthColors.primary,
        textColor: Color = HealthColors.primaryText
    ) {
        self.items = items
        self.bulletColor = bulletColor
        self.textColor = textColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: HealthSpacing.sm) {
                    Text("•")
                        .healthTextStyle(.body, color: bulletColor)
                        .frame(width: 12, alignment: .leading)
                    
                    Text(item)
                        .healthTextStyle(.body, color: textColor)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
}

// MARK: - Info Category Component
/// Component for displaying categorized information within InfoCard
struct InfoCategory: View {
    let category: InfoCategoryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Category header
            HStack(spacing: HealthSpacing.sm) {
                if let icon = category.icon {
                    Text(icon)
                        .font(.system(size: 20))
                }
                
                Text(category.title)
                    .healthTextStyle(.bodyMedium, color: category.color ?? HealthColors.primaryText)
            }
            
            // Category items
            if !category.items.isEmpty {
                InfoList(
                    items: category.items,
                    bulletColor: category.color ?? HealthColors.secondaryText,
                    textColor: HealthColors.primaryText
                )
                .padding(.leading, HealthSpacing.xl)
            }
        }
    }
}

// MARK: - Info Category Model
struct InfoCategoryModel: Identifiable, Sendable {
    let id = UUID()
    let icon: String?
    let title: String
    let items: [String]
    let color: Color?
    
    init(
        icon: String? = nil,
        title: String,
        items: [String] = [],
        color: Color? = nil
    ) {
        self.icon = icon
        self.title = title
        self.items = items
        self.color = color
    }
}

// MARK: - Specialized Info Cards

// Tips Card
struct TipsInfoCard: View {
    let tips: [String]
    
    var body: some View {
        InfoCard(
            title: "💡 Pro Tips",
            icon: "lightbulb.fill",
            accentColor: .orange,
            backgroundStyle: .warning
        ) {
            InfoList(items: tips, bulletColor: .orange)
        }
    }
}

// Warnings Card
struct WarningsInfoCard: View {
    let warnings: [String]
    
    var body: some View {
        InfoCard(
            title: "Important",
            icon: "exclamationmark.triangle.fill",
            accentColor: .red,
            backgroundStyle: .custom(
                backgroundColor: Color.red.opacity(0.05),
                borderColor: Color.red.opacity(0.2),
                borderWidth: 1
            )
        ) {
            InfoList(items: warnings, bulletColor: .red)
        }
    }
}

// Categories Card
struct CategoriesInfoCard: View {
    let categories: [InfoCategoryModel]
    
    var body: some View {
        InfoCard(
            title: "Categories",
            icon: "list.bullet.rectangle",
            accentColor: HealthColors.primary
        ) {
            VStack(spacing: HealthSpacing.lg) {
                ForEach(categories) { category in
                    InfoCategory(category: category)
                }
            }
        }
    }
}

// MARK: - Preview
// Preview removed to avoid compilation issues