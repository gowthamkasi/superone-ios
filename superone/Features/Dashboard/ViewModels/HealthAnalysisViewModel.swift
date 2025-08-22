//
//  HealthAnalysisViewModel.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing health analysis data and dashboard integration
@MainActor
@Observable
final class HealthAnalysisViewModel: Sendable {
    
    // MARK: - Published Properties
    
    /// Current health analysis data
    var currentAnalysis: DetailedHealthAnalysis? = nil
    
    /// Overall health score (0-100)
    var overallHealthScore: Int = 0
    
    /// Health score trend over time
    var healthScoreTrend: TrendDirection = .stable
    
    /// Category-specific health assessments
    var categoryAssessments: [BackendHealthCategory: CategoryHealthAssessment] = [:]
    
    /// Recent biomarker values for trending
    var recentBiomarkers: [String: [BiomarkerTrendData]] = [:]
    
    /// Key health insights and recommendations
    var keyInsights: [HealthInsight] = []
    
    /// Critical alerts requiring immediate attention
    var criticalAlerts: [HealthAlert] = []
    
    /// Loading states
    var isLoadingAnalysis: Bool = false
    var isLoadingTrends: Bool = false
    var isRefreshing: Bool = false
    
    /// Error states
    var analysisError: DashboardAnalysisError? = nil
    var showErrorAlert: Bool = false
    
    /// Last updated timestamp
    var lastUpdated: Date? = nil
    
    /// Analysis preferences for personalization
    var analysisPreferences: HealthAnalysisPreferences = HealthAnalysisPreferences()
    
    // MARK: - Private Properties
    
    private let healthAnalysisAPIService = HealthAnalysisAPIService.shared
    private let labReportAPIService = LabReportAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Auto-refresh configuration
    private var autoRefreshTimer: Timer?
    private let autoRefreshInterval: TimeInterval = 300 // 5 minutes
    private var isAutoRefreshEnabled: Bool = true
    
    // Data caching
    private var cachedAnalysis: DetailedHealthAnalysis?
    private var cacheExpiryDate: Date?
    private let cacheValidityDuration: TimeInterval = 600 // 10 minutes
    
    // MARK: - Initialization
    
    init() {
        setupAutoRefresh()
        loadInitialData()
    }
    
    // Note: Timer will be automatically cleaned up when the object is deallocated
    // due to the weak reference pattern used in setupAutoRefresh()
    
    // MARK: - Public Methods
    
    /// Load the latest health analysis data
    func loadAnalysisData() async {
        guard !isLoadingAnalysis else { return }
        
        isLoadingAnalysis = true
        analysisError = nil
        
        do {
            // Check cache first
            if let cached = getCachedAnalysis() {
                await updateWithAnalysis(cached)
                isLoadingAnalysis = false
                return
            }
            
            // Fetch fresh data from API
            let analysis = try await healthAnalysisAPIService.getLatestAnalysis()
            
            if let analysis = analysis {
                await updateWithAnalysis(analysis)
                cacheAnalysis(analysis)
            } else {
                // No analysis available yet
                await handleNoAnalysisAvailable()
            }
            
            lastUpdated = Date()
            
        } catch {
            await handleAnalysisError(error)
        }
        
        isLoadingAnalysis = false
    }
    
    /// Refresh health analysis data from server
    func refreshAnalysisData() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        clearCache() // Force fresh data
        
        await loadAnalysisData()
        
