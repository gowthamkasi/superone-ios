//
//  UploadStatusService.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import Foundation
import Combine

// MARK: - Upload Status Service

/// Service for real-time monitoring of upload and processing status
@MainActor
final class UploadStatusService: ObservableObject, Sendable {
    
    // MARK: - Singleton
    static let shared = UploadStatusService()
    
    // MARK: - Published Properties
    @Published private(set) var activeUploads: [String: LabReportProcessingStatus] = [:]
    @Published private(set) var isMonitoring = false
    @Published private(set) var monitoringError: UploadStatusError?
    
    // MARK: - Private Properties
    private let labReportAPIService: LabReportAPIService
    private let tokenManager: TokenManager
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    private var statusUpdateSubjects: [String: PassthroughSubject<LabReportProcessingStatus, Never>] = [:]
    
    // MARK: - Configuration
    private let baseUploadPath = "/api/v1/upload"
    private let pollingInterval: TimeInterval = 2.0
    private let fastPollingInterval: TimeInterval = 1.0
    private let maxPollingDuration: TimeInterval = 600.0 // 10 minutes
    private let maxRetryAttempts = 3
    
    // MARK: - Initialization
    
    private init() {
        self.labReportAPIService = LabReportAPIService.shared
        self.tokenManager = TokenManager.shared
    }
    
    // MARK: - Status Monitoring
    
