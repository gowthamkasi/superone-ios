//
//  TestsAPIService.swift
//  SuperOne
//
//  Created by Claude Code on 2025-08-31.
//  Tests API Integration Service with offset/limit pagination
//

@preconcurrency import Foundation

/// Service for interacting with Tests and Health Packages APIs
@MainActor
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
            let response: BaseResponse<TestsListData> = try await networkService.request(
                endpoint: url,
                method: .get,
                timeout: 30.0
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
    func getTestDetails(testId: String) async throws -> TestDetailsResponse {
        let url = buildURL(endpoint: "\(baseEndpoint)/\(testId)")
        
        do {
            let response: BaseResponse<TestDetailsData> = try await networkService.request(
                endpoint: url,
                method: .get,
                timeout: 30.0
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
            let response: BaseResponse<PackagesListData> = try await networkService.request(
                endpoint: url,
                method: .get,
                timeout: 30.0
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
    func getPackageDetails(packageId: String) async throws -> PackageDetailsResponse {
        let url = buildURL(endpoint: "\(packagesEndpoint)/\(packageId)")
        
        do {
            let response: BaseResponse<PackageDetailsData> = try await networkService.request(
                endpoint: url,
                method: .get,
                timeout: 30.0
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
    func toggleFavorite(testId: String) async throws -> FavoriteStatusResponse {
        // First check current status to determine action
        let currentFavorites = try await getUserFavorites(offset: 0, limit: 50)
        let isFavorite = currentFavorites.favorites.contains { $0.id == testId }
        
        let url = buildURL(endpoint: "\(baseEndpoint)/\(testId)/favorite")
        let method: NetworkService.HTTPMethod = isFavorite ? .delete : .post
        
        do {
            let response: BaseResponse<FavoriteStatusData> = try await networkService.request(
                endpoint: url,
                method: method,
                timeout: 30.0
            )
            
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
            let response: BaseResponse<FavoritesListData> = try await networkService.request(
                endpoint: url,
                method: .get,
                timeout: 30.0
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
            let response: BaseResponse<SearchSuggestionsData> = try await networkService.request(
                endpoint: url,
                method: .get,
                timeout: 15.0
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
    let sortOrder: SortOrder?
    
    init(
        category: TestCategory? = nil,
        priceMin: Int? = nil,
        priceMax: Int? = nil,
        fastingRequired: Bool? = nil,
        sampleType: SampleType? = nil,
        featured: Bool? = nil,
        available: Bool? = nil,
        sortBy: TestSortField? = nil,
        sortOrder: SortOrder? = nil
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
    let sortOrder: SortOrder?
    
    init(
        priceMin: Int? = nil,
        priceMax: Int? = nil,
        testCountMin: Int? = nil,
        testCountMax: Int? = nil,
        featured: Bool? = nil,
        popular: Bool? = nil,
        available: Bool? = nil,
        sortBy: PackageSortField? = nil,
        sortOrder: SortOrder? = nil
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

enum SortOrder: String, CaseIterable, Sendable {
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

// MARK: - API Data Models

struct TestsListData: Codable, Sendable {
    let tests: [TestItemData]
    let pagination: OffsetPagination
    let filtersApplied: FiltersAppliedData?
    let availableFilters: AvailableFiltersData?
    
    enum CodingKeys: String, CodingKey {
        case tests
        case pagination
        case filtersApplied = "filters_applied"
        case availableFilters = "available_filters"
    }
}

struct TestItemData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let shortName: String?
    let icon: String
    let category: TestCategory
    let duration: String
    let price: String
    let originalPrice: String?
    let fasting: FastingRequirementData
    let sampleType: SampleTypeData
    let reportTime: String
    let description: String
    let tags: [String]
    let isFeatured: Bool
    let isAvailable: Bool
    let categoryColor: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, category, duration, price, description, tags
        case shortName = "short_name"
        case originalPrice = "original_price"
        case fasting
        case sampleType = "sample_type"
        case reportTime = "report_time"
        case isFeatured = "is_featured"
        case isAvailable = "is_available"
        case categoryColor = "category_color"
    }
}

struct TestDetailsData: Codable, Sendable {
    let id: String
    let name: String
    let shortName: String?
    let icon: String
    let category: TestCategory
    let duration: String
    let price: String
    let originalPrice: String?
    let fasting: FastingRequirementData
    let sampleType: SampleTypeData
    let reportTime: String
    let description: String
    let keyMeasurements: [String]
    let healthBenefits: String
    let sections: [TestSectionData]
    let isFeatured: Bool
    let isAvailable: Bool
    let tags: [String]
    let relatedTests: [RelatedTestData]
    let availableLabs: [AvailableLabData]
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, category, duration, price, description, tags, sections
        case shortName = "short_name"
        case originalPrice = "original_price"
        case fasting
        case sampleType = "sample_type"
        case reportTime = "report_time"
        case keyMeasurements = "key_measurements"
        case healthBenefits = "health_benefits"
        case isFeatured = "is_featured"
        case isAvailable = "is_available"
        case relatedTests = "related_tests"
        case availableLabs = "available_labs"
    }
}

struct PackagesListData: Codable, Sendable {
    let packages: [PackageItemData]
    let pagination: OffsetPagination
    let filtersApplied: PackageFiltersAppliedData?
    let availableFilters: PackageAvailableFiltersData?
    
    enum CodingKeys: String, CodingKey {
        case packages, pagination
        case filtersApplied = "filters_applied"
        case availableFilters = "available_filters"
    }
}

struct PackageItemData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let shortName: String?
    let icon: String
    let description: String
    let duration: String
    let totalTests: Int
    let fastingRequirement: FastingRequirementData
    let reportTime: String
    let packagePrice: Int
    let individualPrice: Int
    let savings: Int
    let discountPercentage: Int
    let formattedPrice: String
    let formattedOriginalPrice: String
    let formattedSavings: String
    let isFeatured: Bool
    let isAvailable: Bool
    let isPopular: Bool
    let category: String
    let averageRating: Double
    let reviewCount: Int
    let testCategories: [TestCategoryData]
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, description, duration, category
        case shortName = "short_name"
        case totalTests = "total_tests"
        case fastingRequirement = "fasting_requirement"
        case reportTime = "report_time"
        case packagePrice = "package_price"
        case individualPrice = "individual_price"
        case savings
        case discountPercentage = "discount_percentage"
        case formattedPrice = "formatted_price"
        case formattedOriginalPrice = "formatted_original_price"
        case formattedSavings = "formatted_savings"
        case isFeatured = "is_featured"
        case isAvailable = "is_available"
        case isPopular = "is_popular"
        case averageRating = "average_rating"
        case reviewCount = "review_count"
        case testCategories = "test_categories"
    }
}

struct PackageDetailsData: Codable, Sendable {
    let id: String
    let name: String
    let shortName: String?
    let icon: String
    let description: String
    let duration: String
    let totalTests: Int
    let fastingRequirement: FastingRequirementData
    let reportTime: String
    let packagePrice: Int
    let individualPrice: Int
    let savings: Int
    let discountPercentage: Int
    let formattedPrice: String
    let formattedOriginalPrice: String
    let formattedSavings: String
    let testCategories: [DetailedTestCategoryData]
    let recommendedFor: [String]
    let notSuitableFor: [String]
    let healthInsights: HealthInsightsData
    let preparationInstructions: PreparationInstructionsData
    let availableLabs: [AvailableLabData]
    let packageVariants: [PackageVariantData]
    let customerReviews: [CustomerReviewData]
    let faqItems: [FAQItemData]
    let isFeatured: Bool
    let isAvailable: Bool
    let isPopular: Bool
    let category: String
    let averageRating: Double
    let relatedPackages: [RelatedPackageData]
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, description, duration, category
        case shortName = "short_name"
        case totalTests = "total_tests"
        case fastingRequirement = "fasting_requirement"
        case reportTime = "report_time"
        case packagePrice = "package_price"
        case individualPrice = "individual_price"
        case savings
        case discountPercentage = "discount_percentage"
        case formattedPrice = "formatted_price"
        case formattedOriginalPrice = "formatted_original_price"
        case formattedSavings = "formatted_savings"
        case testCategories = "test_categories"
        case recommendedFor = "recommended_for"
        case notSuitableFor = "not_suitable_for"
        case healthInsights = "health_insights"
        case preparationInstructions = "preparation_instructions"
        case availableLabs = "available_labs"
        case packageVariants = "package_variants"
        case customerReviews = "customer_reviews"
        case faqItems = "faq_items"
        case isFeatured = "is_featured"
        case isAvailable = "is_available"
        case isPopular = "is_popular"
        case averageRating = "average_rating"
        case relatedPackages = "related_packages"
    }
}

// MARK: - Supporting Data Models

struct FastingRequirementData: Codable, Sendable {
    let required: FastingRequirement
    let displayText: String
    let instructions: String?
    
    enum CodingKeys: String, CodingKey {
        case required
        case displayText = "display_text"
        case instructions
    }
}

struct SampleTypeData: Codable, Sendable {
    let type: SampleType
    let displayName: String
    let icon: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case displayName = "display_name"
        case icon
    }
}

struct FavoriteStatusData: Codable, Sendable {
    let testId: String
    let isFavorite: Bool
    
    enum CodingKeys: String, CodingKey {
        case testId = "test_id"
        case isFavorite = "is_favorite"
    }
}

struct FavoritesListData: Codable, Sendable {
    let favorites: [FavoriteTestData]
    let pagination: OffsetPagination
}

struct FavoriteTestData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let price: String
    let category: String
    let addedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, price, category
        case addedAt = "added_at"
    }
}

struct SearchSuggestionsData: Codable, Sendable {
    let suggestions: [SearchSuggestionData]
    let popularSearches: [String]
    
    enum CodingKeys: String, CodingKey {
        case suggestions
        case popularSearches = "popular_searches"
    }
}

struct SearchSuggestionData: Codable, Sendable {
    let text: String
    let type: SuggestionType
    let count: Int
}

enum SuggestionType: String, Codable, Sendable {
    case test = "test"
    case package = "package"
    case category = "category"
}

struct FiltersAppliedData: Codable, Sendable {
    let search: String?
    let category: String?
    let priceRange: PriceRangeData
    let fastingRequired: Bool?
    
    enum CodingKeys: String, CodingKey {
        case search, category
        case priceRange = "price_range"
        case fastingRequired = "fasting_required"
    }
}

struct AvailableFiltersData: Codable, Sendable {
    let categories: [CategoryFilterData]
    let priceRange: PriceRangeData
    let sampleTypes: [SampleTypeFilterData]
    let fastingOptions: [FastingOptionData]
    
    enum CodingKeys: String, CodingKey {
        case categories
        case priceRange = "price_range"
        case sampleTypes = "sample_types"
        case fastingOptions = "fasting_options"
    }
}

struct PackageFiltersAppliedData: Codable, Sendable {
    let search: String?
    let priceRange: PriceRangeData
    
    enum CodingKeys: String, CodingKey {
        case search
        case priceRange = "price_range"
    }
}

struct PackageAvailableFiltersData: Codable, Sendable {
    let priceRange: PriceRangeData
    let testCountRange: TestCountRangeData
    let categories: [CategoryFilterData]
    
    enum CodingKeys: String, CodingKey {
        case priceRange = "price_range"
        case testCountRange = "test_count_range"
        case categories
    }
}

struct PriceRangeData: Codable, Sendable {
    let min: Int
    let max: Int
}

struct TestCountRangeData: Codable, Sendable {
    let min: Int
    let max: Int
}

struct CategoryFilterData: Codable, Sendable {
    let key: String
    let displayName: String
    let count: Int
    let color: String?
    
    enum CodingKeys: String, CodingKey {
        case key, count, color
        case displayName = "display_name"
    }
}

struct SampleTypeFilterData: Codable, Sendable {
    let key: String
    let displayName: String
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case key, count
        case displayName = "display_name"
    }
}

struct FastingOptionData: Codable, Sendable {
    let key: String
    let displayText: String
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case key, count
        case displayText = "display_text"
    }
}

// MARK: - Additional Data Models

struct TestSectionData: Codable, Sendable {
    let type: TestSectionType
    let title: String
    let content: SectionContentData
    
    enum CodingKeys: String, CodingKey {
        case type, title, content
    }
}

struct SectionContentData: Codable, Sendable {
    let overview: String?
    let bulletPoints: [String]
    let categories: [ContentCategoryData]
    let tips: [String]
    let warnings: [String]
    
    enum CodingKeys: String, CodingKey {
        case overview
        case bulletPoints = "bullet_points"
        case categories, tips, warnings
    }
}

struct ContentCategoryData: Codable, Sendable {
    let icon: String
    let title: String
    let items: [String]
    let color: String?
}

struct RelatedTestData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let price: String
    let category: String
}

struct AvailableLabData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let location: String
    let rating: Double
    let price: String?
    let nextAvailable: String?
    let type: String?
    let distance: String?
    let availability: String?
    let formattedPrice: String?
    let isWalkInAvailable: Bool?
    let nextSlot: String?
    let address: String?
    let phoneNumber: String?
    let services: [String]?
    let reviewCount: Int?
    let operatingHours: String?
    let isRecommended: Bool?
    let offersHomeCollection: Bool?
    let acceptsInsurance: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, location, rating, price, services, address
        case nextAvailable = "next_available"
        case type, distance, availability
        case formattedPrice = "formatted_price"
        case isWalkInAvailable = "is_walk_in_available"
        case nextSlot = "next_slot"
        case phoneNumber = "phone_number"
        case reviewCount = "review_count"
        case operatingHours = "operating_hours"
        case isRecommended = "is_recommended"
        case offersHomeCollection = "offers_home_collection"
        case acceptsInsurance = "accepts_insurance"
    }
}

struct TestCategoryData: Codable, Sendable {
    let name: String
    let icon: String
    let testCount: Int
    
    enum CodingKeys: String, CodingKey {
        case name, icon
        case testCount = "test_count"
    }
}

struct DetailedTestCategoryData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let testCount: Int
    let tests: [CategoryTestData]
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, tests
        case testCount = "test_count"
    }
}

