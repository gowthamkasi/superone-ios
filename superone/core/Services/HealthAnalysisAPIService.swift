//
//  HealthAnalysisAPIService.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import Foundation
import Combine

// MARK: - Health Analysis API Service

/// Service for AI-powered health analysis integration with Super One backend
@MainActor
final class HealthAnalysisAPIService: ObservableObject, Sendable {
    
    // MARK: - Singleton
    static let shared = HealthAnalysisAPIService()
    
    // MARK: - Published Properties
    @Published private(set) var isAnalyzing = false
    @Published private(set) var analysisProgress: Double = 0.0
    @Published private(set) var currentOperation: String = ""
    @Published private(set) var analysisError: HealthAnalysisError?
    @Published private(set) var latestAnalysis: DetailedHealthAnalysis?
    
    // MARK: - Private Properties
    private let networkService: NetworkService
    private let tokenManager: TokenManager
    private var analysisTasks: [String: Task<Void, Error>] = [:]
    private let analysisQueue = DispatchQueue(label: "com.superone.analysis", qos: .userInitiated)
    
    // MARK: - Configuration
    private let baseAnalysisPath = "/api/v1/health-analysis"
    private let pollingInterval: TimeInterval = 2.0
    private let maxPollingDuration: TimeInterval = 300.0 // 5 minutes
    
    // MARK: - Initialization
    
    private init() {
        self.networkService = NetworkService.shared
        self.tokenManager = TokenManager.shared
    }
    
    // MARK: - Analysis Generation
    
    /// Generate comprehensive health analysis from uploaded lab report
    /// - Parameters:
    ///   - labReportId: ID of the uploaded lab report
    ///   - userPreferences: Optional user preferences for personalized analysis
    /// - Returns: Analysis data with initial results
    func generateAnalysis(
        for labReportId: String,
        userPreferences: HealthAnalysisPreferences? = nil
    ) async throws -> HealthAnalysisData {
        
        updateProgress(0.1, operation: "Starting health analysis")
        
        let request = HealthAnalysisRequest(
            labReportId: labReportId,
            userPreferences: userPreferences
        )
        
        updateProgress(0.2, operation: "Sending analysis request")
        
        let endpoint = "\(baseAnalysisPath)/generate"
        let apiRequest = try await createAuthenticatedRequest(
            path: endpoint,
            method: .POST
        )
        
        var urlRequest = apiRequest
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        updateProgress(0.4, operation: "Processing with AI")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthAnalysisError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            throw HealthAnalysisError.serverError(httpResponse.statusCode)
        }
        
        let analysisResponse = try JSONDecoder().decode(HealthAnalysisResponse.self, from: data)
        
        updateProgress(1.0, operation: "Analysis completed")
        resetProgress()
        
