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

// MARK: - Sample Data Factory

extension HealthPackage {
    /// Create sample Comprehensive Health Checkup package
    static func sampleComprehensive() -> HealthPackage {
        var package = HealthPackage(
            id: "comprehensive_001",
            name: "Comprehensive Health Checkup",
            shortName: "Comprehensive",
            icon: "🏥",
            description: "Complete health assessment with 25+ tests covering all major health parameters for preventive healthcare and early detection.",
            duration: "45-60 minutes",
            totalTests: 25,
            fastingRequirement: .hours12,
            reportTime: "Same day (by 6 PM)",
            packagePrice: 2800,
            individualPrice: 4200,
            savings: 1400,
            discountPercentage: 33,
            testCategories: sampleTestCategories(),
            recommendedFor: [
                "Adults 25+ years (Annual checkup)",
                "Family history of chronic diseases",
                "Lifestyle risk factors (stress, diet)",
                "Pre-employment medical requirements",
                "Insurance policy health assessments"
            ],
            notSuitableFor: [
                "Pregnant women (consult doctor first)",
                "Children under 18 years",
                "Recent surgery patients (within 30 days)"
            ],
            healthInsights: sampleHealthInsights(),
            preparationInstructions: samplePreparationInstructions(),
            availableLabs: sampleLabFacilities(),
            packageVariants: samplePackageVariants(),
            customerReviews: sampleCustomerReviews(),
            faqItems: sampleFAQItems(),
            isFeatured: true,
            isAvailable: true
        )
        
        // Set additional UI properties
        package.isPopular = true
        package.category = "Premium"
        
        return package
    }
    
    // MARK: - Sample Data Helpers
    
    private static func sampleTestCategories() -> [HealthTestCategory] {
        return [
            HealthTestCategory(
                name: "Blood Health",
                icon: "🩸",
                tests: [
                    HealthTest(name: "Complete Blood Count (CBC)"),
                    HealthTest(name: "ESR (Erythrocyte Sedimentation Rate)"),
                    HealthTest(name: "Blood Group & Rh Factor"),
                    HealthTest(name: "Peripheral Blood Smear"),
                    HealthTest(name: "Platelet Count"),
                    HealthTest(name: "Hemoglobin Electrophoresis"),
                    HealthTest(name: "Reticulocyte Count"),
                    HealthTest(name: "Iron Studies (Serum Iron, TIBC, Ferritin)")
                ],
                color: .red
            ),
            HealthTestCategory(
                name: "Heart Health",
                icon: "🫀",
                tests: [
                    HealthTest(name: "Total Cholesterol"),
                    HealthTest(name: "HDL Cholesterol"),
                    HealthTest(name: "LDL Cholesterol"),
                    HealthTest(name: "Triglycerides"),
                    HealthTest(name: "VLDL Cholesterol"),
                    HealthTest(name: "Cholesterol/HDL Ratio")
                ],
                color: .red
            ),
            HealthTestCategory(
                name: "Diabetes Panel",
                icon: "🍭",
                tests: [
                    HealthTest(name: "Fasting Blood Sugar"),
                    HealthTest(name: "HbA1c (Average Blood Sugar)"),
                    HealthTest(name: "Post Meal Blood Sugar")
                ],
                color: .orange
            ),
            HealthTestCategory(
                name: "Bone Health",
                icon: "🦴",
                tests: [
                    HealthTest(name: "Vitamin D (25-OH)"),
                    HealthTest(name: "Calcium (Total & Ionized)")
                ],
                color: .blue
            ),
            HealthTestCategory(
                name: "Hormone Panel",
                icon: "🧬",
                tests: [
                    HealthTest(name: "Thyroid Profile (TSH, T3, T4)"),
                    HealthTest(name: "Cortisol"),
                    HealthTest(name: "Insulin (Fasting)")
                ],
                color: .purple
            ),
            HealthTestCategory(
                name: "Organ Function",
                icon: "🔬",
                tests: [
                    HealthTest(name: "Liver Function Test (LFT)"),
                    HealthTest(name: "Kidney Function Test (KFT)"),
                    HealthTest(name: "Urine Analysis (Complete)")
                ],
                color: .green
            )
        ]
    }
    
    private static func sampleHealthInsights() -> HealthInsights {
        return HealthInsights(
            earlyDetection: [
                "Diabetes & Pre-diabetes",
                "Heart disease risk",
                "Liver & kidney problems",
                "Anemia & blood disorders",
                "Thyroid dysfunction",
                "Vitamin deficiencies"
            ],
            healthMonitoring: [
                "Overall fitness level",
                "Organ function status",
                "Nutritional health",
                "Hormonal balance"
            ],
            aiPoweredAnalysis: [
                "Personalized health score",
                "Risk assessment for chronic diseases",
                "Lifestyle recommendations",
                "Follow-up test suggestions"
            ]
        )
    }
    
