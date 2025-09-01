import SwiftUI
import Foundation

// Import required types from other models
// These types are defined in TestDetailsModels.swift - ensure they're accessible

// MARK: - Health Package Models

/// Main health package model containing all package information
struct HealthPackage: Sendable, Identifiable {
    let id: String
    let name: String
    let shortName: String
    let icon: String
    let description: String
    let duration: String
    let totalTests: Int
    let fastingRequirement: FastingRequirement
    let reportTime: String
    
    // Pricing information
    let packagePrice: Int
    let individualPrice: Int
    let savings: Int
    let discountPercentage: Int
    
    // Package details
    let testCategories: [HealthTestCategory]
    let recommendedFor: [String]
    let notSuitableFor: [String]
    let healthInsights: HealthInsights
    let preparationInstructions: PreparationInstructions
    let availableLabs: [LabFacility]
    let packageVariants: [PackageVariant]
    let customerReviews: [CustomerReview]
    let faqItems: [FAQItem]
    
    var isFeatured: Bool
    var isAvailable: Bool
    
    // Additional properties for UI display
    var isPopular: Bool = false
    var category: String = "Basic"
    var currency: String = "₹"
    var price: Double { Double(packagePrice) }
    var originalPrice: Double? { individualPrice > packagePrice ? Double(individualPrice) : nil }
    
    // Computed properties
    var formattedPrice: String { "₹\(packagePrice.formatted())" }
    var formattedOriginalPrice: String { "₹\(individualPrice.formatted())" }
    var formattedSavings: String { "₹\(savings.formatted())" }
    var averageRating: Double {
        guard !customerReviews.isEmpty else { return 0.0 }
        return customerReviews.map { $0.rating }.reduce(0.0, +) / Double(customerReviews.count)
    }
}

// MARK: - Health Test Category

/// Represents a category of tests within a health package
struct HealthTestCategory: Sendable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let testCount: Int
    let tests: [HealthTest]
    let color: Color?
    
    init(id: String = UUID().uuidString, name: String, icon: String, tests: [HealthTest], color: Color? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.tests = tests
        self.testCount = tests.count
        self.color = color
    }
}

/// Individual health test within a category
struct HealthTest: Sendable, Identifiable {
    let id: String
    let name: String
    let shortName: String?
    let description: String?
    
    init(id: String = UUID().uuidString, name: String, shortName: String? = nil, description: String? = nil) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.description = description
    }
}

// MARK: - Health Insights

/// Health insights and benefits provided by the package
struct HealthInsights: Sendable {
    let earlyDetection: [String]
    let healthMonitoring: [String]
    let aiPoweredAnalysis: [String]
    let additionalBenefits: [String]
    
    init(
        earlyDetection: [String] = [],
        healthMonitoring: [String] = [],
        aiPoweredAnalysis: [String] = [],
        additionalBenefits: [String] = []
    ) {
        self.earlyDetection = earlyDetection
        self.healthMonitoring = healthMonitoring
        self.aiPoweredAnalysis = aiPoweredAnalysis
        self.additionalBenefits = additionalBenefits
    }
}

// MARK: - Preparation Instructions

/// Preparation instructions for the health package
struct PreparationInstructions: Sendable {
    let fastingHours: Int
    let dayBefore: [String]
    let morningOfTest: [String]
    let whatToBring: [String]
    let generalTips: [String]
    
    init(
        fastingHours: Int = 12,
        dayBefore: [String] = [],
        morningOfTest: [String] = [],
        whatToBring: [String] = [],
        generalTips: [String] = []
    ) {
        self.fastingHours = fastingHours
        self.dayBefore = dayBefore
        self.morningOfTest = morningOfTest
        self.whatToBring = whatToBring
        self.generalTips = generalTips
    }
}

// MARK: - Lab Facility

/// Lab facility information with pricing and availability
struct LabFacility: Sendable, Identifiable {
    let id: String
    let name: String
    let type: LabType
    let rating: Double
    let distance: String
    let availability: String
    let price: Int
    let isWalkInAvailable: Bool
    let nextSlot: String?
    let address: String?
    let phoneNumber: String?
    
    // Additional properties required by views
    let location: String
    let services: [String]
    let reviewCount: Int
    let operatingHours: String
    let isRecommended: Bool
    let offersHomeCollection: Bool
    let acceptsInsurance: Bool
    
    var formattedPrice: String { "₹\(price.formatted())" }
    var displayRating: String { String(format: "%.1f", rating) }
}

/// Lab facility type
enum LabType: String, CaseIterable, Sendable {
    case lab = "lab"
    case hospital = "hospital"
    case homeCollection = "home_collection"
    case clinic = "clinic"
    
    var displayName: String {
        switch self {
        case .lab: return "Lab"
        case .hospital: return "Hospital"
        case .homeCollection: return "Home Collection"
        case .clinic: return "Clinic"
        }
    }
    
    var icon: String {
        switch self {
        case .lab: return "🏥"
        case .hospital: return "🏥"
        case .homeCollection: return "🏠"
        case .clinic: return "🏥"
        }
    }
}

// MARK: - Package Variant

/// Alternative package options
struct PackageVariant: Sendable, Identifiable {
    let id: String
    let name: String
    let price: Int
    let testCount: Int
    let duration: String
    let description: String
    let isPopular: Bool
    
    var formattedPrice: String { "₹\(price.formatted())" }
}

// MARK: - Customer Review

/// Customer review model
struct CustomerReview: Sendable, Identifiable {
    let id: String
    let customerName: String
    let rating: Double
    let comment: String
    let date: Date
    let isVerified: Bool
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var displayRating: String {
        let fullStars = Int(rating)
        let hasHalfStar = rating - Double(fullStars) >= 0.5
        let emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0)
        
        return String(repeating: "⭐", count: fullStars) +
               (hasHalfStar ? "⭐" : "") +
               String(repeating: "⚪", count: emptyStars)
    }
}

// MARK: - FAQ Item

/// FAQ item model
struct FAQItem: Sendable, Identifiable {
    let id: String
    let question: String
    let answer: String
    var isExpanded: Bool
    
    init(id: String = UUID().uuidString, question: String, answer: String, isExpanded: Bool = false) {
        self.id = id
        self.question = question
        self.answer = answer
        self.isExpanded = isExpanded
    }
}

// MARK: - Observable State Management

@MainActor
@Observable
final class HealthPackageState {
    var package: HealthPackage
    var isSaved: Bool = false
    var expandedFAQs: Set<String> = []
    var expandedTestCategories: Set<String> = []
    
    init(package: HealthPackage) {
        self.package = package
    }
    
    func toggleSaved() {
        isSaved.toggle()
    }
    
    func toggleFAQ(withId id: String) {
        if expandedFAQs.contains(id) {
            expandedFAQs.remove(id)
        } else {
            expandedFAQs.insert(id)
        }
    }
    
    func toggleTestCategory(withId id: String) {
        if expandedTestCategories.contains(id) {
            expandedTestCategories.remove(id)
        } else {
            expandedTestCategories.insert(id)
        }
    }
    
    func isTestCategoryExpanded(_ id: String) -> Bool {
        expandedTestCategories.contains(id)
    }
    
    func isFAQExpanded(_ id: String) -> Bool {
        expandedFAQs.contains(id)
    }
}

// MARK: - Removed Sample Data Factory
// All sample/mock health package data has been removed to ensure production safety
// Health package data should only come from real LabLoop API calls