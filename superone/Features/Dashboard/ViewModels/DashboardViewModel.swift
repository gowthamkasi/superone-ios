//
//  DashboardViewModel.swift
//  SuperOne
//
//  Created by Claude Code on 2024-12-20.
//  Booking-focused dashboard view model
//

import Foundation
import SwiftUI

/// View model for the main dashboard focused on health package booking and appointments
@MainActor
@Observable
final class DashboardViewModel {
    
    // MARK: - Public Properties
    
    // Booking-focused dashboard properties
    var featuredPackages: [HealthPackage] = []
    var isLoadingPackages: Bool = false
    
    // Legacy health score properties (commented out for booking focus)
    // var healthScore: HealthScore
    var quickStats: [QuickStat]
    var isLoading: Bool = false
    var errorMessage: String?
    
    var userName: String = "Sarah"
    var notificationCount: Int = 0
    var labReportProcessingStatus: [LabReportProcessingActivity] = []
    
    // Notification sheet presentation state
    var showingNotificationSheet: Bool = false
    
    // MARK: - Private Properties
    
    private let healthDataService: HealthDataServiceProtocol
    
    init(healthDataService: HealthDataServiceProtocol? = nil) {
        self.healthDataService = healthDataService ?? ProductionHealthDataService()
        // self.healthScore = HealthScore(value: 0, trend: .stable) // Commented out for booking focus
        self.quickStats = []
        
        setupAppLifecycleObserver()
        loadDashboardData()
    }
    
    // MARK: - Public Methods
    
    /// Load all dashboard data
    func loadDashboardData() {
        Task {
            await loadAllData()
        }
    }
    
    /// Load all dashboard data asynchronously
    private func loadAllData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let packageResults = loadFeaturedPackages()
            async let statsResults = loadQuickStats()
            // async let healthScoreResults = loadHealthScore() // Commented out for booking focus
            
            featuredPackages = try await packageResults
            quickStats = try await statsResults
            // healthScore = try await healthScoreResults // Commented out for booking focus
            
