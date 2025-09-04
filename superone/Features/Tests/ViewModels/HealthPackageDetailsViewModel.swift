import SwiftUI
import Foundation

/// Health package details view model with Swift 6.0 concurrency compliance
@MainActor
@Observable
final class HealthPackageDetailsViewModel {
    
    // MARK: - Published Properties
    private(set) var packageDetails: HealthPackage?
    private(set) var packageDetailsState: HealthPackageDetailsState?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isSaved = false
    private(set) var canShare = true
    
    // MARK: - Private Properties
    private let testsAPIService = TestsAPIService.shared
    private let packageService: PackageServiceProtocol
    private let favoriteService: FavoriteServiceProtocol
    
    // MARK: - Initialization
    init(
        packageService: PackageServiceProtocol? = nil,
        favoriteService: FavoriteServiceProtocol? = nil
    ) {
        // Use real services by default, allow injection for testing
        self.packageService = packageService ?? RealPackageService()
        self.favoriteService = favoriteService ?? PackageFavoriteService()
    }
    
    // MARK: - Public Methods
    
    /// Load package details by ID
    func loadPackageDetails(packageId: String) {
        Task {
            await loadPackageDetailsAsync(packageId: packageId)
        }
    }
    
    /// Toggle section expansion state
    func toggleSection(withId id: UUID) {
        packageDetailsState?.toggleSection(withId: id)
    }
    
    /// Toggle favorite status
    func toggleFavorite() {
        guard let package = packageDetails else { return }
        
        Task {
            await toggleFavoriteAsync(package: package)
        }
    }
    
    /// Share package details
    func sharePackage() -> PackageShareSheet? {
        guard let package = packageDetails, canShare else { return nil }
        
        let shareText = """
        \(package.name)
        
        Total Tests: \(package.totalTests)
        Duration: \(package.duration)
        Price: \(package.formattedPrice)
        Fasting: \(package.fastingRequirement.displayText)
        
        \(package.description)
        
        Shared from Super One Health App
        """
        
        return PackageShareSheet(activityItems: [shareText])
    }
    
    /// Navigate to booking flow
    func bookPackage(completion: @escaping (Bool) -> Void) {
        guard let package = packageDetails else {
            completion(false)
            return
        }
        
        Task {
            let success = await bookPackageAsync(package: package)
            await MainActor.run {
                completion(success)
            }
        }
    }
    
    /// Refresh package details
    func refresh() {
        guard let packageId = packageDetails?.id else { return }
        loadPackageDetails(packageId: packageId)
    }
    
    // MARK: - Private Methods
    
