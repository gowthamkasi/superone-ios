//
//  APIResponseModels.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//

import Foundation

// MARK: - Base Response Models

/// Base response structure for all API responses
struct BaseResponse<T: Codable>: Codable, Sendable where T: Sendable {
    let success: Bool
    let message: String?
    let data: T?
    let timestamp: Date?
    let meta: ResponseMeta?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case timestamp
        case meta
    }
}

/// Response metadata
struct ResponseMeta: Codable, Equatable, Sendable {
    let requestedAt: Date?
    let processingTime: Double?
    let version: String?
    let requestId: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case requestedAt
        case processingTime
        case version
        case requestId
    }
}

// ErrorResponse is defined in NetworkModels.swift

/// Error details for debugging
struct ErrorDetails: Codable, Equatable, Sendable {
    let field: String?
    let message: String?
    let value: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case field
        case message
        case value
    }
}

/// Pagination metadata
struct Pagination: Codable, Equatable, Sendable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNext: Bool?
    let hasPrevious: Bool?
    let currentPage: Int?
    
    // Convenience property for compatibility
    var hasMorePages: Bool {
        return hasNext ?? (page < totalPages)
    }
    
    nonisolated enum CodingKeys: String, CodingKey {
        case page
        case limit
        case total
        case totalPages
        case hasNext
        case hasPrevious
        case currentPage
    }
}

// MARK: - Authentication Response Models

/// User response (for /user/me endpoint)
struct UserResponse: Codable, Equatable, Sendable {
    let success: Bool
    let message: String?
    let data: User?
    let timestamp: Date?
    let meta: ResponseMeta?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case timestamp
        case meta
    }
    
    nonisolated init(success: Bool, message: String?, data: User?, timestamp: Date?, meta: ResponseMeta? = nil) {
        self.success = success
        self.message = message
        self.data = data
        self.timestamp = timestamp
        self.meta = meta
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        data = try container.decodeIfPresent(User.self, forKey: .data)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
        meta = try container.decodeIfPresent(ResponseMeta.self, forKey: .meta)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(meta, forKey: .meta)
    }
}

/// Authentication response
struct AuthResponse: Codable, Equatable, Sendable {
    let success: Bool
    let message: String?
    let data: AuthData?
    let timestamp: Date?
    let error: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case timestamp
        case error
    }
    
    nonisolated init(success: Bool, message: String?, data: AuthData?, timestamp: Date?, error: String? = nil) {
        self.success = success
        self.message = message
        self.data = data
        self.timestamp = timestamp
        self.error = error
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        data = try container.decodeIfPresent(AuthData.self, forKey: .data)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(error, forKey: .error)
    }
}

/// Authentication data
struct AuthData: Codable, Equatable, Sendable {
    let user: User
    let tokens: AuthTokens
    
    nonisolated enum CodingKeys: String, CodingKey {
        case user
        case tokens
    }
    
    nonisolated init(user: User, tokens: AuthTokens) {
        self.user = user
        self.tokens = tokens
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(User.self, forKey: .user)
        tokens = try container.decode(AuthTokens.self, forKey: .tokens)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
        try container.encode(tokens, forKey: .tokens)
    }
}

/// Authentication tokens
struct AuthTokens: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case tokenType
        case expiresIn
    }
    
    nonisolated init(accessToken: String, refreshToken: String, tokenType: String, expiresIn: Int?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
        tokenType = try container.decode(String.self, forKey: .tokenType)
        expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        try container.encode(tokenType, forKey: .tokenType)
        try container.encodeIfPresent(expiresIn, forKey: .expiresIn)
    }
}




/// Token refresh response
struct TokenResponse: Codable, Equatable, Sendable {
    let success: Bool
    let data: AuthTokens?
    let message: String?
    let timestamp: Date?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
        case timestamp
    }
    
    nonisolated init(success: Bool, data: AuthTokens?, message: String?, timestamp: Date?) {
        self.success = success
        self.data = data
        self.message = message
        self.timestamp = timestamp
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        data = try container.decodeIfPresent(AuthTokens.self, forKey: .data)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }
}

/// Logout request model matching backend API contract
struct LogoutRequest: @preconcurrency Codable, Equatable, Sendable {
    let deviceId: String?
    let allDevices: Bool?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case deviceId
        case allDevices
    }
    
    nonisolated init(deviceId: String? = nil, allDevices: Bool? = nil) {
        self.deviceId = deviceId
        self.allDevices = allDevices
    }
}

