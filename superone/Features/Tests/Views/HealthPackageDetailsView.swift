import SwiftUI

/// Health package details view using reusable components
/// Built with SwiftUI 6.0+ and modern actor isolation patterns
@MainActor
struct HealthPackageDetailsView: View {
    
    // MARK: - Properties
    let packageId: String
    @State private var viewModel = HealthPackageDetailsViewModel()
    @State private var navigateToBooking = false
    @State private var showingShareSheet = false
    @State private var shareSheet: PackageShareSheet?
    @State private var showFloatingHeader = false
    @State private var showAllTestsSheet = false
    @State private var currentCategoryIndex = 0
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        CommonPageLayout {
            contentView
        } bottomContent: {
            bottomButtonsBar
        }
        .task {
            await loadPackageDetails()
        }
        .navigationDestination(isPresented: $navigateToBooking) {
            PackageBookingDateTimeView(packageDetails: viewModel.packageDetails)
        }
        .sheet(item: $shareSheet) { sheet in
            sheet
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScrollOffsetChanged"))) { notification in
            if let offset = notification.object as? CGFloat {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showFloatingHeader = offset < -100
                }
            }
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: 0) {
            // Header section
            headerSection
            
            // Main content sections
            if viewModel.isLoading {
                packageDetailsSkeletonContent
                    .padding(.horizontal, HealthSpacing.screenPadding)
                    .padding(.top, HealthSpacing.xs)
            } else {
                VStack(spacing: HealthSpacing.lg) {
                    // Package overview card
                    if let package = viewModel.packageDetails {
                        packageOverviewCard(package: package)
                            .padding(.horizontal, HealthSpacing.screenPadding)
                    }
                    
                    // Tests included section
                    if let package = viewModel.packageDetails {
                        testsIncludedSection(package: package)
                            .padding(.horizontal, HealthSpacing.screenPadding)
                    }
                    
                    // Information sections
                    if let state = viewModel.packageDetailsState {
                        informationSections(state: state)
                            .padding(.horizontal, HealthSpacing.screenPadding)
                    }
                }
                .padding(.top, HealthSpacing.xs)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        CommonPageHeader(
            title: viewModel.packageDetails?.name ?? "Package Details",
            showFloatingHeader: showFloatingHeader,
            rightActions: [
                .savedState(isSaved: viewModel.isSaved) {
                    Task { @MainActor in
                        viewModel.toggleFavorite()
                    }
                },
                .share {
                    Task { @MainActor in
                        sharePackage()
                    }
                }
            ],
            onBackTap: {
                dismiss()
            }
        )
    }
    
    // MARK: - Package Overview Card
    private func packageOverviewCard(package: HealthPackage) -> some View {
        DetailsOverviewCard(
            icon: package.icon,
            title: package.name,
            subtitle: package.shortName,
            iconBackgroundColor: HealthColors.primary.opacity(0.1)
        ) {
            packageDetailsGrid(package: package)
        }
    }
    
    // MARK: - Package Details Grid
    private func packageDetailsGrid(package: HealthPackage) -> some View {
        DetailsGrid(items: [
            DetailGridItem(
                icon: "clock.fill",
                title: "Duration",
                value: package.duration,
                color: .blue
            ),
            DetailGridItem(
                icon: "indianrupeesign.circle.fill",
                title: "Price",
                value: package.formattedPrice,
                color: .green,
                originalValue: package.originalPrice != nil ? String(format: "₹%.0f", package.originalPrice!) : nil
            ),
            DetailGridItem(
                icon: package.fastingRequirement.isRequired ? "fork.knife" : "checkmark.circle.fill",
                title: "Fasting",
                value: package.fastingRequirement.displayText,
                color: package.fastingRequirement.isRequired ? .orange : .green
            ),
            DetailGridItem(
                icon: "testtube.2",
                title: "Tests",
                value: "\(package.totalTests) tests",
                color: HealthColors.primary
            ),
            DetailGridItem(
                icon: "doc.text.fill",
                title: "Report",
                value: package.reportTime,
                color: .purple
            )
        ])
    }
    
    // MARK: - Tests Included Section
    private func testsIncludedSection(package: HealthPackage) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Section header with View All button
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "testtube.2")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.primary)
                
                Text("Tests Included (\(package.totalTests) tests)")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
                
                Button(action: {
                    Task { @MainActor in
                        showAllTestsSheet = true
                    }
                }) {
                    Text("View All")
                        .healthTextStyle(.caption1, color: HealthColors.primary)
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("View all \(package.totalTests) tests")
                .accessibilityHint("Opens a detailed view of all test categories and their individual tests")
            }
            
            // Horizontal sliding test categories
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(package.testCategories.enumerated()), id: \.element.id) { index, category in
                            testCategoryCard(category: category)
                                .frame(width: geometry.size.width - (HealthSpacing.screenPadding * 2))
                                .padding(.horizontal, HealthSpacing.screenPadding)
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: .init(
                    get: { currentCategoryIndex },
                    set: { newIndex in
                        if let index = newIndex {
                            currentCategoryIndex = index
                        }
                    }
                ))
            }
            .frame(height: 180)
            
            // Page indicator dots
            if package.testCategories.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<package.testCategories.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentCategoryIndex ? HealthColors.primary : HealthColors.primary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentCategoryIndex)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, HealthSpacing.xs)
            }
        }
        .cardPadding()
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
        .sheet(isPresented: $showAllTestsSheet) {
            AllTestsSheet(package: package)
        }
    }
    
    // MARK: - Test Category Card (Optimized for Slider)
    private func testCategoryCard(category: HealthTestCategory) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            // Category header
            HStack(spacing: HealthSpacing.sm) {
                Text(category.icon)
                    .font(.system(size: 18))
                    .frame(width: 28, height: 28)
                    .background((category.color ?? HealthColors.primary).opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(category.name)
                        .healthTextStyle(.subheadline, color: HealthColors.primaryText)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    
                    Text("\(category.testCount) tests")
                        .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                }
                
                Spacer(minLength: 0)
            }
            
            Divider()
                .background(HealthColors.border.opacity(0.5))
            
            // Sample tests (always show exactly 3 tests)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(category.tests.prefix(3)), id: \.id) { test in
                    HStack(spacing: HealthSpacing.xs) {
                        Circle()
                            .fill(HealthColors.primary.opacity(0.3))
                            .frame(width: 4, height: 4)
                        
                        Text(test.shortName ?? test.name)
                            .healthTextStyle(.caption1, color: HealthColors.primaryText)
                            .multilineTextAlignment(.leading)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
                
                // Always show "+X more" if there are more than 3 tests
                if category.tests.count > 3 {
                    HStack(spacing: HealthSpacing.xs) {
                        Circle()
                            .fill(HealthColors.primary)
                            .frame(width: 4, height: 4)
                        
                        Text("+\(category.tests.count - 3) more")
                            .healthTextStyle(.caption1, color: HealthColors.primary)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(width: 280, height: 140)
        .padding(HealthSpacing.md)
        .background(HealthColors.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                .stroke((category.color ?? HealthColors.primary).opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.name) category with \(category.testCount) tests")
        .accessibilityHint("Swipe to see more test categories or tap View All for complete list")
    }
    
    // MARK: - Information Sections
    private func informationSections(state: HealthPackageDetailsState) -> some View {
        VStack(spacing: HealthSpacing.lg) {
            ForEach(state.sections) { section in
                sectionInfoCard(section: section)
            }
        }
    }
    
    // MARK: - Section Info Card
    private func sectionInfoCard(section: PackageSection) -> some View {
        CollapsibleInfoCard(
            title: section.title,
            icon: section.type.icon,
            accentColor: HealthColors.primary,
            isInitiallyExpanded: false
        ) {
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                // Overview text
                if let overview = section.content.overview, !overview.isEmpty {
                    Text(overview)
                        .healthTextStyle(.body, color: HealthColors.primaryText)
                }
                
                // Bullet points
                if !section.content.bulletPoints.isEmpty {
                    InfoList(items: section.content.bulletPoints)
                }
                
                // Categories (for FAQ section)
                if !section.content.categories.isEmpty {
                    VStack(spacing: HealthSpacing.lg) {
                        ForEach(section.content.categories) { category in
                            InfoCategory(
                                category: InfoCategoryModel(
                                    icon: category.icon,
                                    title: category.title,
                                    items: category.items,
                                    color: category.color
                                )
                            )
                        }
                    }
                }
                
                // Tips section
                if !section.content.tips.isEmpty {
                    VStack(spacing: HealthSpacing.sm) {
                        Divider().background(HealthColors.border)
                        
                        TipsInfoCard(tips: section.content.tips)
                    }
                }
                
                // Warnings section
                if !section.content.warnings.isEmpty {
                    VStack(spacing: HealthSpacing.sm) {
                        Divider().background(HealthColors.border)
                        
                        WarningsInfoCard(warnings: section.content.warnings)
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Buttons Bar
    private var bottomButtonsBar: some View {
        BottomButtonsBar(
            primaryAction: BottomButtonAction.bookPackage {
                Task { @MainActor in
                    bookPackage()
                }
            },
            isLoading: viewModel.isLoading
        )
    }
    
    // MARK: - Actions
    private func sharePackage() {
        shareSheet = viewModel.sharePackage()
    }
    
    private func bookPackage() {
        navigateToBooking = true
    }
    
    private func loadPackageDetails() async {
        await MainActor.run {
            viewModel.loadPackageDetails(packageId: packageId)
        }
    }
    
    // MARK: - Skeleton Loading Content
    
    private var packageDetailsSkeletonContent: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Package overview skeleton
            CardSkeleton(showImage: true, imageSize: CGSize(width: 80, height: 80), contentLines: 4)
            
            // Tests included section skeleton
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                // Section header
                HStack {
                    HealthSkeletonView(
                        width: 140,
                        height: 20
                    )
                    Spacer()
                }
                
                // Test categories grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: HealthSpacing.md) {
                    ForEach(0..<6, id: \.self) { _ in
                        GridItemSkeleton(showTitle: true, showSubtitle: false)
                    }
                }
            }
            .padding(HealthSpacing.cardPadding)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
            
            // Information sections skeleton
            DetailsSkeleton(sectionCount: 3, itemsPerSection: 4)
        }
    }
}

// MARK: - All Tests Modal Sheet

/// Modal sheet displaying all test categories and their complete test lists
/// Uses modern SwiftUI 6.0+ navigation and proper actor isolation patterns
@MainActor
struct AllTestsSheet: View {
    let package: HealthPackage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: HealthSpacing.lg) {
                    ForEach(package.testCategories) { category in
                        testCategorySection(category: category)
                    }
                }
                .padding(HealthSpacing.screenPadding)
            }
            .navigationTitle("All Tests")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Task { @MainActor in
                            dismiss()
                        }
                    }
                    .foregroundColor(HealthColors.primary)
                    .fontWeight(.semibold)
                    .accessibilityLabel("Close all tests view")
                }
            }
            .background(HealthColors.secondaryBackground)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Test Category Section
    private func testCategorySection(category: HealthTestCategory) -> some View {
        CollapsibleInfoCard(
            title: category.name,
            subtitle: "\(category.testCount) tests included",
            icon: "testtube.2",
            accentColor: category.color ?? HealthColors.primary,
            isInitiallyExpanded: false
        ) {
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                ForEach(category.tests) { test in
                    testItemRow(test: test, categoryColor: category.color ?? HealthColors.primary)
                }
            }
        }
    }
    
    // MARK: - Test Item Row
    private func testItemRow(test: HealthTest, categoryColor: Color) -> some View {
        HStack(spacing: HealthSpacing.sm) {
            // Test indicator dot
            Circle()
                .fill(categoryColor.opacity(0.3))
                .frame(width: 6, height: 6)
            
            // Test details
            VStack(alignment: .leading, spacing: 2) {
                Text(test.name)
                    .healthTextStyle(.body, color: HealthColors.primaryText)
                    .multilineTextAlignment(.leading)
                
                if let shortName = test.shortName, shortName != test.name {
                    Text("(\(shortName))")
                        .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                }
                
                if let description = test.description {
                    Text(description)
                        .healthTextStyle(.caption2, color: HealthColors.secondaryText)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, HealthSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(test.name)
        .accessibilityHint(test.description ?? "Individual test in \(test.name) category")
    }
}

// MARK: - BottomButtonAction Extension for Package Booking

extension BottomButtonAction {
    static func bookPackage(action: @escaping @Sendable () -> Void) -> BottomButtonAction {
        BottomButtonAction(
            title: "Book Package",
            icon: "calendar.badge.plus",
            style: .primary,
            accessibilityLabel: "Book package appointment",
            accessibilityHint: "Double tap to proceed with booking this health package",
            action: action
        )
    }
}


// MARK: - Previews

struct HealthPackageDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthPackageDetailsView(packageId: "comprehensive_001")
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
        
        HealthPackageDetailsView(packageId: "comprehensive_001")
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}