    private static func samplePreparationInstructions() -> PreparationInstructions {
        return PreparationInstructions(
            fastingHours: 12,
            dayBefore: [
                "Light dinner by 8:00 PM",
                "Only water after 8:00 PM",
                "Avoid alcohol for 24 hours",
                "Get 7-8 hours of sleep"
            ],
            morningOfTest: [
                "No food or drinks (except water)",
                "Take regular medications with water",
                "Wear comfortable, loose clothing"
            ],
            whatToBring: [
                "Photo ID (Aadhar, Driving License)",
                "Previous health reports (if any)",
                "Current medications list",
                "Doctor's prescription (if applicable)"
            ],
            generalTips: [
                "Schedule morning appointments",
                "Stay hydrated with water",
                "Relax and remain calm"
            ]
        )
    }
    
    private static func sampleLabFacilities() -> [LabFacility] {
        return [
            LabFacility(
                id: "lab_001",
                name: "LabLoop Central Lab",
                type: .lab,
                rating: 4.8,
                distance: "2.3 km",
                availability: "Next: Today 3:00 PM",
                price: 2800,
                isWalkInAvailable: false,
                nextSlot: "Today 3:00 PM",
                address: "123 Health Street, Medical District",
                phoneNumber: "+91 98765 43210",
                location: "Medical District, Mumbai",
                services: ["Blood Tests", "X-Ray", "Ultrasound", "ECG"],
                reviewCount: 245,
                operatingHours: "6:00 AM - 10:00 PM",
                isRecommended: true,
                offersHomeCollection: true,
                acceptsInsurance: true
            ),
            LabFacility(
                id: "lab_002",
                name: "Zero Hospital",
                type: .hospital,
                rating: 4.2,
                distance: "3.1 km",
                availability: "Walk-ins OK",
                price: 2650,
                isWalkInAvailable: true,
                nextSlot: nil,
                address: "456 Medical Avenue, Health City",
                phoneNumber: "+91 98765 43211",
                location: "Health City, Mumbai",
                services: ["Blood Tests", "MRI", "CT Scan", "Pathology"],
                reviewCount: 189,
                operatingHours: "24 Hours",
                isRecommended: false,
                offersHomeCollection: false,
                acceptsInsurance: true
            ),
            LabFacility(
                id: "home_001",
                name: "Home Collection",
                type: .homeCollection,
                rating: 4.7,
                distance: "Available tomorrow 7-9 AM",
                availability: "Available tomorrow 7-9 AM",
                price: 3100,
                isWalkInAvailable: false,
                nextSlot: "Tomorrow 7:00 AM",
                address: nil,
                phoneNumber: "+91 98765 43212",
                location: "Your Location",
                services: ["Blood Collection", "Sample Collection"],
                reviewCount: 532,
                operatingHours: "7:00 AM - 9:00 AM",
                isRecommended: true,
                offersHomeCollection: true,
                acceptsInsurance: false
            )
        ]
    }
    
    private static func samplePackageVariants() -> [PackageVariant] {
        return [
            PackageVariant(
                id: "basic_001",
                name: "Basic Health Checkup",
                price: 1200,
                testCount: 15,
                duration: "30 min",
                description: "Essential tests for routine health monitoring",
                isPopular: false
            ),
            PackageVariant(
                id: "executive_001",
                name: "Executive Health Package",
                price: 4500,
                testCount: 40,
                duration: "90 min",
                description: "40+ tests + ECG + consultation",
                isPopular: true
            ),
            PackageVariant(
                id: "women_001",
                name: "Women's Health Package",
                price: 3200,
                testCount: 28,
                duration: "60 min",
                description: "Specialized tests for women 25+",
                isPopular: false
            )
        ]
    }
    
    private static func sampleCustomerReviews() -> [CustomerReview] {
        return [
            CustomerReview(
                id: "review_001",
                customerName: "Priya S.",
                rating: 5.0,
                comment: "Comprehensive package with detailed report. Found vitamin D deficiency early and started treatment. Highly recommended!",
                date: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date(),
                isVerified: true
            ),
            CustomerReview(
                id: "review_002",
                customerName: "Rahul M.",
                rating: 5.0,
                comment: "Great value for money. All tests done in one go, report was ready same evening. Staff was very professional.",
                date: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
                isVerified: true
            ),
            CustomerReview(
                id: "review_003",
                customerName: "Anita K.",
                rating: 4.0,
                comment: "Good package but waiting time was long. Report quality is excellent with AI insights. Will book again next year.",
                date: Calendar.current.date(byAdding: .weekOfYear, value: -3, to: Date()) ?? Date(),
                isVerified: true
            )
        ]
    }
    
    private static func sampleFAQItems() -> [FAQItem] {
        return [
            FAQItem(
                question: "Can I customize the package?",
                answer: "Yes, you can add/remove specific tests based on your health needs and doctor's recommendations."
            ),
            FAQItem(
                question: "How long do results take?",
                answer: "Most test results are available the same day by 6 PM. Complex tests may take 24-48 hours."
            ),
            FAQItem(
                question: "Is home collection available?",
                answer: "Yes, home collection is available with an additional ₹300 collection fee. Our trained phlebotomists will visit your location."
            ),
            FAQItem(
                question: "Can I eat after the test?",
                answer: "Yes, you can resume your normal diet immediately after the blood collection is complete."
            ),
            FAQItem(
                question: "What if I'm taking medications?",
                answer: "Continue taking your regular medications unless specifically advised otherwise by your doctor. Bring a list of current medications."
            )
        ]
    }
}