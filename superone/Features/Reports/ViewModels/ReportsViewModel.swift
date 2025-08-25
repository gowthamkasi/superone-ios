//
//  ReportsViewModel.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import Foundation
import SwiftUI

/// ViewModel for managing lab reports display and interactions
@MainActor
@Observable
final class ReportsViewModel {
    
    // MARK: - Published Properties
    
    /// All lab reports
    var reports: [LabReportDocument] = []
    
    /// Filtered reports based on search and filters
    var filteredReports: [LabReportDocument] = []
    
    /// Loading states
    var isLoading: Bool = false
    var isLoadingHistory: Bool = false
    
    /// Error handling
    var errorMessage: String?
    var showError: Bool = false
    
    /// Search and filter state
    var searchText: String = "" {
        didSet {
            applyFilters()
        }
    }
    
    var selectedCategory: HealthCategory? = nil {
        didSet {
            applyFilters()
        }
    }
    
    var selectedStatus: ProcessingStatus? = nil {
        didSet {
            applyFilters()
        }
    }
    
    var sortOrder: SortOrder = .dateNewest {
        didSet {
            applySorting()
        }
    }
    
    /// View state
    var selectedReport: LabReportDocument? = nil
    var showReportDetail: Bool = false
    var showFilterSheet: Bool = false
    var showUploadSheet: Bool = false
    var showDeleteAlert: Bool = false
    
    /// Location state
    var locationText: String? = "Getting location..."
    
    // MARK: - Enhanced Properties for Three-Tab System
    
    /// Recent reports for Recent tab
    var recentReports: [LabReportDocument] {
        reports.filter { report in
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return report.uploadDate >= thirtyDaysAgo
        }.sorted { $0.uploadDate > $1.uploadDate }
    }
    
    /// Processing reports
    var processingReports: [LabReportDocument] {
        reports.filter { $0.processingStatus == .processing || $0.processingStatus == .analyzing }
            .sorted { $0.uploadDate > $1.uploadDate }
    }
    
    /// Recent completed reports
    var recentCompletedReports: [LabReportDocument] {
        reports.filter { $0.processingStatus == .completed }
            .sorted { $0.uploadDate > $1.uploadDate }
    }
    
    /// Grouped reports for History tab
    var groupedReports: [DateGroupedReports] = []
    
    /// Health trends data
    var healthTrends: [HealthTrendUI] = []
    
    /// Health categories data
    var healthCategoriesData: [HealthCategoryData] = []
    
    /// AI insights
    var aiInsights: [AIInsight] = []
    
    /// Trending biomarkers
    var trendingBiomarkers: [BiomarkerTrend] = []
    
    /// Health recommendations
    var healthRecommendations: [HealthRecommendationUI] = []
    
    /// Report to be deleted (for confirmation)
    private var reportToDelete: LabReportDocument?
    
    // MARK: - Private Properties
    
    private let networkService = NetworkService.shared
    
    // MARK: - Initialization
    
    init() {
        applyFilters()
    }
    
    // MARK: - Public Methods
    