        return analysisResponse.data
    }
    
    /// Get detailed analysis by ID
    /// - Parameters:
    ///   - analysisId: ID of the health analysis
    ///   - includeRawResponse: Whether to include raw AI response data
    /// - Returns: Detailed health analysis with all assessments
    func getAnalysis(
        _ analysisId: String,
        includeRawResponse: Bool = false
    ) async throws -> DetailedHealthAnalysis {
        
        let endpoint = "\(baseAnalysisPath)/\(analysisId)"
        var queryItems: [URLQueryItem] = []
        
        if includeRawResponse {
            queryItems.append(URLQueryItem(name: "includeRawResponse", value: "true"))
        }
        
        var urlComponents = URLComponents(string: AppConfiguration.baseURL + endpoint)
        if !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }
        
        guard let url = urlComponents?.url else {
            throw HealthAnalysisError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        guard let token = await tokenManager.getValidToken() else {
            throw HealthAnalysisError.authenticationRequired
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthAnalysisError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HealthAnalysisError.serverError(httpResponse.statusCode)
        }
        
        let analysisResponse = try JSONDecoder().decode(HealthAnalysisResponse.self, from: data)
        
        // Store latest analysis for dashboard integration
        let detailedAnalysis = DetailedHealthAnalysis(
            id: analysisResponse.data.analysisId,
            overallHealthScore: analysisResponse.data.overallHealthScore,
            healthTrend: analysisResponse.data.healthTrend,
            riskLevel: analysisResponse.data.riskLevel,
            categoryAssessments: [:], // Populated by full analysis endpoint
            integratedAssessment: IntegratedAssessment(
                overallRisk: analysisResponse.data.riskLevel,
                keyFindings: analysisResponse.data.primaryConcerns,
                correlations: [],
                systemicConcerns: [],
                preventiveActions: [],
                monitoringRecommendations: []
            ),
            recommendations: HealthRecommendations(
                immediate: analysisResponse.data.immediateActions.map { action in
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
            confidence: analysisResponse.data.confidence,
            analysisDate: analysisResponse.data.analysisDate,
            summary: AnalysisSummary(
                keyInsights: [],
                primaryConcerns: analysisResponse.data.primaryConcerns,
                positiveFindings: [],
                actionRequired: !analysisResponse.data.immediateActions.isEmpty,
                urgencyLevel: analysisResponse.data.riskLevel == .high ? .immediate : .routine,
                nextSteps: analysisResponse.data.immediateActions
            ),
            highPriorityRecommendations: []
        )
        
        self.latestAnalysis = detailedAnalysis
        return detailedAnalysis
    }
    
    /// Get latest health analysis for user
    /// - Returns: Most recent health analysis
    func getLatestAnalysis() async throws -> DetailedHealthAnalysis? {
        let endpoint = "\(baseAnalysisPath)/latest"
        
        let request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .GET
        )
        
        var urlRequest = request
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthAnalysisError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            // No analysis found - not an error
            return nil
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HealthAnalysisError.serverError(httpResponse.statusCode)
        }
        
        let analysisResponse = try JSONDecoder().decode(HealthAnalysisResponse.self, from: data)
        return try await getAnalysis(analysisResponse.data.analysisId)
    }
    
    /// Get analysis history with pagination
    /// - Parameters:
    ///   - page: Page number (default: 1)
    ///   - limit: Items per page (default: 10)
    /// - Returns: Paginated analysis history
    func getAnalysisHistory(
        page: Int = 1,
        limit: Int = 10
    ) async throws -> AnalysisHistoryResponse {
        
        let endpoint = "\(baseAnalysisPath)/history?page=\(page)&limit=\(limit)"
        
        let request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .GET
        )
        
        var urlRequest = request
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthAnalysisError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HealthAnalysisError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(AnalysisHistoryResponse.self, from: data)
    }
    
    /// Get analysis statistics
    /// - Parameter timeRange: Time range in days (default: 365)
    /// - Returns: Analysis statistics and trends
    func getAnalysisStatistics(timeRange: Int = 365) async throws -> AnalysisStatistics {
        let endpoint = "\(baseAnalysisPath)/stats?timeRange=\(timeRange)"
        
        let request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .GET
        )
        
        var urlRequest = request
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthAnalysisError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HealthAnalysisError.serverError(httpResponse.statusCode)
        }
        
        let statsResponse = try JSONDecoder().decode(AnalysisStatisticsResponse.self, from: data)
        return statsResponse.data
    }
    
    /// Personalize recommendations for existing analysis
    /// - Parameters:
    ///   - analysisId: ID of the analysis to personalize
    ///   - userPreferences: User preferences for personalization
    /// - Returns: Personalized recommendations
    func personalizeRecommendations(
        for analysisId: String,
        userPreferences: HealthAnalysisPreferences
    ) async throws -> PersonalizedRecommendations {
        
        updateProgress(0.1, operation: "Personalizing recommendations")
        
        let request = PersonalizeRecommendationsRequest(userPreferences: userPreferences)
        let endpoint = "\(baseAnalysisPath)/\(analysisId)/personalize"
        
        var urlRequest = try await createAuthenticatedRequest(
            path: endpoint,
            method: .POST
        )
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        updateProgress(0.5, operation: "Generating personalized recommendations")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthAnalysisError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HealthAnalysisError.serverError(httpResponse.statusCode)
        }
        
        updateProgress(1.0, operation: "Personalization completed")
        resetProgress()
        
        let personalizedResponse = try JSONDecoder().decode(PersonalizedRecommendationsResponse.self, from: data)
        return personalizedResponse.data.personalizedRecommendations
    }
    
    /// Compare multiple analyses to identify trends
    /// - Parameter analysisIds: Array of analysis IDs to compare
    /// - Returns: Analysis comparison with trends and insights
    func compareAnalyses(_ analysisIds: [String]) async throws -> AnalysisComparison {
        let analysisIdsString = analysisIds.joined(separator: ",")
        let endpoint = "\(baseAnalysisPath)/compare?analysisIds=\(analysisIdsString)"
        
        let request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .GET
        )
        
        var urlRequest = request
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthAnalysisError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HealthAnalysisError.serverError(httpResponse.statusCode)
        }
        
        let comparisonResponse = try JSONDecoder().decode(AnalysisComparisonResponse.self, from: data)
        return comparisonResponse.data
    }
    
    /// Delete health analysis
    /// - Parameter analysisId: ID of the analysis to delete
    func deleteAnalysis(_ analysisId: String) async throws {
        let endpoint = "\(baseAnalysisPath)/\(analysisId)"
        
        let request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .DELETE
        )
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthAnalysisError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HealthAnalysisError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Real-time Analysis Monitoring
    
    /// Monitor analysis progress with real-time updates
    /// - Parameter analysisId: ID of the analysis to monitor
    /// - Returns: AsyncSequence of progress updates
    func monitorAnalysisProgress(_ analysisId: String) -> AsyncThrowingStream<AnalysisProgressUpdate, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let startTime = Date()
                var lastStatus: String = ""
                
                while !Task.isCancelled {
                    do {
                        // Get current analysis status
                        let analysis = try await getAnalysis(analysisId)
                        
                        let progressUpdate = AnalysisProgressUpdate(
                            analysisId: analysisId,
                            status: "completed", // Analysis is complete if we can fetch it
                            progress: 1.0,
                            currentStage: "Analysis Complete",
                            estimatedTimeRemaining: 0,
                            confidence: analysis.confidence,
                            timestamp: Date()
                        )
                        
                        continuation.yield(progressUpdate)
                        continuation.finish()
                        break
                        
                    } catch {
                        // If analysis not found yet, continue polling
                        if Date().timeIntervalSince(startTime) > maxPollingDuration {
                            continuation.finish(throwing: HealthAnalysisError.analysisTimeout)
                            break
                        }
                        
                        // Send progress update
                        let elapsed = Date().timeIntervalSince(startTime)
                        let progress = min(elapsed / maxPollingDuration, 0.9)
                        
                        let progressUpdate = AnalysisProgressUpdate(
                            analysisId: analysisId,
                            status: "processing",
                            progress: progress,
                            currentStage: "AI Analysis in Progress",
                            estimatedTimeRemaining: max(0, maxPollingDuration - elapsed),
                            confidence: nil,
                            timestamp: Date()
                        )
                        
                        continuation.yield(progressUpdate)
                        
                        try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
                    }
                }
            }
            
            // Store task for cancellation
            analysisTasks[analysisId] = task
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    /// Cancel analysis monitoring
    /// - Parameter analysisId: ID of the analysis to stop monitoring
    func cancelAnalysisMonitoring(_ analysisId: String) {
        analysisTasks[analysisId]?.cancel()
        analysisTasks.removeValue(forKey: analysisId)
    }
    
    /// Get biomarker trends for specific time range
    /// - Parameter timeRange: Time range for trend analysis
    /// - Returns: Dictionary of biomarker trends organized by biomarker name
    func getBiomarkerTrends(timeRange: HealthTrendTimeRange) async throws -> [String: [BiomarkerTrendData]] {
        let endpoint = "\(baseAnalysisPath)/trends?timeRange=\(timeRange.rawValue)"
        
        let request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .GET
        )
        
        var urlRequest = request
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HealthAnalysisError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HealthAnalysisError.serverError(httpResponse.statusCode)
        }
        
        let trendsResponse = try JSONDecoder().decode(BiomarkerTrendsResponse.self, from: data)
        return trendsResponse.data
    }
    
    // MARK: - Private Helper Methods
    
    private func createAuthenticatedRequest(path: String, method: HTTPMethod) async throws -> URLRequest {
        guard let token = await tokenManager.getValidToken() else {
            throw HealthAnalysisError.authenticationRequired
        }
        
        guard let url = URL(string: AppConfiguration.baseURL + path) else {
            throw HealthAnalysisError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    private func updateProgress(_ progress: Double, operation: String) {
        Task { @MainActor in
            self.analysisProgress = progress
            self.currentOperation = operation
            self.isAnalyzing = progress > 0 && progress < 1.0
        }
    }
    
    private func resetProgress() {
        Task { @MainActor in
            self.analysisProgress = 0.0
            self.currentOperation = ""
            self.isAnalyzing = false
            self.analysisError = nil
        }
    }
}

// MARK: - Supporting Types

/// Real-time analysis progress update
struct AnalysisProgressUpdate: Sendable {
    let analysisId: String
    let status: String
    let progress: Double
    let currentStage: String
    let estimatedTimeRemaining: TimeInterval
    let confidence: Double?
    let timestamp: Date
}

/// Personalized recommendations response wrapper
struct PersonalizedRecommendationsResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let data: PersonalizedRecommendationsData
    let timestamp: String
}

