//
//  TestsListViewModel.swift
//  SuperOne
//
//  Created by Claude Code on 2025-08-31.
//  Simplified Tests ViewModel following Labs pattern while preserving UI contracts
//

import Foundation
import SwiftUI
import Combine

/// Simplified ViewModel managing tests list following Labs page pattern
@MainActor
@Observable
final class TestsListViewModel {
    
    // MARK: - Published Properties (Preserved for UI compatibility)
    
    /// Current list of tests - maintains UI contract
    private(set) var tests: [TestItemData] = []
    
    /// Current search query - maintains UI contract  
    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                handleSearchTextChange()
            }
        }
    }
    
    /// Selected category filter - maintains UI contract
    var selectedCategory: TestCategory? = nil {
        didSet {
            if selectedCategory != oldValue {
                loadTestsIfNeeded()  // Direct call - no Task wrapper like Labs
            }
        }
    }
    
    /// Loading states - copying EXACT Labs pattern
    private(set) var isLoadingTests: Bool = false
    private(set) var isLoadingMore: Bool = false
    private(set) var hasMoreTests: Bool = true
    
    /// Error handling - copying EXACT Labs pattern  
    var errorMessage: String?
    var showError: Bool = false
    
    /// Available filters from the API - maintains UI contract
    private(set) var availableFilters: AvailableFiltersData?
    
    /// Applied filters information - maintains UI contract
    private(set) var appliedFilters: FiltersAppliedData?
    
    /// Search suggestions - maintains UI contract
    private(set) var searchSuggestions: [SearchSuggestionData] = []
    
    /// Whether search suggestions are loading - maintains UI contract
    private(set) var isLoadingSuggestions: Bool = false
    
    // MARK: - Private Properties
    
    private let testsAPIService = TestsAPIService.shared
    private var currentOffset: Int = 0
    private let pageSize: Int = 20
    private var cancellables = Set<AnyCancellable>()
    
    /// Search debounce task
    private var searchTask: Task<Void, Never>?
    
    /// Suggestions debounce task
    private var suggestionsTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        #if DEBUG
        print("🔗 TestsListViewModel: Initializing with simplified API service")
        print("  - TestsAPIService: \(type(of: testsAPIService))")
        print("  - Initial tests count: \(tests.count)")
        #endif
        
        // Setup authentication state observer
        setupAuthenticationObserver()
        
        #if DEBUG
        print("📍 TestsListViewModel: Initialization complete - lazy loading pattern")
        #endif
    }
    
    deinit {
        // Tasks will be cancelled automatically when the view model is deallocated
        // No need to explicitly cancel here due to actor isolation
    }
    
    // MARK: - Public Methods (Preserving UI contracts)
    
    /// Load tests if needed - EXACT copy of Labs loadLabFacilitiesIfNeeded()
    func loadTestsIfNeeded() {
        #if DEBUG
        print("🔥 TestsListViewModel.loadTestsIfNeeded() called")
        print("  - tests.isEmpty: \(tests.isEmpty)")
        print("  - isLoadingTests: \(isLoadingTests)")
        print("  - tests.count: \(tests.count)")
        #endif
        
        // Skip if already loaded or currently loading
        guard tests.isEmpty && !isLoadingTests else { 
            #if DEBUG
            print("  - GUARD FAILED: Not calling loadTests()")
            #endif
            return 
        }
        
        #if DEBUG
        print("  - GUARD PASSED: Calling loadTests()")
        #endif
        loadTests()
    }
    
    /// Load tests - EXACT copy of Labs loadLabFacilities()
    func loadTests() {
        #if DEBUG
        print("🚀 TestsListViewModel.loadTests() called - Setting isLoadingTests = true")
        #endif
        
        isLoadingTests = true
        
        Task {
            #if DEBUG
            print("📡 Making API call to testsAPIService.searchTests()")
            #endif
            
            do {
                // Load tests from API
                let response = try await testsAPIService.searchTests(
                    query: searchText.isEmpty ? nil : searchText,
                    category: selectedCategory?.rawValue,
                    offset: 0,
                    limit: pageSize
                )
                
                // Keep tests empty if API returns empty - no fallback mock data
                tests = response.tests
                hasMoreTests = response.hasMore
                currentOffset = response.nextOffset
                
                isLoadingTests = false
            } catch {
                errorMessage = "Failed to load tests: \(error.localizedDescription)"
                showError = true
                
                // Keep tests empty on API failure - no fallback mock data
                isLoadingTests = false
            }
        }
    }
    
    /// Load more tests (infinite scroll) - maintains UI contract
    func loadMoreTests() async {
        guard !isLoadingMore && hasMoreTests && !isLoadingTests else { return }
        
        isLoadingMore = true
        
        do {
            let response = try await testsAPIService.searchTests(
                query: searchText.isEmpty ? nil : searchText,
                category: selectedCategory?.rawValue,
                offset: currentOffset,
                limit: pageSize
            )
            
            // Append new tests to existing list
            tests.append(contentsOf: response.tests)
            hasMoreTests = response.hasMore
            currentOffset = response.nextOffset
            
        } catch {
            errorMessage = "Failed to load more tests: \(error.localizedDescription)"
            showError = true
        }
        
        isLoadingMore = false
    }
    
    /// Refresh tests (pull to refresh) - maintains UI contract
    func refreshTests() {
        currentOffset = 0
        hasMoreTests = true
        loadTests()  // Remove await - direct call like Labs
    }
    
    /// Load search suggestions - maintains UI contract
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
                let suggestions = try await testsAPIService.getSearchSuggestions(
                    query: query,
                    limit: 10
                )
                
                if !Task.isCancelled {
                    await MainActor.run { searchSuggestions = suggestions }
                }
                
            } catch {
                if !Task.isCancelled {
                    await MainActor.run { searchSuggestions = [] }
                }
            }
            
            await MainActor.run { isLoadingSuggestions = false }
        }
    }
    
    /// Clear error - maintains UI contract
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    /// Force retry tests loading - maintains UI contract
    func retry() {
        loadTests()  // Direct call - no Task wrapper like Labs
    }
    
    /// Check if we should load more tests (for infinite scroll) - maintains UI contract
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
    
    /// Handle search text changes with debouncing - maintains UI contract
    private func handleSearchTextChange() {
        // Cancel previous search task
        searchTask?.cancel()
        
        searchTask = Task {
            // Debounce for 500ms
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            guard !Task.isCancelled else { return }
            
            loadTests()  // Remove await - direct call like Labs
        }
        
        // Load suggestions immediately for better UX
        Task {
            await loadSearchSuggestions(for: searchText)
        }
    }
    
    /// Setup authentication state observer - simplified
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
        
        // Listen for sign in notifications
        NotificationCenter.default
            .publisher(for: .userDidSignIn)
            .sink { [weak self] _ in
                Task {
                    await MainActor.run {
                        // Reset on successful sign in - let view handle loading
                        self?.tests = []
                        self?.errorMessage = nil
                        self?.showError = false
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Clear all tests data (called during logout) - maintains UI contract
    private func clearTestsData() {
        tests = []
        isLoadingTests = false
        isLoadingMore = false
        hasMoreTests = true
        errorMessage = nil
        showError = false
        searchText = ""
        selectedCategory = nil
        searchSuggestions = []
        isLoadingSuggestions = false
        availableFilters = nil
        appliedFilters = nil
        currentOffset = 0
    }
}

// MARK: - Computed Properties Extension (Preserving UI contracts)

extension TestsListViewModel {
    
    /// Filtered tests based on current search and category - maintains UI contract
    var filteredTests: [TestItemData] {
        return tests // API already handles filtering
    }
    
    /// Whether the list is empty and not loading - maintains UI contract
    var isEmpty: Bool {
        return tests.isEmpty && !isLoadingTests
    }
    
    /// Whether to show loading indicator - maintains UI contract
    var shouldShowLoading: Bool {
        return isLoadingTests && tests.isEmpty
    }
    
    /// Whether to show load more indicator - maintains UI contract
    var shouldShowLoadMore: Bool {
        return isLoadingMore || (hasMoreTests && !tests.isEmpty)
    }
    
    /// Categories for filter chips - maintains UI contract
    var availableCategories: [TestCategory] {
        return TestCategory.allCases
    }
    
    /// Category filter count - maintains UI contract
    func categoryCount(for category: TestCategory) -> Int {
        availableFilters?.categories.first { $0.key == category.rawValue }?.count ?? 0
    }
}

// MARK: - Error Handling Extension (Preserving UI contracts)

extension TestsListViewModel {
    
    /// Whether the error is recoverable - maintains UI contract
    var canRetry: Bool {
        guard let errorMsg = errorMessage, !errorMsg.isEmpty else { return false }
        return true // Most errors in this simplified pattern are retryable
    }
}

// MARK: - Search Functionality Extension (Preserving UI contracts)

extension TestsListViewModel {
    
    /// Apply a search suggestion - maintains UI contract
    /// - Parameter suggestion: The selected suggestion
    func applySuggestion(_ suggestion: SearchSuggestionData) {
        searchText = suggestion.text
        searchSuggestions = [] // Clear suggestions after selection
    }
    
    /// Clear search - maintains UI contract
    func clearSearch() {
        searchText = ""
        searchSuggestions = []
    }
    
    /// Whether search suggestions should be shown - maintains UI contract
    var shouldShowSuggestions: Bool {
        return !searchSuggestions.isEmpty && !searchText.isEmpty
    }
}

// TestCategory extension already defined in TestsAPIModels.swift