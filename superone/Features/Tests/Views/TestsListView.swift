import SwiftUI

/// Simple tests list view for navigation to test details
struct TestsListView: View {
    
    // MARK: - Properties
    @State private var searchText = ""
    @State private var selectedCategory: TestCategory? = nil
    private let tests = [
        TestDetails.sampleCBC(),
        TestDetails.sampleLipidProfile()
    ]
    
    // MARK: - Computed Properties
    private var filteredTests: [TestDetails] {
        var filtered = tests
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { test in
                test.name.localizedCaseInsensitiveContains(searchText) ||
                test.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter section
                searchAndFilterSection
                
                // Tests list
                testsList
            }
            .navigationTitle("Health Tests")
            .navigationBarTitleDisplayMode(.large)
            .background(HealthColors.secondaryBackground.ignoresSafeArea())
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: HealthSpacing.md) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(HealthColors.secondaryText)
                
                TextField("Search tests...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
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
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    // Individual category buttons
                    ForEach(TestCategory.allCases, id: \.self) { category in
                        CategoryFilterChip(
                            title: category.displayName,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
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
                if filteredTests.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredTests, id: \.id) { test in
                        NavigationLink(destination: TestDetailsView(testId: test.id)) {
                            TestListCard(test: test)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.vertical, HealthSpacing.lg)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: HealthSpacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(HealthColors.secondaryText)
            
            Text("No tests found")
                .healthTextStyle(.title3, color: HealthColors.primaryText)
            
            Text("Try adjusting your search or filter criteria")
                .healthTextStyle(.body, color: HealthColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, HealthSpacing.xxxxl)
    }
}

// MARK: - Category Filter Chip

private struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .healthTextStyle(.captionMedium, color: isSelected ? .white : HealthColors.primaryText)
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
    let test: TestDetails
    
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