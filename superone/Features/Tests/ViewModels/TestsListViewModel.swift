//
//  TestsListViewModel.swift
//  SuperOne
//
//  Created by Claude Code on 2025-08-31.
//  Offset-based pagination ViewModel for Tests List with infinite scroll
//

import Foundation
import SwiftUI

/// ViewModel managing tests list with offset-based pagination and infinite scroll
@MainActor
@Observable
final class TestsListViewModel {
    
    // MARK: - Published Properties
    
    /// Current list of tests
    private(set) var tests: [TestItemData] = []
    
    /// Current search query
    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                handleSearchTextChange()
            }
        }
    }
    
    /// Selected category filter
    var selectedCategory: TestCategory? = nil {
        didSet {
            if selectedCategory != oldValue {
                resetAndLoadTests()
            }
        }
    }
    
    /// Current loading state
    private(set) var isLoading: Bool = false
    
    /// Whether we're loading more tests (infinite scroll)
    private(set) var isLoadingMore: Bool = false
    
    /// Whether there are more tests to load
    private(set) var hasMoreTests: Bool = true
    
    /// Current error if any
    private(set) var error: TestsAPIError?
    
    /// Available filters from the API
    private(set) var availableFilters: AvailableFiltersData?
    
    /// Applied filters information
    private(set) var appliedFilters: FiltersAppliedData?
    
    /// Search suggestions
    private(set) var searchSuggestions: [SearchSuggestionData] = []
    
    /// Whether search suggestions are loading
    private(set) var isLoadingSuggestions: Bool = false
    
    // MARK: - Private Properties
    
    private let testsAPIService = TestsAPIService.shared
    private var currentOffset: Int = 0
    private let pageSize: Int = 20
    
    /// Current test filters
    private var currentFilters: TestFilters? {
        return TestFilters(
            category: selectedCategory,
            available: true // Always show only available tests
        )
    }
    
    /// Search debounce task
    private var searchTask: Task<Void, Never>?
    
    /// Suggestions debounce task
    private var suggestionsTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        // Load initial data
        Task {
            await loadTests()
        }
    }
    
    // MARK: - Public Methods
    
    /// Load initial tests (reset pagination)
    func loadTests() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        currentOffset = 0
        hasMoreTests = true
        
        do {
            let response = try await testsAPIService.getTests(
                offset: currentOffset,
                limit: pageSize,
                search: searchText.isEmpty ? nil : searchText,
                filters: currentFilters
            )
            
            tests = response.tests
            availableFilters = response.availableFilters
            appliedFilters = response.filtersApplied
            hasMoreTests = response.pagination.hasMore
            currentOffset = response.pagination.nextOffset ?? currentOffset
            
        } catch let apiError as TestsAPIError {
            error = apiError
            tests = []
        } catch {
            self.error = TestsAPIError.fetchFailed(error.localizedDescription)
            tests = []
        }
        
        isLoading = false
    }
    
    /// Load more tests (infinite scroll)
    func loadMoreTests() async {
        guard !isLoadingMore && hasMoreTests && !isLoading else { return }
        
        isLoadingMore = true
        
        do {
            let response = try await testsAPIService.getTests(
                offset: currentOffset,
                limit: pageSize,
                search: searchText.isEmpty ? nil : searchText,
                filters: currentFilters
            )
            
            // Append new tests to existing list
            tests.append(contentsOf: response.tests)
            hasMoreTests = response.pagination.hasMore
            currentOffset = response.pagination.nextOffset ?? currentOffset
            
        } catch let apiError as TestsAPIError {
            self.error = apiError
        } catch {
            self.error = TestsAPIError.fetchFailed(error.localizedDescription)
        }
        
        isLoadingMore = false
    }
    
    /// Refresh tests (pull to refresh)
    func refreshTests() async {
        currentOffset = 0
        hasMoreTests = true
        await loadTests()
    }
    
    /// Toggle favorite status for a test
    /// - Parameter testId: Test identifier
    func toggleFavorite(for testId: String) async {
        do {
            let response = try await testsAPIService.toggleFavorite(testId: testId)
            
            // Update the test in the local list
            if let index = tests.firstIndex(where: { $0.id == testId }) {
                // Note: We don't have isFavorite in TestItemData, so this is a placeholder
                // In a real implementation, you'd need to add this field to the model
                // or refresh the specific test data
            }
            
        } catch let apiError as TestsAPIError {
            self.error = apiError
        } catch {
            self.error = TestsAPIError.favoriteUpdateFailed(error.localizedDescription)
        }
    }
    
    /// Load search suggestions
    /// - Parameter query: Search query
    func loadSearchSuggestions(for query: String) async {
        guard query.count >= 2 else {
            searchSuggestions = []
            return
        }
        
        // Cancel previous suggestions task
        suggestionsTask?.cancel()
        
        suggestionsTask = Task {
            // Debounce for 300ms
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            guard !Task.isCancelled else { return }
            
            isLoadingSuggestions = true
            
            do {
                let response = try await testsAPIService.getSearchSuggestions(
                    query: query,
                    limit: 10
                )
                
                if !Task.isCancelled {
                    searchSuggestions = response.suggestions
                }
                
            } catch {
                if !Task.isCancelled {
                    searchSuggestions = []
                }
            }
            
            isLoadingSuggestions = false
        }
    }
    
    /// Clear error
    func clearError() {
        error = nil
    }
    
    /// Check if we should load more tests (for infinite scroll)
    /// - Parameter testId: ID of the test that appeared
    func checkForLoadMore(testId: String) {
        // Load more when we're near the end (last 5 items)
        if let index = tests.firstIndex(where: { $0.id == testId }),
           index >= tests.count - 5 {
            Task {
                await loadMoreTests()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Handle search text changes with debouncing
    private func handleSearchTextChange() {
        // Cancel previous search task
        searchTask?.cancel()
        
        searchTask = Task {
            // Debounce for 500ms
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            guard !Task.isCancelled else { return }
            
            await resetAndLoadTests()
        }
        
        // Load suggestions immediately for better UX
        Task {
            await loadSearchSuggestions(for: searchText)
        }
    }
    
    /// Reset pagination and load tests
    private func resetAndLoadTests() async {
        currentOffset = 0
        hasMoreTests = true
        await loadTests()
    }
}

// MARK: - Computed Properties Extension

extension TestsListViewModel {
    
    /// Filtered tests based on current search and category
    var filteredTests: [TestItemData] {
        return tests // API already handles filtering
    }
    
    /// Whether the list is empty and not loading
    var isEmpty: Bool {
        return tests.isEmpty && !isLoading
    }
    
    /// Whether to show loading indicator
    var shouldShowLoading: Bool {
        return isLoading && tests.isEmpty
    }
    
    /// Whether to show load more indicator
    var shouldShowLoadMore: Bool {
        return isLoadingMore || (hasMoreTests && !tests.isEmpty)
    }
    
    /// Categories for filter chips
    var availableCategories: [TestCategory] {
        return TestCategory.allCases
    }
    
    /// Category filter count
    func categoryCount(for category: TestCategory) -> Int {
        availableFilters?.categories.first { $0.key == category.rawValue }?.count ?? 0
    }
}

// MARK: - Error Handling Extension

extension TestsListViewModel {
    
    /// User-friendly error message
    var errorMessage: String {
        guard let error = error else { return "" }
        
        switch error {
        case .fetchFailed(let message):
            return "Failed to load tests: \(message)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        case .networkError(let networkError):
            return "Network error: \(networkError.localizedDescription)"
        default:
            return error.errorDescription ?? "An unknown error occurred"
        }
    }
    
    /// Whether the error is recoverable
    var canRetry: Bool {
        guard let error = error else { return false }
        
        switch error {
        case .fetchFailed, .searchFailed, .networkError:
            return true
        default:
            return false
        }
    }
    
    /// Retry the failed operation
    func retry() {
        Task {
            await loadTests()
        }
    }
}

// MARK: - Search Functionality Extension

extension TestsListViewModel {
    
    /// Apply a search suggestion
    /// - Parameter suggestion: The selected suggestion
    func applySuggestion(_ suggestion: SearchSuggestionData) {
        searchText = suggestion.text
        searchSuggestions = [] // Clear suggestions after selection
    }
    
    /// Clear search
    func clearSearch() {
        searchText = ""
        searchSuggestions = []
    }
    
    /// Whether search suggestions should be shown
    var shouldShowSuggestions: Bool {
        return !searchSuggestions.isEmpty && !searchText.isEmpty
    }
}

// MARK: - Preview Support

#if DEBUG
extension TestsListViewModel {
    
    /// Create a mock instance for previews
    static func mock() -> TestsListViewModel {
        let viewModel = TestsListViewModel()
        
        // Add mock data
        Task { @MainActor in
            viewModel.tests = [
                // Mock test data would go here
            ]
            viewModel.isLoading = false
            viewModel.hasMoreTests = true
        }
        
        return viewModel
    }
}
#endif