    /// Load reports from backend/local storage
    func loadReports() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Implement actual data loading from backend API using LabReportAPIService to fetch user's lab reports
            reports = []
            applyFilters()
        } catch {
            errorMessage = "Failed to load reports: \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Refresh reports data
    func refreshReports() async {
        await loadReports()
    }
    
    /// Select a report for detail view
    func selectReport(_ report: LabReportDocument) {
        selectedReport = report
        showReportDetail = true
    }
    
    /// Clear filters
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedStatus = nil
        sortOrder = .dateNewest
        applyFilters()
    }
    
    /// Get reports count by status
    func getReportsCount(for status: ProcessingStatus) -> Int {
        return reports.filter { $0.processingStatus == status }.count
    }
    
    /// Export report as PDF
    func exportReport(_ report: LabReportDocument) {
        // PDF export functionality will be implemented with backend integration
    }
    
    /// Share report
    func shareReport(_ report: LabReportDocument) {
        // Share functionality will be implemented
    }
    
    /// Delete report (show confirmation)
    func deleteReport(_ report: LabReportDocument) {
        reportToDelete = report
        showDeleteAlert = true
    }
    
    /// Confirm deletion
    func confirmDelete() {
        guard let report = reportToDelete else { return }
        reports.removeAll { $0.id == report.id }
        reportToDelete = nil
        applyFilters()
        refreshGroupedReports()
        refreshHealthData()
    }
    
    /// Location methods
    func refreshLocation() {
        // Implement location refresh
        locationText = "Current Location"
    }
    
    /// Health category selection
    func selectHealthCategory(_ category: HealthCategory) {
        selectedCategory = category
        // Navigate to category-specific view
    }
    
    /// Biomarker selection
    func selectBiomarker(_ biomarker: BiomarkerTrend) {
        // Navigate to biomarker detail view
    }
    
    // MARK: - Private Methods
    
    private func applyFilters() {
        var filtered = reports
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { report in
                report.fileName.localizedCaseInsensitiveContains(searchText) ||
                report.documentType?.displayName.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.healthCategory == category }
        }
        
        // Apply status filter
        if let status = selectedStatus {
            filtered = filtered.filter { $0.processingStatus == status }
        }
        
        filteredReports = filtered
        applySorting()
    }
    
    private func applySorting() {
        switch sortOrder {
        case .dateNewest:
            filteredReports.sort { $0.uploadDate > $1.uploadDate }
        case .dateOldest:
            filteredReports.sort { $0.uploadDate < $1.uploadDate }
        case .nameAZ:
            filteredReports.sort { $0.fileName < $1.fileName }
        case .nameZA:
            filteredReports.sort { $0.fileName > $1.fileName }
        case .status:
            filteredReports.sort { $0.processingStatus.rawValue < $1.processingStatus.rawValue }
        }
    }
    
    /// Refresh grouped reports for History tab
    private func refreshGroupedReports() {
        let calendar = Calendar.current
        let now = Date()
        
        // Group reports by date periods
        let thisWeek = reports.filter { 
            calendar.isDate($0.uploadDate, equalTo: now, toGranularity: .weekOfYear)
        }
        
        let lastWeek = reports.filter {
            let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            return calendar.isDate($0.uploadDate, equalTo: weekAgo, toGranularity: .weekOfYear)
        }
        
        let thisMonth = reports.filter {
            calendar.isDate($0.uploadDate, equalTo: now, toGranularity: .month) &&
            !calendar.isDate($0.uploadDate, equalTo: now, toGranularity: .weekOfYear)
        }
        
        let lastMonth = reports.filter {
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return calendar.isDate($0.uploadDate, equalTo: monthAgo, toGranularity: .month)
        }
        
        let older = reports.filter {
            let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now) ?? now
            return $0.uploadDate < twoMonthsAgo
        }
        
        var groups: [DateGroupedReports] = []
        
        if !thisWeek.isEmpty {
            groups.append(DateGroupedReports(
                id: "thisWeek",
                title: "This Week",
                reports: thisWeek.sorted { $0.uploadDate > $1.uploadDate }
            ))
        }
        
        if !lastWeek.isEmpty {
            groups.append(DateGroupedReports(
                id: "lastWeek", 
                title: "Last Week",
                reports: lastWeek.sorted { $0.uploadDate > $1.uploadDate }
            ))
        }
        
        if !thisMonth.isEmpty {
            groups.append(DateGroupedReports(
                id: "thisMonth",
                title: "This Month",
                reports: thisMonth.sorted { $0.uploadDate > $1.uploadDate }
            ))
        }
        
        if !lastMonth.isEmpty {
            groups.append(DateGroupedReports(
                id: "lastMonth",
                title: "Last Month", 
                reports: lastMonth.sorted { $0.uploadDate > $1.uploadDate }
            ))
        }
        
        if !older.isEmpty {
            groups.append(DateGroupedReports(
                id: "older",
                title: "Older",
                reports: older.sorted { $0.uploadDate > $1.uploadDate }
            ))
        }
        
        groupedReports = groups
    }
    
    /// Refresh health data for Categories tab
    private func refreshHealthData() {
        refreshHealthTrends()
        refreshHealthCategories()
        refreshAIInsights()
        refreshBiomarkerTrends()
        refreshHealthRecommendations()
    }
    
    private func refreshHealthTrends() {
        // Mock health trends data - replace with actual data loading
        healthTrends = [
            HealthTrendUI(
                id: "cholesterol",
                title: "Cholesterol: Improving",
                subtitle: "Down 25 mg/dL since February",
                trendIcon: "arrow.down.right",
                trendColor: HealthColors.healthGood,
                improvement: "-12%"
            ),
            HealthTrendUI(
                id: "glucose",
                title: "Blood Sugar: Stable", 
                subtitle: "Consistent good control",
                trendIcon: "arrow.right",
                trendColor: HealthColors.primary,
                improvement: nil
            ),
            HealthTrendUI(
                id: "vitaminD",
                title: "Vitamin D: Needs Attention",
                subtitle: "Below optimal range",
                trendIcon: "arrow.up.right",
                trendColor: HealthColors.healthWarning,
                improvement: "Low"
            )
        ]
    }
    
    private func refreshHealthCategories() {
        // Mock health categories data - replace with actual data loading
        healthCategoriesData = [
            HealthCategoryData(
                id: "cardiovascular",
                category: .cardiovascular,
                reportCount: 5,
                latestTrend: HealthTrendUI(
                    id: "cardio",
                    title: "Improving",
                    subtitle: "",
                    trendIcon: "arrow.down.right",
                    trendColor: HealthColors.healthGood,
                    improvement: nil
                )
            ),
            HealthCategoryData(
                id: "metabolic",
                category: .metabolic,
                reportCount: 3,
                latestTrend: HealthTrendUI(
                    id: "metabolic",
                    title: "Stable",
                    subtitle: "",
                    trendIcon: "arrow.right",
                    trendColor: HealthColors.primary,
                    improvement: nil
                )
            )
        ]
    }
    
    private func refreshAIInsights() {
        // Mock AI insights - replace with actual data loading
        aiInsights = [
            AIInsight(
                id: "cholesterol-high",
                title: "Cholesterol levels show improvement",
                summary: "Your LDL cholesterol has decreased by 15% since last test",
                icon: "heart.fill",
                priority: .medium,
                date: Date().addingTimeInterval(-86400)
            ),
            AIInsight(
                id: "vitamin-d-low",
                title: "Vitamin D levels need attention",
                summary: "Consider increasing sun exposure and dietary sources",
                icon: "sun.max.fill",
                priority: .high,
                date: Date().addingTimeInterval(-172800)
            )
        ]
    }
    
    private func refreshBiomarkerTrends() {
        // Mock biomarker trends - replace with actual data loading
        trendingBiomarkers = [
            BiomarkerTrend(
                id: "cholesterol",
                name: "Total Cholesterol",
                currentValue: "185 mg/dL",
                status: .good,
                trendIcon: "arrow.down.right",
                trendColor: HealthColors.healthGood,
                changeText: "15% improvement"
            ),
            BiomarkerTrend(
                id: "glucose",
                name: "Fasting Glucose",
                currentValue: "95 mg/dL",
                status: .normal,
                trendIcon: "arrow.right",
                trendColor: HealthColors.primary,
                changeText: "Stable range"
            )
        ]
    }
    
    private func refreshHealthRecommendations() {
        // Mock health recommendations - replace with actual data loading
        healthRecommendations = [
            HealthRecommendationUI(
                id: "exercise",
                title: "Increase cardiovascular exercise",
                description: "Based on your cholesterol levels, aim for 150 minutes of moderate exercise weekly",
                icon: "figure.run",
                priority: .medium
            ),
            HealthRecommendationUI(
                id: "vitamin-d",
                title: "Consider Vitamin D supplementation",
                description: "Your levels are below optimal range. Consult with your doctor about supplements",
                icon: "pills.fill",
                priority: .high
            )
        ]
    }
    
    /// Navigate to book test functionality
    func navigateToBookTest(appState: AppState) {
        // Navigate to Appointments tab (index 1) and ensure Tests sub-tab is selected
        appState.selectedTab = 1
        
        // Post a notification that will be picked up by AppointmentsView to select Tests tab
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToTestsTab"),
            object: nil
        )
    }
    
}