/// Logout response data from backend
struct LogoutData: @preconcurrency Codable, Equatable, Sendable {
    let success: Bool
    let message: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case message
    }
}

/// Logout response matching backend API contract
struct LogoutResponse: @preconcurrency Codable, Equatable, Sendable {
    let success: Bool
    let message: String?
    let data: LogoutData?
    let timestamp: String?
    let error: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case timestamp
        case error
    }
    
    nonisolated init(success: Bool, message: String? = nil, data: LogoutData? = nil, timestamp: String? = nil, error: String? = nil) {
        self.success = success
        self.message = message
        self.data = data
        self.timestamp = timestamp
        self.error = error
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        data = try container.decodeIfPresent(LogoutData.self, forKey: .data)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(error, forKey: .error)
    }
}

/// Password reset response
struct PasswordResetResponse: Codable, Equatable, Sendable {
    let success: Bool
    let message: String?
    let data: PasswordResetData?
    let timestamp: Date?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case timestamp
    }
    
    nonisolated init(success: Bool, message: String?, data: PasswordResetData?, timestamp: Date?) {
        self.success = success
        self.message = message
        self.data = data
        self.timestamp = timestamp
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        data = try container.decodeIfPresent(PasswordResetData.self, forKey: .data)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }
}

/// Password reset data
struct PasswordResetData: Codable, Equatable, Sendable {
    let resetToken: String?
    let expiresAt: Date?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case resetToken
        case expiresAt
    }
}

// MARK: - Dashboard Response Models

/// Dashboard overview response
struct DashboardOverviewResponse: Codable, Equatable, Sendable {
    let success: Bool
    let data: DashboardOverviewData?
    let message: String?
    let timestamp: Date?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
        case timestamp
    }
}

/// Dashboard overview data
struct DashboardOverviewData: Codable, Equatable, Sendable {
    let user: UserInfo
    let healthScore: HealthScoreData
    let greeting: GreetingData
    let stats: QuickStatsData
    let alerts: [DashboardResponse.HealthAlert]
    let lastUpdated: Date
    
    nonisolated enum CodingKeys: String, CodingKey {
        case user
        case healthScore
        case greeting
        case stats
        case alerts
        case lastUpdated
    }
}

/// User info for dashboard
struct UserInfo: Codable, Equatable, Sendable {
    let name: String
    let email: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case name
        case email
    }
}

/// Health score data
struct HealthScoreData: Codable, Equatable, Sendable {
    let overall: Double
    let trend: String
    let status: String
    let lastCalculated: Date?
    let categoryBreakdown: [String: Double]?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case overall
        case trend
        case status
        case lastCalculated
        case categoryBreakdown
    }
}

/// Greeting data
struct GreetingData: Codable, Equatable, Sendable {
    let timeBasedGreeting: String
    let personalizedMessage: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case timeBasedGreeting
        case personalizedMessage
    }
}

/// Quick stats data
struct QuickStatsData: Codable, Equatable, Sendable {
    let recentTests: Int
    let recommendations: Int
    let healthAlerts: Int
    let upcomingAppointments: Int
    
    nonisolated enum CodingKeys: String, CodingKey {
        case recentTests
        case recommendations
        case healthAlerts
        case upcomingAppointments
    }
}


// MARK: - Upload Response Models

/// Upload response
struct UploadResponse: Codable, Equatable, Sendable {
    let success: Bool
    let message: String?
    let data: UploadData?
    let timestamp: Date?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case timestamp
    }
    
    nonisolated init(success: Bool, message: String?, data: UploadData?, timestamp: Date?) {
        self.success = success
        self.message = message
        self.data = data
        self.timestamp = timestamp
    }
}

/// Upload data
struct UploadData: Codable, Equatable, Sendable {
    let labReportId: String
    let fileName: String
    let fileSize: Int
    let uploadUrl: String?
    let processingStatus: String
    let estimatedProcessingTime: Int?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case labReportId
        case fileName
        case fileSize
        case uploadUrl
        case processingStatus
        case estimatedProcessingTime
    }
    
    nonisolated init(labReportId: String, fileName: String, fileSize: Int, uploadUrl: String?, processingStatus: String, estimatedProcessingTime: Int?) {
        self.labReportId = labReportId
        self.fileName = fileName
        self.fileSize = fileSize
        self.uploadUrl = uploadUrl
        self.processingStatus = processingStatus
        self.estimatedProcessingTime = estimatedProcessingTime
    }
}