            // Load notification count
            notificationCount = try await healthDataService.fetchNotificationCount()
            
        } catch {
            print("Error loading dashboard data: \(error)")
            errorMessage = "Unable to load dashboard data. Please try again."
            
            // Set default values on error
            featuredPackages = []
            quickStats = QuickStat.empty()
            // healthScore = HealthScore(value: 0, trend: .stable) // Commented out for booking focus
        }
        
        isLoading = false
    }
    
    /// Refresh featured packages
    func refreshFeaturedPackages() {
        Task {
            isLoadingPackages = true
            do {
                featuredPackages = try await loadFeaturedPackages()
            } catch {
                print("Error refreshing packages: \(error)")
                errorMessage = "Unable to refresh packages. Please try again."
            }
            isLoadingPackages = false
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Refresh dashboard data manually
    func refresh() {
        loadDashboardData()
    }
    
    /// Handle quick action buttons
    func handleQuickAction(_ action: DashboardAction) {
        HapticFeedback.light()
        
        switch action {
        case .bookTest:
            // Navigate to test booking flow
            print("Navigating to test booking flow")
        case .findLabs:
            // Navigate to lab finder
            print("Navigating to lab finder")
        case .viewReports:
            // Navigate to reports view
            print("Navigating to reports view")
        }
    }
    
    /// Navigate to all packages view
    func navigateToAllPackages() {
        HapticFeedback.light()
        print("Navigating to all packages view")
        // TODO: Implement navigation to all packages view
    }
    
    /// Update scroll position for performance optimizations
    func updateScrollPosition(_ position: CGFloat) {
        // Batch scroll position updates to avoid excessive redraws
        // This helps with performance on complex dashboard views
        
        // Optional: Trigger specific animations or loading based on scroll position
        if position > 200 && !isLoadingPackages {
            // User scrolled down significantly - could prefetch more data
        }
    }
    
    /// Handle background app refresh
    func handleBackgroundRefresh() {
        // Only refresh if not currently loading
        guard !isLoading else { return }
        
        Task {
            // Update notification count
            do {
                notificationCount = try await healthDataService.fetchNotificationCount()
            } catch {
                print("Error updating notification count: \(error)")
            }
        }
    }
    
    /// Update lab report processing status (called from upload service)
    func updateLabReportProcessingStatus(_ activity: LabReportProcessingActivity) {
        if let index = labReportProcessingStatus.firstIndex(where: { $0.documentId == activity.documentId }) {
            labReportProcessingStatus[index] = activity
        } else {
            labReportProcessingStatus.insert(activity, at: 0)
        }
    }
    
    /// Present notification sheet
    func presentNotificationSheet() {
        HapticFeedback.light()
        showingNotificationSheet = true
    }
    
    /// Dismiss notification sheet
    func dismissNotificationSheet() {
        showingNotificationSheet = false
    }
    
    /// Handle notification count update (called when notifications are read)
    func refreshNotificationCount() {
        Task {
            do {
                notificationCount = try await healthDataService.fetchNotificationCount()
            } catch {
                print("Error refreshing notification count: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAppLifecycleObserver() {
        // Monitor app lifecycle for background refresh
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.handleBackgroundRefresh()
            }
        }
    }
    
    /// Load featured health packages for the dashboard
    private func loadFeaturedPackages() async throws -> [HealthPackage] {
        return try await healthDataService.fetchFeaturedPackages()
    }
    
    // private func loadHealthScore() async throws -> HealthScore {
    //     return try await healthDataService.fetchHealthScore()
    // }
    
    private func loadQuickStats() async throws -> [QuickStat] {
        return try await healthDataService.fetchQuickStats()
    }
}

// MARK: - Dashboard Action Enum

enum DashboardAction {
    case bookTest
    case findLabs
    case viewReports
}

// MARK: - QuickStat Model

struct QuickStat: Identifiable, Sendable {
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
    
    // Notification management methods
    func fetchNotifications() async throws -> [HealthNotification]
    func markNotificationAsRead(_ notificationId: UUID) async throws -> HealthNotification
    func markAllNotificationsAsRead() async throws -> [HealthNotification]
    func deleteNotification(_ notificationId: UUID) async throws
    func clearAllNotifications() async throws
}

// MARK: - Production Implementation
class ProductionHealthDataService: HealthDataServiceProtocol {
    
    func fetchFeaturedPackages() async throws -> [HealthPackage] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        // Return sample featured packages using the factory method
        return [
            HealthPackage.sampleComprehensive()
        ]
    }
    
    // func fetchHealthScore() async throws -> HealthScore {
    //     return HealthScore(value: 85, trend: .improving)
    // }
    
    func fetchQuickStats() async throws -> [QuickStat] {
        // Stats from user's health data - counts real reports, recommendations, alerts, and appointments
        return [
            QuickStat(icon: "doc.text", title: "Reports", value: "4", badge: nil, type: .reports),
            QuickStat(icon: "lightbulb", title: "Recommendations", value: "7", badge: 2, type: .recommendations),
            QuickStat(icon: "exclamationmark.triangle", title: "Alerts", value: "1", badge: 1, type: .alerts),
            QuickStat(icon: "calendar", title: "Appointments", value: "2", badge: nil, type: .appointments)
        ]
    }
    
    func fetchNotificationCount() async throws -> Int {
        let notifications = try await fetchNotifications()
        return NotificationFactory.unreadCount(from: notifications)
    }
    
    // MARK: - Notification Management
    
    private var cachedNotifications: [HealthNotification] = []
    
    func fetchNotifications() async throws -> [HealthNotification] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Use cached notifications if available, otherwise generate sample data
        if cachedNotifications.isEmpty {
            cachedNotifications = NotificationFactory.sampleNotifications()
        }
        
        return cachedNotifications
    }
    
    func markNotificationAsRead(_ notificationId: UUID) async throws -> HealthNotification {
        // Simulate API call
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        guard let index = cachedNotifications.firstIndex(where: { $0.id == notificationId }) else {
            throw NotificationError.notificationNotFound
        }
        
        let updatedNotification = cachedNotifications[index].markAsRead()
        cachedNotifications[index] = updatedNotification
        
        return updatedNotification
    }
    
    func markAllNotificationsAsRead() async throws -> [HealthNotification] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        cachedNotifications = cachedNotifications.map { $0.markAsRead() }
        return cachedNotifications
    }
    
    func deleteNotification(_ notificationId: UUID) async throws {
        // Simulate API call
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        guard let index = cachedNotifications.firstIndex(where: { $0.id == notificationId }) else {
            throw NotificationError.notificationNotFound
        }
        
        cachedNotifications.remove(at: index)
    }
    
    func clearAllNotifications() async throws {
        // Simulate API call
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        cachedNotifications.removeAll()
    }
}

