import SwiftUI

/// Featured health packages section with horizontal scrolling carousel
/// Replaces RecentActivitySection to showcase popular health packages
struct FeaturedPackagesSection: View {
    let packages: [HealthPackage]
    let onPackageSelect: (HealthPackage) -> Void
    let onSeeAllPackages: () -> Void
    let isLoading: Bool
    
    @State private var isVisible = false
    @State private var cardVisibilityStates: [String: Bool] = [:]
    
    init(
        packages: [HealthPackage] = [],
        isLoading: Bool = false,
        onPackageSelect: @escaping (HealthPackage) -> Void = { _ in },
        onSeeAllPackages: @escaping () -> Void = {}
    ) {
        self.packages = packages
        self.isLoading = isLoading
        self.onPackageSelect = onPackageSelect
        self.onSeeAllPackages = onSeeAllPackages
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Section Header
            sectionHeader
            
            // Packages Carousel or Loading/Empty States
            if isLoading {
                loadingState
            } else if packages.isEmpty {
                emptyState
            } else {
                packagesCarousel
            }
        }
        .onAppear {
            animateSection()
        }
    }
    
    // MARK: - Section Header
    
    private var sectionHeader: some View {
        HStack {
            Text("Popular Health Packages")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
                .opacity(isVisible ? 1 : 0)
                .offset(x: isVisible ? 0 : -20)
                .animation(.easeInOut(duration: 0.5).delay(0.1), value: isVisible)
            
            Spacer()
            
            Button("See All Packages") {
                HapticFeedback.light()
                onSeeAllPackages()
            }
            .font(HealthTypography.caption1)
            .foregroundColor(HealthColors.primary)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.5).delay(0.2), value: isVisible)
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Packages Carousel
    
    private var packagesCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: HealthSpacing.lg) {
                // Leading padding for first card
                Color.clear
                    .frame(width: HealthSpacing.screenPadding - HealthSpacing.lg)
                
                ForEach(Array(packages.enumerated()), id: \.element.id) { index, package in
                    PackageCarouselCard(
                        package: package,
                        isVisible: cardVisibilityStates[package.id] ?? false,
                        onSelect: {
                            HapticFeedback.medium()
                            onPackageSelect(package)
                        }
                    )
                    .onAppear {
                        // Staggered animation for each card
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                                cardVisibilityStates[package.id] = true
                            }
                        }
                    }
                }
                
                // Trailing padding for last card
                Color.clear
                    .frame(width: HealthSpacing.screenPadding - HealthSpacing.lg)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollClipDisabled()
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3).delay(0.3), value: isVisible)
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: HealthSpacing.lg) {
                // Leading padding
                Color.clear
                    .frame(width: HealthSpacing.screenPadding - HealthSpacing.lg)
                
                ForEach(0..<3, id: \.self) { _ in
                    PackageSkeletonCard()
                }
                
                // Trailing padding
                Color.clear
                    .frame(width: HealthSpacing.screenPadding - HealthSpacing.lg)
            }
        }
        .scrollClipDisabled()
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(HealthColors.secondaryText.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 18))
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                // Content
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text("No Packages Available")
                        .font(HealthTypography.subheadline)
                        .foregroundColor(HealthColors.secondaryText)
                    
                    Text("Health packages will appear here when available")
                        .font(HealthTypography.caption1)
                        .foregroundColor(HealthColors.tertiaryText)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.vertical, HealthSpacing.sm)
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3).delay(0.2), value: isVisible)
    }
    
    // MARK: - Animation Methods
    
    private func animateSection() {
        isVisible = true
        
        // Initialize all cards as not visible initially
        for package in packages {
            cardVisibilityStates[package.id] = false
        }
    }
}

// MARK: - Package Carousel Card

