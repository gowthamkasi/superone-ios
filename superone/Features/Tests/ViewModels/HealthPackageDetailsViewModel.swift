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
    private let packageService: PackageServiceProtocol
    private let favoriteService: FavoriteServiceProtocol
    
    // MARK: - Initialization
    init(
        packageService: PackageServiceProtocol = MockPackageService(),
        favoriteService: FavoriteServiceProtocol = MockFavoriteService()
    ) {
        self.packageService = packageService
        self.favoriteService = favoriteService
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
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return await MainActor.run {
            switch packageId {
            case "comprehensive_001":
                return HealthPackage.sampleComprehensive()
            default:
                return HealthPackage.sampleComprehensive()
            }
        }
    }
    
    func getRelatedPackages(packageId: String) async throws -> [HealthPackage] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return await MainActor.run {
            [HealthPackage.sampleComprehensive()]
        }
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