struct CategoryTestData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let shortName: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case shortName = "short_name"
    }
}

struct HealthInsightsData: Codable, Sendable {
    let earlyDetection: [String]
    let healthMonitoring: [String]
    let aiPoweredAnalysis: [String]
    let additionalBenefits: [String]
    
    enum CodingKeys: String, CodingKey {
        case earlyDetection = "early_detection"
        case healthMonitoring = "health_monitoring"
        case aiPoweredAnalysis = "ai_powered_analysis"
        case additionalBenefits = "additional_benefits"
    }
}

struct PreparationInstructionsData: Codable, Sendable {
    let fastingHours: Int
    let dayBefore: [String]
    let morningOfTest: [String]
    let whatToBring: [String]
    let generalTips: [String]
    
    enum CodingKeys: String, CodingKey {
        case fastingHours = "fasting_hours"
        case dayBefore = "day_before"
        case morningOfTest = "morning_of_test"
        case whatToBring = "what_to_bring"
        case generalTips = "general_tips"
    }
}

struct PackageVariantData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let price: Int
    let formattedPrice: String
    let testCount: Int
    let duration: String
    let description: String
    let isPopular: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, price, duration, description
        case formattedPrice = "formatted_price"
        case testCount = "test_count"
        case isPopular = "is_popular"
    }
}

struct CustomerReviewData: Codable, Sendable, Identifiable {
    let id: String
    let customerName: String
    let rating: Double
    let comment: String
    let date: String
    let isVerified: Bool
    let timeAgo: String
    
    enum CodingKeys: String, CodingKey {
        case id, rating, comment, date
        case customerName = "customer_name"
        case isVerified = "is_verified"
        case timeAgo = "time_ago"
    }
}

struct FAQItemData: Codable, Sendable, Identifiable {
    let id: String
    let question: String
    let answer: String
}

struct RelatedPackageData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let price: Int
    let testCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, price
        case testCount = "test_count"
    }
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