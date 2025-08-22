import SwiftUI

/// Health package card for displaying individual health test packages
/// Uses animation and follows the existing design system
struct HealthPackageCard: View {
    let package: HealthPackage
    let onSelect: () -> Void
    
    @State private var isVisible: Bool = false
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            onSelect()
        }) {
            VStack(spacing: HealthSpacing.lg) {
                // Header section with category badge and popular indicator
                HStack {
                    // Category badge
                    CategoryBadge(category: package.category)
                        .opacity(isVisible ? 1 : 0)
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.2), value: isVisible)
                    
                    Spacer()
                    
                    // Popular indicator
                    if package.isPopular {
                        PopularBadge()
                            .opacity(isVisible ? 1 : 0)
                            .scaleEffect(isVisible ? 1.0 : 0.8)
                            .animation(.spring(duration: 0.6, bounce: 0.4).delay(0.3), value: isVisible)
                    }
                }
                
                // Package content section
                VStack(spacing: HealthSpacing.md) {
                    // Package name
                    Text(package.name)
                        .font(HealthTypography.headingSmall)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.4), value: isVisible)
                    
                    // Description
                    Text(package.description)
                        .font(HealthTypography.bodyRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 8)
                        .animation(.easeOut(duration: 0.4).delay(0.5), value: isVisible)
                    
                    // Test count indicator
                    TestCountIndicator(count: package.testCount)
                        .opacity(isVisible ? 1 : 0)
                        .scaleEffect(isVisible ? 1.0 : 0.9)
                        .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.6), value: isVisible)
                    
                    // Price display
                    PriceDisplay(
                        price: package.price,
                        originalPrice: package.originalPrice,
                        currency: package.currency
                    )
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1.0 : 0.9)
                    .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.7), value: isVisible)
                }
                
                Spacer(minLength: HealthSpacing.md)
                
                // Select package button
                VStack(spacing: HealthSpacing.xs) {
                    HStack(spacing: HealthSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Select Package")
                            .font(HealthTypography.buttonSecondary)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: HealthSpacing.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .fill(buttonBackgroundGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .stroke(buttonBorderGradient, lineWidth: 1)
                    )
                    .shadow(
                        color: buttonShadowColor,
                        radius: 6,
                        x: 0,
                        y: 3
                    )
                    .scaleEffect(isVisible ? 1.0 : 0.9)
                    .opacity(isVisible ? 1.0 : 0)
                    .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.8), value: isVisible)
                }
            }
            .padding(HealthSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                    .fill(cardBackgroundGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                            .stroke(cardBorderColor, lineWidth: cardBorderWidth)
                    )
                    .healthCardShadow()
            )
            .scaleEffect(isVisible ? 1.0 : 0.95)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.1), value: isVisible)
        }
        .buttonStyle(HealthPackageCardButtonStyle())
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var cardBackgroundGradient: LinearGradient {
        if package.isPopular {
            return LinearGradient(
                colors: [
                    HealthColors.accent.opacity(0.1),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(.secondarySystemBackground),
                    Color(.tertiarySystemBackground).opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var cardBorderColor: Color {
        package.isPopular ? HealthColors.primary.opacity(0.3) : HealthColors.border.opacity(0.3)
    }
    
    private var cardBorderWidth: CGFloat {
        package.isPopular ? 1.5 : 0.5
    }
    
    private var buttonBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [HealthColors.primary, HealthColors.forest],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var buttonBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                HealthColors.primary.opacity(0.6),
                HealthColors.forest.opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var buttonShadowColor: Color {
        HealthColors.primary.opacity(0.25)
    }
}

// MARK: - Category Badge
struct CategoryBadge: View {
    let category: PackageCategory
    
    var body: some View {
        Text(category.rawValue.capitalized)
            .font(HealthTypography.captionMedium)
            .foregroundColor(categoryColor)
            .padding(.horizontal, HealthSpacing.sm)
            .padding(.vertical, HealthSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                    .fill(categoryColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                            .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                    )
            )
    }
    
    private var categoryColor: Color {
        switch category {
        case .basic:
            return HealthColors.healthNeutral
        case .premium:
            return HealthColors.primary
        case .complete:
            return HealthColors.forest
        case .specialty:
            return HealthColors.secondary
        }
    }
}

// MARK: - Popular Badge
struct PopularBadge: View {
    var body: some View {
        HStack(spacing: HealthSpacing.xs) {
            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            
            Text("Popular")
                .font(HealthTypography.captionMedium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, HealthSpacing.sm)
        .padding(.vertical, HealthSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                .fill(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(
            color: Color.orange.opacity(0.4),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Test Count Indicator
struct TestCountIndicator: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: HealthSpacing.xs) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(HealthColors.primary)
            
            Text("\(count) tests included")
                .font(HealthTypography.footnote)
                .foregroundColor(HealthColors.tertiaryText)
        }
        .padding(.horizontal, HealthSpacing.md)
        .padding(.vertical, HealthSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                .fill(HealthColors.accent.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                        .stroke(HealthColors.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Price Display
struct PriceDisplay: View {
    let price: Double
    let originalPrice: Double?
    let currency: String
    
    var body: some View {
        VStack(spacing: HealthSpacing.xs) {
            // Main price
            HStack(alignment: .firstTextBaseline, spacing: HealthSpacing.xs) {
                Text(currency)
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primary)
                
                Text(formatPrice(price))
                    .font(HealthTypography.healthMetricValue)
                    .foregroundColor(HealthColors.primary)
                    .monospacedDigit()
            }
            
            // Original price (if discounted)
            if let originalPrice = originalPrice, originalPrice > price {
                HStack(alignment: .firstTextBaseline, spacing: HealthSpacing.xs) {
                    Text("Was:")
                        .font(HealthTypography.caption1)
                        .foregroundColor(HealthColors.tertiaryText)
                    
                    Text("\(currency)\(formatPrice(originalPrice))")
                        .font(HealthTypography.footnote)
                        .foregroundColor(HealthColors.tertiaryText)
                        .strikethrough()
                    
                    // Savings badge
                    let savings = originalPrice - price
                    let savingsPercentage = Int((savings / originalPrice) * 100)
                    
                    Text("Save \(savingsPercentage)%")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.healthGood)
                        .padding(.horizontal, HealthSpacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(HealthColors.healthGood.opacity(0.1))
                        )
                }
            }
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}

// MARK: - Health Package Model
struct HealthPackage: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let originalPrice: Double?
    let currency: String
    let testCount: Int
    let category: PackageCategory
    let isPopular: Bool
    let features: [String]
    let estimatedDuration: String
    let sampleType: [String]
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        price: Double,
        originalPrice: Double? = nil,
        currency: String = "$",
        testCount: Int,
        category: PackageCategory,
        isPopular: Bool = false,
        features: [String] = [],
        estimatedDuration: String = "1-2 days",
        sampleType: [String] = ["Blood"]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.originalPrice = originalPrice
        self.currency = currency
        self.testCount = testCount
        self.category = category
        self.isPopular = isPopular
        self.features = features
        self.estimatedDuration = estimatedDuration
        self.sampleType = sampleType
    }
}

// MARK: - Package Category
enum PackageCategory: String, CaseIterable, Identifiable {
    case basic = "basic"
    case premium = "premium"
    case complete = "complete"
    case specialty = "specialty"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .basic: return "Basic"
        case .premium: return "Premium"
        case .complete: return "Complete"
        case .specialty: return "Specialty"
        }
    }
    
    var description: String {
        switch self {
        case .basic: return "Essential health markers"
        case .premium: return "Comprehensive analysis"
        case .complete: return "Full health assessment"
        case .specialty: return "Targeted testing"
        }
    }
}

// MARK: - Health Package Card Button Style
struct HealthPackageCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.2), value: configuration.isPressed)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                    .fill(Color.clear)
                    .contentShape(Rectangle())
            )
            .accessibilityAddTraits(.isButton)
    }
}


// MARK: - Sample Data for Development
extension HealthPackage {
    static let mockPackages: [HealthPackage] = [
        HealthPackage(
            name: "Essential Health Panel",
            description: "Basic health screening covering key biomarkers including cholesterol, glucose, and CBC",
            price: 149.99,
            testCount: 12,
            category: .basic,
            features: ["Complete Blood Count", "Lipid Panel", "Basic Metabolic Panel"],
            estimatedDuration: "1-2 days",
            sampleType: ["Blood"]
        ),
        HealthPackage(
            name: "Comprehensive Health Assessment",
            description: "Detailed analysis of cardiovascular, metabolic, and immune system health",
            price: 299.99,
            originalPrice: 349.99,
            testCount: 24,
            category: .premium,
            isPopular: true,
            features: ["Advanced Lipid Profile", "HbA1c", "Inflammatory Markers", "Vitamin D"],
            estimatedDuration: "2-3 days",
            sampleType: ["Blood", "Urine"]
        ),
        HealthPackage(
            name: "Complete Wellness Profile",
            description: "Full spectrum health evaluation including hormones, nutrients, and genetic markers",
            price: 499.99,
            originalPrice: 599.99,
            testCount: 40,
            category: .complete,
            features: ["Hormone Panel", "Nutritional Assessment", "Cardiac Risk", "Liver Function"],
            estimatedDuration: "3-5 days",
            sampleType: ["Blood", "Saliva", "Urine"]
        ),
        HealthPackage(
            name: "Heart Health Specialty",
            description: "Focused cardiovascular assessment with advanced cardiac biomarkers",
            price: 199.99,
            testCount: 15,
            category: .specialty,
            features: ["Advanced Lipid Profile", "Cardiac Enzymes", "Inflammation Markers"],
            estimatedDuration: "1-2 days",
            sampleType: ["Blood"]
        )
    ]
}

// MARK: - Preview
#Preview("Single Package - Popular") {
    HealthPackageCard(
        package: HealthPackage.mockPackages[1]
    ) {
        print("Package selected")
    }
    .padding()
    .background(HealthColors.background)
}

#Preview("Single Package - Basic") {
    HealthPackageCard(
        package: HealthPackage.mockPackages[0]
    ) {
        print("Package selected")
    }
    .padding()
    .background(HealthColors.background)
}

#Preview("Package Grid") {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: HealthSpacing.lg) {
        ForEach(HealthPackage.mockPackages) { package in
            HealthPackageCard(package: package) {
                print("Selected: \(package.name)")
            }
        }
    }
    .padding()
    .background(HealthColors.background)
}

#Preview("Dark Mode") {
    HealthPackageCard(
        package: HealthPackage.mockPackages[2]
    ) {
        print("Package selected")
    }
    .padding()
    .background(HealthColors.background)
    .preferredColorScheme(.dark)
}

#Preview("Compact Size") {
    ScrollView {
        VStack(spacing: HealthSpacing.md) {
            ForEach(HealthPackage.mockPackages) { package in
                HealthPackageCard(package: package) {
                    print("Selected: \(package.name)")
                }
            }
        }
        .padding(.horizontal, HealthSpacing.md)
    }
    .background(HealthColors.background)
}