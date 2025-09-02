import SwiftUI

/// Tests list view with real API integration and infinite scroll
struct TestsListView: View {
    
    // MARK: - Properties
    @State private var viewModel = TestsListViewModel()
    @State private var showSuggestions = false
    @Environment(\.authenticationContext) private var authContext
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(AppFlowManager.self) private var flowManager
    
    init() {
        #if DEBUG
        print("🏗️ TestsListView.init() called - TestsListView is being created")
        #endif
    }
    
    // MARK: - Body
    var body: some View {
        #if DEBUG
        let _ = print("🎨 TestsListView.body computed - View is rendering")
        #endif
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
                
                // Error overlay
                if viewModel.showError {
                    errorOverlay()
                }
            }
            .navigationTitle("Health Tests")
            .navigationBarTitleDisplayMode(.large)
            .background(HealthColors.secondaryBackground.ignoresSafeArea())
            .refreshable {
                viewModel.refreshTests()  // Remove await - direct call like Labs
            }
        }
        .onAppear {
            #if DEBUG
            print("👀 TestsListView.onAppear called - Tests tab is now visible")
            print("📊 Current ViewModel state:")
            print("  - tests.count: \(viewModel.tests.count)")
            print("  - isLoadingTests: \(viewModel.isLoadingTests)")
            print("  - searchText: '\(viewModel.searchText)'")
            print("🚀 About to call viewModel.loadTestsIfNeeded()")
            #endif
            
            // Lazy load tests only when Tests tab is accessed - following Labs pattern
            viewModel.loadTestsIfNeeded()
            
            #if DEBUG
            print("✅ viewModel.loadTestsIfNeeded() call completed")
            #endif
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
                    if viewModel.shouldShowLoading {
                        // Show skeleton filter chips while loading
                        ForEach(0..<5, id: \.self) { _ in
                            HealthSkeletonView(
                                width: .random(in: 60...100),
                                height: 32,
                                cornerRadius: HealthCornerRadius.round
                            )
                        }
                    } else {
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
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
            }
        }
        .padding(.top, HealthSpacing.md)
        .padding(.horizontal, HealthSpacing.screenPadding)
        .background(HealthColors.secondaryBackground)
    }
    
    // MARK: - Tests List (Authentication already verified at top level)
    private var testsList: some View {
        ScrollView {
            LazyVStack(spacing: HealthSpacing.md) {
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
        SkeletonList(count: 6, staggerDelay: 0.1) { index in
            TestCardSkeleton()
        }
        .padding(.top, HealthSpacing.md)
    }
    
    // MARK: - Load More View
    private var loadMoreView: some View {
        VStack(spacing: HealthSpacing.md) {
            // Load more indicator
            HStack(spacing: HealthSpacing.sm) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(HealthColors.primary)
                
                Text("Loading more tests...")
                    .healthTextStyle(.caption1, color: HealthColors.secondaryText)
            }
            .padding(HealthSpacing.md)
            
            // Show additional skeleton cards while loading more
            ForEach(0..<3, id: \.self) { _ in
                TestCardSkeleton()
            }
        }
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
                    VStack(spacing: HealthSpacing.xs) {
                        ForEach(0..<4, id: \.self) { index in
                            HStack(spacing: HealthSpacing.md) {
                                // Icon skeleton
                                HealthSkeletonView(
                                    width: 20,
                                    height: 20,
                                    cornerRadius: HealthCornerRadius.xs
                                )
                                
                                // Text content
                                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                                    HealthSkeletonView(
                                        width: .random(in: 100...180),
                                        height: 16
                                    )
                                    HealthSkeletonView(
                                        width: .random(in: 60...120),
                                        height: 12
                                    )
                                }
                                
                                Spacer()
                            }
                            .padding(HealthSpacing.md)
                            
                            if index < 3 {
                                Divider()
                                    .padding(.leading, HealthSpacing.md)
                            }
                        }
                    }
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
    
    // MARK: - Error Overlay
    private func errorOverlay() -> some View {
        VStack(spacing: HealthSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(HealthColors.error)
            
            Text("Something Went Wrong")
                .healthTextStyle(.title3, color: HealthColors.primaryText)
            
            Text(viewModel.errorMessage ?? "An error occurred")
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
    
    // MARK: - Error Helper Methods - Simplified following Labs pattern
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