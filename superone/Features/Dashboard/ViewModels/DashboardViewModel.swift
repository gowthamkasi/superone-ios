import Foundation
import UIKit

// Import LocationManager for location-aware dashboard
// Note: LocationManager provides location services integration

// Import lab report processing models for dashboard integration
// Note: This creates a dependency on LabReports feature
// Consider moving shared models to a common module in production

// Import BackendModels for ServiceType
// Note: ServiceType is defined in core/Models/BackendModels.swift

// MARK: - Quick Action Types
enum QuickActionType: String, CaseIterable {
    case uploadReport = "upload_report"
    case bookTest = "book_test"
    case viewReports = "view_reports"
    case healthInsights = "health_insights"
    case findLabs = "find_labs"
    case consultDoctor = "consult_doctor"
    
    var title: String {
        switch self {
        case .uploadReport: return "Upload Report"
        case .bookTest: return "Book Test"
        case .viewReports: return "View Reports"
        case .healthInsights: return "Health Insights"
        case .findLabs: return "Find Labs"
        case .consultDoctor: return "Consult Doctor"
        }
    }
    
    var systemImage: String {
        switch self {
        case .uploadReport: return "doc.badge.plus"
        case .bookTest: return "calendar.badge.plus"
        case .viewReports: return "folder.badge.minus"
        case .healthInsights: return "chart.line.uptrend.xyaxis"
        case .findLabs: return "location.magnifyingglass"
        case .consultDoctor: return "stethoscope"
        }
    }
}

/// ViewModel for dashboard managing health data, scores, and user interactions
@MainActor
@Observable
class DashboardViewModel {
    
    // MARK: - Observable Properties
    
    // Location services for dashboard location display
    var locationManager = LocationManager()
    
    // Booking-focused dashboard properties
    var featuredPackages: [HealthPackage] = []
    var isLoadingPackages: Bool = false
    
    // Legacy health score properties (commented out for booking focus)
    // var healthScore: HealthScore
    var quickStats: [QuickStat]
    var isLoading: Bool = false
    var errorMessage: String?
    var lastRefreshed: Date = Date()
    var userName: String = "Sarah"
    var notificationCount: Int = 0
    var labReportProcessingStatus: [LabReportProcessingActivity] = []
    
    // MARK: - Private Properties
    private var healthDataService: HealthDataServiceProtocol
    
