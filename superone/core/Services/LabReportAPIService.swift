//
//  LabReportAPIService.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import Foundation
import UIKit
import Combine

// MARK: - Lab Report API Service

/// Comprehensive service for lab report upload and processing via Super One backend
@MainActor
final class LabReportAPIService: ObservableObject, Sendable {
    
    // MARK: - Singleton
    static let shared = LabReportAPIService()
    
    // MARK: - Published Properties
    @Published private(set) var isUploading = false
    @Published private(set) var uploadProgress: Double = 0.0
    @Published private(set) var currentOperation: String = ""
    @Published private(set) var uploadError: LabReportUploadError?
    
    // MARK: - Private Properties
    private let networkService: NetworkService
    private let tokenManager: TokenManager
    private var uploadTasks: [UUID: URLSessionUploadTask] = [:]
    private var progressObservers: [UUID: NSKeyValueObservation] = [:]
    private let uploadQueue = DispatchQueue(label: "com.superone.upload", qos: .utility)
    
    // MARK: - Configuration
    private let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB
    private let allowedMimeTypes = ["application/pdf", "image/jpeg", "image/png", "image/heic"]
    private let baseUploadPath = "/api/v1/upload"
    
    // MARK: - Initialization
    
    private init() {
        self.networkService = NetworkService.shared
        self.tokenManager = TokenManager.shared
    }
    
    // MARK: - Public Upload Methods
    
    /// Upload a single lab report document
    /// - Parameters:
    ///   - document: The lab report document to upload
    ///   - userPreferences: Optional user preferences for analysis
    /// - Returns: Upload result with processing status
    func uploadDocument(
        _ document: LabReportDocument,
        userPreferences: HealthAnalysisPreferences? = nil
    ) async throws -> LabReportUploadResult {
        
        updateProgress(0.1, operation: "Preparing document upload")
        
        // Validate document
        try validateDocument(document)
        
        // Prepare upload data
        updateProgress(0.2, operation: "Preparing upload data")
        let uploadData = try await prepareUploadData(for: document, userPreferences: userPreferences)
        
        // Create upload request
        updateProgress(0.3, operation: "Creating upload request")
        let request = try await createUploadRequest(uploadData: uploadData)
        
        // Perform upload with progress tracking
        updateProgress(0.4, operation: "Uploading document")
        let uploadResponse = try await performUpload(request: request, data: uploadData.formData)
        
        updateProgress(1.0, operation: "Upload completed")
        
        // Create result
        let result = LabReportUploadResult(
            uploadId: uploadResponse.id,
            labReportId: uploadResponse.id,
            fileName: document.fileName,
            fileSize: document.fileSize,
            uploadStatus: .completed,
            estimatedProcessingTime: 0,
            ocrMethod: .awsTextract,
            timestamp: Date(),
            documentType: .labReport
        )
        
        resetProgress()
        return result
    }
    
    /// Upload multiple documents in batch
    /// - Parameters:
    ///   - documents: Array of documents to upload
    ///   - userPreferences: Optional user preferences for analysis
    /// - Returns: Array of upload results
    func uploadDocumentsBatch(
        _ documents: [LabReportDocument],
        userPreferences: HealthAnalysisPreferences? = nil
    ) async throws -> [LabReportUploadResult] {
        
        updateProgress(0.0, operation: "Starting batch upload")
        
        guard documents.count <= 5 else {
            throw LabReportUploadError.batchSizeExceeded
        }
        
        // Validate all documents first
        for document in documents {
            try validateDocument(document)
        }
        
        // Prepare batch upload data
        updateProgress(0.1, operation: "Preparing batch upload")
        let batchData = try await prepareBatchUploadData(for: documents, userPreferences: userPreferences)
        
        // Create batch upload request
        updateProgress(0.2, operation: "Creating batch upload request")
        let request = try await createBatchUploadRequest(uploadData: batchData)
        
        // Perform batch upload
        updateProgress(0.3, operation: "Uploading documents batch")
        let batchResponse = try await performBatchUpload(request: request, data: batchData.formData)
        
        updateProgress(1.0, operation: "Batch upload completed")
        
        // Create results
        let results = batchResponse.successful.map { uploadData in
            LabReportUploadResult(
                uploadId: uploadData.id,
                labReportId: uploadData.id,
                fileName: uploadData.document.fileName,
                fileSize: uploadData.document.fileSize,
                uploadStatus: .completed,
                estimatedProcessingTime: 0,
                ocrMethod: .awsTextract,
                timestamp: Date(),
                documentType: .labReport
            )
        }
        
        resetProgress()
        return results
    }
    