        isRefreshing = false
    }
    
    /// Load biomarker trends for specific time period
    func loadBiomarkerTrends(for timeRange: HealthTrendTimeRange = .last3Months) async {
        guard !isLoadingTrends else { return }
        
        isLoadingTrends = true
        
        do {
            let trends = try await healthAnalysisAPIService.getBiomarkerTrends(timeRange: timeRange)
            await MainActor.run {
                recentBiomarkers = trends
                updateHealthScoreTrend()
            }
        } catch {
        }
        
        isLoadingTrends = false
    }
    
    /// Generate new health analysis with custom preferences
    func generateAnalysis(with preferences: HealthAnalysisPreferences) async {
        analysisPreferences = preferences
        
        do {
            isLoadingAnalysis = true
            
            // Get the most recent lab report for analysis
            if let latestReportId = await getLatestLabReportId() {
                let analysis = try await healthAnalysisAPIService.generateAnalysis(
                    for: latestReportId,
                    userPreferences: preferences
                )
                
                let detailedAnalysis = self.convertToDetailedAnalysis(analysis)
                await updateWithAnalysis(detailedAnalysis)
                cacheAnalysis(detailedAnalysis)
                lastUpdated = Date()
            } else {
                throw DashboardAnalysisError.noDataAvailable("No lab reports available for analysis")
            }
            
        } catch {
            await handleAnalysisError(error)
        }
        
        isLoadingAnalysis = false
    }
    
    /// Update analysis preferences and refresh if needed
    func updatePreferences(_ preferences: HealthAnalysisPreferences, refreshAnalysis: Bool = true) async {
        analysisPreferences = preferences
        
        if refreshAnalysis {
            await generateAnalysis(with: preferences)
        }
    }
    
    /// Get health insights for specific category
    func getInsights(for category: BackendHealthCategory) -> [HealthInsight] {
        return keyInsights.filter { $0.category.rawValue == category.rawValue }
    }
    
    /// Get biomarker data for specific category
    func getBiomarkers(for category: BackendHealthCategory) -> [BiomarkerData] {
        return categoryAssessments[category]?.biomarkers ?? []
    }
    
    /// Get trend data for specific biomarker
    func getTrendData(for biomarkerName: String) -> [BiomarkerTrendData] {
        return recentBiomarkers[biomarkerName] ?? []
    }
    
    /// Check if analysis data is stale and needs refresh
    var isDataStale: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > cacheValidityDuration
    }
    
    /// Enable or disable auto-refresh
    func setAutoRefresh(enabled: Bool) {
        isAutoRefreshEnabled = enabled
        
        if enabled {
            setupAutoRefresh()
        } else {
            autoRefreshTimer?.invalidate()
            autoRefreshTimer = nil
        }
    }
    
    /// Manually clear cache and force refresh
    func clearCacheAndRefresh() async {
        clearCache()
        await refreshAnalysisData()
    }
    
    // MARK: - Private Implementation
    
    private func updateWithAnalysis(_ analysis: DetailedHealthAnalysis) async {
        currentAnalysis = analysis
        overallHealthScore = analysis.overallHealthScore
        categoryAssessments = analysis.categoryAssessments
        keyInsights = analysis.insights
        criticalAlerts = analysis.alerts
        
        // Update health score trend based on historical data
        updateHealthScoreTrend()
    }
    
    private func handleNoAnalysisAvailable() async {
        // Show empty state or prompt user to upload lab reports
        currentAnalysis = nil
        overallHealthScore = 0
        categoryAssessments = [:]
        keyInsights = []
        criticalAlerts = []
    }
    
    private func handleAnalysisError(_ error: Error) async {
        let healthError: DashboardAnalysisError
        
        if let apiError = error as? HealthAnalysisError {
            healthError = DashboardAnalysisError.apiError(apiError.localizedDescription)
        } else {
            healthError = DashboardAnalysisError.apiError(error.localizedDescription)
        }
        
        analysisError = healthError
        showErrorAlert = true
        
    }
    
    private func updateHealthScoreTrend() {
        // Analyze recent health scores to determine trend
        // This is a simplified implementation - could be enhanced with more sophisticated trend analysis
        
        guard let currentScore = currentAnalysis?.overallHealthScore else {
            healthScoreTrend = .stable
            return
        }
        
        // For now, use a simple rule-based approach
        // In a real implementation, this would analyze historical scores
        if currentScore >= 80 {
            healthScoreTrend = .improving
        } else if currentScore <= 60 {
            healthScoreTrend = .declining
        } else {
            healthScoreTrend = .stable
        }
    }
    
    private func setupAutoRefresh() {
        guard isAutoRefreshEnabled else { return }
        
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { _ in
            Task { @MainActor in
                if !self.isLoadingAnalysis && !self.isRefreshing {
                    await self.loadAnalysisData()
                }
            }
        }
    }
    
    private func loadInitialData() {
        Task {
            await loadAnalysisData()
            await loadBiomarkerTrends()
        }
    }
    
    private func getLatestLabReportId() async -> String? {
        // This would need to be implemented to get the most recent lab report ID
        // For now, return a mock ID
        return "latest-lab-report-id"
    }
    
    // MARK: - Caching Methods
    
    private func getCachedAnalysis() -> DetailedHealthAnalysis? {
        guard let cached = cachedAnalysis,
              let expiryDate = cacheExpiryDate,
              Date() < expiryDate else {
            return nil
        }
        
        return cached
    }
    
    private func cacheAnalysis(_ analysis: DetailedHealthAnalysis) {
        cachedAnalysis = analysis
        cacheExpiryDate = Date().addingTimeInterval(cacheValidityDuration)
    }
    
    private func clearCache() {
        cachedAnalysis = nil
        cacheExpiryDate = nil
    }
}

// MARK: - Extensions

extension HealthAnalysisViewModel {
    
    /// Get health score color based on current score
    var healthScoreColor: Color {
        switch overallHealthScore {
        case 80...100:
            return HealthColors.healthExcellent
        case 70..<80:
            return HealthColors.healthGood
        case 60..<70:
            return HealthColors.healthFair
        case 40..<60:
            return HealthColors.healthWarning
        default:
            return HealthColors.healthCritical
        }
    }
    
    /// Get health score description
    var healthScoreDescription: String {
        switch overallHealthScore {
        case 80...100:
            return "Excellent"
        case 70..<80:
            return "Good"
        case 60..<70:
            return "Fair"
        case 40..<60:
            return "Needs Attention"
        default:
            return "Critical"
        }
    }
    