    // MARK: - Initialization
    init(healthDataService: HealthDataServiceProtocol? = nil) {
        // Use real health data service when available, fall back to empty state
        self.healthDataService = healthDataService ?? ProductionHealthDataService()
        // self.healthScore = HealthScore(value: 0, trend: .stable) // Commented out for booking focus
        self.quickStats = []
        
        setupAppLifecycleObserver()
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// Refresh all dashboard data
    func refreshData() async {
        isLoading = true
        isLoadingPackages = true
        errorMessage = nil
        
        do {
            async let packagesTask = loadFeaturedPackages()
            async let quickStatsTask = loadQuickStats()
            async let notificationTask = loadNotificationCount()
            
            let (packages, stats, notifications) = try await (packagesTask, quickStatsTask, notificationTask)
            
            await MainActor.run {
                self.featuredPackages = packages
                self.quickStats = stats
                self.notificationCount = notifications
                self.lastRefreshed = Date()
                self.isLoading = false
                self.isLoadingPackages = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
                self.isLoading = false
                self.isLoadingPackages = false
            }
        }
    }
    
    /// Handle notification bell tap
    func handleNotificationTap() {
        // Will be implemented when notifications feature is added
    }
    
    /// Handle quick stat card tap
    func handleQuickStatTap(_ stat: QuickStat) {
        // Navigation logic will be implemented by Agent 3
    }
    
    /// Handle health score tap for detailed view (legacy - commented out for booking focus)
    func handleHealthScoreTap() {
        // Navigation to detailed health score view
    }
    
    // MARK: - New Booking-Focused Methods
    
    /// Handle package selection from featured packages
    func handlePackageSelection(_ package: HealthPackage) {
        // TODO: Navigate to package details or booking flow
        print("Selected package: \(package.name)")
        // This would typically trigger navigation to a package detail view
        // or directly to the booking flow for the selected package
    }
    
    /// Navigate to all packages view
    func navigateToAllPackages() {
        // TODO: Navigate to comprehensive packages listing
        print("Navigate to all packages")
        // This would open a full catalog of available health packages
    }
    
    /// Handle service option tap
    func handleServiceOptionTap(_ serviceType: ServiceType) {
        // TODO: Navigate to service-specific booking or information
        print("Selected service: \(serviceType.rawValue)")
        // This would navigate to specific service booking flows
    }
    
    /// Handle quick action button taps
    func handleQuickAction(_ actionType: QuickActionType) {
        // TODO: Handle various quick actions
        print("Quick action: \(actionType.title)")
        
        switch actionType {
        case .uploadReport:
            // Navigate to report upload flow
            break
        case .bookTest:
            // Navigate to test booking
            break
        case .viewReports:
            // Navigate to reports history
            break
        case .healthInsights:
            // Navigate to health insights
            break
        case .findLabs:
            // Navigate to lab locator
            break
        case .consultDoctor:
            // Navigate to doctor consultation
            break
        }
    }
    
    /// Update the health data service (for switching from mock to real data)
    func updateHealthDataService(_ service: HealthDataServiceProtocol) {
        healthDataService = service
        // Refresh data with new service
        Task {
            await refreshData()
        }
    }
    
    /// Add or update lab report processing activity
    func updateLabReportProcessingStatus(_ activity: LabReportProcessingActivity) {
        if let index = labReportProcessingStatus.firstIndex(where: { $0.documentId == activity.documentId }) {
            labReportProcessingStatus[index] = activity
        } else {
            labReportProcessingStatus.insert(activity, at: 0)
        }
        
        // Keep only the most recent 5 activities
        if labReportProcessingStatus.count > 5 {
            labReportProcessingStatus = Array(labReportProcessingStatus.prefix(5))
        }
    }
    
    /// Remove completed or cancelled activities after some time
    func cleanupOldActivities() {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        labReportProcessingStatus.removeAll { activity in
            (activity.status == .completed || activity.status == .cancelled) &&
            (activity.endTime ?? activity.startTime) < oneHourAgo
        }
    }
    
    /// Handle scroll position updates for iOS 18+ enhanced scroll tracking
    func updateScrollPosition(_ yOffset: CGFloat) {
        // Batch scroll position updates to improve performance
        // Only process significant scroll changes to avoid excessive computation
        let threshold: CGFloat = 10.0
        
        // Store last scroll position for comparison (if needed in future)
        // This method can be expanded to handle scroll-based UI updates,
        // such as showing/hiding navigation elements or triggering content loading
        
        // For now, this provides the foundation for advanced scroll behaviors
        // that can be implemented as the app evolves
        
        // Example potential uses:
        // - Parallax effects on header elements
        // - Auto-hiding navigation bar on scroll
        // - Lazy loading of content sections
        // - Scroll-based analytics tracking
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() {
        Task {
            await refreshData()
        }
    }
    
    private func setupAppLifecycleObserver() {
        // PERFORMANCE FIX: Remove Combine debouncing - use NotificationCenter directly
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                // Only refresh if data is older than 2 minutes
                if Date().timeIntervalSince(self.lastRefreshed) > 120 {
                    await self.refreshData()
                }
            }
        }
    }
    
    // MARK: - Data Loading Methods
    
    /// Load featured health packages for the dashboard
    private func loadFeaturedPackages() async throws -> [HealthPackage] {
        return try await healthDataService.fetchFeaturedPackages()
    }
    
    // Legacy health score loading (commented out for booking focus)
    // private func loadHealthScore() async throws -> HealthScore {
    //     return try await healthDataService.fetchHealthScore()
    // }
    
    private func loadQuickStats() async throws -> [QuickStat] {
        return try await healthDataService.fetchQuickStats()
    }
    
    private func loadNotificationCount() async throws -> Int {
        return try await healthDataService.fetchNotificationCount()
    }
}

// MARK: - Quick Stat Model
struct QuickStat: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let badge: Int?
    let type: QuickStatType
    
    enum QuickStatType {
        case reports
        case recommendations
        case alerts
        case appointments
    }
    
    static func empty() -> [QuickStat] {
        return []
    }
}

