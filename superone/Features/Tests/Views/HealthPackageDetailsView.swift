import SwiftUI

// MARK: - View Extensions for Typography
extension View {
    /// Apply health text style with weight support
    func healthTextStyle(
        _ style: TypographyStyle,
        color: Color = HealthColors.primaryText,
        weight: Font.Weight = .regular,
        alignment: TextAlignment = .leading
    ) -> some View {
        self.font(style.font.weight(weight))
            .foregroundColor(color)
            .multilineTextAlignment(alignment)
    }
}

/// Comprehensive health package details view based on wireframe specification
/// Features complete package information, pricing, tests, labs, and booking flow
struct HealthPackageDetailsView: View {
    
    // MARK: - Properties
    let package: HealthPackage
    @State private var packageState: HealthPackageState
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToBooking = false
    @State private var showShareSheet = false
    @State private var showCustomizeSheet = false
    @State private var showComparePackages = false
    @State private var selectedLab: LabFacility?
    
    // MARK: - Initialization
    init(package: HealthPackage) {
        self.package = package
        self._packageState = State(initialValue: HealthPackageState(package: package))
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Main scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with navigation
                        headerSection
                        
                        // Package overview
                        packageOverviewSection
                            .padding(.top, HealthSpacing.lg)
                        
                        // Main content sections
                        VStack(spacing: HealthSpacing.xl) {
                            testsIncludedSection
                            whoShouldTakeSection
                            healthInsightsSection
                            preparationInstructionsSection
                            availableLabsSection
                            packageVariantsSection
                            customerReviewsSection
                            faqSection
                        }
                        .padding(.top, HealthSpacing.xl)
                        .padding(.horizontal, HealthSpacing.screenPadding)
                        
                        // Bottom spacing for fixed action bar
                        Spacer()
                            .frame(height: 120)
                    }
                }
                .background(HealthColors.secondaryBackground.ignoresSafeArea())
                
                // Fixed bottom action bar
                bottomActionBar(safeAreaBottom: geometry.safeAreaInsets.bottom)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareText])
        }
        .sheet(isPresented: $showCustomizeSheet) {
            CustomizePackageSheet(package: package)
        }
        .sheet(isPresented: $showComparePackages) {
            ComparePackagesSheet(currentPackage: package)
        }
        .navigationDestination(isPresented: $navigateToBooking) {
            TestBookingDateTimeView(testDetails: nil)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        ZStack(alignment: .topLeading) {
            // Background gradient
            LinearGradient(
                colors: [
                    HealthColors.primary.opacity(0.1),
                    HealthColors.secondaryBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            
            // Header content
            VStack(spacing: 0) {
                // Status bar spacer
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 44)
                
                // Navigation and actions
                HStack {
                    // Back button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(HealthColors.primaryText)
                            .frame(width: 44, height: 44)
                            .background(HealthColors.primaryBackground)
                            .clipShape(Circle())
                            .healthCardShadow()
                    }
                    
                    // Title
                    Text(package.name)
                        .healthTextStyle(.title3, color: HealthColors.primaryText)
                        .lineLimit(1)
                        .padding(.horizontal, HealthSpacing.md)
                    
                    Spacer()
                    
                    // Heart (save) button
                    Button {
                        packageState.toggleSaved()
                    } label: {
                        Image(systemName: packageState.isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(packageState.isSaved ? .red : HealthColors.secondaryText)
                            .frame(width: 44, height: 44)
                    }
                    
                    // Share button
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(HealthColors.secondaryText)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
            }
        }
    }
    
    // MARK: - Package Overview Section
    private var packageOverviewSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Package header
            VStack(spacing: HealthSpacing.sm) {
                Text(package.icon)
                    .font(.system(size: 40))
                
                Text(package.name)
                    .healthTextStyle(.title2, color: HealthColors.primaryText, weight: .bold)
                    .multilineTextAlignment(.center)
                
                Text(package.description)
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HealthSpacing.lg)
            }
            
            // Package stats
            HStack(spacing: HealthSpacing.lg) {
                statItem(icon: "⏱️", title: "Duration", value: package.duration)
                statItem(icon: "📋", title: "Tests", value: "\(package.totalTests) Tests Included")
                statItem(icon: "🍽️", title: "Fasting", value: package.fastingRequirement.displayText)
                statItem(icon: "📊", title: "Report", value: package.reportTime)
            }
            .padding(.horizontal, HealthSpacing.md)
            
            // Pricing card
            pricingCard
            
            // Action buttons
            actionButtons
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    private func statItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: HealthSpacing.xs) {
            Text(icon)
                .font(.system(size: 20))
            
            Text(title)
                .healthTextStyle(.captionRegular, color: HealthColors.secondaryText)
            
            Text(value)
                .healthTextStyle(.caption2, color: HealthColors.primaryText, weight: .medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var pricingCard: some View {
        VStack(spacing: HealthSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text("💰 Package Price: \(package.formattedPrice)")
                        .healthTextStyle(.body, color: HealthColors.primaryText, weight: .bold)
                    
                    Text("Individual Cost: \(package.formattedOriginalPrice)")
                        .healthTextStyle(.body, color: HealthColors.secondaryText)
                        .strikethrough()
                    
                    Text("💡 You Save: \(package.formattedSavings) (\(package.discountPercentage)% off)")
                        .healthTextStyle(.body, color: HealthColors.healthExcellent, weight: .semibold)
                }
                Spacer()
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.primaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(HealthColors.primary.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .healthCardShadow()
    }
    
    private var actionButtons: some View {
        VStack(spacing: HealthSpacing.md) {
            // Primary action button
            Button {
                navigateToBooking = true
            } label: {
                Text("Book This Package")
                    .healthTextStyle(.body, color: .white, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(HealthColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Secondary action buttons
            HStack(spacing: HealthSpacing.md) {
                Button {
                    showCustomizeSheet = true
                } label: {
                    Text("Customize")
                        .healthTextStyle(.body, color: HealthColors.primary, weight: .medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(HealthColors.primaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(HealthColors.primary, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button {
                    showComparePackages = true
                } label: {
                    Text("Compare Packages")
                        .healthTextStyle(.body, color: HealthColors.primary, weight: .medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(HealthColors.primaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(HealthColors.primary, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    // MARK: - Tests Included Section
    private var testsIncludedSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("📋 Tests Included (\(package.totalTests))")
                .healthTextStyle(.title3, color: HealthColors.primaryText, weight: .bold)
            
            ForEach(package.testCategories) { category in
                testCategoryCard(category)
            }
            
            // Additional action buttons
            HStack(spacing: HealthSpacing.md) {
                actionButton("View All Test Details", systemImage: "doc.text")
                actionButton("What Each Test Checks", systemImage: "questionmark.circle")
            }
        }
    }
    
    private func testCategoryCard(_ category: HealthTestCategory) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Category header
            Button {
                packageState.toggleTestCategory(withId: category.id)
            } label: {
                HStack {
                    Text("\(category.icon) \(category.name) (\(category.testCount) tests)")
                        .healthTextStyle(.body, color: HealthColors.primaryText, weight: .semibold)
                    
                    Spacer()
                    
                    Image(systemName: packageState.isTestCategoryExpanded(category.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            // Expandable test list
            if packageState.isTestCategoryExpanded(category.id) {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    ForEach(category.tests) { test in
                        HStack {
                            Text("•")
                                .foregroundColor(category.color ?? HealthColors.primary)
                            Text(test.name)
                                .healthTextStyle(.body, color: HealthColors.primaryText)
                        }
                        .padding(.leading, HealthSpacing.sm)
                    }
                }
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .healthCardShadow()
    }
    
    // MARK: - Who Should Take Section
    private var whoShouldTakeSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("🎯 Recommended For")
                .healthTextStyle(.title3, color: HealthColors.primaryText, weight: .bold)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                ForEach(package.recommendedFor, id: \.self) { recommendation in
                    HStack(alignment: .top) {
                        Text("✅")
                        Text(recommendation)
                            .healthTextStyle(.body, color: HealthColors.primaryText)
                    }
                }
            }
            .padding(HealthSpacing.md)
            .background(HealthColors.healthExcellent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("🚫 Not suitable for:")
                .healthTextStyle(.body, color: HealthColors.primaryText, weight: .semibold)
                .padding(.top, HealthSpacing.sm)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                ForEach(package.notSuitableFor, id: \.self) { restriction in
                    HStack(alignment: .top) {
                        Text("•")
                            .foregroundColor(.red)
                        Text(restriction)
                            .healthTextStyle(.body, color: HealthColors.primaryText)
                    }
                }
            }
            .padding(HealthSpacing.md)
            .background(HealthColors.healthCritical.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Health Insights Section
    private var healthInsightsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("📊 Health Insights & Benefits")
                .healthTextStyle(.title3, color: HealthColors.primaryText, weight: .bold)
            
            insightCategory("Early Detection:", items: package.healthInsights.earlyDetection)
            insightCategory("Health Monitoring:", items: package.healthInsights.healthMonitoring)
            insightCategory("AI-Powered Analysis:", items: package.healthInsights.aiPoweredAnalysis)
            
            HStack(spacing: HealthSpacing.md) {
                actionButton("Sample Health Report", systemImage: "doc.text")
                actionButton("AI Analysis Demo", systemImage: "brain")
            }
        }
    }
    
    private func insightCategory(_ title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            Text(title)
                .healthTextStyle(.body, color: HealthColors.primaryText, weight: .semibold)
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(HealthColors.primary)
                    Text(item)
                        .healthTextStyle(.body, color: HealthColors.primaryText)
                }
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Preparation Instructions Section
    private var preparationInstructionsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("📝 Preparation Guide")
                .healthTextStyle(.title3, color: HealthColors.primaryText, weight: .bold)
            
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                Text("🍽️ Fasting: \(package.preparationInstructions.fastingHours)-\(package.preparationInstructions.fastingHours + 2) hours required")
                    .healthTextStyle(.body, color: HealthColors.primaryText, weight: .semibold)
                
                preparationCategory("Day Before Test:", items: package.preparationInstructions.dayBefore)
                preparationCategory("Morning of Test:", items: package.preparationInstructions.morningOfTest)
                preparationCategory("What to Bring:", items: package.preparationInstructions.whatToBring)
            }
            .padding(HealthSpacing.md)
            .background(HealthColors.primaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .healthCardShadow()
            
            HStack(spacing: HealthSpacing.md) {
                actionButton("Download Prep Guide", systemImage: "square.and.arrow.down")
                actionButton("Set Reminders", systemImage: "alarm")
            }
        }
    }
    
    private func preparationCategory(_ title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            Text(title)
                .healthTextStyle(.body, color: HealthColors.primaryText, weight: .semibold)
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top) {
                    Text("✅")
                    Text(item)
                        .healthTextStyle(.body, color: HealthColors.primaryText)
                }
            }
        }
    }
    
    // MARK: - Available Labs Section
    private var availableLabsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Available at \(package.availableLabs.count) labs near you")
                .healthTextStyle(.title3, color: HealthColors.primaryText, weight: .bold)
            
            ForEach(package.availableLabs) { lab in
                labCard(lab)
            }
            
            HStack(spacing: HealthSpacing.md) {
                actionButton("View All Labs", systemImage: "list.bullet")
                actionButton("Compare Prices", systemImage: "chart.bar")
            }
        }
    }
    
    private func labCard(_ lab: LabFacility) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text("\(lab.type.icon) \(lab.name)")
                        .healthTextStyle(.body, color: HealthColors.primaryText, weight: .semibold)
                    
                    HStack {
                        Text("⭐ \(lab.displayRating)")
                        Text("• \(lab.distance)")
                        Text("• \(lab.availability)")
                    }
                    .healthTextStyle(.captionRegular, color: HealthColors.secondaryText)
                }
                
                Spacer()
                
                Text(lab.formattedPrice)
                    .healthTextStyle(.body, color: HealthColors.primaryText, weight: .bold)
            }
            
            HStack(spacing: HealthSpacing.md) {
                Button {
                    selectedLab = lab
                    navigateToBooking = true
                } label: {
                    Text("Book Now")
                        .healthTextStyle(.captionMedium, color: .white)
                        .padding(.horizontal, HealthSpacing.md)
                        .padding(.vertical, HealthSpacing.xs)
                        .background(HealthColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button {
                    // Show lab details
                } label: {
                    Text("Details")
                        .healthTextStyle(.captionMedium, color: HealthColors.primary)
                        .padding(.horizontal, HealthSpacing.md)
                        .padding(.vertical, HealthSpacing.xs)
                        .background(HealthColors.primaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(HealthColors.primary, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .healthCardShadow()
    }
    
    // MARK: - Package Variants Section
    private var packageVariantsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Other Package Options")
                .healthTextStyle(.title3, color: HealthColors.primaryText, weight: .bold)
            
            ForEach(package.packageVariants) { variant in
                packageVariantCard(variant)
            }
            
            HStack(spacing: HealthSpacing.md) {
                actionButton("View All Packages", systemImage: "list.bullet")
                actionButton("Package Comparison", systemImage: "chart.bar.doc.horizontal")
            }
        }
    }
    
    private func packageVariantCard(_ variant: PackageVariant) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                HStack {
                    if variant.isPopular {
                        Text("👑")
                    }
                    Text(variant.name)
                        .healthTextStyle(.body, color: HealthColors.primaryText, weight: .semibold)
                    Spacer()
                    Text(variant.formattedPrice)
                        .healthTextStyle(.body, color: HealthColors.primaryText, weight: .bold)
                }
                
                Text("\(variant.testCount)+ tests • \(variant.duration) duration")
                    .healthTextStyle(.captionRegular, color: HealthColors.secondaryText)
            }
            
            Spacer()
            
            VStack(spacing: HealthSpacing.xs) {
                Button {
                    // View details
                } label: {
                    Text("View Details")
                        .healthTextStyle(.caption2, color: HealthColors.primary, weight: .medium)
                }
                
                Button {
                    // Book now
                } label: {
                    Text("Book Now")
                        .healthTextStyle(.caption2, color: HealthColors.primary, weight: .medium)
                }
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Customer Reviews Section
    private var customerReviewsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("⭐ Customer Reviews (\(String(format: "%.1f", package.averageRating))/5)")
                .healthTextStyle(.title3, color: HealthColors.primaryText, weight: .bold)
            
            ForEach(package.customerReviews.prefix(3), id: \.id) { review in
                reviewCard(review)
            }
            
            HStack(spacing: HealthSpacing.md) {
                actionButton("View All Reviews", systemImage: "text.bubble")
                actionButton("Write Review", systemImage: "square.and.pencil")
            }
        }
    }
    
    private func reviewCard(_ review: CustomerReview) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            HStack {
                Text("\(review.displayRating) \(review.customerName) (\(review.timeAgo))")
                    .healthTextStyle(.captionMedium, color: HealthColors.primaryText)
                Spacer()
            }
            
            Text("\"\(review.comment)\"")
                .healthTextStyle(.body, color: HealthColors.primaryText)
                .italic()
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - FAQ Section
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("❓ Frequently Asked Questions")
                .healthTextStyle(.title3, color: HealthColors.primaryText, weight: .bold)
            
            ForEach(package.faqItems) { faq in
                faqCard(faq)
            }
            
            HStack(spacing: HealthSpacing.md) {
                actionButton("View All FAQs", systemImage: "questionmark.circle")
                actionButton("Ask Question", systemImage: "message")
            }
        }
    }
    
    private func faqCard(_ faq: FAQItem) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            Button {
                packageState.toggleFAQ(withId: faq.id)
            } label: {
                HStack {
                    Text("Q: \(faq.question)")
                        .healthTextStyle(.body, color: HealthColors.primaryText, weight: .medium)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: packageState.isFAQExpanded(faq.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            if packageState.isFAQExpanded(faq.id) {
                Text("A: \(faq.answer)")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .padding(.top, HealthSpacing.xs)
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Bottom Action Bar
    private func bottomActionBar(safeAreaBottom: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(HealthColors.border)
                .frame(height: 0.5)
            
            // Action buttons
            HStack(spacing: HealthSpacing.md) {
                // Save button
                Button {
                    packageState.toggleSaved()
                } label: {
                    HStack {
                        Image(systemName: packageState.isSaved ? "heart.fill" : "heart")
                            .foregroundColor(packageState.isSaved ? .red : HealthColors.secondaryText)
                        Text("Save")
                            .healthTextStyle(.captionMedium, color: HealthColors.secondaryText)
                    }
                    .frame(width: 70, height: 48)
                }
                
                // Share button
                Button {
                    showShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(HealthColors.secondaryText)
                        Text("Share")
                            .healthTextStyle(.captionMedium, color: HealthColors.secondaryText)
                    }
                    .frame(width: 70, height: 48)
                }
                
                // Main booking button
                Button {
                    navigateToBooking = true
                } label: {
                    Text("Book Package - \(package.formattedPrice)")
                        .healthTextStyle(.body, color: .white, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(HealthColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.vertical, HealthSpacing.md)
            .background(HealthColors.primaryBackground)
            
            // Safe area padding
            Rectangle()
                .fill(HealthColors.primaryBackground)
                .frame(height: safeAreaBottom)
        }
    }
    
    // MARK: - Helper Views
    private func actionButton(_ title: String, systemImage: String) -> some View {
        Button {
            // Handle action
        } label: {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                Text(title)
                    .healthTextStyle(.captionMedium, color: HealthColors.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(HealthColors.primaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(HealthColors.primary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Computed Properties
    private var shareText: String {
        "Check out this health package: \(package.name) - \(package.formattedPrice) (Save \(package.formattedSavings)!)"
    }
}

// MARK: - Helper Views and Sheets


/// Customize package sheet (placeholder)
struct CustomizePackageSheet: View {
    let package: HealthPackage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Customize \(package.name)")
                    .healthTextStyle(.title2, color: HealthColors.primaryText, weight: .bold)
                    .padding()
                
                Text("Package customization coming soon!")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Compare packages sheet (placeholder)
struct ComparePackagesSheet: View {
    let currentPackage: HealthPackage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Compare Packages")
                    .healthTextStyle(.title2, color: HealthColors.primaryText, weight: .bold)
                    .padding()
                
                Text("Package comparison coming soon!")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Usage Example & Integration
extension HealthPackageDetailsView {
    /// Static method to create a navigation-ready view with a comprehensive package
    static func withComprehensivePackage() -> some View {
        HealthPackageDetailsView(package: HealthPackage.sampleComprehensive())
    }
    
    /// Static method for testing with different packages
    static func withPackage(_ package: HealthPackage) -> some View {
        HealthPackageDetailsView(package: package)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        HealthPackageDetailsView.withComprehensivePackage()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    NavigationView {
        HealthPackageDetailsView.withComprehensivePackage()
    }
    .preferredColorScheme(.dark)
}

// MARK: - Temporary Navigation Extension
// Note: This would typically be handled by passing the health package through the navigation system
// For now, we'll use the existing TestBookingDateTimeView with test details conversion