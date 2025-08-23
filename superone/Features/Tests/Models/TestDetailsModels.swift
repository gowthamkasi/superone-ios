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
enum TestCategory: String, CaseIterable, Sendable {
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
enum FastingRequirement: String, CaseIterable, Sendable {
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
enum SampleType: String, CaseIterable, Sendable {
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
    let type: TestSectionType
    let title: String
    let content: TestSectionContent
    var isExpanded: Bool
    
    init(type: TestSectionType, title: String, content: TestSectionContent, isExpanded: Bool = false) {
        self.type = type
        self.title = title
        self.content = content
        self.isExpanded = isExpanded
    }
}

/// Section type enumeration
enum TestSectionType: String, CaseIterable, Sendable {
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

// MARK: - Sample Data Factory

extension TestDetails {
    /// Create sample Complete Blood Count (CBC) test
    static func sampleCBC() -> TestDetails {
        return TestDetails(
            id: "cbc_001",
            name: "Complete Blood Count (CBC)",
            shortName: "CBC",
            icon: "🩸",
            category: .bloodTest,
            duration: "15 minutes",
            price: "₹500",
            originalPrice: "₹600",
            fasting: .hours12,
            sampleType: .blood,
            reportTime: "Same day (6-8 hours)",
            description: "A Complete Blood Count (CBC) is one of the most common blood tests that evaluates your overall health and detects various disorders.",
            keyMeasurements: [
                "Red Blood Cells (RBC) - Oxygen carriers",
                "White Blood Cells (WBC) - Infection fighters",
                "Platelets - Blood clotting helpers",
                "Hemoglobin - Oxygen-carrying protein",
                "Hematocrit - Percentage of red blood cells in blood"
            ],
            healthBenefits: "This test provides a snapshot of your blood health and helps detect anemia, infections, blood disorders, and immune system problems.",
            sections: cbcSections(),
            isFeatured: true,
            isAvailable: true,
            tags: ["blood", "routine", "comprehensive", "health checkup"]
        )
    }
    
    /// Create sample Lipid Profile test
    static func sampleLipidProfile() -> TestDetails {
        return TestDetails(
            id: "lipid_001",
            name: "Lipid Profile Complete",
            shortName: "Lipid Profile",
            icon: "💖",
            category: .cardiology,
            duration: "10 minutes",
            price: "₹400",
            originalPrice: "₹500",
            fasting: .hours12,
            sampleType: .blood,
            reportTime: "Same day (4-6 hours)",
            description: "A comprehensive cholesterol panel that evaluates your risk for heart disease and stroke.",
            keyMeasurements: [
                "Total Cholesterol",
                "HDL (Good) Cholesterol",
                "LDL (Bad) Cholesterol",
                "Triglycerides",
                "Non-HDL Cholesterol"
            ],
            healthBenefits: "Helps assess cardiovascular risk and guide treatment decisions for heart health.",
            sections: lipidSections(),
            isFeatured: true,
            isAvailable: true,
            tags: ["cholesterol", "heart", "cardiovascular", "lipids"]
        )
    }
    
    // MARK: - Section Factories
    