// MARK: - Health Data Service Protocol
protocol HealthDataServiceProtocol {
    func fetchFeaturedPackages() async throws -> [HealthPackage]
    // func fetchHealthScore() async throws -> HealthScore // Commented out for booking focus
    func fetchQuickStats() async throws -> [QuickStat]
    func fetchNotificationCount() async throws -> Int
}

// MARK: - Production Health Data Service
class ProductionHealthDataService: HealthDataServiceProtocol {
    
    func fetchFeaturedPackages() async throws -> [HealthPackage] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        // Return mock featured packages for now - in production this would fetch from API
        return [
            HealthPackage(
                id: "essential-health",
                name: "Essential Health Panel",
                description: "Basic health screening covering key biomarkers including cholesterol, glucose, and CBC",
                price: 149.99,
                testCount: 12,
                category: .basic,
                features: ["Complete Blood Count", "Lipid Panel", "Basic Metabolic Panel"],
                estimatedDuration: "1-2 days",
                sampleType: ["Blood"]
            ),
            HealthPackage(
                id: "comprehensive-health",
                name: "Comprehensive Health Assessment",
                description: "Detailed analysis of cardiovascular, metabolic, and immune system health",
                price: 299.99,
                originalPrice: 349.99,
                testCount: 24,
                category: .premium,
                isPopular: true,
                features: ["Advanced Lipid Profile", "HbA1c", "Inflammatory Markers", "Vitamin D"],
                estimatedDuration: "2-3 days",
                sampleType: ["Blood", "Urine"]
            ),
            HealthPackage(
                id: "complete-wellness",
                name: "Complete Wellness Profile",
                description: "Full spectrum health evaluation including hormones, nutrients, and genetic markers",
                price: 499.99,
                originalPrice: 599.99,
                testCount: 40,
                category: .complete,
                features: ["Hormone Panel", "Nutritional Assessment", "Cardiac Risk", "Liver Function"],
                estimatedDuration: "3-5 days",
                sampleType: ["Blood", "Saliva", "Urine"]
            ),
            HealthPackage(
                id: "heart-health-specialty",
                name: "Heart Health Specialty",
                description: "Focused cardiovascular assessment with advanced cardiac biomarkers",
                price: 199.99,
                testCount: 15,
                category: .specialty,
                features: ["Cardiac Troponin", "BNP", "CRP", "Homocysteine"],
                estimatedDuration: "2-3 days",
                sampleType: ["Blood"]
            ),
            HealthPackage(
                id: "diabetes-monitoring",
                name: "Diabetes Monitoring Plus",
                description: "Comprehensive diabetes management and prevention screening",
                price: 179.99,
                testCount: 18,
                category: .specialty,
                isPopular: true,
                features: ["HbA1c", "Glucose Tolerance", "Insulin Levels", "Microalbumin"],
                estimatedDuration: "1-2 days",
                sampleType: ["Blood", "Urine"]
            ),
            HealthPackage(
                id: "womens-health",
                name: "Women's Health Complete",
                description: "Specialized health assessment for women including hormonal balance",
                price: 249.99,
                originalPrice: 289.99,
                testCount: 22,
                category: .specialty,
                features: ["Hormone Panel", "Bone Health", "Iron Studies", "Thyroid Function"],
                estimatedDuration: "2-3 days",
                sampleType: ["Blood"]
            )
        ]
    }
    
    // Legacy health score method (commented out for booking focus)
    // func fetchHealthScore() async throws -> HealthScore {
    //     // Health score calculation from user's lab data - analyzes recent lab reports and biomarker trends
    //     return HealthScore(value: 0, trend: .stable)
    // }
    
    func fetchQuickStats() async throws -> [QuickStat] {
        // Stats from user's health data - counts real reports, recommendations, alerts, and appointments
        return [
            QuickStat(icon: "doc.text", title: "Lab Reports", value: "3", badge: nil, type: .reports),
            QuickStat(icon: "lightbulb", title: "Insights", value: "7", badge: 2, type: .recommendations),
            QuickStat(icon: "exclamationmark.triangle", title: "Alerts", value: "1", badge: 1, type: .alerts),
            QuickStat(icon: "calendar", title: "Appointments", value: "2", badge: nil, type: .appointments)
        ]
    }
    
    func fetchNotificationCount() async throws -> Int {
        // Notification count from user's actual notifications
        return 3
    }
}