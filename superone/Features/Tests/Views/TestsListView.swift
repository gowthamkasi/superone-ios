import SwiftUI

/// Tests list view with real API integration and infinite scroll
struct TestsListView: View {
    
    // MARK: - Properties
    @State private var viewModel = TestsListViewModel()
    @State private var showSuggestions = false
    @Environment(\.authenticationContext) private var authContext
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Search and filter section
                    searchAndFilterSection
                    
                    // Tests list
                    testsList
                }
                
                // Search suggestions overlay
                if showSuggestions && viewModel.shouldShowSuggestions {
                    searchSuggestionsOverlay
                }
                
                // Authentication required overlay
                if !authContext.isAuthenticated {
                    authenticationRequiredOverlay
                }
                
                // Error overlay
                if let error = viewModel.error, authContext.isAuthenticated {
                    errorOverlay(error: error)
                }
            }
            .navigationTitle("Health Tests")
            .navigationBarTitleDisplayMode(.large)
            .background(HealthColors.secondaryBackground.ignoresSafeArea())
            .refreshable {
                await viewModel.refreshTests()
            }
            .onAppear {
                #if DEBUG
                print("🏥 TestsListView: Checking authentication state")
                print("  - Is authenticated: \(authContext.isAuthenticated)")
                
                // Use Task for accessing hasStoredTokens to avoid actor isolation issues
                Task {
                    let hasTokens = TokenManager.shared.hasStoredTokens()
                    print("  - Has stored tokens: \(hasTokens)")
                }
                #endif
                
                // Check authentication state and load tests if authenticated
                Task {
                    let hasTokens = TokenManager.shared.hasStoredTokens()
                    if authContext.isAuthenticated && hasTokens {
                        #if DEBUG
                        print("✅ TestsListView: User is authenticated - loading tests")
                        #endif
                        // Only load if we don't have tests already
                        if viewModel.tests.isEmpty && viewModel.error == nil {
                            await viewModel.loadTests()
                        }
                    } else {
                        #if DEBUG
                        print("🔒 TestsListView: User not authenticated - clearing data")
                        #endif
                        // Clear any existing data if not authenticated
                        await MainActor.run {
                            viewModel.clearTestsData()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: HealthSpacing.md) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(HealthColors.secondaryText)
                
                TextField("Search tests...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture {
                        showSuggestions = true
                    }
                    .onChange(of: viewModel.searchText) { _, newValue in
                        if !newValue.isEmpty {
                            showSuggestions = true
                        }
                    }
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                        showSuggestions = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
            }
            .padding(HealthSpacing.md)
            .background(HealthColors.primaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.md))
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HealthSpacing.sm) {
                    // All categories button
                    CategoryFilterChip(
                        title: "All",
                        isSelected: viewModel.selectedCategory == nil,
                        action: { 
                            viewModel.selectedCategory = nil
                            showSuggestions = false
                        }
                    )
                    
                    // Individual category buttons
                    ForEach(TestCategory.allCases, id: \.self) { category in
                        CategoryFilterChip(
                            title: category.displayName,
                            isSelected: viewModel.selectedCategory == category,
                            count: viewModel.categoryCount(for: category),
                            action: { 
                                viewModel.selectedCategory = category
                                showSuggestions = false
                            }
                        )
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
            }
        }
        .padding(.top, HealthSpacing.md)
        .padding(.horizontal, HealthSpacing.screenPadding)
        .background(HealthColors.secondaryBackground)
    }
    
    // MARK: - Tests List
    private var testsList: some View {
        ScrollView {
            LazyVStack(spacing: HealthSpacing.md) {
                // Only show content if authenticated
                if authContext.isAuthenticated {
                    if viewModel.shouldShowLoading {
                        loadingView
                    } else if viewModel.isEmpty {
                        emptyStateView
                    } else {
                        #if DEBUG
                        // Debug information for what data we're showing
                        let _ = print("📋 TestsListView: Displaying \(viewModel.tests.count) tests")
                        let _ = viewModel.tests.enumerated().forEach { index, test in
                            print("  [\(index)]: \(test.name) - \(test.price) (ID: \(test.id))")
                        }
                        #endif
                        
                        ForEach(viewModel.tests, id: \.id) { test in
                            NavigationLink(destination: TestDetailsView(testId: test.id)) {
                                TestListCard(test: test)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onAppear {
                                // Trigger infinite scroll when item appears
                                viewModel.checkForLoadMore(testId: test.id)
                            }
                        }
                        
                        // Load more indicator
                        if viewModel.shouldShowLoadMore {
                            loadMoreView
                        }
                    }
                } else {
                    // Show placeholder content for unauthenticated state
                    VStack(spacing: HealthSpacing.lg) {
                        Image(systemName: "testtube.2")
                            .font(.system(size: 48))
                            .foregroundColor(HealthColors.secondaryText)
                        
                        Text("Discover Health Tests")
                            .healthTextStyle(.title3, color: HealthColors.primaryText)
                        
                        Text("Sign in to explore hundreds of health tests and packages tailored for your wellness journey.")
                            .healthTextStyle(.body, color: HealthColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, HealthSpacing.xxxxl)
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.vertical, HealthSpacing.lg)
        }
        .onTapGesture {
            showSuggestions = false
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: HealthSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(HealthColors.primary)
            
            Text("Loading tests...")
                .healthTextStyle(.body, color: HealthColors.secondaryText)
        }
        .padding(.top, HealthSpacing.xxxxl)
    }
    
    // MARK: - Load More View
    private var loadMoreView: some View {
        HStack(spacing: HealthSpacing.sm) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(HealthColors.primary)
            
            Text("Loading more tests...")
                .healthTextStyle(.caption1, color: HealthColors.secondaryText)
        }
        .padding(HealthSpacing.lg)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: HealthSpacing.lg) {
            Image(systemName: viewModel.searchText.isEmpty ? "testtube.2" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(HealthColors.secondaryText)
            
            Text(viewModel.searchText.isEmpty ? "No tests available" : "No tests found")
                .healthTextStyle(.title3, color: HealthColors.primaryText)
            
            Text(viewModel.searchText.isEmpty ? 
                "Check back later for available tests" : 
                "Try adjusting your search or filter criteria")
                .healthTextStyle(.body, color: HealthColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, HealthSpacing.xxxxl)
    }
    
    // MARK: - Search Suggestions Overlay
    private var searchSuggestionsOverlay: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Spacer to position below search bar
            Rectangle()
                .fill(Color.clear)
                .frame(height: 120) // Approximate height of search and filter section
            
            // Suggestions list
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.isLoadingSuggestions {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading suggestions...")
                            .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                        Spacer()
                    }
                    .padding(HealthSpacing.md)
                } else {
                    ForEach(viewModel.searchSuggestions, id: \.text) { suggestion in
                        Button {
                            viewModel.applySuggestion(suggestion)
                            showSuggestions = false
                        } label: {
                            HStack {
                                Image(systemName: suggestionIcon(for: suggestion.type))
                                    .foregroundColor(HealthColors.primary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.text)
                                        .healthTextStyle(.bodyMedium, color: HealthColors.primaryText)
                                    
                                    Text("\(suggestion.count) results")
                                        .healthTextStyle(.caption2, color: HealthColors.secondaryText)
                                }
                                
                                Spacer()
                            }
                            .padding(HealthSpacing.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .padding(.leading, HealthSpacing.md)
                    }
                }
            }
            .background(HealthColors.primaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.md))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            Spacer()
        }
        .background(Color.clear)
        .onTapGesture {
            showSuggestions = false
        }
    }
    
    // MARK: - Authentication Required Overlay
    private var authenticationRequiredOverlay: some View {
        VStack(spacing: HealthSpacing.lg) {
            Image(systemName: "person.crop.circle.badge.exclamationmark.fill")
                .font(.system(size: 48))
                .foregroundColor(HealthColors.primary)
            
            Text("Sign In Required")
                .healthTextStyle(.title3, color: HealthColors.primaryText)
            
            Text("Please sign in to view available health tests and packages.")
                .healthTextStyle(.body, color: HealthColors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Sign In") {
                // Navigation to sign in would be handled by parent view or coordinator
                // For now, we'll just clear the error to trigger a refresh
                Task {
                    if authContext.isAuthenticated {
                        await viewModel.loadTests()
                    }
                }
            }
            .buttonStyle(HealthButtonStyle(style: .primary))
        }
        .padding(HealthSpacing.xl)
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.lg))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Error Overlay
    private func errorOverlay(error: TestsAPIError) -> some View {
        VStack(spacing: HealthSpacing.lg) {
            Image(systemName: errorIcon(for: error))
                .font(.system(size: 48))
                .foregroundColor(errorColor(for: error))
            
            Text(errorTitle(for: error))
                .healthTextStyle(.title3, color: HealthColors.primaryText)
            
            Text(viewModel.errorMessage)
                .healthTextStyle(.body, color: HealthColors.secondaryText)
                .multilineTextAlignment(.center)
            
            HStack(spacing: HealthSpacing.md) {
                // Clear error button
                Button("Dismiss") {
                    viewModel.clearError()
                }
                .buttonStyle(HealthButtonStyle(style: .secondary))
                
                // Retry button (if error is retryable)
                if viewModel.canRetry {
                    Button("Try Again") {
                        viewModel.retry()
                    }
                    .buttonStyle(HealthButtonStyle(style: .primary))
                }
            }
        }
        .padding(HealthSpacing.xl)
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.lg))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Helper Methods
    
    private func suggestionIcon(for type: SuggestionType) -> String {
        switch type {
        case .test:
            return "testtube.2"
        case .package:
            return "doc.text.fill"
        case .category:
            return "tag.fill"
        }
    }
    
    // MARK: - Error Helper Methods
    
    private func errorIcon(for error: TestsAPIError) -> String {
        switch error {
        case .unauthorized, .forbidden:
            return "person.crop.circle.badge.exclamationmark.fill"
        case .networkError:
            return "wifi.exclamationmark"
        case .serverError:
            return "server.rack"
        case .testNotFound, .packageNotFound:
            return "magnifyingglass"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private func errorColor(for error: TestsAPIError) -> Color {
        switch error {
        case .unauthorized, .forbidden:
            return HealthColors.primary
        case .networkError:
            return .orange
        case .serverError:
            return HealthColors.error
        case .testNotFound, .packageNotFound:
            return HealthColors.secondaryText
        default:
            return HealthColors.error
        }
    }
    
    private func errorTitle(for error: TestsAPIError) -> String {
        switch error {
        case .unauthorized:
            return "Authentication Required"
        case .forbidden:
            return "Access Denied"
        case .networkError:
            return "Connection Problem"
        case .serverError:
            return "Server Error"
        case .testNotFound, .packageNotFound:
            return "Not Found"
        default:
            return "Something Went Wrong"
        }
    }
}

// MARK: - Category Filter Chip

private struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    init(title: String, isSelected: Bool, count: Int = 0, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.count = count
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HealthSpacing.xs) {
                Text(title)
                    .healthTextStyle(.captionMedium, color: isSelected ? .white : HealthColors.primaryText)
                
                if count > 0 && !isSelected {
                    Text("(\(count))")
                        .healthTextStyle(.caption2, color: HealthColors.secondaryText)
                }
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(
                isSelected ? HealthColors.primary : HealthColors.primaryBackground
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(HealthColors.border, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Test List Card

private struct TestListCard: View {
    let test: TestItemData
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            // Test icon
            Text(test.icon)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(test.category.color.opacity(0.1))
                .clipShape(Circle())
            
            // Test information
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(test.name)
                        .healthTextStyle(.bodyMedium, color: HealthColors.primaryText)
                        .lineLimit(1)
                    
                    if test.isFeatured {
                        Text("FEATURED")
                            .healthTextStyle(.caption2, color: .white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(HealthColors.primary)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                
                Text(test.description)
                    .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                    .lineLimit(2)
                
                HStack(spacing: HealthSpacing.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(HealthColors.secondaryText)
                        Text(test.duration)
                            .healthTextStyle(.caption2, color: HealthColors.secondaryText)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text(test.price)
                            .healthTextStyle(.caption2, color: HealthColors.primaryText)
                        
                        if let originalPrice = test.originalPrice {
                            Text(originalPrice)
                                .healthTextStyle(.caption2, color: HealthColors.tertiaryText)
                                .strikethrough()
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(HealthColors.secondaryText)
        }
        .cardPadding()
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
    }
}

// MARK: - Previews

#if DEBUG
struct TestsListView_Previews: PreviewProvider {
    static var previews: some View {
        TestsListView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
        
        TestsListView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}
#endif