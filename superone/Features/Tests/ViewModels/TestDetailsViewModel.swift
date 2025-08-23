import SwiftUI
import Foundation

/// Test details view model with Swift 6.0 concurrency compliance
@MainActor
@Observable
final class TestDetailsViewModel {
    
    // MARK: - Published Properties
    private(set) var testDetails: TestDetails?
    private(set) var testDetailsState: TestDetailsState?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isSaved = false
    private(set) var canShare = true
    
    // MARK: - Private Properties
    private let testService: TestServiceProtocol
    private let favoriteService: FavoriteServiceProtocol
    
    // MARK: - Initialization
    init(
        testService: TestServiceProtocol = MockTestService(),
        favoriteService: FavoriteServiceProtocol = MockFavoriteService()
    ) {
        self.testService = testService
        self.favoriteService = favoriteService
    }
    
    // MARK: - Public Methods
    
    /// Load test details by ID
    func loadTestDetails(testId: String) {
        Task {
            await loadTestDetailsAsync(testId: testId)
        }
    }
    
    /// Toggle section expansion state
    func toggleSection(withId id: UUID) {
        testDetailsState?.toggleSection(withId: id)
    }
    
    /// Toggle favorite status
    func toggleFavorite() {
        guard let test = testDetails else { return }
        
        Task {
            await toggleFavoriteAsync(test: test)
        }
    }
    
    /// Share test details
    func shareTest() -> TestShareSheet? {
        guard let test = testDetails, canShare else { return nil }
        
        let shareText = """
        \(test.name)
        
        Duration: \(test.duration)
        Price: \(test.price)
        Sample: \(test.sampleType.displayName)
        Fasting: \(test.fasting.displayText)
        
        \(test.description)
        
        Shared from Super One Health App
        """
        
        return TestShareSheet(activityItems: [shareText])
    }
    
    /// Navigate to booking flow
    func bookTest(completion: @escaping (Bool) -> Void) {
        guard let test = testDetails else {
            completion(false)
            return
        }
        
        Task {
            let success = await bookTestAsync(test: test)
            await MainActor.run {
                completion(success)
            }
        }
    }
    
    /// Refresh test details
    func refresh() {
        guard let testId = testDetails?.id else { return }
        loadTestDetails(testId: testId)
    }
    
    // MARK: - Private Methods
    
    private func loadTestDetailsAsync(testId: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let details = try await testService.getTestDetails(testId: testId)
            let favoriteStatus = try await favoriteService.isFavorite(testId: testId)
            
            await MainActor.run {
                testDetails = details
                testDetailsState = TestDetailsState(sections: details.sections)
                isSaved = favoriteStatus
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load test details: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func toggleFavoriteAsync(test: TestDetails) async {
        do {
            let currentSavedState = await MainActor.run { isSaved }
            if currentSavedState {
                try await favoriteService.removeFavorite(testId: test.id)
                await MainActor.run { isSaved = false }
            } else {
                try await favoriteService.addFavorite(testId: test.id)
                await MainActor.run { isSaved = true }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update favorite status: \(error.localizedDescription)"
            }
        }
    }
    
    private func bookTestAsync(test: TestDetails) async -> Bool {
        do {
            // Simulate booking process
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Failed to book test: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Check if test requires preparation
    var requiresPreparation: Bool {
        testDetails?.fasting.isRequired == true
    }
    
    /// Get formatted price with discount
    var priceDisplay: String {
        guard let test = testDetails else { return "" }
        
        if let originalPrice = test.originalPrice {
            return "\(test.price) \(originalPrice)"
        } else {
            return test.price
        }
    }
    
    /// Get test category color
    var categoryColor: Color {
        testDetails?.category.color ?? HealthColors.primary
    }
}

// MARK: - Service Protocols

/// Protocol for test data service
protocol TestServiceProtocol: Sendable {
    func getTestDetails(testId: String) async throws -> TestDetails
    func getRelatedTests(testId: String) async throws -> [TestDetails]
}

/// Protocol for favorite management service
protocol FavoriteServiceProtocol: Sendable {
    func isFavorite(testId: String) async throws -> Bool
    func addFavorite(testId: String) async throws
    func removeFavorite(testId: String) async throws
    func getAllFavorites() async throws -> [String]
}

// MARK: - Mock Implementations

/// Mock test service for development and testing
actor MockTestService: TestServiceProtocol {
    
    func getTestDetails(testId: String) async throws -> TestDetails {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return await MainActor.run {
            switch testId {
            case "cbc_001":
                return TestDetails.sampleCBC()
            case "lipid_001":
                return TestDetails.sampleLipidProfile()
            default:
                return TestDetails.sampleCBC()
            }
        }
    }
    
    func getRelatedTests(testId: String) async throws -> [TestDetails] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return await MainActor.run {
            [
                TestDetails.sampleLipidProfile(),
                TestDetails.sampleCBC()
            ]
        }
    }
}

/// Mock favorite service for development and testing
actor MockFavoriteService: FavoriteServiceProtocol {
    
    private var favorites: Set<String> = []
    
    func isFavorite(testId: String) async throws -> Bool {
        // Simulate storage delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        return favorites.contains(testId)
    }
    
    func addFavorite(testId: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        favorites.insert(testId)
    }
    
    func removeFavorite(testId: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        favorites.remove(testId)
    }
    
    func getAllFavorites() async throws -> [String] {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        return Array(favorites)
    }
}

// MARK: - Test Share Sheet

struct TestShareSheet: UIViewControllerRepresentable, Identifiable {
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

struct TestDetailsError: LocalizedError, Sendable {
    let description: String
    
    nonisolated var errorDescription: String? {
        return description
    }
    
    static let testNotFound = TestDetailsError(description: "Test not found")
    static let networkError = TestDetailsError(description: "Network connection error")
    static let invalidData = TestDetailsError(description: "Invalid test data received")
}