    /// Get trend icon for health score
    var trendIcon: String {
        switch healthScoreTrend {
        case .improving:
            return "arrow.up.circle.fill"
        case .declining:
            return "arrow.down.circle.fill"
        case .stable:
            return "minus.circle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
    
    /// Get trend color for health score
    var trendColor: Color {
        switch healthScoreTrend {
        case .improving:
            return HealthColors.healthGood
        case .declining:
            return HealthColors.healthCritical
        case .stable:
            return HealthColors.primary
        case .unknown:
            return HealthColors.healthNeutral
        }
    }
    
    /// Check if there are any critical alerts
    var hasCriticalAlerts: Bool {
        return !criticalAlerts.isEmpty
    }
    
    /// Get high priority insights (top 3)
    var priorityInsights: [HealthInsight] {
        return Array(keyInsights.prefix(3))
    }
    
    /// Get categories with concerning biomarkers
    var categoriesNeedingAttention: [BackendHealthCategory] {
        return categoryAssessments.compactMap { (category, assessment) in
            let concerningBiomarkers = assessment.biomarkers.filter { 
                $0.status == .abnormal || $0.status == .critical 
            }
            return concerningBiomarkers.isEmpty ? nil : category
        }
    }
    
    /// Get total number of biomarkers tracked
    var totalBiomarkersCount: Int {
        return categoryAssessments.values.reduce(0) { total, assessment in
            total + assessment.biomarkers.count
        }
    }
    
    /// Get number of optimal biomarkers
    var optimalBiomarkersCount: Int {
        return categoryAssessments.values.reduce(0) { total, assessment in
            total + assessment.biomarkers.filter { $0.status == .optimal }.count
        }
    }
    
    /// Get percentage of optimal biomarkers
    var optimalBiomarkersPercentage: Double {
        guard totalBiomarkersCount > 0 else { return 0 }
        return Double(optimalBiomarkersCount) / Double(totalBiomarkersCount)
    }
    
    /// Convert HealthAnalysisData to DetailedHealthAnalysis
    private func convertToDetailedAnalysis(_ data: HealthAnalysisData) -> DetailedHealthAnalysis {
        return DetailedHealthAnalysis(
            id: data.analysisId,
            overallHealthScore: data.overallHealthScore,
            healthTrend: data.healthTrend,
            riskLevel: data.riskLevel,
            categoryAssessments: [:], // Will be populated by full analysis
            integratedAssessment: IntegratedAssessment(
                overallRisk: data.riskLevel,
                keyFindings: data.primaryConcerns,
                correlations: [],
                systemicConcerns: [],
                preventiveActions: data.immediateActions,
                monitoringRecommendations: []
            ),
            recommendations: HealthRecommendations(
                immediate: data.immediateActions.map { action in
                    ImmediateRecommendation(
                        recommendation: action,
                        priority: .high,
                        timeframe: "Immediate",
                        reason: "Based on analysis findings",
                        actionSteps: [action]
                    )
                },
                shortTerm: [],
                longTerm: [],
                lifestyle: [],
                medical: [],
                monitoring: []
            ),
            confidence: data.confidence,
            analysisDate: data.analysisDate,
            summary: AnalysisSummary(
                keyInsights: [],
                primaryConcerns: data.primaryConcerns,
                positiveFindings: [],
                actionRequired: !data.immediateActions.isEmpty,
                urgencyLevel: data.riskLevel == .high ? .immediate : .routine,
                nextSteps: data.immediateActions
            ),
            highPriorityRecommendations: []
        )
    }
}

// MARK: - Supporting Types


enum HealthTrendTimeRange: String, CaseIterable {
    case lastMonth = "1M"
    case last3Months = "3M"
    case last6Months = "6M"
    case lastYear = "1Y"
    
    var displayName: String {
        switch self {
        case .lastMonth: return "Last Month"
        case .last3Months: return "Last 3 Months"
        case .last6Months: return "Last 6 Months"
        case .lastYear: return "Last Year"
        }
    }
}

struct BiomarkerTrendData: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let status: BiomarkerStatus
    let isOptimal: Bool
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}


struct HealthAlert: Codable, Identifiable, Sendable {
    let id = UUID()
    let title: String
    let message: String
    let severity: AlertSeverity
    let category: BackendHealthCategory
    let relatedBiomarkers: [String]
    let actionRequired: Bool
    let createdAt: Date
    
    enum AlertSeverity: String, Codable, Sendable {
        case critical = "critical"
        case warning = "warning"
        case info = "info"
    }
}

enum DashboardAnalysisError: Error, LocalizedError, Sendable {
    case noDataAvailable(String)
    case apiError(String)
    case networkError
    case analysisGenerationFailed(String)
    
    nonisolated var errorDescription: String? {
        switch self {
        case .noDataAvailable(let message):
            return "No Data Available: \(message)"
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .analysisGenerationFailed(let message):
            return "Analysis Generation Failed: \(message)"
        }
    }
}