/// Compact version of HealthPackageCard optimized for carousel display
struct PackageCarouselCard: View {
    let package: HealthPackage
    let isVisible: Bool
    let onSelect: () -> Void
    
    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 320
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: HealthSpacing.md) {
                // Header with category and popular badge
                HStack {
                    CategoryBadge(category: package.category)
                    
                    Spacer()
                    
                    if package.isPopular {
                        PopularBadge()
                    }
                }
                
                // Package content
                VStack(spacing: HealthSpacing.sm) {
                    // Package name
                    Text(package.name)
                        .font(HealthTypography.headingSmall)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                    
                    // Description
                    Text(package.description)
                        .font(HealthTypography.caption1)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                    
                    // Test count
                    HStack(spacing: HealthSpacing.xs) {
                        Image(systemName: "list.clipboard.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(HealthColors.primary)
                        
                        Text("\(package.totalTests) tests")
                            .font(HealthTypography.caption1)
                            .foregroundColor(HealthColors.tertiaryText)
                    }
                    .padding(.horizontal, HealthSpacing.sm)
                    .padding(.vertical, HealthSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                            .fill(HealthColors.accent.opacity(0.1))
                    )
                }
                
                Spacer()
                
                // Price and select button
                VStack(spacing: HealthSpacing.sm) {
                    // Price display
                    HStack(alignment: .firstTextBaseline, spacing: HealthSpacing.xs) {
                        Text(package.currency)
                            .font(HealthTypography.caption1)
                            .foregroundColor(HealthColors.primary)
                        
                        Text(formatPrice(package.price))
                            .font(HealthTypography.headingSmall)
                            .foregroundColor(HealthColors.primary)
                            .monospacedDigit()
                        
                        if let originalPrice = package.originalPrice, originalPrice > package.price {
                            Text("\(package.currency)\(formatPrice(originalPrice))")
                                .font(HealthTypography.caption2)
                                .foregroundColor(HealthColors.tertiaryText)
                                .strikethrough()
                        }
                    }
                    
                    // Select button
                    HStack(spacing: HealthSpacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Select")
                            .font(HealthTypography.buttonSmall)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .fill(
                                LinearGradient(
                                    colors: [HealthColors.primary, HealthColors.forest],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(
                        color: HealthColors.primary.opacity(0.25),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                }
            }
            .padding(HealthSpacing.lg)
            .frame(width: cardWidth, height: cardHeight)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                    .fill(cardBackgroundGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                            .stroke(cardBorderColor, lineWidth: cardBorderWidth)
                    )
                    .healthCardShadow()
            )
        }
        .buttonStyle(CarouselCardButtonStyle())
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(duration: 0.5, bounce: 0.2), value: isVisible)
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
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}

// MARK: - Package Skeleton Card

/// Loading skeleton for package cards
struct PackageSkeletonCard: View {
    @State private var shimmerOffset: CGFloat = -200
    
    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 320
    
    var body: some View {
        VStack(spacing: HealthSpacing.md) {
            // Header skeletons
            HStack {
                RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                    .fill(shimmerGradient)
                    .frame(width: 60, height: 20)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                    .fill(shimmerGradient)
                    .frame(width: 50, height: 20)
            }
            
            // Content skeletons
            VStack(spacing: HealthSpacing.sm) {
                // Title skeleton
                RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                    .fill(shimmerGradient)
                    .frame(height: 20)
                
                RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                    .fill(shimmerGradient)
                    .frame(width: 150, height: 20)
                
                // Description skeletons
                VStack(spacing: HealthSpacing.xs) {
                    RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                        .fill(shimmerGradient)
                        .frame(height: 14)
                    
                    RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                        .fill(shimmerGradient)
                        .frame(height: 14)
                    
                    RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                        .fill(shimmerGradient)
                        .frame(width: 120, height: 14)
                }
                
                // Test count skeleton
                RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                    .fill(shimmerGradient)
                    .frame(width: 80, height: 24)
            }
            
            Spacer()
            
            // Bottom section skeletons
            VStack(spacing: HealthSpacing.sm) {
                // Price skeleton
                RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                    .fill(shimmerGradient)
                    .frame(width: 100, height: 18)
                
                // Button skeleton
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .fill(shimmerGradient)
                    .frame(height: 36)
            }
        }
        .padding(HealthSpacing.lg)
        .frame(width: cardWidth, height: cardHeight)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                .fill(Color(.secondarySystemBackground))
                .healthCardShadow()
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.tertiarySystemFill),
                Color(.quaternarySystemFill),
                Color(.tertiarySystemFill)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Carousel Card Button Style

struct CarouselCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.1), value: configuration.isPressed)
    }
}


// MARK: - Preview

#Preview("Featured Packages Section") {
    ScrollView {
        VStack(spacing: HealthSpacing.sectionSpacing) {
            FeaturedPackagesSection(
                packages: [HealthPackage.sampleComprehensive()],
                isLoading: false,
                onPackageSelect: { package in
                    print("Selected package: \(package.name)")
                },
                onSeeAllPackages: {
                    print("See all packages tapped")
                }
            )
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
        .padding(.top, HealthSpacing.md)
    }
    .background(HealthColors.background)
}

#Preview("Loading State") {
    ScrollView {
        VStack(spacing: HealthSpacing.sectionSpacing) {
            FeaturedPackagesSection(
                packages: [],
                isLoading: true
            )
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
        .padding(.top, HealthSpacing.md)
    }
    .background(HealthColors.background)
}

#Preview("Empty State") {
    ScrollView {
        VStack(spacing: HealthSpacing.sectionSpacing) {
            FeaturedPackagesSection(
                packages: [],
                isLoading: false
            )
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
        .padding(.top, HealthSpacing.md)
    }
    .background(HealthColors.background)
}

#Preview("Dark Mode") {
    ScrollView {
        VStack(spacing: HealthSpacing.sectionSpacing) {
            FeaturedPackagesSection(
                packages: [HealthPackage.sampleComprehensive()],
                isLoading: false
            )
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
        .padding(.top, HealthSpacing.md)
    }
    .background(HealthColors.background)
    .preferredColorScheme(.dark)
}