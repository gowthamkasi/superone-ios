import SwiftUI

/// Reusable collapsible section component for test details
struct CollapsibleSection: View {
    
    // MARK: - Properties
    let section: TestSection
    private let onToggle: ((UUID) -> Void)?
    
    // MARK: - Animation Properties
    @State private var animationRotation: Double = 0
    @State private var contentHeight: CGFloat = 0
    
    // MARK: - Initialization
    init(section: TestSection, onToggle: ((UUID) -> Void)? = nil) {
        self.section = section
        self.onToggle = onToggle
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header with toggle
            headerView
            
            // Collapsible content
            if section.isExpanded {
                contentView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
        .onChange(of: section.isExpanded) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                animationRotation = newValue ? 90 : 0
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                onToggle?(section.id)
            }
        } label: {
            HStack(spacing: HealthSpacing.md) {
                // Section icon
                Image(systemName: section.type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 28, height: 28)
                
                // Title
                Text(section.title)
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HealthColors.secondaryText)
                    .rotationEffect(.degrees(animationRotation))
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.primaryBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(label: Text("\(section.title), \(section.isExpanded ? "expanded" : "collapsed")"))
        .accessibility(hint: Text("Tap to \(section.isExpanded ? "collapse" : "expand")"))
        .accessibility(addTraits: .isButton)
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Divider
            Divider()
                .background(HealthColors.border)
                .padding(.horizontal, HealthSpacing.lg)
            
            // Section content
            VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                // Overview text
                if let overview = section.content.overview, !overview.isEmpty {
                    Text(overview)
                        .healthTextStyle(.body, color: HealthColors.primaryText)
                        .padding(.horizontal, HealthSpacing.lg)
                }
                
                // Bullet points
                if !section.content.bulletPoints.isEmpty {
                    bulletPointsView
                }
                
                // Categories
                if !section.content.categories.isEmpty {
                    categoriesView
                }
                
                // Tips section
                if !section.content.tips.isEmpty {
                    tipsView
                }
                
                // Warnings section
                if !section.content.warnings.isEmpty {
                    warningsView
                }
            }
            .padding(.bottom, HealthSpacing.lg)
        }
    }
    
    // MARK: - Content Sections
    
    private var bulletPointsView: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            ForEach(section.content.bulletPoints, id: \.self) { point in
                HStack(alignment: .top, spacing: HealthSpacing.sm) {
                    Text("•")
                        .healthTextStyle(.body, color: HealthColors.primary)
                        .frame(width: 12, alignment: .leading)
                    
                    Text(point)
                        .healthTextStyle(.body, color: HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, HealthSpacing.lg)
            }
        }
    }
    
    private var categoriesView: some View {
        VStack(spacing: HealthSpacing.lg) {
            ForEach(section.content.categories) { category in
                CategoryView(category: category)
            }
        }
        .padding(.horizontal, HealthSpacing.lg)
    }
    
    private var tipsView: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                Text("💡 Pro Tips:")
                    .healthTextStyle(.bodyMedium, color: HealthColors.primaryText)
            }
            .padding(.horizontal, HealthSpacing.lg)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                ForEach(section.content.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: HealthSpacing.sm) {
                        Text("•")
                            .healthTextStyle(.body, color: .orange)
                            .frame(width: 12, alignment: .leading)
                        
                        Text(tip)
                            .healthTextStyle(.body, color: HealthColors.primaryText)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, HealthSpacing.lg)
                }
            }
        }
        .padding(.vertical, HealthSpacing.sm)
        .background(Color.orange.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.md))
    }
    
    private var warningsView: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
                
                Text("Important:")
                    .healthTextStyle(.bodyMedium, color: HealthColors.primaryText)
            }
            .padding(.horizontal, HealthSpacing.lg)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                ForEach(section.content.warnings, id: \.self) { warning in
                    HStack(alignment: .top, spacing: HealthSpacing.sm) {
                        Text("•")
                            .healthTextStyle(.body, color: .red)
                            .frame(width: 12, alignment: .leading)
                        
                        Text(warning)
                            .healthTextStyle(.body, color: HealthColors.primaryText)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, HealthSpacing.lg)
                }
            }
        }
        .padding(.vertical, HealthSpacing.sm)
        .background(Color.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.md))
    }
}