    private static func cbcSections() -> [TestSection] {
        return [
            TestSection(
                type: .about,
                title: "About Complete Blood Count (CBC)",
                content: TestSectionContent(
                    overview: "A Complete Blood Count (CBC) is one of the most common blood tests that evaluates your overall health and detects various disorders.",
                    bulletPoints: [
                        "Red Blood Cells (RBC) - Oxygen carriers",
                        "White Blood Cells (WBC) - Infection fighters",
                        "Platelets - Blood clotting helpers",
                        "Hemoglobin - Oxygen-carrying protein",
                        "Hematocrit - Percentage of red blood cells in blood"
                    ]
                )
            ),
            TestSection(
                type: .whyNeeded,
                title: "Why You Might Need This Test",
                content: TestSectionContent(
                    overview: "Common reasons for CBC testing:",
                    categories: [
                        ContentCategory(
                            icon: "🔍",
                            title: "Routine Health Checkup",
                            items: [
                                "Annual physical examination",
                                "Preventive health screening"
                            ]
                        ),
                        ContentCategory(
                            icon: "🤒",
                            title: "Symptoms Investigation",
                            items: [
                                "Unexplained fatigue or weakness",
                                "Frequent infections",
                                "Easy bruising or bleeding",
                                "Pale skin or shortness of breath"
                            ]
                        ),
                        ContentCategory(
                            icon: "📋",
                            title: "Medical Monitoring",
                            items: [
                                "Before surgery or medical procedures",
                                "Monitoring treatment effects",
                                "Managing chronic conditions"
                            ]
                        ),
                        ContentCategory(
                            icon: "⚠️",
                            title: "Specific Concerns",
                            items: [
                                "Suspected anemia",
                                "Blood disorder evaluation",
                                "Immune system assessment"
                            ]
                        )
                    ]
                )
            ),
            TestSection(
                type: .insights,
                title: "Health Insights & Benefits",
                content: TestSectionContent(
                    overview: "What this test can reveal:",
                    categories: [
                        ContentCategory(
                            icon: "🩸",
                            title: "Blood Health Status",
                            items: [
                                "Anemia detection (iron deficiency)",
                                "Blood volume and circulation health",
                                "Oxygen-carrying capacity"
                            ]
                        ),
                        ContentCategory(
                            icon: "🦠",
                            title: "Immune System Function",
                            items: [
                                "White blood cell count & types",
                                "Infection-fighting capability",
                                "Immune system disorders"
                            ]
                        ),
                        ContentCategory(
                            icon: "🧬",
                            title: "Blood Disorders",
                            items: [
                                "Leukemia or lymphoma indicators",
                                "Bleeding or clotting disorders",
                                "Bone marrow function"
                            ]
                        ),
                        ContentCategory(
                            icon: "📈",
                            title: "Trend Monitoring",
                            items: [
                                "Track changes over time",
                                "Monitor treatment effectiveness",
                                "Early detection of developing issues"
                            ]
                        )
                    ],
                    tips: [
                        "Dietary recommendations",
                        "Lifestyle modifications",
                        "Follow-up test suggestions",
                        "When to consult a doctor"
                    ]
                )
            ),
            TestSection(
                type: .preparation,
                title: "Preparation Instructions",
                content: TestSectionContent(
                    overview: "Follow these instructions for accurate results:",
                    categories: [
                        ContentCategory(
                            icon: "🍽️",
                            title: "Fasting Requirements",
                            items: [
                                "Fast for 12 hours before the test",
                                "No food or drinks except water",
                                "Last meal: night before (8 PM)",
                                "Test time: morning (8-10 AM ideal)"
                            ]
                        ),
                        ContentCategory(
                            icon: "💧",
                            title: "What You CAN Have",
                            items: [
                                "✅ Plain water (stay hydrated)",
                                "✅ Essential medications (consult doctor)"
                            ],
                            color: .green
                        ),
                        ContentCategory(
                            icon: "🚫",
                            title: "What to AVOID",
                            items: [
                                "❌ Food and snacks",
                                "❌ Beverages (coffee, tea, juice, soda)",
                                "❌ Chewing gum or mints",
                                "❌ Smoking"
                            ],
                            color: .red
                        ),
                        ContentCategory(
                            icon: "📋",
                            title: "What to Bring",
                            items: [
                                "Government-issued photo ID",
                                "Doctor's prescription (if any)",
                                "Previous test reports",
                                "Insurance card"
                            ]
                        )
                    ],
                    tips: [
                        "Schedule morning appointments",
                        "Get plenty of sleep night before",
                        "Wear comfortable, loose-sleeved clothing",
                        "Relax and stay calm during collection"
                    ]
                )
            ),
            TestSection(
                type: .results,
                title: "Understanding Your Results",
                content: TestSectionContent(
                    overview: "Learn how to interpret your test results and what they mean for your health.",
                    bulletPoints: [
                        "Reference ranges vary by age, gender, and lab",
                        "Results are best interpreted by healthcare professionals",
                        "Abnormal results don't always indicate disease",
                        "Follow-up testing may be recommended"
                    ]
                )
            )
        ]
    }
    
    private static func lipidSections() -> [TestSection] {
        return [
            TestSection(
                type: .about,
                title: "About Lipid Profile",
                content: TestSectionContent(
                    overview: "A comprehensive cholesterol panel that evaluates your risk for heart disease and stroke.",
                    bulletPoints: [
                        "Total Cholesterol - Overall cholesterol level",
                        "HDL Cholesterol - 'Good' cholesterol",
                        "LDL Cholesterol - 'Bad' cholesterol",
                        "Triglycerides - Blood fats",
                        "Non-HDL Cholesterol - Risk assessment"
                    ]
                )
            ),
            TestSection(
                type: .whyNeeded,
                title: "Why You Might Need This Test",
                content: TestSectionContent(
                    categories: [
                        ContentCategory(
                            icon: "💖",
                            title: "Heart Health Screening",
                            items: [
                                "Family history of heart disease",
                                "High blood pressure",
                                "Smoking history",
                                "Diabetes or pre-diabetes"
                            ]
                        ),
                        ContentCategory(
                            icon: "🎯",
                            title: "Risk Assessment",
                            items: [
                                "Age over 40 years",
                                "Obesity or overweight",
                                "Sedentary lifestyle",
                                "Unhealthy diet patterns"
                            ]
                        )
                    ]
                )
            ),
            TestSection(
                type: .preparation,
                title: "Preparation Instructions",
                content: TestSectionContent(
                    overview: "Important: 12-hour fasting required for accurate results.",
                    categories: [
                        ContentCategory(
                            icon: "⏰",
                            title: "Fasting Guidelines",
                            items: [
                                "Fast for 12 hours before test",
                                "Only water allowed during fasting",
                                "No food, drinks, gum, or candy",
                                "Take medications as prescribed"
                            ]
                        )
                    ],
                    tips: [
                        "Schedule morning appointment to minimize fasting time",
                        "Continue regular medications unless advised otherwise",
                        "Avoid alcohol 24 hours before test"
                    ]
                )
            )
        ]
    }
}