/// Batch upload response
struct BatchUploadResponse: Codable, Sendable {
    let success: Bool
    let message: String?
    let data: BatchUploadData?
    let timestamp: Date?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case timestamp
    }
}

/// Batch upload data
struct BatchUploadData: Codable, Sendable {
    let uploadedFiles: [UploadData]
    let totalFiles: Int
    let successfulUploads: Int
    let failedUploads: [UploadError]
    
    nonisolated enum CodingKeys: String, CodingKey {
        case uploadedFiles
        case totalFiles
        case successfulUploads
        case failedUploads
    }
}

// UploadError is now defined in LabReportAPIService.swift

/// Processing status response
struct ProcessingStatusResponse: Codable, Equatable, Sendable {
    let success: Bool
    let data: ProcessingStatusData?
    let message: String?
    let timestamp: Date?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
        case timestamp
    }
}

/// Processing status data
struct ProcessingStatusData: Codable, Equatable, Sendable {
    let labReportId: String
    let status: String
    let progress: Double?
    let currentStep: String?
    let estimatedTimeRemaining: Int?
    let extractedData: ExtractedDataSummary?
    let errors: [ProcessingError]?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case labReportId
        case status
        case progress
        case currentStep
        case estimatedTimeRemaining
        case extractedData
        case errors
    }
}

/// Extracted data summary
struct ExtractedDataSummary: Codable, Equatable, Sendable {
    let biomarkersFound: Int
    let confidence: Double
    let categories: [String]
    
    nonisolated enum CodingKeys: String, CodingKey {
        case biomarkersFound
        case confidence
        case categories
    }
}

/// Processing error
struct ProcessingError: Codable, Equatable, Sendable {
    let step: String
    let error: String
    let recoverable: Bool
    
    nonisolated enum CodingKeys: String, CodingKey {
        case step
        case error
        case recoverable
    }
}

// UploadHistoryResponse and UploadHistoryData are now defined in LabReportAPIService.swift

/// Upload history item
struct UploadHistoryItem: Codable, Equatable, Sendable {
    let labReportId: String
    let fileName: String
    let uploadDate: Date
    let processingStatus: String
    let fileSize: Int
    let biomarkersExtracted: Int?
    let confidence: Double?
    let documentType: String?
    let processingTime: Int?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case labReportId
        case fileName
        case uploadDate
        case processingStatus
        case fileSize
        case biomarkersExtracted
        case confidence
        case documentType
        case processingTime
    }
}

// MARK: - Health Analysis Response Models
// HealthAnalysisResponse and HealthAnalysisData are now defined in HealthAnalysisAPIService.swift

// MARK: - Response Model Extensions

extension BaseResponse {
    
    /// Check if the response is successful
    var isSuccess: Bool {
        return success && data != nil
    }
    
    /// Get error message if available
    var errorMessage: String? {
        return success ? nil : message
    }
}

// ErrorResponse LocalizedError extension moved to NetworkModels.swift

// MARK: - Custom Date Coding

extension BaseResponse {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        data = try container.decodeIfPresent(T.self, forKey: .data)
        
        // Handle flexible date formats
        if let timestampString = try container.decodeIfPresent(String.self, forKey: .timestamp) {
            timestamp = ISO8601DateFormatter().date(from: timestampString)
        } else {
            timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp)
        }
        
        meta = try container.decodeIfPresent(ResponseMeta.self, forKey: .meta)
    }
}

// MARK: - Response Validation

extension BaseResponse {
    
    /// Validate response and throw error if invalid
    func validate() throws {
        if !success {
            throw ErrorResponse(
                error: message ?? "Unknown error occurred",
                message: message ?? "Unknown error occurred",
                code: nil,
                details: nil,
                timestamp: timestamp,
                requestId: nil
            )
        }
    }
    
    /// Get data or throw error
    func getData() throws -> T {
        try validate()
        
        guard let data = data else {
            throw ErrorResponse(
                error: "No data received",
                message: "No data received",
                code: "NO_DATA",
                details: nil,
                timestamp: timestamp,
                requestId: nil
            )
        }
        
        return data
    }
}