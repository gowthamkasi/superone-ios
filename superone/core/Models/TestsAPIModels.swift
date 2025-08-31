//
//  TestsAPIModels.swift
//  SuperOne
//
//  Created by Claude Code on 2025-08-31.
//  Data models for Tests API Service - Separate file to ensure proper isolation
//

import Foundation
import SwiftUI

// MARK: - Core Enums (API-Compatible)

/// Test category enumeration for API compatibility
enum APITestCategory: String, CaseIterable, Sendable, Codable {
    case bloodTest = "blood_test"
    case imaging = "imaging"
    case cardiology = "cardiology"
    case women = "women_health"
    case diabetes = "diabetes"
    case thyroid = "thyroid"
    case liver = "liver"
    case kidney = "kidney"
    case cancer = "cancer_screening"
    case fitness = "fitness"
    case allergy = "allergy"
    case infection = "infection"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .bloodTest: return "Blood Test"
        case .imaging: return "Imaging"
        case .cardiology: return "Cardiology"
        case .women: return "Women's Health"
        case .diabetes: return "Diabetes"
        case .thyroid: return "Thyroid"
        case .liver: return "Liver Function"
        case .kidney: return "Kidney Function"
        case .cancer: return "Cancer Screening"
        case .fitness: return "Fitness"
        case .allergy: return "Allergy"
        case .infection: return "Infection"
        }
    }
    
    /// Color for UI display
    var color: Color {
        switch self {
        case .bloodTest: return .green
        case .imaging: return .blue
        case .cardiology: return .red
        case .women: return .pink
        case .diabetes: return .orange
        case .thyroid: return .purple
        case .liver: return .brown
        case .kidney: return .cyan
        case .cancer: return .red
        case .fitness: return .green
        case .allergy: return .yellow
        case .infection: return .red
        }
    }
}

/// Fasting requirements for API compatibility
enum APIFastingRequirement: String, CaseIterable, Sendable, Codable {
    case none = "none"
    case hours8 = "8_hours"
    case hours10 = "10_hours"
    case hours12 = "12_hours"
    case hours14 = "14_hours"
    case overnight = "overnight"
}

/// Sample type enumeration for API compatibility
enum APISampleType: String, CaseIterable, Sendable, Codable {
    case blood = "blood"
    case urine = "urine"
    case saliva = "saliva"
    case stool = "stool"
    case tissue = "tissue"
    case swab = "swab"
    case breath = "breath"
    case imaging = "imaging"
}

// MARK: - API Data Models

nonisolated struct TestsListData: Codable, Sendable {
    let tests: [TestItemData]
    let pagination: OffsetPagination
    let filtersApplied: FiltersAppliedData?
    let availableFilters: AvailableFiltersData?
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    let category: APITestCategory
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
    
    nonisolated enum CodingKeys: String, CodingKey {
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

nonisolated struct TestDetailsData: Codable, Sendable {
    let id: String
    let name: String
    let shortName: String?
    let icon: String
    let category: APITestCategory
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
    
    nonisolated enum CodingKeys: String, CodingKey {
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

nonisolated struct PackagesListData: Codable, Sendable {
    let packages: [PackageItemData]
    let pagination: OffsetPagination
    let filtersApplied: PackageFiltersAppliedData?
    let availableFilters: PackageAvailableFiltersData?
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
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

nonisolated struct PackageDetailsData: Codable, Sendable {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    let required: APIFastingRequirement
    let displayText: String
    let instructions: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case required
        case displayText = "display_text"
        case instructions
    }
}

struct SampleTypeData: Codable, Sendable {
    let type: APISampleType
    let displayName: String
    let icon: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case type
        case displayName = "display_name"
        case icon
    }
}

nonisolated struct FavoriteStatusData: Codable, Sendable {
    let testId: String
    let isFavorite: Bool
    
    nonisolated enum CodingKeys: String, CodingKey {
        case testId = "test_id"
        case isFavorite = "is_favorite"
    }
}

nonisolated struct FavoritesListData: Codable, Sendable {
    let favorites: [FavoriteTestData]
    let pagination: OffsetPagination
}

struct FavoriteTestData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let price: String
    let category: String
    let addedAt: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, price, category
        case addedAt = "added_at"
    }
}

nonisolated struct SearchSuggestionsData: Codable, Sendable {
    let suggestions: [SearchSuggestionData]
    let popularSearches: [String]
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
        case categories
        case priceRange = "price_range"
        case sampleTypes = "sample_types"
        case fastingOptions = "fasting_options"
    }
}

