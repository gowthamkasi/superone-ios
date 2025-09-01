import SwiftUI
import Foundation

// MARK: - Test Details Models (Restructured as structs for Swift 6 compliance)

/// Comprehensive test details model
struct TestDetails: Sendable, Identifiable {
    let id: String
    let name: String
    let shortName: String
    let icon: String
    let category: TestCategory
    let duration: String
    let price: String
    let originalPrice: String?
    let fasting: FastingRequirement
    let sampleType: SampleType
    let reportTime: String
    let description: String
    let keyMeasurements: [String]
    let healthBenefits: String
    let sections: [TestSection]
    let isFeatured: Bool
    let isAvailable: Bool
    let tags: [String]
}

/// Test category enumeration
enum TestCategory: String, CaseIterable, Sendable, Codable {
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

/// Fasting requirements
enum FastingRequirement: String, CaseIterable, Sendable, Codable {
    case none = "none"
    case hours8 = "8_hours"
    case hours10 = "10_hours"
    case hours12 = "12_hours"
    case hours14 = "14_hours"
    case overnight = "overnight"
    
    var displayText: String {
        switch self {
        case .none: return "Not Required"
        case .hours8: return "Required (8 hours)"
        case .hours10: return "Required (10 hours)"
        case .hours12: return "Required (12 hours)"
        case .hours14: return "Required (14 hours)"
        case .overnight: return "Required (Overnight)"
        }
    }
    
    var instructions: String {
        switch self {
        case .none: return "No fasting required. You can eat normally before this test."
        case .hours8: return "Fast for 8 hours before the test. Only water is allowed."
        case .hours10: return "Fast for 10 hours before the test. Only water is allowed."
        case .hours12: return "Fast for 12 hours before the test. Only water is allowed."
        case .hours14: return "Fast for 14 hours before the test. Only water is allowed."
        case .overnight: return "Fast overnight (typically 8-12 hours). Only water is allowed."
        }
    }
    
    var isRequired: Bool {
        self != .none
    }
}

/// Sample type enumeration
enum SampleType: String, CaseIterable, Sendable, Codable {
    case blood = "blood"
    case urine = "urine"
    case saliva = "saliva"
    case stool = "stool"
    case tissue = "tissue"
    case swab = "swab"
    case breath = "breath"
    case imaging = "imaging"
    
    var displayName: String {
        switch self {
        case .blood: return "Blood"
        case .urine: return "Urine"
        case .saliva: return "Saliva"
        case .stool: return "Stool"
        case .tissue: return "Tissue"
        case .swab: return "Swab"
        case .breath: return "Breath"
        case .imaging: return "Imaging"
        }
    }
    
    var icon: String {
        switch self {
        case .blood: return "drop.fill"
        case .urine: return "testtube.2"
        case .saliva: return "mouth.fill"
        case .stool: return "testtube.2"
        case .tissue: return "bandage.fill"
        case .swab: return "wand.and.stars"
        case .breath: return "wind"
        case .imaging: return "camera.fill"
        }
    }
}

/// Collapsible section model
struct TestSection: Sendable, Identifiable {
    let id = UUID()
    let type: UITestSectionType
    let title: String
    let content: TestSectionContent
    var isExpanded: Bool
    
    init(type: UITestSectionType, title: String, content: TestSectionContent, isExpanded: Bool = false) {
        self.type = type
        self.title = title
        self.content = content
        self.isExpanded = isExpanded
    }
}

/// Section type enumeration for test details
enum UITestSectionType: String, CaseIterable, Sendable, Codable {
    case about = "about"
    case whyNeeded = "why_needed"
    case insights = "insights"
    case preparation = "preparation"
    case results = "results"
    
    var icon: String {
        switch self {
        case .about: return "info.circle.fill"
        case .whyNeeded: return "questionmark.circle.fill"
        case .insights: return "lightbulb.fill"
        case .preparation: return "checklist"
        case .results: return "chart.line.uptrend.xyaxis"
        }
    }
}

/// Section content model
struct TestSectionContent: Sendable {
    let overview: String?
    let bulletPoints: [String]
    let categories: [ContentCategory]
    let tips: [String]
    let warnings: [String]
    
    init(
        overview: String? = nil,
        bulletPoints: [String] = [],
        categories: [ContentCategory] = [],
        tips: [String] = [],
        warnings: [String] = []
    ) {
        self.overview = overview
        self.bulletPoints = bulletPoints
        self.categories = categories
        self.tips = tips
        self.warnings = warnings
    }
}

/// Content category for organized information
struct ContentCategory: Sendable, Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let items: [String]
    let color: Color?
    
    init(icon: String, title: String, items: [String], color: Color? = nil) {
        self.icon = icon
        self.title = title
        self.items = items
        self.color = color
    }
}

// MARK: - Observable wrapper for UI state management

@MainActor
@Observable
final class TestDetailsState {
    var sections: [TestSection]
    
    init(sections: [TestSection]) {
        self.sections = sections
    }
    
    func toggleSection(withId id: UUID) {
        if let index = sections.firstIndex(where: { $0.id == id }) {
            sections[index].isExpanded.toggle()
        }
    }
}

// MARK: - Removed Sample Data Factory
// All sample/mock test data has been removed to ensure production safety
// Test data should only come from real LabLoop API calls
// Removed all hardcoded sample data and section factories