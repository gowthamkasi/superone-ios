//
//  TestsAPIService.swift
//  SuperOne
//
//  Created by Claude Code on 2025-08-31.
//  Tests API Integration Service with offset/limit pagination
//

@preconcurrency import Foundation
import UIKit
import Combine
import os.log
@preconcurrency import Alamofire

// Data models are defined in TestsAPIModels.swift to ensure proper actor isolation

/// Service for interacting with Tests and Health Packages APIs with proper authentication
@MainActor
class TestsAPIService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = TestsAPIService()
    
    // MARK: - Properties
    
    private let networkService: NetworkService
    private let tokenManager = TokenManager.shared
    private let logger = Logger(subsystem: "com.superone.health", category: "TestsAPI")
    
    private let baseEndpoint = "/mobile/tests"
    private let packagesEndpoint = "/mobile/packages"
    private let favoritesEndpoint = "/mobile/favorites/tests"
    
    // MARK: - Initialization
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Tests API Methods
    
    /// Get paginated list of tests with filtering
    /// - Parameters:
    ///   - offset: Number of records to skip (default: 0)
    ///   - limit: Maximum records to return (default: 20, max: 50)
    ///   - search: Search query for tests
    ///   - filters: Test filters for category, price, etc.
    /// - Returns: Tests list response with pagination
    /// - Throws: TestsAPIError for various error conditions
    nonisolated func getTests(
        offset: Int = 0,
        limit: Int = 20,
        search: String? = nil,
        filters: TestFilters? = nil
    ) async throws -> TestsListResponse {
        
        // Ensure we have a valid authentication token
        guard let token = await tokenManager.getValidToken() else {
            #if DEBUG
            print("🔒 TestsAPIService: No valid authentication token available")
            print("  - Has stored tokens: \(tokenManager.hasStoredTokens())")
            #endif
            throw TestsAPIError.unauthorized("Authentication token required")
        }
        
        #if DEBUG
        print("✅ TestsAPIService: Authentication token available for API call")
        #endif
        
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
            print("🔍 TestsAPIService: Starting tests list request")
            print("🔍 Request URL: \(url)")
            print("🔍 Query params: \(queryParams)")
            
            // Make network request with authentication
            let response: BaseResponse<TestsListData> = try await networkService.get(
                url,
                responseType: BaseResponse<TestsListData>.self,
                parameters: nil,
                headers: nil,
                useCache: true
            )
            
            // Validate response
            try response.validate()
            let data = try response.getData()
            
            print("✅ TestsAPIService: Successfully loaded tests")
            print("🔍 Tests count: \(data.tests.count)")
            print("🔍 Has more: \(data.pagination.hasMore)")
            
            return TestsListResponse(
                tests: data.tests,
                pagination: data.pagination,
                filtersApplied: data.filtersApplied,
                availableFilters: data.availableFilters
            )
            
        } catch {
            print("❌ TestsAPIService: Error occurred during tests fetch")
            
            // Handle specific network errors
            if let afError = error.asAFError {
                switch afError {
                case .sessionTaskFailed(let sessionError):
                    if let urlError = sessionError as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet:
                            throw TestsAPIError.networkError("No internet connection available")
                        case .timedOut:
                            throw TestsAPIError.networkError("Request timed out")
                        default:
                            throw TestsAPIError.networkError("Network error: \(urlError.localizedDescription)")
                        }
                    }
                case .responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)):
                    switch statusCode {
                    case 401:
                        await tokenManager.clearTokens()
                        throw TestsAPIError.unauthorized("Authentication required")
                    case 403:
                        throw TestsAPIError.forbidden("Access to tests not permitted")
                    case 500...599:
                        throw TestsAPIError.serverError("Server error occurred")
                    default:
                        throw TestsAPIError.unknownError("HTTP \(statusCode): Failed to fetch tests")
                    }
                default:
                    throw TestsAPIError.networkError("Network error: \(afError.localizedDescription)")
                }
            }
            
            // Re-throw TestsAPIError as-is
            if error is TestsAPIError {
                throw error
            }
            
            // Handle unknown errors
            throw TestsAPIError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Get detailed information for a specific test
    /// - Parameter testId: Unique test identifier
    /// - Returns: Comprehensive test details
    /// - Throws: TestsAPIError for various error conditions
    nonisolated func getTestDetails(testId: String) async throws -> TestDetailsResponse {
        
        // Ensure we have a valid authentication token
        guard let token = await tokenManager.getValidToken() else {
            #if DEBUG
            print("🔒 TestsAPIService: No valid authentication token available")
            print("  - Has stored tokens: \(tokenManager.hasStoredTokens())")
            #endif
            throw TestsAPIError.unauthorized("Authentication token required")
        }
        
        #if DEBUG
        print("✅ TestsAPIService: Authentication token available for API call")
        #endif
        
        let url = buildURL(endpoint: "\(baseEndpoint)/\(testId)")
        
        do {
            print("🔍 TestsAPIService: Starting test details request")
            print("🔍 Test ID: \(testId)")
            print("🔍 Request URL: \(url)")
            
            let response: BaseResponse<TestDetailsData> = try await networkService.get(
                url,
                responseType: BaseResponse<TestDetailsData>.self,
                parameters: nil,
                headers: nil,
                useCache: true
            )
            
            try response.validate()
            let data = try response.getData()
            
            print("✅ TestsAPIService: Successfully loaded test details")
            print("🔍 Test name: \(data.name)")
            
            return TestDetailsResponse(testDetails: data)
            
        } catch {
            print("❌ TestsAPIService: Error occurred during test details fetch")
            
            // Handle specific network errors
            if let afError = error.asAFError {
                switch afError {
                case .responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)):
                    switch statusCode {
                    case 401:
                        await tokenManager.clearTokens()
                        throw TestsAPIError.unauthorized("Authentication required")
                    case 403:
                        throw TestsAPIError.forbidden("Access to test details not permitted")
                    case 404:
                        throw TestsAPIError.testNotFound(testId)
                    case 500...599:
                        throw TestsAPIError.serverError("Server error occurred")
                    default:
                        throw TestsAPIError.unknownError("HTTP \(statusCode): Failed to fetch test details")
                    }
                default:
                    throw TestsAPIError.networkError("Network error: \(afError.localizedDescription)")
                }
            }
            
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
    nonisolated func getPackages(
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
                responseType: BaseResponse<PackagesListData>.self,
                parameters: nil,
                headers: nil,
                useCache: true
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
    nonisolated func getPackageDetails(packageId: String) async throws -> PackageDetailsResponse {
        let url = buildURL(endpoint: "\(packagesEndpoint)/\(packageId)")
        
        do {
            let response: BaseResponse<PackageDetailsData> = try await networkService.get(
                url,
                responseType: BaseResponse<PackageDetailsData>.self,
                parameters: nil,
                headers: nil,
                useCache: true
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
    /// - Throws: TestsAPIError for various error conditions
    nonisolated func toggleFavorite(testId: String) async throws -> FavoriteStatusResponse {
        
        // Ensure we have a valid authentication token
        guard let token = await tokenManager.getValidToken() else {
            #if DEBUG
            print("🔒 TestsAPIService: No valid authentication token available")
            print("  - Has stored tokens: \(tokenManager.hasStoredTokens())")
            #endif
            throw TestsAPIError.unauthorized("Authentication token required")
        }
        
        #if DEBUG
        print("✅ TestsAPIService: Authentication token available for API call")
        #endif
        
        // First check current status to determine action
        let currentFavorites = try await getUserFavorites(offset: 0, limit: 50)
        let isFavorite = currentFavorites.favorites.contains { $0.id == testId }
        
        let url = buildURL(endpoint: "\(baseEndpoint)/\(testId)/favorite")
        
        do {
            print("🔍 TestsAPIService: \(isFavorite ? "Removing" : "Adding") favorite for test \(testId)")
            
            let response: BaseResponse<FavoriteStatusData> = isFavorite 
                ? try await networkService.delete(url, responseType: BaseResponse<FavoriteStatusData>.self, headers: nil)
                : try await networkService.post(url, body: Optional<String>.none, responseType: BaseResponse<FavoriteStatusData>.self, headers: nil)
            
            try response.validate()
            let data = try response.getData()
            
            print("✅ TestsAPIService: Successfully updated favorite status")
            print("🔍 Test \(testId) is now favorite: \(data.isFavorite)")
            
            return FavoriteStatusResponse(
                testId: data.testId,
                isFavorite: data.isFavorite
            )
            
        } catch {
            print("❌ TestsAPIService: Error occurred during favorite update")
            
            // Handle specific network errors
            if let afError = error.asAFError {
                switch afError {
                case .responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)):
                    switch statusCode {
                    case 401:
                        await tokenManager.clearTokens()
                        throw TestsAPIError.unauthorized("Authentication required")
                    case 403:
                        throw TestsAPIError.forbidden("Favorite update not permitted")
                    case 404:
                        throw TestsAPIError.testNotFound(testId)
                    case 500...599:
                        throw TestsAPIError.serverError("Server error occurred")
                    default:
                        throw TestsAPIError.unknownError("HTTP \(statusCode): Failed to update favorite")
                    }
                default:
                    throw TestsAPIError.networkError("Network error: \(afError.localizedDescription)")
                }
            }
            
            throw TestsAPIError.favoriteUpdateFailed(error.localizedDescription)
        }
    }
    
    /// Get user's favorite tests
    /// - Parameters:
    ///   - offset: Number of records to skip
    ///   - limit: Maximum records to return
    /// - Returns: User's favorite tests
    /// - Throws: TestsAPIError for various error conditions
    nonisolated func getUserFavorites(
        offset: Int = 0,
        limit: Int = 20
    ) async throws -> FavoritesListResponse {
        
        // Ensure we have a valid authentication token
        guard let token = await tokenManager.getValidToken() else {
            #if DEBUG
            print("🔒 TestsAPIService: No valid authentication token available")
            print("  - Has stored tokens: \(tokenManager.hasStoredTokens())")
            #endif
            throw TestsAPIError.unauthorized("Authentication token required")
        }
        
        #if DEBUG
        print("✅ TestsAPIService: Authentication token available for API call")
        #endif
        
        let queryParams: [String: String] = [
            "offset": String(offset),
            "limit": String(limit)
        ]
        
        let url = buildURL(endpoint: favoritesEndpoint, queryParams: queryParams)
        
        do {
            print("🔍 TestsAPIService: Starting favorites list request")
            print("🔍 Request URL: \(url)")
            
            let response: BaseResponse<FavoritesListData> = try await networkService.get(
                url,
                responseType: BaseResponse<FavoritesListData>.self,
                parameters: nil,
                headers: nil,
                useCache: true
            )
            
            try response.validate()
            let data = try response.getData()
            
            print("✅ TestsAPIService: Successfully loaded favorites")
            print("🔍 Favorites count: \(data.favorites.count)")
            
            return FavoritesListResponse(
                favorites: data.favorites,
                pagination: data.pagination
            )
            
        } catch {
            print("❌ TestsAPIService: Error occurred during favorites fetch")
            
            // Handle specific network errors
            if let afError = error.asAFError {
                switch afError {
                case .responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)):
                    switch statusCode {
                    case 401:
                        await tokenManager.clearTokens()
                        throw TestsAPIError.unauthorized("Authentication required")
                    case 403:
                        throw TestsAPIError.forbidden("Access to favorites not permitted")
                    case 500...599:
                        throw TestsAPIError.serverError("Server error occurred")
                    default:
                        throw TestsAPIError.unknownError("HTTP \(statusCode): Failed to fetch favorites")
                    }
                default:
                    throw TestsAPIError.networkError("Network error: \(afError.localizedDescription)")
                }
            }
            
            throw TestsAPIError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Get search suggestions for tests and packages
    /// - Parameters:
    ///   - query: Search query (minimum 2 characters)
    ///   - limit: Maximum suggestions to return
    /// - Returns: Search suggestions
    nonisolated func getSearchSuggestions(
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
                responseType: BaseResponse<SearchSuggestionsData>.self,
                parameters: nil,
                headers: nil,
                useCache: false
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
    nonisolated private func buildURL(endpoint: String, queryParams: [String: String] = [:]) -> String {
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
    let category: APITestCategory?
    let priceMin: Int?
    let priceMax: Int?
    let fastingRequired: Bool?
    let sampleType: APISampleType?
    let featured: Bool?
    let available: Bool?
    let sortBy: TestSortField?
    let sortOrder: TestAPISort?
    
    init(
        category: APITestCategory? = nil,
        priceMin: Int? = nil,
        priceMax: Int? = nil,
        fastingRequired: Bool? = nil,
        sampleType: APISampleType? = nil,
        featured: Bool? = nil,
        available: Bool? = nil,
        sortBy: TestSortField? = nil,
        sortOrder: TestAPISort? = nil
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
    let sortOrder: TestAPISort?
    
    init(
        priceMin: Int? = nil,
        priceMax: Int? = nil,
        testCountMin: Int? = nil,
        testCountMax: Int? = nil,
        featured: Bool? = nil,
        popular: Bool? = nil,
        available: Bool? = nil,
        sortBy: PackageSortField? = nil,
        sortOrder: TestAPISort? = nil
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

enum TestAPISort: String, CaseIterable, Sendable {
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
enum TestsAPIError: @preconcurrency LocalizedError, Equatable, Sendable {
    case fetchFailed(String)
    case testNotFound(String)
    case packageNotFound(String)
    case favoriteUpdateFailed(String)
    case searchFailed(String)
    case invalidRequest(String)
    case networkError(String)
    case unauthorized(String)
    case forbidden(String)
    case serverError(String)
    case unknownError(String)
    
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
        case .networkError(let message):
            return "Network error: \(message)"
        case .unauthorized(let message):
            return "Authentication Error: \(message)"
        case .forbidden(let message):
            return "Permission Error: \(message)"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
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
        case .unauthorized:
            return "Please log in again"
        case .forbidden:
            return "You don't have permission to perform this action"
        case .serverError:
            return "Please try again later"
        case .unknownError:
            return "Please try again or contact support if the problem persists"
        }
    }
    
    /// User-friendly error message for UI display
    var userFriendlyMessage: String {
        switch self {
        case .fetchFailed:
            return "Unable to load tests. Please check your connection and try again."
        case .testNotFound:
            return "The requested test could not be found."
        case .packageNotFound:
            return "The requested health package could not be found."
        case .favoriteUpdateFailed:
            return "Unable to update favorites. Please try again."
        case .searchFailed:
            return "Search failed. Please try again."
        case .invalidRequest(let message):
            return message
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .unauthorized:
            return "Please log in to access tests"
        case .forbidden:
            return "You don't have permission to access this feature"
        case .serverError:
            return "Server is temporarily unavailable. Please try again later"
        case .unknownError:
            return "Something went wrong. Please try again"
        }
    }
    
    /// Determine if the error is recoverable by retrying
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .unknownError, .fetchFailed, .searchFailed:
            return true
        case .testNotFound, .packageNotFound, .unauthorized, .forbidden, .invalidRequest, .favoriteUpdateFailed:
            return false
        }
    }
}

// MARK: - TestsAPIError Equatable Support

extension TestsAPIError {
    static func == (lhs: TestsAPIError, rhs: TestsAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.fetchFailed(let lhsMessage), .fetchFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.testNotFound(let lhsId), .testNotFound(let rhsId)):
            return lhsId == rhsId
        case (.packageNotFound(let lhsId), .packageNotFound(let rhsId)):
            return lhsId == rhsId
        case (.favoriteUpdateFailed(let lhsMessage), .favoriteUpdateFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.searchFailed(let lhsMessage), .searchFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.invalidRequest(let lhsMessage), .invalidRequest(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.networkError(let lhsMessage), .networkError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.unauthorized(let lhsMessage), .unauthorized(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.forbidden(let lhsMessage), .forbidden(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.serverError(let lhsMessage), .serverError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.unknownError(let lhsMessage), .unknownError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}