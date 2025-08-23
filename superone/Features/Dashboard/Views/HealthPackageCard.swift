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
                    CategoryBadge(category: "Basic")
                        .opacity(isVisible ? 1 : 0)
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.5).delay(0.2), value: isVisible)
                    
                    Spacer()
                    
                    // Popular indicator
                    if package.isFeatured {
                        PopularBadge()
                            .opacity(isVisible ? 1 : 0)
                            .scaleEffect(isVisible ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.6).delay(0.3), value: isVisible)
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
                    TestCountIndicator(count: package.totalTests)
                        .opacity(isVisible ? 1 : 0)
                        .scaleEffect(isVisible ? 1.0 : 0.9)
                        .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.6), value: isVisible)
                    
                    // Price display
                    PriceDisplay(
                        price: Double(package.packagePrice),
                        originalPrice: Double(package.individualPrice),
                        currency: "₹"
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
            .animation(.easeInOut(duration: 0.5).delay(0.1), value: isVisible)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var cardBackgroundGradient: LinearGradient {
        if package.isFeatured {
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
        package.isFeatured ? HealthColors.primary.opacity(0.3) : HealthColors.border.opacity(0.3)
    }
    
    private var cardBorderWidth: CGFloat {
        package.isFeatured ? 1.5 : 0.5
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
    let category: String
    
    var body: some View {
        Text(category)
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
        switch category.lowercased() {
        case "basic":
            return HealthColors.primary
        case "premium":
            return HealthColors.emerald
        case "complete":
            return HealthColors.healthWarning
        case "specialty":
            return HealthColors.secondary
        default:
            return HealthColors.primary
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

// MARK: - Preview
#Preview("Health Package Card") {
    HealthPackageCard(
        package: HealthPackage.sampleComprehensive()
    ) {
        print("Package selected")
    }
    .padding()
    .background(HealthColors.background)
}