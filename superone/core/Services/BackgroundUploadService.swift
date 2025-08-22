//
//  BackgroundUploadService.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import Foundation
import UIKit
import BackgroundTasks
import Combine

/// Service for handling background uploads with URLSession background configuration
@MainActor
final class BackgroundUploadService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = BackgroundUploadService()
    
    // MARK: - Published Properties
    @Published private(set) var activeBackgroundUploads: [String: BackgroundUploadTask] = [:]
    @Published private(set) var backgroundUploadProgress: [String: Double] = [:]
    @Published private(set) var backgroundUploadErrors: [String: Error] = [:]
    
    // MARK: - Private Properties
    private var backgroundSession: URLSession?
    private let tokenManager = TokenManager.shared
    private let userDefaults = UserDefaults.standard
    
    // Configuration
    private let backgroundSessionIdentifier = "com.superone.background-upload"
    private let maxBackgroundUploadTime: TimeInterval = 30 // 30 seconds for background task
    private let maxConcurrentBackgroundUploads = 3
    
    // Background task management
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private var backgroundProcessingTask: BGProcessingTask?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupBackgroundSession()
        setupBackgroundTaskHandling()
        registerBackgroundTasks()
    }
    
    // MARK: - Public Methods
    
    /// Schedule a document for background upload
    /// - Parameters:
    ///   - document: The lab report document to upload
    ///   - userPreferences: Optional user preferences for analysis
    ///   - priority: Upload priority (high/normal/low)
    /// - Returns: Background upload task identifier
    func scheduleBackgroundUpload(
        _ document: LabReportDocument,
        userPreferences: HealthAnalysisPreferences? = nil,
        priority: BackgroundUploadPriority = .normal
    ) async throws -> String {
        
        // Validate document
        try validateDocumentForBackground(document)
        
        // Create upload task
        let taskId = UUID().uuidString
        let uploadTask = BackgroundUploadTask(
            id: taskId,
            document: document,
            userPreferences: userPreferences,
            priority: priority,
            scheduledAt: Date(),
            retryCount: 0
        )
        
        // Store task
        activeBackgroundUploads[taskId] = uploadTask
        
        // Save to persistent storage
        saveBackgroundUploadTasks()
        
        // Start upload immediately if conditions allow
        if canStartImmediateUpload() {
            await startBackgroundUpload(taskId: taskId)
        } else {
            // Schedule for later execution
            scheduleBackgroundRefresh()
        }
        
        return taskId
    }
    
    /// Cancel a background upload
    /// - Parameter taskId: The upload task identifier
    func cancelBackgroundUpload(taskId: String) {
        guard let uploadTask = activeBackgroundUploads[taskId] else { return }
        
        // Cancel URL session task if running
        if let sessionTask = uploadTask.urlSessionTask {
            sessionTask.cancel()
        }
        
        // Remove from active uploads
        activeBackgroundUploads.removeValue(forKey: taskId)
        backgroundUploadProgress.removeValue(forKey: taskId)
        backgroundUploadErrors.removeValue(forKey: taskId)
        
        // Update persistent storage
        saveBackgroundUploadTasks()
        
        // Post notification
        NotificationCenter.default.post(
            name: .backgroundUploadCancelled,
            object: nil,
            userInfo: ["taskId": taskId]
        )
    }
    
    /// Get status of a background upload
    /// - Parameter taskId: The upload task identifier
    /// - Returns: Current upload status
    func getBackgroundUploadStatus(taskId: String) -> BackgroundUploadStatus? {
        guard let uploadTask = activeBackgroundUploads[taskId] else { return nil }
        
        let progress = backgroundUploadProgress[taskId] ?? 0.0
        let error = backgroundUploadErrors[taskId]
        
        return BackgroundUploadStatus(
            taskId: taskId,
            fileName: uploadTask.document.fileName,
            status: uploadTask.status,
            progress: progress,
            error: error,
            scheduledAt: uploadTask.scheduledAt,
            startedAt: uploadTask.startedAt,
            completedAt: uploadTask.completedAt
        )
    }
    
    /// Get all background upload statuses
    /// - Returns: Array of all background upload statuses
    func getAllBackgroundUploadStatuses() -> [BackgroundUploadStatus] {
        return activeBackgroundUploads.values.compactMap { uploadTask in
            getBackgroundUploadStatus(taskId: uploadTask.id)
        }
    }
    
    /// Resume pending background uploads
    func resumePendingUploads() async {
        let pendingTasks = activeBackgroundUploads.values.filter {
            $0.status == .pending || $0.status == .retrying
        }
        
        for uploadTask in pendingTasks.prefix(maxConcurrentBackgroundUploads) {
            await startBackgroundUpload(taskId: uploadTask.id)
        }
    }
    
    // MARK: - Private Implementation
    
    private func setupBackgroundSession() {
        let config = URLSessionConfiguration.background(withIdentifier: backgroundSessionIdentifier)
        config.isDiscretionary = false // Don't wait for optimal conditions
        config.shouldUseExtendedBackgroundIdleMode = true
        config.sessionSendsLaunchEvents = true
        config.timeoutIntervalForResource = 300 // 5 minutes
        config.httpMaximumConnectionsPerHost = 2
        
        backgroundSession = URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: nil
        )
    }
    
    private func setupBackgroundTaskHandling() {
        // Handle app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.superone.background-upload-process",
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleBackgroundProcessing(task as! BGProcessingTask)
            }
        }
    }
    
    @objc private func appDidEnterBackground() {
        scheduleBackgroundRefresh()
        startBackgroundTaskIfNeeded()
    }
    
    @objc private func appWillEnterForeground() {
        endBackgroundTaskIfNeeded()
        Task {
            await resumePendingUploads()
        }
    }
    
    private func startBackgroundTaskIfNeeded() {
        guard backgroundTaskIdentifier == .invalid else { return }
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "Upload Processing") {
            self.endBackgroundTaskIfNeeded()
        }
    }
    
    private func endBackgroundTaskIfNeeded() {
        guard backgroundTaskIdentifier != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
        backgroundTaskIdentifier = .invalid
    }
    
    private func scheduleBackgroundRefresh() {
        let request = BGProcessingTaskRequest(identifier: "com.superone.background-upload-process")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10) // Start in 10 seconds
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
        }
    }
    
    private func handleBackgroundProcessing(_ task: BGProcessingTask) async {
        backgroundProcessingTask = task
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Process pending uploads
        await processPendingBackgroundUploads()
        
        // Schedule next refresh if needed
        if !activeBackgroundUploads.isEmpty {
            scheduleBackgroundRefresh()
        }
        
        task.setTaskCompleted(success: true)
    }
    
    private func processPendingBackgroundUploads() async {
        let pendingTasks = activeBackgroundUploads.values
            .filter { $0.status == .pending || $0.status == .retrying }
            .sorted { $0.priority.rawValue > $1.priority.rawValue }
        
        for uploadTask in pendingTasks.prefix(maxConcurrentBackgroundUploads) {
            await startBackgroundUpload(taskId: uploadTask.id)
        }
    }
    
    private func startBackgroundUpload(taskId: String) async {
        guard var uploadTask = activeBackgroundUploads[taskId] else { return }
        
        do {
            // Update task status
            uploadTask.status = .uploading
            uploadTask.startedAt = Date()
            activeBackgroundUploads[taskId] = uploadTask
            
            // Prepare upload data
            let uploadData = try await prepareUploadData(
                for: uploadTask.document,
                userPreferences: uploadTask.userPreferences
            )
            
            // Create request
            let request = try await createBackgroundUploadRequest(uploadData: uploadData)
            
            // Start upload task
            guard let session = backgroundSession else {
                throw BackgroundUploadError.sessionNotAvailable
            }
            
            let sessionTask = session.uploadTask(with: request, from: uploadData.formData)
            uploadTask.urlSessionTask = sessionTask
            activeBackgroundUploads[taskId] = uploadTask
            
            sessionTask.resume()
            
            // Initialize progress
            backgroundUploadProgress[taskId] = 0.0
            
        } catch {
            await handleUploadError(taskId: taskId, error: error)
        }
    }
    
    private func validateDocumentForBackground(_ document: LabReportDocument) throws {
        // File size validation (smaller limit for background uploads)
        let maxBackgroundFileSize: Int64 = 5 * 1024 * 1024 // 5MB
        guard document.fileSize <= maxBackgroundFileSize else {
            throw BackgroundUploadError.fileTooLargeForBackground(document.fileSize, maxBackgroundFileSize)
        }
        
        // Data availability validation
        guard document.data != nil else {
            throw BackgroundUploadError.invalidFileData
        }
        
        // Network connectivity check
        guard NetworkMonitor.shared.isConnected else {
            throw BackgroundUploadError.noNetworkConnection
        }
    }
    
    private func canStartImmediateUpload() -> Bool {
        let activeUploads = activeBackgroundUploads.values.filter { $0.status == .uploading }
        return activeUploads.count < maxConcurrentBackgroundUploads && NetworkMonitor.shared.isConnected
    }
    
    private func prepareUploadData(
        for document: LabReportDocument,
        userPreferences: HealthAnalysisPreferences?
    ) async throws -> BackgroundUploadData {
        
        guard let fileData = document.data else {
            throw BackgroundUploadError.invalidFileData
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
        
        // Add background upload flag
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"backgroundUpload\"\r\n".data(using: .utf8)!)
        formData.append("Content-Type: text/plain\r\n\r\n".data(using: .utf8)!)
        formData.append("true".data(using: .utf8)!)
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
        
        return BackgroundUploadData(
            formData: formData,
            boundary: boundary,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }
    
    private func createBackgroundUploadRequest(uploadData: BackgroundUploadData) async throws -> URLRequest {
        guard let token = await tokenManager.getValidToken() else {
            throw BackgroundUploadError.authenticationRequired
        }
        
        guard let url = URL(string: AppConfiguration.baseURL + "/api/v1/upload/lab-report") else {
            throw BackgroundUploadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(uploadData.contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("background", forHTTPHeaderField: "X-Upload-Type")
        
        return request
    }
    
    private func handleUploadError(taskId: String, error: Error) async {
        guard var uploadTask = activeBackgroundUploads[taskId] else { return }
        
        backgroundUploadErrors[taskId] = error
        
        // Check if retry is possible
        if uploadTask.retryCount < 3 && isRetryableError(error) {
            uploadTask.retryCount += 1
            uploadTask.status = .retrying
            activeBackgroundUploads[taskId] = uploadTask
            
            // Schedule retry with exponential backoff
            let retryDelay = pow(2.0, Double(uploadTask.retryCount)) * 10 // 10, 20, 40 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                Task {
                    await self.startBackgroundUpload(taskId: taskId)
                }
            }
        } else {
            // Mark as failed
            uploadTask.status = .failed
            uploadTask.completedAt = Date()
            activeBackgroundUploads[taskId] = uploadTask
            
            // Post notification
            NotificationCenter.default.post(
                name: .backgroundUploadFailed,
                object: nil,
                userInfo: ["taskId": taskId, "error": error]
            )
        }
        
        saveBackgroundUploadTasks()
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        if let nsError = error as NSError? {
            // Network errors that might be temporary
            return nsError.domain == NSURLErrorDomain &&
                   [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet].contains(nsError.code)
        }
        return false
    }
    
    // MARK: - Persistence
    
    private func saveBackgroundUploadTasks() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(Array(activeBackgroundUploads.values)) {
            userDefaults.set(data, forKey: "backgroundUploadTasks")
        }
    }
    
    private func loadBackgroundUploadTasks() {
        guard let data = userDefaults.data(forKey: "backgroundUploadTasks") else { return }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let tasks = try? decoder.decode([BackgroundUploadTask].self, from: data) {
            for task in tasks {
                activeBackgroundUploads[task.id] = task
            }
        }
    }
}