struct PersonalizedRecommendationsData: Codable, Sendable {
    let analysisId: String
    let personalizedRecommendations: PersonalizedRecommendations
    let userPreferences: HealthAnalysisPreferences
}

/// Analysis comparison response wrapper
struct AnalysisComparisonResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let data: AnalysisComparison
    let timestamp: String
}

/// Biomarker trends response wrapper
struct BiomarkerTrendsResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let data: [String: [BiomarkerTrendData]]
    let timestamp: String
}

/// Health analysis request wrapper
struct HealthAnalysisRequest: Codable, Sendable {
    let labReportId: String
    let userPreferences: HealthAnalysisPreferences?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case labReportId = "lab_report_id"
        case userPreferences = "user_preferences"
    }
}

/// Health analysis data response
struct HealthAnalysisData: Codable, Sendable {
    let analysisId: String
    let overallHealthScore: Int
    let healthTrend: TrendDirection
    let riskLevel: RiskLevel
    let primaryConcerns: [String]
    let immediateActions: [String]
    let confidence: Double
    let analysisDate: Date
    
    nonisolated enum CodingKeys: String, CodingKey {
        case analysisId = "analysis_id"
        case overallHealthScore = "overall_health_score"
        case healthTrend = "health_trend"
        case riskLevel = "risk_level"
        case primaryConcerns = "primary_concerns"
        case immediateActions = "immediate_actions"
        case confidence, analysisDate = "analysis_date"
    }
}