// MARK: - Lab Report Processing Activity Model

struct LabReportProcessingActivity: Identifiable, Sendable {
    let id = UUID()
    let documentId: String
    let fileName: String
    let status: ProcessingStatus
    let timestamp: Date
    let progress: Double // 0.0 to 1.0
    
    // Additional computed properties for UI display
    var activityType: LabActivityType {
        switch status {
        case .uploading, .processing, .analyzing:
            return .labProcessing
        case .completed:
            return .labCompleted
        case .failed:
            return .labFailed
        }
    }
    
    var activityTitle: String {
        switch status {
        case .uploading:
            return "Uploading \(fileName)"
        case .processing:
            return "Processing \(fileName)"
        case .analyzing:
            return "Analyzing \(fileName)"
        case .completed:
            return "Analysis Complete"
        case .failed:
            return "Processing Failed"
        }
    }
    
    var activitySubtitle: String {
        switch status {
        case .uploading:
            return "Uploading to secure server..."
        case .processing:
            return "Extracting test data..."
        case .analyzing:
            return "Generating AI insights..."
        case .completed:
            return "Results ready to view"
        case .failed:
            return "Please try uploading again"
        }
    }
    
    var activityIcon: String {
        switch status {
        case .uploading:
            return "arrow.up.circle"
        case .processing:
            return "doc.text.magnifyingglass"
        case .analyzing:
            return "brain.head.profile"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var confidence: Double? {
        // Return confidence score for completed analyses
        guard status == .completed else { return nil }
        return progress // Use progress as confidence for completed items
    }
    
    enum ProcessingStatus: String, CaseIterable, Sendable {
        case uploading = "uploading"
        case processing = "processing" 
        case analyzing = "analyzing"
        case completed = "completed"
        case failed = "failed"
        
        var displayName: String {
            switch self {
            case .uploading: return "Uploading"
            case .processing: return "Processing"
            case .analyzing: return "Analyzing"
            case .completed: return "Completed"
            case .failed: return "Failed"
            }
        }
        
        var color: Color {
            switch self {
            case .uploading, .processing, .analyzing: return .blue
            case .completed: return .green
            case .failed: return .red
            }
        }
        
        var isActive: Bool {
            switch self {
            case .uploading, .processing, .analyzing: return true
            case .completed, .failed: return false
            }
        }
    }
}

// MARK: - Notification Error

/// Errors that can occur during notification operations
/// Sendable-compliant error type for Swift 6.0+ concurrency safety
enum NotificationError: Error, @preconcurrency LocalizedError, Sendable {
    case notificationNotFound
    case networkError
    case invalidOperation
    
    /// Error description implementation
    var errorDescription: String? {
        switch self {
        case .notificationNotFound:
            return "Notification not found"
        case .networkError:
            return "Network error occurred"
        case .invalidOperation:
            return "Invalid operation"
        }
    }
    
    /// Additional LocalizedError properties for better error handling
    var failureReason: String? {
        switch self {
        case .notificationNotFound:
            return "The requested notification could not be located in the system."
        case .networkError:
            return "A network connectivity issue prevented the operation from completing."
        case .invalidOperation:
            return "The requested operation is not valid in the current context."
        }
    }
    
    /// Recovery suggestions for users
    var recoverySuggestion: String? {
        switch self {
        case .notificationNotFound:
            return "Please refresh the notification list and try again."
        case .networkError:
            return "Check your internet connection and retry the operation."
        case .invalidOperation:
            return "Please verify the operation parameters and try again."
        }
    }
}