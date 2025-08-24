import SwiftUI
import Foundation

/// Collapsible version of InfoCard with toggle functionality
/// Designed for sections that need expand/collapse behavior
@MainActor
struct CollapsibleInfoCard<Content: View>: View {
    
    // MARK: - Properties
    let title: String
    let subtitle: String?
    let icon: String?
    let accentColor: Color
    let backgroundStyle: InfoCardBackgroundStyle
    let content: Content
    @State private var isExpanded: Bool
    
    // MARK: - Initializers
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        accentColor: Color = HealthColors.primary,
        backgroundStyle: InfoCardBackgroundStyle = .standard,
        isInitiallyExpanded: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
        self.backgroundStyle = backgroundStyle
        self._isExpanded = State(initialValue: isInitiallyExpanded)
        self.content = content()
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tappable header section
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                headerSection
            }
            .buttonStyle(.plain)
            
            // Collapsible content section
            if isExpanded {
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    Divider()
                        .background(HealthColors.border)
                    
                    content
                }
                .padding(.top, HealthSpacing.xs)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
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
            
            // Chevron toggle indicator
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(HealthColors.secondaryText)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
        }
        .contentShape(Rectangle()) // Make entire area tappable
    }
}

// MARK: - Helper Functions for Content Building
private struct CollapsibleContent {
    static func buildTextAndBulletContent(
        overview: String?,
        bulletPoints: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            if let overview = overview, !overview.isEmpty {
                Text(overview)
                    .healthTextStyle(.body, color: HealthColors.primaryText)
            }
            
            if !bulletPoints.isEmpty {
                InfoList(items: bulletPoints)
            }
        }
    }
}

// MARK: - Specialized Collapsible Info Cards

/// Collapsible About Section Card
struct AboutTestInfoCard: View {
    let overview: String?
    let bulletPoints: [String]
    let isInitiallyExpanded: Bool
    
    init(overview: String? = nil, bulletPoints: [String] = [], isInitiallyExpanded: Bool = false) {
        self.overview = overview
        self.bulletPoints = bulletPoints
        self.isInitiallyExpanded = isInitiallyExpanded
    }
    
    var body: some View {
        CollapsibleInfoCard(
            title: "About Complete Blood Count (CBC)",
            icon: "info.circle.fill",
            accentColor: HealthColors.primary,
            isInitiallyExpanded: isInitiallyExpanded
        ) {
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                if let overview = overview, !overview.isEmpty {
                    Text(overview)
                        .healthTextStyle(.body, color: HealthColors.primaryText)
                }
                
                if !bulletPoints.isEmpty {
                    InfoList(items: bulletPoints)
                }
            }
        }
    }
}

/// Collapsible Instructions Card
struct InstructionsInfoCard: View {
    let instructions: [String]
    let isInitiallyExpanded: Bool
    
    init(instructions: [String], isInitiallyExpanded: Bool = false) {
        self.instructions = instructions
        self.isInitiallyExpanded = isInitiallyExpanded
    }
    
    var body: some View {
        CollapsibleInfoCard(
            title: "Test Instructions",
            icon: "list.clipboard.fill",
            accentColor: .blue,
            backgroundStyle: .info,
            isInitiallyExpanded: isInitiallyExpanded
        ) {
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                if !instructions.isEmpty {
                    InfoList(items: instructions)
                }
            }
        }
    }
}

/// Collapsible Preparation Card
struct PreparationInfoCard: View {
    let preparations: [String]
    let isInitiallyExpanded: Bool
    
    init(preparations: [String], isInitiallyExpanded: Bool = false) {
        self.preparations = preparations
        self.isInitiallyExpanded = isInitiallyExpanded
    }
    
    var body: some View {
        CollapsibleInfoCard(
            title: "Test Preparation",
            icon: "checklist",
            accentColor: .orange,
            backgroundStyle: .warning,
            isInitiallyExpanded: isInitiallyExpanded
        ) {
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                if !preparations.isEmpty {
                    InfoList(items: preparations)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Collapsible Info Cards") {
    ScrollView {
        VStack(spacing: HealthSpacing.lg) {
            AboutTestInfoCard(
                overview: "A Complete Blood Count (CBC) is one of the most common blood tests that evaluates your overall health and detects various disorders.",
                bulletPoints: [
                    "Red Blood Cells (RBC) - Oxygen carriers",
                    "White Blood Cells (WBC) - Infection fighters", 
                    "Platelets - Blood clotting helpers",
                    "Hemoglobin - Oxygen-carrying protein",
                    "Hematocrit - Red blood cell percentage"
                ]
            )
            
            InstructionsInfoCard(
                instructions: [
                    "Fast for 12 hours before the test",
                    "Avoid alcohol 24 hours prior",
                    "Stay hydrated with water only",
                    "Take prescribed medications as usual",
                    "Arrive at lab with valid ID"
                ]
            )
            
            PreparationInfoCard(
                preparations: [
                    "Wear comfortable, loose-fitting clothing",
                    "Bring list of current medications", 
                    "Get adequate sleep the night before",
                    "Avoid strenuous exercise 24 hours prior"
                ]
            )
        }
        .padding(HealthSpacing.screenPadding)
    }
}