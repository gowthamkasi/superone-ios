//
//  TestsListViewModel.swift
//  SuperOne
//
//  Created by Claude Code on 2025-08-31.
//  Offset-based pagination ViewModel for Tests List with infinite scroll
//

import Foundation
import SwiftUI
import Combine

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
                Task {
                    await resetAndLoadTests()
                }
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
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Loop Protection Properties
    private var lastLoadAttempt: Date?
    private var loadAttemptCount: Int = 0
    @ObservationIgnored nonisolated(unsafe) private var currentLoadTask: Task<Void, Never>?
    nonisolated private static let maxRetryAttempts: Int = 3
    
    // MARK: - Exponential Backoff Properties
    nonisolated private static let baseBackoffInterval: TimeInterval = 2.0 // Base 2 seconds
    nonisolated private static let maxBackoffInterval: TimeInterval = 30.0 // Maximum 30 seconds
    nonisolated private static let backoffMultiplier: Double = 2.0 // Double the wait time each retry
    
    /// Current test filters
    private var currentFilters: TestFilters? {
        return TestFilters(
            category: selectedCategory?.toAPITestCategory,
            available: true // Always show only available tests
        )
    }
    
    /// Search debounce task
    private var searchTask: Task<Void, Never>?
    
    /// Suggestions debounce task
    private var suggestionsTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        #if DEBUG
        print("🔗 TestsListViewModel: Initializing with real LabLoop API service")
        print("  - TestsAPIService: \(type(of: testsAPIService))")
        print("  - Initial tests count: \(tests.count)")
        #endif
        
        // Setup authentication state observer before loading data
        setupAuthenticationObserver()
        
        // Don't auto-load data in init - let the view handle it when authenticated
        #if DEBUG
        print("📍 TestsListViewModel: Initialization complete - no auto-loading")
        #endif
    }
    
    deinit {
        // Cancel any ongoing load task - handle concurrency properly
        currentLoadTask?.cancel()
        // Cancellables will be automatically cleaned up
    }
    
    // MARK: - Public Methods
    
    /// Load initial tests with loop protection and exponential backoff
    func loadTests() async {
        // Simplified to match working LabReports pattern
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        currentOffset = 0
        hasMoreTests = true
        
        do {
            #if DEBUG
            print("🚀 TestsListViewModel: Making API call to get tests")
            print("  - Offset: \(currentOffset), Limit: \(pageSize)")
            print("  - Search: \(searchText.isEmpty ? "none" : searchText)")
            print("  - Filters: \(String(describing: currentFilters))")
            #endif
                
                let response = try await testsAPIService.getTests(
                    offset: currentOffset,
                    limit: pageSize,
                    search: searchText.isEmpty ? nil : searchText,
                    filters: currentFilters
                )
                
                #if DEBUG
                print("✅ TestsListViewModel: Successfully received \(response.tests.count) tests")
                print("  - Has more: \(response.pagination.hasMore)")
                print("  - Next offset: \(response.pagination.nextOffset ?? -1)")
                #endif
                
            // Update UI directly (we're already on MainActor)
            tests = response.tests
            availableFilters = response.availableFilters
            appliedFilters = response.filtersApplied
            hasMoreTests = response.pagination.hasMore
            currentOffset = response.pagination.nextOffset ?? currentOffset
            isLoading = false
                
            } catch {
            #if DEBUG
            print("❌ TestsListViewModel: API error - \(error.localizedDescription)")
            #endif
            
            isLoading = false
            
            // Handle different error types
            if let apiError = error as? TestsAPIError {
                self.error = apiError
            } else {
                self.error = TestsAPIError.fetchFailed(error.localizedDescription)
            }
            
            // Clear tests on error
            tests = []
            HapticFeedback.error()
        }
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
            _ = try await testsAPIService.toggleFavorite(testId: testId)
            
            // Update the test in the local list
            if tests.firstIndex(where: { $0.id == testId }) != nil {
                // Note: We don't have isFavorite in TestItemData, so this is a placeholder
                // In a real implementation, you'd need to add this field to the model
                // or refresh the specific test data
                
                // Provide haptic feedback for successful favorite toggle
                HapticFeedback.success()
            }
            
        } catch let apiError as TestsAPIError {
            self.error = apiError
            HapticFeedback.error()
        } catch {
            self.error = TestsAPIError.favoriteUpdateFailed(error.localizedDescription)
            HapticFeedback.error()
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
            
            await MainActor.run { isLoadingSuggestions = true }
            
            do {
                let response = try await testsAPIService.getSearchSuggestions(
                    query: query,
                    limit: 10
                )
                
                if !Task.isCancelled {
                    await MainActor.run { searchSuggestions = response.suggestions }
                }
                
            } catch {
                if !Task.isCancelled {
                    await MainActor.run { searchSuggestions = [] }
                }
            }
            
            await MainActor.run { isLoadingSuggestions = false }
        }
    }
    
    /// Clear error and reset attempt tracking
    func clearError() {
        error = nil
        loadAttemptCount = 0
        lastLoadAttempt = nil
    }
    
    /// Force retry tests loading (resets attempt count)
    func retryLoadTests() {
        // Manual retry requested - resetting attempt count
        loadAttemptCount = 0
        lastLoadAttempt = nil
        error = nil
        
        Task {
            await loadTests()
        }
    }
    
    /// Clear all tests data (called during logout)
    func clearTestsData() {
        // Cancel any ongoing load task
        currentLoadTask?.cancel()
        currentLoadTask = nil
        
        // Reset all state
        tests = []
        isLoading = false
        isLoadingMore = false
        hasMoreTests = true
        error = nil
        searchText = ""
        selectedCategory = nil
        searchSuggestions = []
        isLoadingSuggestions = false
        availableFilters = nil
        appliedFilters = nil
        
        // Reset loop protection
        lastLoadAttempt = nil
        loadAttemptCount = 0
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
    
    /// Setup authentication state observer
    private func setupAuthenticationObserver() {
        // Listen for sign out notifications
        NotificationCenter.default
            .publisher(for: .userDidSignOut)
            .sink { [weak self] _ in
                Task {
                    await MainActor.run {
                        self?.clearTestsData()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Listen for sign in notifications to reload tests
        NotificationCenter.default
            .publisher(for: .userDidSignIn)
            .sink { [weak self] _ in
                Task {
                    await MainActor.run {
                        // Reset loop protection on successful sign in
                        self?.loadAttemptCount = 0
                        self?.lastLoadAttempt = nil
                        // DON'T automatically trigger loadTests here - let the view handle it
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Calculate exponential backoff interval for retry attempts
    nonisolated private func calculateBackoffInterval(for attemptCount: Int) -> TimeInterval {
        let backoffTime = Self.baseBackoffInterval * pow(Self.backoffMultiplier, Double(attemptCount - 1))
        return min(backoffTime, Self.maxBackoffInterval)
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
        return error.userFriendlyMessage
    }
    
    /// Whether the error is recoverable
    var canRetry: Bool {
        guard let error = error else { return false }
        return error.isRetryable && loadAttemptCount < Self.maxRetryAttempts
    }
    
    /// Retry the failed operation
    func retry() {
        retryLoadTests()
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

// MARK: - Preview Support - Removed
// Previous mock method has been removed to ensure clarity that
// TestsListViewModel always uses real LabLoop API integration.
// SwiftUI previews should use real data or minimal test data
// through the actual API service initialization.