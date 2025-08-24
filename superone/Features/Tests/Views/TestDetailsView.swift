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
            
            // Main content sections
            VStack(spacing: HealthSpacing.lg) {
                // Test overview card
                if let test = viewModel.testDetails {
                    testOverviewCard(test: test)
                        .padding(.horizontal, HealthSpacing.screenPadding)
                }
                
                // Information sections
                if let state = viewModel.testDetailsState {
                    informationSections(state: state)
                        .padding(.horizontal, HealthSpacing.screenPadding)
                }
            }
            .padding(.top, HealthSpacing.xs)
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