// MARK: - URLSessionDelegate

extension BackgroundUploadService: URLSessionDelegate, URLSessionTaskDelegate {
    
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        let taskIdentifier = task.taskIdentifier
        
        // Find task ID on main actor
        Task { @MainActor in
            if let taskId = self.activeBackgroundUploads.first(where: { _, uploadTask in
                uploadTask.urlSessionTask?.taskIdentifier == taskIdentifier
            })?.key {
                self.backgroundUploadProgress[taskId] = progress
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let taskIdentifier = task.taskIdentifier
        let taskResponse = task.response
        
        Task { @MainActor in
            if let taskId = self.activeBackgroundUploads.first(where: { _, uploadTask in
                uploadTask.urlSessionTask?.taskIdentifier == taskIdentifier
            })?.key {
                if let error = error {
                    await self.handleUploadError(taskId: taskId, error: error)
                } else {
                    await self.handleUploadSuccess(taskId: taskId, response: taskResponse)
                }
            }
        }
    }
    
    nonisolated func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            // Notify app delegate that background session events are complete
            // Post notification for app delegate to handle
            NotificationCenter.default.post(
                name: .backgroundSessionEventsFinished,
                object: session
            )
        }
    }
    
    nonisolated private func findTaskId(for urlSessionTask: URLSessionTask) -> String? {
        // Since this is called from nonisolated delegate methods, we need to access the data differently
        // We'll pass the task identifier and let the main actor methods handle the lookup
        return nil // Will be handled in the calling methods
    }
    
    private func handleUploadSuccess(taskId: String, response: URLResponse?) async {
        guard var uploadTask = activeBackgroundUploads[taskId] else { return }
        
        uploadTask.status = .completed
        uploadTask.completedAt = Date()
        activeBackgroundUploads[taskId] = uploadTask
        
        backgroundUploadProgress[taskId] = 1.0
        backgroundUploadErrors.removeValue(forKey: taskId)
        
        // Post notification
        NotificationCenter.default.post(
            name: .backgroundUploadCompleted,
            object: nil,
            userInfo: ["taskId": taskId]
        )
        
        saveBackgroundUploadTasks()
        
        // Show local notification if app is in background
        if UIApplication.shared.applicationState != .active {
            await showUploadCompletionNotification(fileName: uploadTask.document.fileName)
        }
    }
    
    private func showUploadCompletionNotification(fileName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Upload Complete"
        content.body = "Your lab report '\(fileName)' has been uploaded successfully"
        content.sound = .default
        content.categoryIdentifier = "UPLOAD_COMPLETE"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Supporting Types

private struct BackgroundUploadData {
    let formData: Data
    let boundary: String
    let contentType: String
}

struct BackgroundUploadTask: Codable {
    let id: String
    let document: LabReportDocument
    let userPreferences: HealthAnalysisPreferences?
    let priority: BackgroundUploadPriority
    let scheduledAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var status: BackgroundUploadTaskStatus
    var retryCount: Int
    var urlSessionTask: URLSessionTask?
    
    init(
        id: String,
        document: LabReportDocument,
        userPreferences: HealthAnalysisPreferences?,
        priority: BackgroundUploadPriority,
        scheduledAt: Date,
        retryCount: Int
    ) {
        self.id = id
        self.document = document
        self.userPreferences = userPreferences
        self.priority = priority
        self.scheduledAt = scheduledAt
        self.retryCount = retryCount
        self.status = .pending
    }
    
    // Exclude urlSessionTask from Codable
    nonisolated enum CodingKeys: String, CodingKey {
        case id, document, userPreferences, priority, scheduledAt
        case startedAt, completedAt, status, retryCount
    }
}

enum BackgroundUploadPriority: Int, CaseIterable, Codable {
    case low = 1
    case normal = 2
    case high = 3
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
}

enum BackgroundUploadTaskStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case uploading = "uploading"
    case retrying = "retrying"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .uploading: return "Uploading"
        case .retrying: return "Retrying"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}

