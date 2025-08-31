//
//  TestsAPIService.swift
//  SuperOne
//
//  Created by Claude Code on 2025-08-31.
//  Tests API Integration Service with offset/limit pagination
//

@preconcurrency import Foundation

// Data models are defined in TestsAPIModels.swift to ensure proper actor isolation

/// Service for interacting with Tests and Health Packages APIs
final class TestsAPIService {
    
    // MARK: - Singleton
    
    static let shared = TestsAPIService()
    
    // MARK: - Properties
    
    private let networkService = NetworkService.shared
    private let baseEndpoint = "/mobile/tests"
    private let packagesEndpoint = "/mobile/packages"
    private let favoritesEndpoint = "/mobile/favorites/tests"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Tests API Methods
    
    /// Get paginated list of tests with filtering
    /// - Parameters:
    ///   - offset: Number of records to skip (default: 0)
    ///   - limit: Maximum records to return (default: 20, max: 50)
    ///   - search: Search query for tests
    ///   - filters: Test filters for category, price, etc.
    /// - Returns: Tests list response with pagination
    @MainActor
    func getTests(
        offset: Int = 0,
        limit: Int = 20,
        search: String? = nil,
        filters: TestFilters? = nil
    ) async throws -> TestsListResponse {
        
        // Build query parameters
        var queryParams: [String: String] = [
            "offset": String(offset),
            "limit": String(min(limit, 50)) // Enforce API limit
        ]
        
        // Add search query if provided
        if let search = search, !search.isEmpty {
            queryParams["search"] = search
        }
        
        // Add filters if provided
        if let filters = filters {
            if let category = filters.category {
                queryParams["category"] = category.rawValue
            }
            
            if let priceMin = filters.priceMin {
                queryParams["price_min"] = String(priceMin)
            }
            
            if let priceMax = filters.priceMax {
                queryParams["price_max"] = String(priceMax)
            }
            
            if let fastingRequired = filters.fastingRequired {
                queryParams["fasting_required"] = String(fastingRequired)
            }
            
            if let sampleType = filters.sampleType {
                queryParams["sample_type"] = sampleType.rawValue
            }
            
            if let featured = filters.featured {
                queryParams["featured"] = String(featured)
            }
            
            if let available = filters.available {
                queryParams["available"] = String(available)
            }
            
            if let sortBy = filters.sortBy {
                queryParams["sort_by"] = sortBy.rawValue
            }
            
            if let sortOrder = filters.sortOrder {
                queryParams["sort_order"] = sortOrder.rawValue
            }
        }
        
        // Build URL with query parameters
        let url = buildURL(endpoint: baseEndpoint, queryParams: queryParams)
        
        do {
            // Make network request
            let response: BaseResponse<TestsListData> = try await networkService.get(
                url,
                responseType: BaseResponse<TestsListData>.self
            )
            
            // Validate response
            try response.validate()
            let data = try response.getData()
            
            return TestsListResponse(
                tests: data.tests,
                pagination: data.pagination,
                filtersApplied: data.filtersApplied,
                availableFilters: data.availableFilters
            )
            
        } catch {
            throw TestsAPIError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Get detailed information for a specific test
    /// - Parameter testId: Unique test identifier
    /// - Returns: Comprehensive test details
    @MainActor
    func getTestDetails(testId: String) async throws -> TestDetailsResponse {
        let url = buildURL(endpoint: "\(baseEndpoint)/\(testId)")
        
        do {
            let response: BaseResponse<TestDetailsData> = try await networkService.get(
                url,
                responseType: BaseResponse<TestDetailsData>.self
            )
            
            try response.validate()
            let data = try response.getData()
            
            return TestDetailsResponse(testDetails: data)
            
        } catch {
            throw TestsAPIError.testNotFound(testId)
        }
    }
    
    /// Get paginated list of health packages
    /// - Parameters:
    ///   - offset: Number of records to skip
    ///   - limit: Maximum records to return
    ///   - search: Search query
    ///   - filters: Package filters
    /// - Returns: Health packages list response
    @MainActor
    func getPackages(
        offset: Int = 0,
        limit: Int = 10,
        search: String? = nil,
        filters: PackageFilters? = nil
    ) async throws -> PackagesListResponse {
        
        var queryParams: [String: String] = [
            "offset": String(offset),
            "limit": String(min(limit, 20)) // Enforce API limit
        ]
        
        if let search = search, !search.isEmpty {
            queryParams["search"] = search
        }
        
        if let filters = filters {
            if let priceMin = filters.priceMin {
                queryParams["price_min"] = String(priceMin)
            }
            
            if let priceMax = filters.priceMax {
                queryParams["price_max"] = String(priceMax)
            }
            
            if let testCountMin = filters.testCountMin {
                queryParams["test_count_min"] = String(testCountMin)
            }
            
            if let testCountMax = filters.testCountMax {
                queryParams["test_count_max"] = String(testCountMax)
            }
            
            if let featured = filters.featured {
                queryParams["featured"] = String(featured)
            }
            
            if let popular = filters.popular {
                queryParams["popular"] = String(popular)
            }
            
            if let available = filters.available {
                queryParams["available"] = String(available)
            }
            
            if let sortBy = filters.sortBy {
                queryParams["sort_by"] = sortBy.rawValue
            }
            
            if let sortOrder = filters.sortOrder {
                queryParams["sort_order"] = sortOrder.rawValue
            }
        }
        
        let url = buildURL(endpoint: packagesEndpoint, queryParams: queryParams)
        
        do {
            let response: BaseResponse<PackagesListData> = try await networkService.get(
                url,
                responseType: BaseResponse<PackagesListData>.self
            )
            
            try response.validate()
            let data = try response.getData()
            
            return PackagesListResponse(
                packages: data.packages,
                pagination: data.pagination,
                filtersApplied: data.filtersApplied,
                availableFilters: data.availableFilters
            )
            
        } catch {
            throw TestsAPIError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Get detailed information for a specific health package
    /// - Parameter packageId: Unique package identifier
    /// - Returns: Comprehensive package details
    @MainActor
    func getPackageDetails(packageId: String) async throws -> PackageDetailsResponse {
        let url = buildURL(endpoint: "\(packagesEndpoint)/\(packageId)")
        
        do {
            let response: BaseResponse<PackageDetailsData> = try await networkService.get(
                url,
                responseType: BaseResponse<PackageDetailsData>.self
            )
            
            try response.validate()
            let data = try response.getData()
            
            return PackageDetailsResponse(packageDetails: data)
            
        } catch {
            throw TestsAPIError.packageNotFound(packageId)
        }
    }
    
    /// Toggle favorite status for a test
    /// - Parameter testId: Test identifier
    /// - Returns: Updated favorite status
    @MainActor
    func toggleFavorite(testId: String) async throws -> FavoriteStatusResponse {
        // First check current status to determine action
        let currentFavorites = try await getUserFavorites(offset: 0, limit: 50)
        let isFavorite = currentFavorites.favorites.contains { $0.id == testId }
        
        let url = buildURL(endpoint: "\(baseEndpoint)/\(testId)/favorite")
        do {
            let response: BaseResponse<FavoriteStatusData> = isFavorite 
                ? try await networkService.delete(url, responseType: BaseResponse<FavoriteStatusData>.self)
                : try await networkService.post(url, responseType: BaseResponse<FavoriteStatusData>.self)
            
            try response.validate()
            let data = try response.getData()
            
            return FavoriteStatusResponse(
                testId: data.testId,
                isFavorite: data.isFavorite
            )
            
        } catch {
            throw TestsAPIError.favoriteUpdateFailed(error.localizedDescription)
        }
    }
    
    /// Get user's favorite tests
    /// - Parameters:
    ///   - offset: Number of records to skip
    ///   - limit: Maximum records to return
    /// - Returns: User's favorite tests
    @MainActor
    func getUserFavorites(
        offset: Int = 0,
        limit: Int = 20
    ) async throws -> FavoritesListResponse {
        
        let queryParams: [String: String] = [
            "offset": String(offset),
            "limit": String(limit)
        ]
        
        let url = buildURL(endpoint: favoritesEndpoint, queryParams: queryParams)
        
        do {
            let response: BaseResponse<FavoritesListData> = try await networkService.get(
                url,
                responseType: BaseResponse<FavoritesListData>.self
            )
            
            try response.validate()
            let data = try response.getData()
            
            return FavoritesListResponse(
                favorites: data.favorites,
                pagination: data.pagination
            )
            
        } catch {
            throw TestsAPIError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Get search suggestions for tests and packages
    /// - Parameters:
    ///   - query: Search query (minimum 2 characters)
    ///   - limit: Maximum suggestions to return
    /// - Returns: Search suggestions
    @MainActor
    func getSearchSuggestions(
        query: String,
        limit: Int = 10
    ) async throws -> SearchSuggestionsResponse {
        
        guard query.count >= 2 else {
            throw TestsAPIError.invalidRequest("Query must be at least 2 characters")
        }
        
        let queryParams: [String: String] = [
            "q": query,
            "limit": String(limit)
        ]
        
        let url = buildURL(endpoint: "\(baseEndpoint)/search/suggestions", queryParams: queryParams)
        
        do {
            let response: BaseResponse<SearchSuggestionsData> = try await networkService.get(
                url,
                responseType: BaseResponse<SearchSuggestionsData>.self
            )
            
            try response.validate()
            let data = try response.getData()
            
            return SearchSuggestionsResponse(
                suggestions: data.suggestions,
                popularSearches: data.popularSearches
            )
            
        } catch {
            throw TestsAPIError.searchFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Build URL with base path and query parameters
    private func buildURL(endpoint: String, queryParams: [String: String] = [:]) -> String {
        var url = endpoint
        
        if !queryParams.isEmpty {
            let queryString = queryParams
                .compactMap { key, value in
                    guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                          let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                        return nil
                    }
                    return "\(encodedKey)=\(encodedValue)"
                }
                .joined(separator: "&")
            
            url += "?\(queryString)"
        }
        
        return url
    }
}

// MARK: - Filter Models

/// Test filters for API requests
struct TestFilters: Sendable {
    let category: TestCategory?
    let priceMin: Int?
    let priceMax: Int?
    let fastingRequired: Bool?
    let sampleType: SampleType?
    let featured: Bool?
    let available: Bool?
    let sortBy: TestSortField?
    let sortOrder: TestsSortOrder?
    
    init(
        category: TestCategory? = nil,
        priceMin: Int? = nil,
        priceMax: Int? = nil,
        fastingRequired: Bool? = nil,
        sampleType: SampleType? = nil,
        featured: Bool? = nil,
        available: Bool? = nil,
        sortBy: TestSortField? = nil,
        sortOrder: TestsSortOrder? = nil
    ) {
        self.category = category
        self.priceMin = priceMin
        self.priceMax = priceMax
        self.fastingRequired = fastingRequired
        self.sampleType = sampleType
        self.featured = featured
        self.available = available
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }
}

/// Package filters for API requests
struct PackageFilters: Sendable {
    let priceMin: Int?
    let priceMax: Int?
    let testCountMin: Int?
    let testCountMax: Int?
    let featured: Bool?
    let popular: Bool?
    let available: Bool?
    let sortBy: PackageSortField?
    let sortOrder: TestsSortOrder?
    
    init(
        priceMin: Int? = nil,
        priceMax: Int? = nil,
        testCountMin: Int? = nil,
        testCountMax: Int? = nil,
        featured: Bool? = nil,
        popular: Bool? = nil,
        available: Bool? = nil,
        sortBy: PackageSortField? = nil,
        sortOrder: TestsSortOrder? = nil
    ) {
        self.priceMin = priceMin
        self.priceMax = priceMax
        self.testCountMin = testCountMin
        self.testCountMax = testCountMax
        self.featured = featured
        self.popular = popular
        self.available = available
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }
}

// MARK: - Sort Enums

enum TestSortField: String, CaseIterable, Sendable {
    case name = "name"
    case price = "price"
    case duration = "duration"
    case popularity = "popularity"
}

enum PackageSortField: String, CaseIterable, Sendable {
    case name = "name"
    case price = "price"
    case testCount = "test_count"
    case popularity = "popularity"
    case savings = "savings"
}

enum TestsSortOrder: String, CaseIterable, Sendable {
    case ascending = "asc"
    case descending = "desc"
}

// MARK: - API Response Models

/// Tests list response model
struct TestsListResponse: Sendable {
    let tests: [TestItemData]
    let pagination: OffsetPagination
    let filtersApplied: FiltersAppliedData?
    let availableFilters: AvailableFiltersData?
}

/// Package list response model
struct PackagesListResponse: Sendable {
    let packages: [PackageItemData]
    let pagination: OffsetPagination
    let filtersApplied: PackageFiltersAppliedData?
    let availableFilters: PackageAvailableFiltersData?
}

/// Test details response model
struct TestDetailsResponse: Sendable {
    let testDetails: TestDetailsData
}

/// Package details response model
struct PackageDetailsResponse: Sendable {
    let packageDetails: PackageDetailsData
}

/// Favorite status response model
struct FavoriteStatusResponse: Sendable {
    let testId: String
    let isFavorite: Bool
}

/// Favorites list response model
struct FavoritesListResponse: Sendable {
    let favorites: [FavoriteTestData]
    let pagination: OffsetPagination
}

/// Search suggestions response model
struct SearchSuggestionsResponse: Sendable {
    let suggestions: [SearchSuggestionData]
    let popularSearches: [String]
}

// MARK: - Error Handling

/// Custom errors for Tests API operations
enum TestsAPIError: LocalizedError, Sendable {
    case fetchFailed(String)
    case testNotFound(String)
    case packageNotFound(String)
    case favoriteUpdateFailed(String)
    case searchFailed(String)
    case invalidRequest(String)
    case networkError(Error)
    
    nonisolated var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to fetch data: \(message)"
        case .testNotFound(let testId):
            return "Test not found: \(testId)"
        case .packageNotFound(let packageId):
            return "Package not found: \(packageId)"
        case .favoriteUpdateFailed(let message):
            return "Failed to update favorites: \(message)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    nonisolated var recoverySuggestion: String? {
        switch self {
        case .fetchFailed, .searchFailed:
            return "Please try again or check your internet connection."
        case .testNotFound, .packageNotFound:
            return "The requested item may have been removed or is temporarily unavailable."
        case .favoriteUpdateFailed:
            return "Please try updating your favorites again."
        case .invalidRequest:
            return "Please check your input and try again."
        case .networkError:
            return "Please check your internet connection and try again."
        }
    }
}