/// Health analysis response wrapper
struct HealthAnalysisResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let data: HealthAnalysisData
    let timestamp: String
}

/// Analysis history response wrapper
struct AnalysisHistoryResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let data: [HealthAnalysisData]
    let pagination: PaginationInfo
    let timestamp: String
}

/// Analysis statistics data
struct AnalysisStatistics: Codable, Sendable {
    let totalAnalyses: Int
    let averageScore: Double
    let trendDirection: TrendDirection
    let improvementPercentage: Double
    let lastAnalysisDate: Date?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case totalAnalyses = "total_analyses"
        case averageScore = "average_score"
        case trendDirection = "trend_direction"
        case improvementPercentage = "improvement_percentage"
        case lastAnalysisDate = "last_analysis_date"
    }
}

/// Analysis statistics response wrapper
struct AnalysisStatisticsResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let data: AnalysisStatistics
    let timestamp: String
}

/// Personalized recommendations data
struct PersonalizedRecommendations: Codable, Sendable {
    let recommendations: [HealthRecommendation]
    let priority: RecommendationPriority
    let personalizationFactors: [String]
    
    nonisolated enum CodingKeys: String, CodingKey {
        case recommendations
        case priority
        case personalizationFactors = "personalization_factors"
    }
}

/// Personalize recommendations request
struct PersonalizeRecommendationsRequest: Codable, Sendable {
    let userPreferences: HealthAnalysisPreferences
    
    nonisolated enum CodingKeys: String, CodingKey {
        case userPreferences = "user_preferences"
    }
}

/// Analysis comparison data
struct AnalysisComparison: Codable, Sendable {
    let comparedAnalyses: [String]
    let trendAnalysis: TrendAnalysis
    let improvementAreas: [String]
    let concerningChanges: [String]
    
    nonisolated enum CodingKeys: String, CodingKey {
        case comparedAnalyses = "compared_analyses"
        case trendAnalysis = "trend_analysis"
        case improvementAreas = "improvement_areas"
        case concerningChanges = "concerning_changes"
    }
}

/// Trend analysis data
struct TrendAnalysis: Codable, Sendable {
    let overallTrend: TrendDirection
    let categoryTrends: [String: TrendDirection]
    let significantChanges: [String]
    
    nonisolated enum CodingKeys: String, CodingKey {
        case overallTrend = "overall_trend"
        case categoryTrends = "category_trends"
        case significantChanges = "significant_changes"
    }
}

/// Pagination information
struct PaginationInfo: Codable, Sendable {
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let itemsPerPage: Int
    
    nonisolated enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case totalPages = "total_pages"
        case totalItems = "total_items"
        case itemsPerPage = "items_per_page"
    }
}

// MARK: - Health Analysis Errors

enum HealthAnalysisError: Error, LocalizedError, Sendable {
    case invalidURL
    case authenticationRequired
    case invalidResponse
    case serverError(Int)
    case analysisNotFound
    case analysisTimeout
    case networkError(Error)
    case decodingError(Error)
    case analysisInProgress
    case insufficientData
    
    nonisolated var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API endpoint URL"
        case .authenticationRequired:
            return "Authentication token required"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: HTTP \(code)"
        case .analysisNotFound:
            return "Health analysis not found"
        case .analysisTimeout:
            return "Analysis processing timed out"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .analysisInProgress:
            return "Analysis is still in progress"
        case .insufficientData:
            return "Insufficient data for analysis"
        }
    }
    
    nonisolated var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Check API configuration"
        case .authenticationRequired:
            return "Please log in again"
        case .invalidResponse, .serverError:
            return "Try again later or contact support"
        case .analysisNotFound:
            return "Analysis may have been deleted or not generated yet"
        case .analysisTimeout:
            return "Try requesting a new analysis"
        case .networkError:
            return "Check your internet connection"
        case .decodingError:
            return "Update the app or contact support"
        case .analysisInProgress:
            return "Wait for current analysis to complete"
        case .insufficientData:
            return "Upload a more detailed lab report"
        }
    }
}