// MARK: - Supporting Types

enum SortOrder: String, CaseIterable {
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    case nameAZ = "Name (A-Z)"
    case nameZA = "Name (Z-A)"
    case status = "Status"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .dateNewest: return "arrow.down"
        case .dateOldest: return "arrow.up"
        case .nameAZ: return "textformat.abc"
        case .nameZA: return "textformat.abc"
        case .status: return "checkmark.circle"
        }
    }
}

// MARK: - Supporting Data Models

struct DateGroupedReports: Identifiable {
    let id: String
    let title: String
    let reports: [LabReportDocument]
}

// Use HealthTrend from BackendModels.swift
// HealthTrend is already defined in BackendModels.swift

// UI-specific HealthTrend data structure for Reports tab
struct HealthTrendUI: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let trendIcon: String
    let trendColor: Color
    let improvement: String?
}

struct HealthCategoryData: Identifiable {
    let id: String
    let category: HealthCategory
    let reportCount: Int
    let latestTrend: HealthTrendUI?
}

struct AIInsight: Identifiable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let priority: Priority
    let date: Date
    
    enum Priority {
        case low, medium, high
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return HealthColors.primary
            case .medium: return HealthColors.healthWarning
            case .high: return HealthColors.healthCritical
            }
        }
    }
}

struct BiomarkerTrend: Identifiable {
    let id: String
    let name: String
    let currentValue: String
    let status: HealthStatus
    let trendIcon: String
    let trendColor: Color
    let changeText: String
}

