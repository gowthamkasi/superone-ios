//
//  TestsAPIService.swift
//  SuperOne
//
//  Created by Claude Code on 2025-08-31.
//  Simplified Tests API Integration Service following Labs pattern
//

@preconcurrency import Foundation
@preconcurrency import Alamofire

/// Simplified service for interacting with Tests APIs following Labs page pattern
final class TestsAPIService {
    
    // MARK: - Singleton
    
    static let shared = TestsAPIService()
    
    // MARK: - Properties
    
    private let networkService = NetworkService.shared
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Tests API Methods
    
    /// Search for tests with basic filters - following Labs page pattern
    /// - Parameters:
    ///   - query: Optional search query text
    ///   - category: Test category filter
    ///   - offset: Pagination offset
    ///   - limit: Results per page
    /// - Returns: Array of tests
    func searchTests(
        query: String? = nil,
        category: String? = nil,
        offset: Int = 0,
        limit: Int = 20
    ) async throws -> TestsResponse {
        
        #if DEBUG
        print("🌐 TestsAPIService.searchTests() called with:")
        print("  - query: \(query ?? "nil")")
        print("  - category: \(category ?? "nil")")
        print("  - offset: \(offset)")
        print("  - limit: \(limit)")
        #endif
        
        // Build query parameters - simplified approach like Labs
        var queryParams: [String: String] = [
            "offset": String(offset),
            "limit": String(limit)
        ]
        
        // Add search query
        if let query = query, !query.isEmpty {
            queryParams["search"] = query
        }
        
        // Add category filter
        if let category = category, !category.isEmpty {
            queryParams["category"] = category
        }
        
        // Always show only available tests
        queryParams["available"] = "true"
        
        // Build URL with query parameters - following LabFacilityAPIService pattern
        let url = APIConfiguration.labLoopURL(
            for: "/mobile/tests",
            queryParameters: queryParams
        )
        
        #if DEBUG
        print("🔗 Built URL: \(url)")
        print("🔗 About to call makeLabLoopRequest...")
        #endif
        
        do {
            // Make request to LabLoop API - same pattern as Labs
            let response: LabLoopAPIResponse<LabLoopTestsResponse> = try await makeLabLoopRequest(url: url)
            
            // Check response success - same pattern as Labs
            guard response.success else {
                throw TestsAPIError.searchFailed(response.error?.userMessage ?? "Search failed")
            }
            
            // Use tests directly from API response (already in correct format)
            let tests = response.data.tests
            let totalCount = response.pagination?.totalCount ?? 0
            let hasMore = (offset + tests.count) < totalCount
            let nextOffset = hasMore ? offset + tests.count : offset
            
            return TestsResponse(
                tests: tests,
                hasMore: hasMore,
                nextOffset: nextOffset
            )
            
        } catch {
            if error is TestsAPIError {
                throw error
            } else {
                throw TestsAPIError.networkError(error)
            }
        }
    }
    
    /// Get search suggestions for tests
    /// - Parameters:
    ///   - query: Search query
    ///   - limit: Maximum suggestions to return
    /// - Returns: Search suggestions
    func getSearchSuggestions(
        query: String,
        limit: Int = 10
    ) async throws -> [SearchSuggestionData] {
        
        guard query.count >= 2 else {
            return []
        }
        
        let queryParams: [String: String] = [
            "q": query,
            "limit": String(limit)
        ]
        
        let url = APIConfiguration.labLoopURL(
            for: "/mobile/tests/suggestions",
            queryParameters: queryParams
        )
        
        do {
            let response: LabLoopAPIResponse<LabLoopSuggestionsResponse> = try await makeLabLoopRequest(url: url)
            
            guard response.success else {
                throw TestsAPIError.searchFailed(response.error?.userMessage ?? "Suggestions failed")
            }
            
            return response.data.suggestions
            
        } catch {
            // Return empty suggestions on error - don't break the UI
            return []
        }
    }
    
    /// Get package details (stub for maintaining compatibility)
    func getPackageDetails(packageId: String) async throws -> PackageDetailsResponse {
        throw TestsAPIError.packageNotFound(packageId)
    }
    
    /// Toggle favorite status (stub for maintaining compatibility)
    func toggleFavorite(testId: String) async throws -> FavoriteStatusResponse {
        throw TestsAPIError.networkError(URLError(.networkConnectionLost))
    }
    
    /// Get user favorites (stub for maintaining compatibility)
    func getUserFavorites(offset: Int = 0, limit: Int = 20) async throws -> FavoritesListResponse {
        throw TestsAPIError.networkError(URLError(.networkConnectionLost))
    }
    
    /// Get test details (stub for maintaining compatibility)  
    func getTestDetails(testId: String) async throws -> TestDetailsResponse {
        throw TestsAPIError.testNotFound(testId)
    }
    
    // MARK: - Private Helper Methods
    