    /// Start monitoring upload status with real-time updates
    /// - Parameter labReportId: ID of the lab report to monitor
    /// - Returns: AsyncSequence of status updates
    func startMonitoring(_ labReportId: String) -> AsyncThrowingStream<LabReportProcessingStatus, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                await performStatusMonitoring(
                    labReportId: labReportId,
                    continuation: continuation
                )
            }
            
            pollingTasks[labReportId] = task
            isMonitoring = true
            
            continuation.onTermination = { _ in
                task.cancel()
                Task { @MainActor in
                    self.pollingTasks.removeValue(forKey: labReportId)
                    self.activeUploads.removeValue(forKey: labReportId)
                    if self.pollingTasks.isEmpty {
                        self.isMonitoring = false
                    }
                }
            }
        }
    }
    
    /// Monitor multiple uploads simultaneously
    /// - Parameter labReportIds: Array of lab report IDs to monitor
    /// - Returns: Dictionary of AsyncSequences keyed by lab report ID
    func startBatchMonitoring(_ labReportIds: [String]) -> [String: AsyncThrowingStream<LabReportProcessingStatus, Error>] {
        var streams: [String: AsyncThrowingStream<LabReportProcessingStatus, Error>] = [:]
        
        for labReportId in labReportIds {
            streams[labReportId] = startMonitoring(labReportId)
        }
        
        return streams
    }
    
    /// Get current status for a specific upload
    /// - Parameter labReportId: ID of the lab report
    /// - Returns: Current processing status
    func getCurrentStatus(_ labReportId: String) async throws -> LabReportProcessingStatus {
        do {
            let status = try await labReportAPIService.getProcessingStatus(for: labReportId)
            
            // Update local cache
            activeUploads[labReportId] = status
            
            return status
        } catch {
            throw UploadStatusError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Get cached status if available, otherwise fetch from server
    /// - Parameter labReportId: ID of the lab report
    /// - Returns: Processing status (cached or fresh)
    func getStatus(_ labReportId: String) async throws -> LabReportProcessingStatus {
        // Return cached status if available and recent
        if let cachedStatus = activeUploads[labReportId],
           let updatedAt = ISO8601DateFormatter().date(from: cachedStatus.updatedAt),
           Date().timeIntervalSince(updatedAt) < 30 { // 30 seconds freshness
            return cachedStatus
        }
        
        // Fetch fresh status
        return try await getCurrentStatus(labReportId)
    }
    
    /// Stop monitoring a specific upload
    /// - Parameter labReportId: ID of the lab report to stop monitoring
    func stopMonitoring(_ labReportId: String) {
        pollingTasks[labReportId]?.cancel()
        pollingTasks.removeValue(forKey: labReportId)
        activeUploads.removeValue(forKey: labReportId)
        statusUpdateSubjects.removeValue(forKey: labReportId)
        
        if pollingTasks.isEmpty {
            isMonitoring = false
        }
    }
    
    /// Stop monitoring all uploads
    func stopAllMonitoring() {
        for (_, task) in pollingTasks {
            task.cancel()
        }
        
        pollingTasks.removeAll()
        activeUploads.removeAll()
        statusUpdateSubjects.removeAll()
        isMonitoring = false
    }
    
    /// Get status update publisher for reactive UI updates
    /// - Parameter labReportId: ID of the lab report
    /// - Returns: Publisher that emits status updates
    func statusUpdatePublisher(for labReportId: String) -> AnyPublisher<LabReportProcessingStatus, Never> {
        if let subject = statusUpdateSubjects[labReportId] {
            return subject.eraseToAnyPublisher()
        }
        
        let subject = PassthroughSubject<LabReportProcessingStatus, Never>()
        statusUpdateSubjects[labReportId] = subject
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Batch Operations
    
    /// Get status for multiple uploads
    /// - Parameter labReportIds: Array of lab report IDs
    /// - Returns: Dictionary of statuses keyed by lab report ID
    func getBatchStatus(_ labReportIds: [String]) async throws -> [String: LabReportProcessingStatus] {
        var statuses: [String: LabReportProcessingStatus] = [:]
        
        // Use TaskGroup for concurrent fetching
        try await withThrowingTaskGroup(of: (String, LabReportProcessingStatus).self) { group in
            for labReportId in labReportIds {
                group.addTask {
                    let status = try await self.getCurrentStatus(labReportId)
                    return (labReportId, status)
                }
            }
            
            for try await (labReportId, status) in group {
                statuses[labReportId] = status
            }
        }
        
        return statuses
    }
    
    /// Get processing statistics for all active uploads
    /// - Returns: Processing statistics summary
    func getProcessingStatistics() -> ProcessingStatistics {
        let totalUploads = activeUploads.count
        let completedUploads = activeUploads.values.filter { $0.status == .completed }.count
        let failedUploads = activeUploads.values.filter { $0.status == .failed }.count
        let processingUploads = activeUploads.values.filter { 
            $0.status == .processing || $0.status == .analyzing 
        }.count
        
        let averageProgress = activeUploads.values.map { $0.progress }.reduce(0, +) / Double(max(totalUploads, 1))
        
        let estimatedTimeRemaining = activeUploads.values.compactMap { $0.estimatedTimeRemaining }.reduce(0, +)
        
        return ProcessingStatistics(
            totalUploads: totalUploads,
            completedUploads: completedUploads,
            failedUploads: failedUploads,
            processingUploads: processingUploads,
            averageProgress: averageProgress,
            estimatedTimeRemaining: estimatedTimeRemaining
        )
    }
    
    // MARK: - Private Implementation
    
    private func performStatusMonitoring(
        labReportId: String,
        continuation: AsyncThrowingStream<LabReportProcessingStatus, Error>.Continuation
    ) async {
        let startTime = Date()
        var retryCount = 0
        var lastStatus: UploadStatus = .uploading
        
        while !Task.isCancelled {
            do {
                let status = try await getCurrentStatus(labReportId)
                
                // Update local cache
                activeUploads[labReportId] = status
                
                // Emit status update
                continuation.yield(status)
                
                // Also send to reactive publisher if available
                statusUpdateSubjects[labReportId]?.send(status)
                
                // Check if processing is complete
                if status.status == .completed || status.status == .failed || status.status == .cancelled {
                    continuation.finish()
                    break
                }
                
                // Reset retry count on successful fetch
                retryCount = 0
                lastStatus = status.status
                
                // Check timeout
                if Date().timeIntervalSince(startTime) > maxPollingDuration {
                    continuation.finish(throwing: UploadStatusError.pollingTimeout)
                    break
                }
                
                // Determine polling interval based on current stage
                let interval = getPollingInterval(for: status.currentStage)
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                
            } catch {
                retryCount += 1
                
                if retryCount >= maxRetryAttempts {
                    continuation.finish(throwing: UploadStatusError.maxRetriesExceeded)
                    break
                }
                
                // Exponential backoff for retries
                let backoffDelay = min(pollingInterval * pow(2.0, Double(retryCount)), 30.0)
                try? await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
            }
        }
        
        // Cleanup
        await MainActor.run {
            pollingTasks.removeValue(forKey: labReportId)
            statusUpdateSubjects[labReportId]?.send(completion: .finished)
            statusUpdateSubjects.removeValue(forKey: labReportId)
            
            if pollingTasks.isEmpty {
                isMonitoring = false
            }
        }
    }
    
    private func getPollingInterval(for stage: ProcessingStage) -> TimeInterval {
        switch stage {
        case .uploaded, .completed, .failed:
            return pollingInterval
        case .ocrProcessing, .healthAnalysis:
            return fastPollingInterval // Poll faster during intensive processing
        case .documentClassification, .biomarkerExtraction:
            return pollingInterval
        }
    }
    
    /// Create authenticated request for status checking
    private func createAuthenticatedRequest(path: String) async throws -> URLRequest {
        guard let token = await tokenManager.getValidToken() else {
            throw UploadStatusError.authenticationRequired
        }
        
        guard let url = URL(string: AppConfiguration.baseURL + path) else {
            throw UploadStatusError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return request
    }
}

// MARK: - Supporting Types

/// Processing statistics summary
struct ProcessingStatistics: Sendable {
    let totalUploads: Int
    let completedUploads: Int
    let failedUploads: Int
    let processingUploads: Int
    let averageProgress: Double
    let estimatedTimeRemaining: Int
    
    var completionRate: Double {
        guard totalUploads > 0 else { return 0.0 }
        return Double(completedUploads) / Double(totalUploads)
    }
    
    var failureRate: Double {
        guard totalUploads > 0 else { return 0.0 }
        return Double(failedUploads) / Double(totalUploads)
    }
    
    var isProcessingActive: Bool {
        return processingUploads > 0
    }
    
    var formattedEstimatedTime: String {
        if estimatedTimeRemaining <= 0 {
            return "Unknown"
        }
        
        let minutes = estimatedTimeRemaining / 60
        let seconds = estimatedTimeRemaining % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

/// Real-time status update with metadata
struct StatusUpdate: Sendable {
    let labReportId: String
    let status: LabReportProcessingStatus
    let timestamp: Date
    let isFromCache: Bool
    
    init(labReportId: String, status: LabReportProcessingStatus, isFromCache: Bool = false) {
        self.labReportId = labReportId
        self.status = status
        self.timestamp = Date()
        self.isFromCache = isFromCache
    }
}

/// Status monitoring configuration
struct MonitoringConfiguration {
    let pollingInterval: TimeInterval
    let maxDuration: TimeInterval
    let maxRetries: Int
    let enableFastPolling: Bool
    let cacheDuration: TimeInterval
    
    static let `default` = MonitoringConfiguration(
        pollingInterval: 2.0,
        maxDuration: 600.0,
        maxRetries: 3,
        enableFastPolling: true,
        cacheDuration: 30.0
    )
    
    static let aggressive = MonitoringConfiguration(
        pollingInterval: 1.0,
        maxDuration: 300.0,
        maxRetries: 5,
        enableFastPolling: true,
        cacheDuration: 15.0
    )
    
    static let conservative = MonitoringConfiguration(
        pollingInterval: 5.0,
        maxDuration: 900.0,
        maxRetries: 2,
        enableFastPolling: false,
        cacheDuration: 60.0
    )
}

// MARK: - Upload Status Errors

enum UploadStatusError: Error, LocalizedError {
    case invalidURL
    case authenticationRequired
    case fetchFailed(String)
    case pollingTimeout
    case maxRetriesExceeded
    case networkUnavailable
    case invalidResponse
    case serverError(Int)
    
    nonisolated var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid status endpoint URL"
        case .authenticationRequired:
            return "Authentication token required"
        case .fetchFailed(let message):
            return "Status fetch failed: \(message)"
        case .pollingTimeout:
            return "Status monitoring timed out"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: HTTP \(code)"
        }
    }
    
    nonisolated var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Check API configuration"
        case .authenticationRequired:
            return "Please log in again"
        case .fetchFailed:
            return "Try refreshing or check your connection"
        case .pollingTimeout:
            return "Processing may still be ongoing - try checking manually"
        case .maxRetriesExceeded:
            return "Check your internet connection and try again"
        case .networkUnavailable:
            return "Connect to the internet and try again"
        case .invalidResponse, .serverError:
            return "Try again later or contact support"
        }
    }
}

// MARK: - Extensions

extension LabReportProcessingStatus {
    /// Check if status indicates active processing
    var isActivelyProcessing: Bool {
        switch status {
        case .uploading, .processing, .analyzing:
            return true
        case .completed, .failed, .cancelled:
            return false
        }
    }
    
    /// Get human-readable status description
    var statusDescription: String {
        return "\(status.displayName): \(currentStage.description)"
    }
    
    /// Get estimated completion time
    var estimatedCompletionTime: Date? {
        guard let timeRemaining = estimatedTimeRemaining, timeRemaining > 0 else {
            return nil
        }
        return Date().addingTimeInterval(TimeInterval(timeRemaining))
    }
    
    /// Check if status represents an error state
    var isErrorState: Bool {
        return status == .failed || (errorMessage != nil && !errorMessage!.isEmpty)
    }
}