// Use HealthRecommendation from BackendModels.swift
// HealthRecommendation is already defined in BackendModels.swift

// UI-specific HealthRecommendation data structure for Reports tab
struct HealthRecommendationUI: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let priority: Priority
    
    enum Priority {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return HealthColors.primary
            case .medium: return HealthColors.healthWarning
            case .high: return HealthColors.healthCritical
            }
        }
    }
}

// MARK: - Extensions
// ProcessingStatus extensions are already defined in BackendModels.swift

extension LabReportDocument {
    var processingProgress: Double {
        switch processingStatus {
        case .pending: return 0.0
        case .uploading: return 0.1
        case .preprocessing: return 0.2
        case .processing: return 0.3
        case .analyzing: return 0.7
        case .extracting: return 0.5
        case .validating: return 0.8
        case .retrying: return 0.1
        case .paused: return 0.0
        case .completed: return 1.0
        case .failed: return 0.0
        case .cancelled: return 0.0
        }
    }
    
    var currentProcessingStep: String {
        switch processingStatus {
        case .pending: return "Queued for processing"
        case .uploading: return "Uploading document"
        case .preprocessing: return "Preparing document"
        case .processing: return "Extracting text from document"
        case .analyzing: return "Analyzing biomarkers with AI"
        case .extracting: return "Extracting biomarker data"
        case .validating: return "Validating extracted data"
        case .retrying: return "Retrying processing"
        case .paused: return "Processing paused"
        case .completed: return "Analysis complete"
        case .failed: return "Processing failed"
        case .cancelled: return "Processing cancelled"
        }
    }
}

// MARK: - Health Category Extensions
// HealthCategory extensions are already defined in BackendModels.swift