    private func loadPackageDetailsAsync(packageId: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let details = try await packageService.getPackageDetails(packageId: packageId)
            let favoriteStatus = try await favoriteService.isFavorite(testId: packageId)
            
            await MainActor.run {
                packageDetails = details
                packageDetailsState = HealthPackageDetailsState(sections: createSections(from: details))
                isSaved = favoriteStatus
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load package details: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func toggleFavoriteAsync(package: HealthPackage) async {
        do {
            let currentSavedState = await MainActor.run { isSaved }
            if currentSavedState {
                try await favoriteService.removeFavorite(testId: package.id)
                await MainActor.run { isSaved = false }
            } else {
                try await favoriteService.addFavorite(testId: package.id)
                await MainActor.run { isSaved = true }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update favorite status: \(error.localizedDescription)"
            }
        }
    }
    
    private func bookPackageAsync(package: HealthPackage) async -> Bool {
        do {
            // Simulate booking process
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Failed to book package: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    private func createSections(from package: HealthPackage) -> [PackageSection] {
        var sections: [PackageSection] = []
        
        // Health Insights section
        sections.append(PackageSection(
            id: UUID(),
            title: "Health Insights",
            type: .insights,
            content: PackageSectionContent(
                overview: "This comprehensive package provides valuable health insights through AI-powered analysis and early detection capabilities.",
                bulletPoints: package.healthInsights.earlyDetection + package.healthInsights.healthMonitoring,
                categories: [],
                tips: [],
                warnings: []
            ),
            isExpanded: false
        ))
        
        // Preparation Instructions section
        if !package.preparationInstructions.dayBefore.isEmpty {
            sections.append(PackageSection(
                id: UUID(),
                title: "Preparation Instructions",
                type: .preparation,
                content: PackageSectionContent(
                    overview: "Follow these instructions to ensure accurate test results.",
                    bulletPoints: package.preparationInstructions.dayBefore + package.preparationInstructions.morningOfTest,
                    categories: [],
                    tips: package.preparationInstructions.generalTips,
                    warnings: []
                ),
                isExpanded: false
            ))
        }
        
        // Recommended For section
        if !package.recommendedFor.isEmpty {
            sections.append(PackageSection(
                id: UUID(),
                title: "Recommended For",
                type: .recommendedFor,
                content: PackageSectionContent(
                    overview: "This package is specially designed for:",
                    bulletPoints: package.recommendedFor,
                    categories: [],
                    tips: [],
                    warnings: package.notSuitableFor.isEmpty ? [] : ["Not recommended for: " + package.notSuitableFor.joined(separator: ", ")]
                ),
                isExpanded: false
            ))
        }
        
       
        
        return sections
    }
    
    // MARK: - Convenience Methods
    
    /// Check if package requires preparation
    var requiresPreparation: Bool {
        packageDetails?.fastingRequirement != FastingRequirement.none
    }
    
    /// Get formatted price with discount
    var priceDisplay: String {
        guard let package = packageDetails else { return "" }
        
        if let originalPrice = package.originalPrice {
            return "\(package.formattedPrice) \(String(format: "₹%.0f", originalPrice))"
        } else {
            return package.formattedPrice
        }
    }
    
    /// Get package category color
    var categoryColor: Color {
        HealthColors.primary
    }
}

// MARK: - Service Protocols

/// Protocol for package data service
protocol PackageServiceProtocol: Sendable {
    func getPackageDetails(packageId: String) async throws -> HealthPackage
    func getRelatedPackages(packageId: String) async throws -> [HealthPackage]
}

// MARK: - Mock Implementations

/// Mock package service for development and testing
actor MockPackageService: PackageServiceProtocol {
    
    func getPackageDetails(packageId: String) async throws -> HealthPackage {
        // TODO: Replace with actual LabLoop API call
        // Simulate network delay then throw error - no hardcoded package data
        try await Task.sleep(nanoseconds: 500_000_000)
        throw NSError(domain: "HealthPackage", code: 404, userInfo: [NSLocalizedDescriptionKey: "Package not found"])
    }
    
    func getRelatedPackages(packageId: String) async throws -> [HealthPackage] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // TODO: Replace with actual LabLoop API call
        // Return empty array - no hardcoded related packages
        return []
    }
}

// MARK: - State Management

@MainActor
@Observable
final class HealthPackageDetailsState {
    private(set) var sections: [PackageSection]
    
    init(sections: [PackageSection]) {
        self.sections = sections
    }
    
    func toggleSection(withId id: UUID) {
        if let index = sections.firstIndex(where: { $0.id == id }) {
            sections[index].isExpanded.toggle()
        }
    }
}

// MARK: - Package Section Models

struct PackageSection: Identifiable, Sendable {
    let id: UUID
    let title: String
    let type: PackageSectionType
    let content: PackageSectionContent
    var isExpanded: Bool
    
    init(id: UUID = UUID(), title: String, type: PackageSectionType, content: PackageSectionContent, isExpanded: Bool = false) {
        self.id = id
        self.title = title
        self.type = type
        self.content = content
        self.isExpanded = isExpanded
    }
}

struct PackageSectionContent: Sendable {
    let overview: String?
    let bulletPoints: [String]
    let categories: [PackageSectionCategory]
    let tips: [String]
    let warnings: [String]
}

struct PackageSectionCategory: Identifiable, Sendable {
    let id: UUID
    let icon: String
    let title: String
    let items: [String]
    let color: Color
    
    init(id: UUID = UUID(), icon: String, title: String, items: [String], color: Color) {
        self.id = id
        self.icon = icon
        self.title = title
        self.items = items
        self.color = color
    }
}

enum PackageSectionType: Sendable {
    case insights
    case preparation
    case recommendedFor
    case faq
    
    var icon: String {
        switch self {
        case .insights:
            return "brain.head.profile"
        case .preparation:
            return "checklist"
        case .recommendedFor:
            return "person.2.circle"
        case .faq:
            return "questionmark.circle"
        }
    }
}

// MARK: - Real Implementations

/// Real package service using TestsAPIService
actor RealPackageService: PackageServiceProtocol {
    
    nonisolated private let testsAPIService: TestsAPIService
    
    init() {
        testsAPIService = TestsAPIService.shared
    }
    
    func getPackageDetails(packageId: String) async throws -> HealthPackage {
        do {
            let response = try await testsAPIService.getPackageDetails(packageId: packageId)
            let packageDetailsData = response.packageDetails
            
            // Convert PackageDetailsData to HealthPackage in MainActor context
            return await MainActor.run {
                convertToHealthPackage(from: packageDetailsData)
            }
            
        } catch let apiError as TestsAPIError {
            throw PackageDetailsError(description: apiError.errorDescription ?? "Failed to load package details")
        } catch {
            throw PackageDetailsError(description: error.localizedDescription)
        }
    }
    
    func getRelatedPackages(packageId: String) async throws -> [HealthPackage] {
        do {
            let response = try await testsAPIService.getPackageDetails(packageId: packageId)
            
            // Convert related packages from the API response in MainActor context
            return await MainActor.run {
                response.packageDetails.relatedPackages.compactMap { relatedPackage in
                    // For now, create simplified health packages from the related data
                    return HealthPackage(
                    id: relatedPackage.id,
                    name: relatedPackage.name,
                    shortName: relatedPackage.name,
                    icon: "📋",
                    description: "Related health package",
                    duration: "30 minutes",
                    totalTests: relatedPackage.testCount,
                    fastingRequirement: FastingRequirement.none,
                    reportTime: "Same day",
                    packagePrice: relatedPackage.price,
                    individualPrice: Int(Double(relatedPackage.price) * 1.2),
                    savings: Int(Double(relatedPackage.price) * 0.2),
                    discountPercentage: 17,
                    testCategories: [],
                    recommendedFor: [],
                    notSuitableFor: [],
                    healthInsights: HealthInsights(
                        earlyDetection: [],
                        healthMonitoring: [],
                        aiPoweredAnalysis: [],
                        additionalBenefits: []
                    ),
                    preparationInstructions: PreparationInstructions(
                        fastingHours: 0,
                        dayBefore: [],
                        morningOfTest: [],
                        whatToBring: [],
                        generalTips: []
                    ),
                    availableLabs: [],
                    packageVariants: [],
                    customerReviews: [],
                    faqItems: [],
                        isFeatured: false,
                        isAvailable: true
                    )
                }
            }
            
        } catch {
            // Return empty array on error rather than throwing
            return []
        }
    }
    
    /// Convert API model to UI model
    @MainActor
    private func convertToHealthPackage(from apiData: PackageDetailsData) -> HealthPackage {
        var healthPackage = HealthPackage(
            id: apiData.id,
            name: apiData.name,
            shortName: apiData.shortName ?? apiData.name,
            icon: apiData.icon,
            description: apiData.description,
            duration: apiData.duration,
            totalTests: apiData.totalTests,
            fastingRequirement: .none, // Default to avoid main actor isolation
            reportTime: apiData.reportTime,
            packagePrice: apiData.packagePrice,
            individualPrice: apiData.individualPrice,
            savings: apiData.savings,
            discountPercentage: apiData.discountPercentage,
            testCategories: convertTestCategories(from: apiData.testCategories),
            recommendedFor: apiData.recommendedFor,
            notSuitableFor: apiData.notSuitableFor,
            healthInsights: convertHealthInsights(from: apiData.healthInsights),
            preparationInstructions: convertPreparationInstructions(from: apiData.preparationInstructions),
            availableLabs: convertAvailableLabs(from: apiData.availableLabs),
            packageVariants: convertPackageVariants(from: apiData.packageVariants),
            customerReviews: convertCustomerReviews(from: apiData.customerReviews),
            faqItems: convertFAQItems(from: apiData.faqItems),
            isFeatured: apiData.isFeatured,
            isAvailable: apiData.isAvailable
        )
        
        // Set additional properties
        healthPackage.isPopular = apiData.isPopular
        healthPackage.category = apiData.category
        
        return healthPackage
    }
    
    /// Convert test categories from API to UI model
    @MainActor
    private func convertTestCategories(from apiCategories: [DetailedTestCategoryData]) -> [HealthTestCategory] {
        return apiCategories.map { apiCategory in
            HealthTestCategory(
                id: apiCategory.id,
                name: apiCategory.name,
                icon: apiCategory.icon,
                tests: apiCategory.tests.map { apiTest in
                    HealthTest(
                        id: apiTest.id,
                        name: apiTest.name,
                        shortName: apiTest.shortName,
                        description: apiTest.description
                    )
                },
                color: nil
            )
        }
    }
    
    /// Convert health insights
    @MainActor
    private func convertHealthInsights(from apiInsights: HealthInsightsData) -> HealthInsights {
        return HealthInsights(
            earlyDetection: apiInsights.earlyDetection,
            healthMonitoring: apiInsights.healthMonitoring,
            aiPoweredAnalysis: apiInsights.aiPoweredAnalysis,
            additionalBenefits: apiInsights.additionalBenefits
        )
    }
    
    /// Convert preparation instructions
    @MainActor
    private func convertPreparationInstructions(from apiInstructions: PreparationInstructionsData) -> PreparationInstructions {
        return PreparationInstructions(
            fastingHours: apiInstructions.fastingHours,
            dayBefore: apiInstructions.dayBefore,
            morningOfTest: apiInstructions.morningOfTest,
            whatToBring: apiInstructions.whatToBring,
            generalTips: apiInstructions.generalTips
        )
    }
    
    /// Convert available labs
    nonisolated private func convertAvailableLabs(from apiLabs: [AvailableLabData]) -> [LabFacility] {
        return apiLabs.map { apiLab in
            LabFacility(
                id: apiLab.id,
                name: apiLab.name,
                type: LabType(rawValue: apiLab.type ?? "lab") ?? .lab,
                rating: apiLab.rating,
                coordinates: nil, // TODO: Extract coordinates from API when available
                availability: apiLab.availability ?? "Available",
                price: Int(apiLab.price?.replacingOccurrences(of: "₹", with: "").replacingOccurrences(of: ",", with: "") ?? "0") ?? 0,
                isWalkInAvailable: apiLab.isWalkInAvailable ?? false,
                nextSlot: apiLab.nextSlot,
                address: apiLab.address,
                phoneNumber: apiLab.phoneNumber,
                website: nil, // TODO: Add website field when available from API
                location: apiLab.location,
                services: apiLab.services ?? [],
                reviewCount: apiLab.reviewCount ?? 0,
                operatingHours: apiLab.operatingHours ?? "9 AM - 6 PM",
                isRecommended: apiLab.isRecommended ?? false,
                offersHomeCollection: apiLab.offersHomeCollection ?? false,
                acceptsInsurance: apiLab.acceptsInsurance ?? false
            )
        }
    }
    
    /// Convert package variants
    nonisolated private func convertPackageVariants(from apiVariants: [PackageVariantData]) -> [PackageVariant] {
        return apiVariants.map { apiVariant in
            PackageVariant(
                id: apiVariant.id,
                name: apiVariant.name,
                price: apiVariant.price,
                testCount: apiVariant.testCount,
                duration: apiVariant.duration,
                description: apiVariant.description,
                isPopular: apiVariant.isPopular
            )
        }
    }
    
    /// Convert customer reviews
    nonisolated private func convertCustomerReviews(from apiReviews: [CustomerReviewData]) -> [CustomerReview] {
        return apiReviews.map { apiReview in
            CustomerReview(
                id: apiReview.id,
                customerName: apiReview.customerName,
                rating: apiReview.rating,
                comment: apiReview.comment,
                date: Date(), // Default to current date since API provides string
                isVerified: apiReview.isVerified
            )
        }
    }
    
    /// Convert FAQ items
    @MainActor
    private func convertFAQItems(from apiFAQs: [FAQItemData]) -> [FAQItem] {
        return apiFAQs.map { apiFAQ in
            FAQItem(
                id: apiFAQ.id,
                question: apiFAQ.question,
                answer: apiFAQ.answer
            )
        }
    }
}

/// Real favorite service for HealthPackageDetailsViewModel
actor PackageFavoriteService: FavoriteServiceProtocol {
    
    nonisolated private let testsAPIService: TestsAPIService
    
    init() {
        testsAPIService = TestsAPIService.shared
    }
    private var cachedFavorites: Set<String> = []
    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    func isFavorite(testId: String) async throws -> Bool {
        await refreshFavoritesIfNeeded()
        return cachedFavorites.contains(testId)
    }
    
    func addFavorite(testId: String) async throws {
        do {
            let response = try await testsAPIService.toggleFavorite(testId: testId)
            if response.isFavorite {
                cachedFavorites.insert(testId)
            }
        } catch let apiError as TestsAPIError {
            throw PackageDetailsError(description: apiError.errorDescription ?? "Failed to add favorite")
        }
    }
    
    func removeFavorite(testId: String) async throws {
        do {
            let response = try await testsAPIService.toggleFavorite(testId: testId)
            if !response.isFavorite {
                cachedFavorites.remove(testId)
            }
        } catch let apiError as TestsAPIError {
            throw PackageDetailsError(description: apiError.errorDescription ?? "Failed to remove favorite")
        }
    }
    
    func getAllFavorites() async throws -> [String] {
        await refreshFavoritesIfNeeded()
        return Array(cachedFavorites)
    }
    
    /// Refresh favorites cache if needed
    private func refreshFavoritesIfNeeded() async {
        let now = Date()
        
        // Check if cache is still valid
        if let lastFetch = lastFetchTime,
           now.timeIntervalSince(lastFetch) < cacheValidityDuration {
            return
        }
        
        do {
            let response = try await testsAPIService.getUserFavorites(offset: 0, limit: 100)
            cachedFavorites = Set(response.favorites.map { $0.id })
            lastFetchTime = now
        } catch {
            // Keep existing cache on error
        }
    }
}

// MARK: - Package Share Sheet

struct PackageShareSheet: UIViewControllerRepresentable, Identifiable {
    let id = UUID()
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Error Types

struct PackageDetailsError: LocalizedError, Sendable {
    let description: String
    
    nonisolated var errorDescription: String? {
        return description
    }
    
    static let packageNotFound = PackageDetailsError(description: "Package not found")
    static let networkError = PackageDetailsError(description: "Network connection error")
    static let invalidData = PackageDetailsError(description: "Invalid package data received")
}

