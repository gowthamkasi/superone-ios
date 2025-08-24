import SwiftUI
import Foundation

/// Reusable card component for displaying overview sections with icon, title, and details grid
/// Optimized for health-related information display with consistent styling
@MainActor
struct DetailsOverviewCard<Content: View>: View {
    
    // MARK: - Properties
    let icon: String
    let title: String
    let subtitle: String?
    let iconBackgroundColor: Color
    let customContent: Content?
    
    // MARK: - Initializers
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconBackgroundColor: Color = HealthColors.primary.opacity(0.1),
        @ViewBuilder customContent: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconBackgroundColor = iconBackgroundColor
        self.customContent = customContent()
    }
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconBackgroundColor: Color = HealthColors.primary.opacity(0.1)
    ) where Content == EmptyView {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconBackgroundColor = iconBackgroundColor
        self.customContent = nil
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.lg) {
            // Header section
            headerSection
            
            // Custom content if provided
            if let customContent = customContent {
                customContent
            }
        }
        .cardPadding()
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: HealthSpacing.md) {
            // Icon
            iconView
            
            // Title and subtitle
            titleSection
            
            Spacer()
        }
    }
    
    // MARK: - Icon View
    private var iconView: some View {
        Text(icon)
            .font(.system(size: 32))
            .frame(width: 50, height: 50)
            .background(iconBackgroundColor)
            .clipShape(Circle())
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .healthTextStyle(.title2, color: HealthColors.primaryText)
                .multilineTextAlignment(.leading)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .healthTextStyle(.caption1, color: HealthColors.secondaryText)
            }
        }
    }
}

// MARK: - Detail Item Component
/// Individual detail item for use within DetailsOverviewCard
struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let originalValue: String?
    let fullWidth: Bool
    
    init(
        icon: String,
        title: String,
        value: String,
        color: Color,
        originalValue: String? = nil,
        fullWidth: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.originalValue = originalValue
        self.fullWidth = fullWidth
    }
    
    var body: some View {
        HStack(spacing: HealthSpacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 4) {
                    Text(value)
                        .healthTextStyle(.subheadline, color: HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    if let originalValue = originalValue {
                        Text(originalValue)
                            .healthTextStyle(.caption1, color: HealthColors.tertiaryText)
                            .strikethrough()
                    }
                    
                    Spacer()
                }
            }
            
            if !fullWidth {
                Spacer()
            }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .padding(HealthSpacing.sm)
        .background(HealthColors.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.md))
    }
}

// MARK: - Details Grid Component
/// Grid layout for displaying multiple detail items
struct DetailsGrid: View {
    let items: [DetailGridItem]
    let columns: Int
    
    init(items: [DetailGridItem], columns: Int = 2) {
        self.items = items
        self.columns = columns
    }
    
    var body: some View {
        VStack(spacing: HealthSpacing.sm) {
            ForEach(Array(items.chunked(into: columns)), id: \.self) { rowItems in
                HStack(spacing: HealthSpacing.md) {
                    ForEach(rowItems, id: \.id) { item in
                        DetailItem(
                            icon: item.icon,
                            title: item.title,
                            value: item.value,
                            color: item.color,
                            originalValue: item.originalValue,
                            fullWidth: rowItems.count == 1
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

// MARK: - Detail Grid Item
struct DetailGridItem: Hashable, Identifiable, Sendable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let color: Color
    let originalValue: String?
    
    init(
        icon: String,
        title: String,
        value: String,
        color: Color,
        originalValue: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.originalValue = originalValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DetailGridItem, rhs: DetailGridItem) -> Bool {
        lhs.id == rhs.id
    }
}


// MARK: - Preview
// Preview removed to avoid compilation issues