    /// Make authenticated request to LabLoop API - following Labs pattern
    private func makeLabLoopRequest<T: Codable>(url: String) async throws -> T {
        #if DEBUG
        print("🌍 makeLabLoopRequest called with URL: \(url)")
        #endif
        
        let urlRequest = URLRequest(url: URL(string: url)!)
        
        #if DEBUG
        print("📲 Creating Alamofire request...")
        #endif
        
        return try await withCheckedThrowingContinuation { @Sendable continuation in
            AF.request(urlRequest)
                .validate()
                .responseData { @Sendable response in
                    switch response.result {
                    case .success(let data):
                        do {
                            nonisolated(unsafe) let decoder = JSONDecoder()
                            decoder.dateDecodingStrategy = .iso8601
                            nonisolated(unsafe) let decodedResponse = try decoder.decode(T.self, from: data)
                            continuation.resume(returning: decodedResponse)
                        } catch {
                            continuation.resume(throwing: TestsAPIError.serverError("Failed to decode response"))
                        }
                    case .failure(let error):
                        // Map Alamofire errors to custom errors
                        let mappedError: TestsAPIError
                        if let statusCode = response.response?.statusCode {
                            switch statusCode {
                            case 401:
                                mappedError = TestsAPIError.unauthorized("Authentication required")
                            case 403:
                                mappedError = TestsAPIError.forbidden("Access denied")
                            case 404:
                                mappedError = TestsAPIError.testNotFound("Tests not found")
                            case 400:
                                mappedError = TestsAPIError.searchFailed("Invalid request parameters")
                            case 500...599:
                                mappedError = TestsAPIError.serverError("Server error occurred")
                            default:
                                mappedError = TestsAPIError.networkError(error)
                            }
                        } else {
                            mappedError = TestsAPIError.networkError(error)
                        }
                        continuation.resume(throwing: mappedError)
                    }
                }
        }
    }
}

// MARK: - Simple Response Models

/// Simple test response model - maintains UI compatibility
struct TestsResponse {
    let tests: [TestItemData]
    let hasMore: Bool
    let nextOffset: Int
}


// MARK: - Error Handling

/// Simple error model following Labs pattern - maintaining UI compatibility
enum TestsAPIError: @preconcurrency LocalizedError, Sendable {
    case searchFailed(String)
    case networkError(Error)
    case noResults
    case unauthorized(String)
    case forbidden(String)
    case serverError(String)
    case testNotFound(String)
    case packageNotFound(String)
    
    nonisolated var errorDescription: String? {
        switch self {
        case .searchFailed(let message):
            return "Failed to search tests: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noResults:
            return "No tests found"
        case .unauthorized(let message):
            return "Authentication Error: \(message)"
        case .forbidden(let message):
            return "Permission Error: \(message)"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .testNotFound(let testId):
            return "Test not found: \(testId)"
        case .packageNotFound(let packageId):
            return "Package not found: \(packageId)"
        }
    }
    
    /// User-friendly error message for UI display
    var userFriendlyMessage: String {
        switch self {
        case .searchFailed:
            return "Unable to load tests. Please try again."
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .noResults:
            return "No tests available at the moment."
        case .unauthorized:
            return "Please log in to access tests"
        case .forbidden:
            return "You don't have permission to access this feature"
        case .serverError:
            return "Server is temporarily unavailable. Please try again later"
        case .testNotFound:
            return "The requested test could not be found."
        case .packageNotFound:
            return "The requested health package could not be found."
        }
    }
    
    /// Determine if the error is recoverable by retrying
    var isRetryable: Bool {
        switch self {
        case .searchFailed, .networkError, .serverError:
            return true
        case .noResults, .unauthorized, .forbidden, .testNotFound, .packageNotFound:
            return false
        }
    }
}

// Note: API endpoints already defined in APIConfiguration.swift

// MARK: - LabLoop Response Models for Tests

/// LabLoop API response for tests - using existing TestsListData structure
struct LabLoopTestsResponse: Codable {
    let tests: [TestItemData]
    let pagination: LabLoopPagination?
    
    // Convert from LabLoop raw response if needed
    static func fromRawResponse(_ raw: [String: Any]) -> LabLoopTestsResponse? {
        // This would be used if we need to transform raw API response
        // For now, assume API returns properly formatted TestItemData
        return nil
    }
}

/// LabLoop suggestions response - simple structure for testing
struct LabLoopSuggestionsResponse: Codable {
    let suggestions: [SearchSuggestionData]
}

// MARK: - Compatibility Response Models

/// Package details response model (for compatibility)
struct PackageDetailsResponse: Sendable {
    let packageDetails: PackageDetailsData
}

/// Favorite status response model (for compatibility)  
struct FavoriteStatusResponse: Sendable {
    let testId: String
    let isFavorite: Bool
}

/// Favorites list response model (for compatibility)
struct FavoritesListResponse: Sendable {
    let favorites: [FavoriteTestData]
    let pagination: OffsetPagination
}

/// Test details response model (for compatibility)
struct TestDetailsResponse: Sendable {
    let testDetails: TestDetailsData
}