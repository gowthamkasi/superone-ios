import SwiftUI

/// Refactored test details view using reusable components
/// Built with SwiftUI 6.0+ and modern actor isolation patterns
@MainActor
struct TestDetailsView: View {
    
    // MARK: - Properties
    let testId: String
    @State private var viewModel = TestDetailsViewModel()
    @State private var navigateToBooking = false
    @State private var showingShareSheet = false
    @State private var shareSheet: TestShareSheet?
    @State private var showFloatingHeader = false
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        CommonPageLayout {
            contentView
        } bottomContent: {
            bottomButtonsBar
        }
        .task {
            await loadTestDetails()
        }
        .navigationDestination(isPresented: $navigateToBooking) {
            TestBookingDateTimeView(testDetails: viewModel.testDetails)
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
            
            // Main content sections with state management
            Group {
                if viewModel.isLoading {
                    loadingStateView
                } else if let errorMessage = viewModel.errorMessage {
                    errorStateView(message: errorMessage)
                } else if let test = viewModel.testDetails {
                    contentStateView(test: test)
                } else {
                    emptyStateView
                }
            }
            .padding(.top, HealthSpacing.xs)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .animation(.easeInOut(duration: 0.3), value: viewModel.testDetails?.id)
        }
    }
    
    // MARK: - Loading State View
    private var loadingStateView: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Loading skeleton for test overview card
            loadingSkeletonCard
                .padding(.horizontal, HealthSpacing.screenPadding)
            
            // Loading skeletons for information sections
            VStack(spacing: HealthSpacing.lg) {
                ForEach(0..<3, id: \.self) { _ in
                    loadingSkeletonSection
                        .padding(.horizontal, HealthSpacing.screenPadding)
                }
            }
        }
    }
    
    // MARK: - Error State View
    private func errorStateView(message: String) -> some View {
        VStack(spacing: HealthSpacing.lg) {
            Spacer()
            
            VStack(spacing: HealthSpacing.lg) {
                // Error icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(HealthColors.error)
                
                // Error title
                Text("Unable to Load Test Details")
                    .healthTextStyle(.title2, color: HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                
                // Error message
                Text(message)
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HealthSpacing.lg)
                
                // Retry button
                Button {
                    Task { @MainActor in
                        await loadTestDetails()
                    }
                } label: {
                    HStack(spacing: HealthSpacing.sm) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, HealthSpacing.lg)
                    .padding(.vertical, HealthSpacing.md)
                    .background(HealthColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.md))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: HealthSpacing.lg) {
            Spacer()
            
            VStack(spacing: HealthSpacing.lg) {
                // Empty state icon
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(HealthColors.secondaryText)
                
                // Empty state title
                Text("Test Details Not Found")
                    .healthTextStyle(.title2, color: HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                
                // Empty state message
                Text("The test you're looking for couldn't be found. It may have been removed or is temporarily unavailable.")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HealthSpacing.lg)
                
                // Back to tests button
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: HealthSpacing.sm) {
                        Image(systemName: "arrow.left")
                        Text("Back to Tests")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, HealthSpacing.lg)
                    .padding(.vertical, HealthSpacing.md)
                    .background(HealthColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.md))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Content State View
    private func contentStateView(test: TestDetails) -> some View {
        VStack(spacing: HealthSpacing.lg) {
            // Test overview card
            testOverviewCard(test: test)
                .padding(.horizontal, HealthSpacing.screenPadding)
            
            // Information sections
            if let state = viewModel.testDetailsState {
                informationSections(state: state)
                    .padding(.horizontal, HealthSpacing.screenPadding)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        CommonPageHeader(
            title: viewModel.testDetails?.name ?? "Test Details",
            showFloatingHeader: showFloatingHeader,
            rightActions: [
                .savedState(isSaved: viewModel.isSaved) {
                    Task { @MainActor in
                        viewModel.toggleFavorite()
                    }
                },
                .share {
                    Task { @MainActor in
                        shareTest()
                    }
                }
            ],
            onBackTap: {
                dismiss()
            }
        )
    }
    
    
    // MARK: - Test Overview Card
    private func testOverviewCard(test: TestDetails) -> some View {
        DetailsOverviewCard(
            icon: test.icon,
            title: test.name,
            subtitle: test.tags.isEmpty ? nil : test.tags.joined(separator: " • "),
            iconBackgroundColor: test.category.color.opacity(0.1)
        ) {
            testDetailsGrid(test: test)
        }
    }
    
    // MARK: - Test Details Grid
    private func testDetailsGrid(test: TestDetails) -> some View {
        DetailsGrid(items: [
            DetailGridItem(
                icon: "clock.fill",
                title: "Duration",
                value: test.duration,
                color: .blue
            ),
            DetailGridItem(
                icon: "indianrupeesign.circle.fill",
                title: "Price",
                value: test.price,
                color: .green,
                originalValue: test.originalPrice
            ),
            DetailGridItem(
                icon: test.fasting.isRequired ? "fork.knife" : "checkmark.circle.fill",
                title: "Fasting",
                value: test.fasting.displayText,
                color: test.fasting.isRequired ? .orange : .green
            ),
            DetailGridItem(
                icon: test.sampleType.icon,
                title: "Sample",
                value: test.sampleType.displayName,
                color: test.category.color
            ),
            DetailGridItem(
                icon: "doc.text.fill",
                title: "Report",
                value: test.reportTime,
                color: .purple
            )
        ])
    }
    
    // MARK: - Information Sections
    private func informationSections(state: TestDetailsState) -> some View {
        VStack(spacing: HealthSpacing.lg) {
            ForEach(state.sections) { section in
                sectionInfoCard(section: section)
            }
        }
    }
    
    // MARK: - Section Info Card
    private func sectionInfoCard(section: TestSection) -> some View {
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
                
                // Categories
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
            primaryAction: BottomButtonAction.book {
                Task { @MainActor in
                    bookTest()
                }
            },
            secondaryAction: BottomButtonAction.addToCart {
                Task { @MainActor in
                    addToCart()
                }
            },
            isLoading: viewModel.isLoading
        )
    }
    
    // MARK: - Actions
    private func shareTest() {
        shareSheet = viewModel.shareTest()
    }
    
    private func addToCart() {
        // TODO: Implement cart functionality
        // Add the current test to shopping cart
        print("Adding test to cart: \(testId)")
    }
    
    private func bookTest() {
        navigateToBooking = true
    }
    
    private func loadTestDetails() async {
        await MainActor.run {
            viewModel.loadTestDetails(testId: testId)
        }
    }
    
    // MARK: - Loading Skeleton Views
    
    private var loadingSkeletonCard: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Header skeleton
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(HealthColors.secondaryBackground)
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(HealthColors.secondaryBackground)
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(HealthColors.secondaryBackground)
                        .frame(width: 120, height: 16)
                }
                
                Spacer()
            }
            
            // Grid skeleton
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: HealthSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(spacing: HealthSpacing.sm) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(HealthColors.secondaryBackground)
                            .frame(height: 16)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(HealthColors.secondaryBackground)
                            .frame(height: 12)
                    }
                    .padding(HealthSpacing.md)
                    .background(HealthColors.primaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.sm))
                }
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
    }
    
    private var loadingSkeletonSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Section header skeleton
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(HealthColors.secondaryBackground)
                    .frame(width: 24, height: 24)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(HealthColors.secondaryBackground)
                    .frame(width: 150, height: 18)
                
                Spacer()
            }
            
            // Content lines skeleton
            VStack(spacing: HealthSpacing.sm) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(HealthColors.secondaryBackground)
                        .frame(height: 14)
                        .frame(maxWidth: index == 2 ? .infinity * 0.7 : .infinity, alignment: .leading)
                }
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
    }
}



// MARK: - Previews

struct TestDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        TestDetailsView(testId: "cbc_001")
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
        
        TestDetailsView(testId: "cbc_001")
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        
        TestDetailsView(testId: "lipid_001")
            .preferredColorScheme(.light)
            .previewDisplayName("Lipid Profile")
    }
}