    /// Get processing status for uploaded document
    /// - Parameter labReportId: ID of the uploaded lab report
    /// - Returns: Current processing status
    func getProcessingStatus(for labReportId: String) async throws -> LabReportProcessingStatus {
        let endpoint = "\(baseUploadPath)/status/\(labReportId)"
        
        var request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .GET
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LabReportUploadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LabReportUploadError.serverError(httpResponse.statusCode)
        }
        
        let statusResponse = try JSONDecoder().decode(UploadStatusResponse.self, from: data)
        return statusResponse.data
    }
    
    /// Get upload history with pagination
    /// - Parameters:
    ///   - page: Page number (default: 1)
    ///   - limit: Items per page (default: 10)
    /// - Returns: Paginated upload history
    func getUploadHistory(page: Int = 1, limit: Int = 10) async throws -> UploadHistoryData {
        let endpoint = "\(baseUploadPath)/history?page=\(page)&limit=\(limit)"
        
        var request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .GET
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LabReportUploadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LabReportUploadError.serverError(httpResponse.statusCode)
        }
        
        let historyResponse = try JSONDecoder().decode(UploadHistoryResponse.self, from: data)
        return historyResponse.data
    }
    
    /// Get detailed upload statistics and metrics
    /// - Parameter timeRange: Time range for statistics (optional)
    /// - Returns: Detailed upload metrics
    func getUploadStatistics(timeRange: HistoryTimeRange? = nil) async throws -> UploadMetrics {
        var endpoint = "\(baseUploadPath)/statistics"
        if let range = timeRange {
            endpoint += "?timeRange=\(range.rawValue)"
        }
        
        var request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .GET
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LabReportUploadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LabReportUploadError.serverError(httpResponse.statusCode)
        }
        
        let statisticsResponse = try JSONDecoder().decode(BackendProcessingStatisticsResponse.self, from: data)
        
        // Convert ProcessingStatistics to UploadMetrics
        return UploadMetrics(
            totalUploads: statisticsResponse.data.total,
            completedUploads: statisticsResponse.data.completed,
            failedUploads: statisticsResponse.data.failed,
            processingUploads: statisticsResponse.data.inProgress,
            cancelledUploads: statisticsResponse.data.cancelled,
            totalDataSize: statisticsResponse.data.totalFileSize,
            averageFileSize: statisticsResponse.data.totalFileSize / Int64(max(statisticsResponse.data.total, 1)),
            largestFileSize: 0, // Would need to be provided by API
            smallestFileSize: 0, // Would need to be provided by API
            averageProcessingTime: 0, // Would need to be provided by API
            fastestProcessingTime: 0, // Would need to be provided by API
            slowestProcessingTime: 0, // Would need to be provided by API
            uploadsByFileType: [:], // Would need to be provided by API
            uploadsByDocumentType: [:], // Would need to be provided by API
            uploadsByHealthCategory: [:], // Would need to be provided by API
            dailyUploads: [], // Would need to be provided by API
            monthlyUploads: [], // Would need to be provided by API
            successRateByFileType: [:], // Would need to be provided by API
            errorCategories: [:] // Would need to be provided by API
        )
    }
    
    /// Get filtered upload history with advanced options
    /// - Parameter filterRequest: Filter criteria for history
    /// - Returns: Filtered upload history
    func getFilteredUploadHistory(_ filterRequest: HistoryFilterRequest, page: Int = 1, limit: Int = 10) async throws -> UploadHistoryData {
        let endpoint = "\(baseUploadPath)/history/filtered"
        
        var request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .POST
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Create request body with filters and pagination
        struct FilteredHistoryRequest: Codable {
            let filters: HistoryFilterRequest
            let pagination: FilteredHistoryPagination
        }
        
        struct FilteredHistoryPagination: Codable {
            let page: Int
            let limit: Int
        }
        
        let requestBody = FilteredHistoryRequest(
            filters: filterRequest,
            pagination: FilteredHistoryPagination(page: page, limit: limit)
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LabReportUploadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LabReportUploadError.serverError(httpResponse.statusCode)
        }
        
        let historyResponse = try JSONDecoder().decode(UploadHistoryResponse.self, from: data)
        return historyResponse.data
    }
    
    /// Perform batch operations on upload history
    /// - Parameter batchRequest: Batch operation request
    /// - Returns: Batch operation result
    func performBatchHistoryOperation(_ batchRequest: BatchHistoryOperationRequest) async throws -> BatchHistoryOperationResponse.BatchOperationResult {
        let endpoint = "\(baseUploadPath)/history/batch"
        
        var request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .POST
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        request.httpBody = try JSONEncoder().encode(batchRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LabReportUploadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LabReportUploadError.serverError(httpResponse.statusCode)
        }
        
        let batchResponse = try JSONDecoder().decode(BatchHistoryOperationResponse.self, from: data)
        return batchResponse.data
    }
    
    /// Delete uploaded lab report
    /// - Parameter labReportId: ID of the lab report to delete
    func deleteUpload(_ labReportId: String) async throws {
        let endpoint = "\(baseUploadPath)/\(labReportId)"
        
        let request = try await createAuthenticatedRequest(
            path: endpoint,
            method: .DELETE
        )
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LabReportUploadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LabReportUploadError.serverError(httpResponse.statusCode)
        }
    }
    
    /// Cancel ongoing upload
    /// - Parameter uploadId: ID of the upload to cancel
    func cancelUpload(_ uploadId: UUID) {
        uploadTasks[uploadId]?.cancel()
        uploadTasks.removeValue(forKey: uploadId)
        progressObservers[uploadId]?.invalidate()
        progressObservers.removeValue(forKey: uploadId)
        resetProgress()
    }
    
    // MARK: - Private Upload Implementation
    
    private func validateDocument(_ document: LabReportDocument) throws {
        // File size validation
        guard document.fileSize <= maxFileSize else {
            throw LabReportUploadError.fileSizeExceeded(document.fileSize, maxFileSize)
        }
        
        // MIME type validation
        guard allowedMimeTypes.contains(document.mimeType) else {
            throw LabReportUploadError.unsupportedFileType(document.mimeType)
        }
        
        // Data availability validation
        guard document.data != nil else {
            throw LabReportUploadError.invalidFileData
        }
    }
    
    private func prepareUploadData(
        for document: LabReportDocument,
        userPreferences: HealthAnalysisPreferences?
    ) async throws -> LabReportUploadData {
        
        guard let fileData = document.data else {
            throw LabReportUploadError.invalidFileData
        }
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var formData = Data()
        
        // Add file data
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(document.fileName)\"\r\n".data(using: .utf8)!)
        formData.append("Content-Type: \(document.mimeType)\r\n\r\n".data(using: .utf8)!)
        formData.append(fileData)
        formData.append("\r\n".data(using: .utf8)!)
        
        // Add user preferences if provided
        if let preferences = userPreferences {
            let preferencesJSON = try JSONEncoder().encode(preferences)
            formData.append("--\(boundary)\r\n".data(using: .utf8)!)
            formData.append("Content-Disposition: form-data; name=\"userPreferences\"\r\n".data(using: .utf8)!)
            formData.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            formData.append(preferencesJSON)
            formData.append("\r\n".data(using: .utf8)!)
        }
        
        formData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return LabReportUploadData(
            formData: formData,
            boundary: boundary,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }
    
    private func prepareBatchUploadData(
        for documents: [LabReportDocument],
        userPreferences: HealthAnalysisPreferences?
    ) async throws -> LabReportUploadData {
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var formData = Data()
        
        // Add each file
        for (_, document) in documents.enumerated() {
            guard let fileData = document.data else {
                throw LabReportUploadError.invalidFileData
            }
            
            formData.append("--\(boundary)\r\n".data(using: .utf8)!)
            formData.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(document.fileName)\"\r\n".data(using: .utf8)!)
            formData.append("Content-Type: \(document.mimeType)\r\n\r\n".data(using: .utf8)!)
            formData.append(fileData)
            formData.append("\r\n".data(using: .utf8)!)
        }
        
        // Add user preferences if provided
        if let preferences = userPreferences {
            let preferencesJSON = try JSONEncoder().encode(preferences)
            formData.append("--\(boundary)\r\n".data(using: .utf8)!)
            formData.append("Content-Disposition: form-data; name=\"userPreferences\"\r\n".data(using: .utf8)!)
            formData.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            formData.append(preferencesJSON)
            formData.append("\r\n".data(using: .utf8)!)
        }
        
        formData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return LabReportUploadData(
            formData: formData,
            boundary: boundary,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }
    
    private func createUploadRequest(uploadData: LabReportUploadData) async throws -> URLRequest {
        let endpoint = "\(baseUploadPath)/lab-report"
        var request = try await createAuthenticatedRequest(path: endpoint, method: HTTPMethod.POST)
        
        request.setValue(uploadData.contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return request
    }
    
    private func createBatchUploadRequest(uploadData: LabReportUploadData) async throws -> URLRequest {
        let endpoint = "\(baseUploadPath)/lab-reports/batch"
        var request = try await createAuthenticatedRequest(path: endpoint, method: HTTPMethod.POST)
        
        request.setValue(uploadData.contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return request
    }
    
    private func performUpload(request: URLRequest, data: Data) async throws -> LabReportResponse {
        let uploadTask = URLSession.shared.uploadTask(with: request, from: data)
        
        // Store task for potential cancellation
        let taskId = UUID()
        uploadTasks[taskId] = uploadTask
        
        // Create progress observer
        let progressObserver = uploadTask.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            Task { @MainActor in
                self?.updateProgress(0.4 + (progress.fractionCompleted * 0.5), operation: "Uploading...")
            }
        }
        progressObservers[taskId] = progressObserver
        
        defer {
            uploadTasks.removeValue(forKey: taskId)
            progressObserver.invalidate()
            progressObservers.removeValue(forKey: taskId)
        }
        
        let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LabReportUploadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            throw LabReportUploadError.serverError(httpResponse.statusCode)
        }
        
        let uploadResponse = try JSONDecoder().decode(SingleUploadResponse.self, from: responseData)
        return uploadResponse.data
    }
    
    private func performBatchUpload(request: URLRequest, data: Data) async throws -> BatchUploadResult {
        let uploadTask = URLSession.shared.uploadTask(with: request, from: data)
        
        // Store task for potential cancellation
        let taskId = UUID()
        uploadTasks[taskId] = uploadTask
        
        // Create progress observer
        let progressObserver = uploadTask.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            Task { @MainActor in
                self?.updateProgress(0.3 + (progress.fractionCompleted * 0.6), operation: "Uploading batch...")
            }
        }
        progressObservers[taskId] = progressObserver
        
        defer {
            uploadTasks.removeValue(forKey: taskId)
            progressObserver.invalidate()
            progressObservers.removeValue(forKey: taskId)
        }
        
        let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LabReportUploadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            throw LabReportUploadError.serverError(httpResponse.statusCode)
        }
        
        let batchResponse = try JSONDecoder().decode(MultipleBatchUploadResponse.self, from: responseData)
        return batchResponse.data
    }
    
    private func createAuthenticatedRequest(path: String, method: HTTPMethod) async throws -> URLRequest {
        guard let token = await tokenManager.getValidToken() else {
            throw LabReportUploadError.authenticationRequired
        }
        
        guard let url = URL(string: AppConfiguration.baseURL + path) else {
            throw LabReportUploadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    // MARK: - Progress Management
    
    private func updateProgress(_ progress: Double, operation: String) {
        Task { @MainActor in
            self.uploadProgress = progress
            self.currentOperation = operation
            self.isUploading = progress > 0 && progress < 1.0
        }
    }
    
    private func resetProgress() {
        Task { @MainActor in
            self.uploadProgress = 0.0
            self.currentOperation = ""
            self.isUploading = false
            self.uploadError = nil
        }
    }
}

// MARK: - Supporting Types

private struct LabReportUploadData {
    let formData: Data
    let boundary: String
    let contentType: String
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - Upload Errors

enum LabReportUploadError: Error, LocalizedError, Sendable {
    case fileSizeExceeded(Int64, Int64)
    case unsupportedFileType(String)
    case invalidFileData
    case batchSizeExceeded
    case invalidURL
    case authenticationRequired
    case invalidResponse
    case serverError(Int)
    case networkError(Error)
    case encodingError(Error)
    
    nonisolated var errorDescription: String? {
        switch self {
        case .fileSizeExceeded(let size, let maxSize):
            return "File size (\(size) bytes) exceeds maximum allowed (\(maxSize) bytes)"
        case .unsupportedFileType(let type):
            return "File type '\(type)' is not supported"
        case .invalidFileData:
            return "Invalid or corrupted file data"
        case .batchSizeExceeded:
            return "Batch upload cannot exceed 5 documents"
        case .invalidURL:
            return "Invalid API endpoint URL"
        case .authenticationRequired:
            return "Authentication token required"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: HTTP \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Data encoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Response Types

/// Upload history data response
struct UploadHistoryData: Codable, Sendable {
    let uploads: [LabReportResponse]
    let pagination: PaginationInfo
    let totalSize: Int64
    let categories: [DocumentType]
    
    nonisolated enum CodingKeys: String, CodingKey {
        case uploads
        case pagination
        case totalSize = "total_size"
        case categories
    }
}

/// Single upload response
struct SingleUploadResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let data: LabReportResponse
    let timestamp: String
}

/// Multiple batch upload response
struct MultipleBatchUploadResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let data: BatchUploadResult
    let timestamp: String
}

/// Batch upload result
struct BatchUploadResult: Codable, Sendable {
    let successful: [LabReportResponse]
    let failed: [UploadError]
    let totalUploaded: Int
    let totalFailed: Int
    
    nonisolated enum CodingKeys: String, CodingKey {
        case successful
        case failed
        case totalUploaded = "total_uploaded"
        case totalFailed = "total_failed"
    }
}

/// Upload error details
struct UploadError: Codable, Sendable {
    let fileName: String
    let error: String
    let errorCode: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case error
        case errorCode = "error_code"
    }
}

/// Upload history response wrapper
struct UploadHistoryResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let data: UploadHistoryData
    let timestamp: String
}