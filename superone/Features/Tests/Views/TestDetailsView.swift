import SwiftUI

/// Comprehensive test details view following wireframe specifications
struct TestDetailsView: View {
    
    // MARK: - Properties
    let testId: String
    @State private var viewModel = TestDetailsViewModel()
    @State private var showingBookingSheet = false
    @State private var showingShareSheet = false
    @State private var shareSheet: TestShareSheet?
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Animation Properties
    @State private var headerOffset: CGFloat = 0
    @State private var showFloatingHeader = false
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            mainContent
            
            // Fixed bottom action bar
            bottomActionBar
        }
        .navigationBarHidden(true)
        .background(HealthColors.secondaryBackground.ignoresSafeArea())
        .task {
            await loadTestDetails()
        }
        .sheet(isPresented: $showingBookingSheet) {
            TestBookingSheet(testDetails: viewModel.testDetails)
        }
        .sheet(item: $shareSheet) { sheet in
            sheet
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header section
                headerSection
                
                // Test overview card
                if let test = viewModel.testDetails {
                    testOverviewCard(test: test)
                        .padding(.horizontal, HealthSpacing.screenPadding)
                        .padding(.top, HealthSpacing.xs)
                }
                
                // Collapsible sections
                if let state = viewModel.testDetailsState {
                    sectionsContent(state: state)
                        .padding(.horizontal, HealthSpacing.screenPadding)
                        .padding(.top, HealthSpacing.xl)
                }
                
                // Bottom spacing for action bar
                Spacer()
                    .frame(height: 120)
            }
        }
        .coordinateSpace(name: "scroll")
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            headerOffset = value
            withAnimation(.easeInOut(duration: 0.25)) {
                showFloatingHeader = value < -100
            }
        }
        .overlay(alignment: .top) {
            if showFloatingHeader {
                floatingHeader
            }
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
                    if let testName = viewModel.testDetails?.name {
                        Text(testName)
                            .healthTextStyle(.title3, color: HealthColors.primaryText)
                            .lineLimit(1)
                            .padding(.horizontal, HealthSpacing.md)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: HealthSpacing.md) {
                        // Favorite button
                        Button {
                            viewModel.toggleFavorite()
                        } label: {
                            Image(systemName: viewModel.isSaved ? "heart.fill" : "heart")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(viewModel.isSaved ? .red : HealthColors.secondaryText)
                                .frame(width: 44, height: 44)
                                .background(HealthColors.primaryBackground)
                                .clipShape(Circle())
                                .healthCardShadow()
                        }
                        
                        // Share button
                        Button {
                            shareTest()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(HealthColors.secondaryText)
                                .frame(width: 44, height: 44)
                                .background(HealthColors.primaryBackground)
                                .clipShape(Circle())
                                .healthCardShadow()
                        }
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
            }
        }
    }
    
    // MARK: - Floating Header
    private var floatingHeader: some View {
        BlurView(style: .systemMaterial)
            .frame(height: 94)
            .overlay {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 44)
                    
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(HealthColors.primaryText)
                        }
                        
                        if let test = viewModel.testDetails {
                            Text(test.name)
                                .healthTextStyle(.headline, color: HealthColors.primaryText)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.toggleFavorite()
                        } label: {
                            Image(systemName: viewModel.isSaved ? "heart.fill" : "heart")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(viewModel.isSaved ? .red : HealthColors.secondaryText)
                        }
                    }
                    .padding(.horizontal, HealthSpacing.screenPadding)
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Test Overview Card
    private func testOverviewCard(test: TestDetails) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.lg) {
            // Test header
            HStack(spacing: HealthSpacing.md) {
                // Test icon
                Text(test.icon)
                    .font(.system(size: 32))
                    .frame(width: 50, height: 50)
                    .background(test.category.color.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(test.name)
                        .healthTextStyle(.title2, color: HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    if !test.tags.isEmpty {
                        Text(test.tags.joined(separator: " • "))
                            .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                    }
                }
                
                Spacer()
            }
            
            // Test details grid
            testDetailsGrid(test: test)
        }
        .cardPadding()
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
    }
    
    // MARK: - Test Details Grid
    private func testDetailsGrid(test: TestDetails) -> some View {
        VStack(spacing: HealthSpacing.sm) {
            // First row
            HStack(spacing: HealthSpacing.md) {
                TestDetailItem(
                    icon: "clock.fill",
                    title: "Duration",
                    value: test.duration,
                    color: .blue
                )
                
                TestDetailItem(
                    icon: "indianrupeesign.circle.fill",
                    title: "Price",
                    value: test.price,
                    color: .green,
                    originalValue: test.originalPrice
                )
            }
            
            // Second row
            HStack(spacing: HealthSpacing.md) {
                TestDetailItem(
                    icon: test.fasting.isRequired ? "fork.knife" : "checkmark.circle.fill",
                    title: "Fasting",
                    value: test.fasting.displayText,
                    color: test.fasting.isRequired ? .orange : .green
                )
                
                TestDetailItem(
                    icon: test.sampleType.icon,
                    title: "Sample",
                    value: test.sampleType.displayName,
                    color: test.category.color
                )
            }
            
            // Third row
            TestDetailItem(
                icon: "doc.text.fill",
                title: "Report",
                value: test.reportTime,
                color: .purple,
                            )
        }
    }
    
    // MARK: - Sections Content
    private func sectionsContent(state: TestDetailsState) -> some View {
        VStack(spacing: HealthSpacing.lg) {
            ForEach(state.sections) { section in
                CollapsibleSection(section: section) { sectionId in
                    viewModel.toggleSection(withId: sectionId)
                }
            }
        }
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        BlurView(style: .systemMaterial)
            .frame(height: 100)
            .overlay {
                HStack(spacing: HealthSpacing.md) {
                    // Add to Cart button
                    Button {
                        addToCart()
                    } label: {
                        HStack(spacing: HealthSpacing.sm) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("Add to Cart")
                                .healthTextStyle(.buttonPrimary)
                        }
                        .foregroundColor(HealthColors.primary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(HealthColors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                    }
                    .disabled(viewModel.isLoading)
                    
                    // Book Test button
                    Button {
                        bookTest()
                    } label: {
                        HStack(spacing: HealthSpacing.sm) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("Book Test")
                                .healthTextStyle(.buttonPrimary, color: .white)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(HealthColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .padding(.bottom, 34) // Safe area bottom
            }
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
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
        showingBookingSheet = true
    }
    
    private func loadTestDetails() async {
        await MainActor.run {
            viewModel.loadTestDetails(testId: testId)
        }
    }
}

// MARK: - Test Detail Item Component

private struct TestDetailItem: View {
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
                
                HStack(spacing: 4) {
                    Text(value)
                        .healthTextStyle(.subheadline, color: HealthColors.primaryText)
                    
                    if let originalValue = originalValue {
                        Text(originalValue)
                            .healthTextStyle(.caption1, color: HealthColors.tertiaryText)
                            .strikethrough()
                    }
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

// MARK: - Blur View

private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Test Booking Sheet

private struct TestBookingSheet: View {
    let testDetails: TestDetails?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedTimeSlot: String? = nil
    
    private let timeSlots = [
        "08:00 AM - 10:00 AM", "10:00 AM - 12:00 PM", "02:00 PM - 04:00 PM",
        "04:00 PM - 06:00 PM", "06:00 PM - 08:00 PM", "08:00 PM - 10:00 PM"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: HealthSpacing.xl) {
                    if let test = testDetails {
                        VStack(spacing: HealthSpacing.md) {
                            
                            
                            Text("Choose your preferred date and time slot")
                                .healthTextStyle(.body, color: HealthColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, HealthSpacing.xl)
                    }
                    
                    // Date Picker Section
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        
                        
                        DatePicker("Select Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .accentColor(HealthColors.primary)
                    }
                    .cardPadding()
                    .background(HealthColors.primaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
                    .healthCardShadow()
                    
                    // Time Slot Section
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        Text("Select Time Slot")
                            .healthTextStyle(.headline, color: HealthColors.primaryText)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: HealthSpacing.sm), count: 2), spacing: HealthSpacing.sm) {
                            ForEach(timeSlots, id: \.self) { timeSlot in
                                Button(timeSlot) {
                                    selectedTimeSlot = timeSlot
                                }
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(selectedTimeSlot == timeSlot ? HealthColors.primary : HealthColors.tertiaryBackground)
                                .foregroundColor(selectedTimeSlot == timeSlot ? .white : HealthColors.primaryText)
                                .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                                .healthTextStyle(.bodyMedium)
                            }
                        }
                    }
                    .cardPadding()
                    .background(HealthColors.primaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
                    .healthCardShadow()
                    
                    // Action Buttons
                    VStack(spacing: HealthSpacing.lg) {
                        Button("Next") {
                            // if home sample collection avialble naviagte to Preview booking page
                            // else naviagte to lab selection page
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(selectedTimeSlot != nil ? HealthColors.primary : HealthColors.tertiaryBackground)
                        .foregroundColor(selectedTimeSlot != nil ? .white : HealthColors.secondaryText)
                        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                        .disabled(selectedTimeSlot == nil)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(HealthColors.tertiaryBackground)
                        .foregroundColor(HealthColors.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                    }
                    .padding(.bottom, HealthSpacing.xl)
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .background(HealthColors.primaryBackground)
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