struct PackageFiltersAppliedData: Codable, Sendable {
    let search: String?
    let priceRange: PriceRangeData
    
    nonisolated enum CodingKeys: String, CodingKey {
        case search
        case priceRange = "price_range"
    }
}

struct PackageAvailableFiltersData: Codable, Sendable {
    let priceRange: PriceRangeData
    let testCountRange: TestCountRangeData
    let categories: [CategoryFilterData]
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
        case key, count, color
        case displayName = "display_name"
    }
}

struct SampleTypeFilterData: Codable, Sendable {
    let key: String
    let displayName: String
    let count: Int
    
    nonisolated enum CodingKeys: String, CodingKey {
        case key, count
        case displayName = "display_name"
    }
}

struct FastingOptionData: Codable, Sendable {
    let key: String
    let displayText: String
    let count: Int
    
    nonisolated enum CodingKeys: String, CodingKey {
        case key, count
        case displayText = "display_text"
    }
}

// MARK: - Additional Data Models

struct TestSectionData: Codable, Sendable {
    let type: APITestSectionType
    let title: String
    let content: SectionContentData
    
    nonisolated enum CodingKeys: String, CodingKey {
        case type, title, content
    }
}

/// API-specific test section type enumeration
enum APITestSectionType: String, CaseIterable, Sendable, Codable {
    case about = "about"
    case whyNeeded = "why_needed"
    case insights = "insights"
    case preparation = "preparation"
    case results = "results"
    
    var displayName: String {
        switch self {
        case .about: return "About"
        case .whyNeeded: return "Why Needed"
        case .insights: return "Insights"
        case .preparation: return "Preparation"
        case .results: return "Results"
        }
    }
}

struct SectionContentData: Codable, Sendable {
    let overview: String?
    let bulletPoints: [String]
    let categories: [ContentCategoryData]
    let tips: [String]
    let warnings: [String]
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, icon, tests
        case testCount = "test_count"
    }
}

struct CategoryTestData: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let shortName: String?
    let description: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, description
        case shortName = "short_name"
    }
}

struct HealthInsightsData: Codable, Sendable {
    let earlyDetection: [String]
    let healthMonitoring: [String]
    let aiPoweredAnalysis: [String]
    let additionalBenefits: [String]
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
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
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, price
        case testCount = "test_count"
    }
}

// MARK: - Type Conversion Extensions

/// Extension to convert between TestCategory and APITestCategory
extension TestCategory {
    /// Convert TestCategory to APITestCategory
    var toAPITestCategory: APITestCategory? {
        switch self {
        case .bloodTest: return .bloodTest
        case .imaging: return .imaging
        case .cardiology: return .cardiology
        case .women: return .women
        case .diabetes: return .diabetes
        case .thyroid: return .thyroid
        case .liver: return .liver
        case .kidney: return .kidney
        case .cancer: return .cancer
        case .fitness: return .fitness
        case .allergy: return .allergy
        case .infection: return .infection
        }
    }
}

extension APITestCategory {
    /// Convert APITestCategory to TestCategory
    nonisolated var toTestCategory: TestCategory? {
        switch self {
        case .bloodTest: return .bloodTest
        case .imaging: return .imaging
        case .cardiology: return .cardiology
        case .women: return .women
        case .diabetes: return .diabetes
        case .thyroid: return .thyroid
        case .liver: return .liver
        case .kidney: return .kidney
        case .cancer: return .cancer
        case .fitness: return .fitness
        case .allergy: return .allergy
        case .infection: return .infection
        }
    }
}

extension APIFastingRequirement {
    /// Convert APIFastingRequirement to FastingRequirement
    nonisolated var toFastingRequirement: FastingRequirement {
        switch self {
        case .none: return .none
        case .hours8: return .hours8
        case .hours10: return .hours10
        case .hours12: return .hours12
        case .hours14: return .hours14
        case .overnight: return .overnight
        }
    }
}

extension APISampleType {
    /// Convert APISampleType to SampleType
    nonisolated var toSampleType: SampleType {
        switch self {
        case .blood: return .blood
        case .urine: return .urine
        case .saliva: return .saliva
        case .stool: return .stool
        case .tissue: return .tissue
        case .swab: return .swab
        case .breath: return .breath
        case .imaging: return .imaging
        }
    }
}

extension APITestSectionType {
    /// Convert APITestSectionType to UITestSectionType
    nonisolated var toUITestSectionType: UITestSectionType {
        switch self {
        case .about: return .about
        case .whyNeeded: return .whyNeeded
        case .insights: return .insights
        case .preparation: return .preparation
        case .results: return .results
        }
    }
}