// MARK: - Category View Component

private struct CategoryView: View {
    let category: ContentCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Category header
            HStack(spacing: HealthSpacing.sm) {
                Text(category.icon)
                    .font(.system(size: 20))
                
                Text(category.title)
                    .healthTextStyle(.bodyMedium, color: category.color ?? HealthColors.primaryText)
            }
            
            // Category items
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                ForEach(category.items, id: \.self) { item in
                    HStack(alignment: .top, spacing: HealthSpacing.sm) {
                        Text("•")
                            .healthTextStyle(.body, color: category.color ?? HealthColors.secondaryText)
                            .frame(width: 12, alignment: .leading)
                        
                        Text(item)
                            .healthTextStyle(.body, color: HealthColors.primaryText)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(.leading, HealthSpacing.xl)
        }
        .padding(.vertical, HealthSpacing.sm)
    }
}

// MARK: - Previews

struct CollapsibleSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: HealthSpacing.lg) {
                // Collapsed section
                CollapsibleSection(
                    section: TestSection(
                        type: .about,
                        title: "About Complete Blood Count (CBC)",
                        content: TestSectionContent(
                            overview: "A Complete Blood Count (CBC) is one of the most common blood tests that evaluates your overall health and detects various disorders.",
                            bulletPoints: [
                                "Red Blood Cells (RBC) - Oxygen carriers",
                                "White Blood Cells (WBC) - Infection fighters",
                                "Platelets - Blood clotting helpers"
                            ]
                        ),
                        isExpanded: false
                    )
                )
                
                // Expanded section with categories
                CollapsibleSection(
                    section: TestSection(
                        type: .whyNeeded,
                        title: "Why You Might Need This Test",
                        content: TestSectionContent(
                            overview: "Common reasons for CBC testing:",
                            categories: [
                                ContentCategory(
                                    icon: "🔍",
                                    title: "Routine Health Checkup",
                                    items: [
                                        "Annual physical examination",
                                        "Preventive health screening"
                                    ]
                                ),
                                ContentCategory(
                                    icon: "🤒",
                                    title: "Symptoms Investigation",
                                    items: [
                                        "Unexplained fatigue or weakness",
                                        "Frequent infections"
                                    ]
                                )
                            ]
                        ),
                        isExpanded: true
                    )
                )
                
                // Section with tips
                CollapsibleSection(
                    section: TestSection(
                        type: .preparation,
                        title: "Preparation Instructions",
                        content: TestSectionContent(
                            overview: "Follow these instructions for accurate results:",
                            categories: [
                                ContentCategory(
                                    icon: "💧",
                                    title: "What You CAN Have",
                                    items: [
                                        "✅ Plain water (stay hydrated)",
                                        "✅ Essential medications (consult doctor)"
                                    ],
                                    color: HealthColors.healthGood
                                )
                            ],
                            tips: [
                                "Schedule morning appointments",
                                "Get plenty of sleep night before",
                                "Wear comfortable, loose-sleeved clothing"
                            ]
                        ),
                        isExpanded: true
                    )
                )
            }
            .padding(HealthSpacing.lg)
        }
        .background(HealthColors.secondaryBackground)
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode")
        
        ScrollView {
            VStack(spacing: HealthSpacing.lg) {
                CollapsibleSection(
                    section: TestSection(
                        type: .insights,
                        title: "Health Insights & Benefits",
                        content: TestSectionContent(
                            overview: "What this test can reveal:",
                            categories: [
                                ContentCategory(
                                    icon: "🩸",
                                    title: "Blood Health Status",
                                    items: [
                                        "Anemia detection (iron deficiency)",
                                        "Blood volume and circulation health"
                                    ]
                                )
                            ]
                        ),
                        isExpanded: true
                    )
                )
            }
            .padding(HealthSpacing.lg)
        }
        .background(HealthColors.secondaryBackground)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}