struct BackgroundUploadStatus {
    let taskId: String
    let fileName: String
    let status: BackgroundUploadTaskStatus
    let progress: Double
    let error: Error?
    let scheduledAt: Date
    let startedAt: Date?
    let completedAt: Date?
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
    
    var duration: TimeInterval? {
        guard let startedAt = startedAt else { return nil }
        let endTime = completedAt ?? Date()
        return endTime.timeIntervalSince(startedAt)
    }
}

// MARK: - Errors

enum BackgroundUploadError: Error, LocalizedError, Sendable {
    case fileTooLargeForBackground(Int64, Int64)
    case invalidFileData
    case noNetworkConnection
    case sessionNotAvailable
    case authenticationRequired
    case invalidURL
    case backgroundTaskExpired
    case maxRetriesExceeded
    
    nonisolated var errorDescription: String? {
        switch self {
        case .fileTooLargeForBackground(let size, let maxSize):
            return "File size (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))) exceeds background upload limit (\(ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)))"
        case .invalidFileData:
            return "Invalid or corrupted file data"
        case .noNetworkConnection:
            return "No network connection available"
        case .sessionNotAvailable:
            return "Background upload session not available"
        case .authenticationRequired:
            return "Authentication required for background upload"
        case .invalidURL:
            return "Invalid upload URL"
        case .backgroundTaskExpired:
            return "Background task time limit exceeded"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let backgroundUploadCompleted = Notification.Name("backgroundUploadCompleted")
    static let backgroundUploadFailed = Notification.Name("backgroundUploadFailed")
    static let backgroundUploadCancelled = Notification.Name("backgroundUploadCancelled")
    static let backgroundUploadProgress = Notification.Name("backgroundUploadProgress")
    static let backgroundSessionEventsFinished = Notification.Name("backgroundSessionEventsFinished")
}

// MARK: - Network Monitor

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    
    private init() {
        // Initialize network monitoring
        // Implementation would use Network framework
    }
}

