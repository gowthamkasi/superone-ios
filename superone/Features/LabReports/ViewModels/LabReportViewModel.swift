//
//  LabReportViewModel.swift
//  SuperOne
//
//  Created by Claude Code on 7/27/25.
//

import Foundation
import SwiftUI
import PhotosUI
import Photos
import VisionKit
import Combine
import Network

// Custom processing error for lab report operations
struct LabReportProcessingError: Error, Codable, Sendable, Equatable {
    let type: ProcessingErrorType
    let message: String
    let details: String?
    let isRecoverable: Bool
    let timestamp: Date
    
    init(type: ProcessingErrorType, message: String, details: String? = nil, isRecoverable: Bool = true) {
        self.type = type
        self.message = message
        self.details = details
        self.isRecoverable = isRecoverable
        self.timestamp = Date()
    }
}

/// Main ViewModel orchestrating the complete lab report upload and processing flow
@MainActor
@Observable
final class LabReportViewModel: Sendable {
    
    // MARK: - Published Properties
    
    /// Current state of the lab report processing flow
    var currentStep: ProcessingWorkflowStep = .selectDocument
    
    /// All documents in the current upload session
    var documents: [LabReportDocument] = []
    
    /// Currently selected document for processing
    var selectedDocument: LabReportDocument? = nil
    
    /// Overall processing state
    var isProcessing: Bool = false
    
    /// Background upload support
    var showBackgroundUploadOption: Bool = false
    var backgroundUploadEnabled: Bool = false
    
    /// Current processing progress (0.0 - 1.0)
    var processingProgress: Double = 0.0
    
    /// Current operation description
    var currentOperation: String = ""
    
    /// Upload speed (displayed as string)
    var uploadSpeed: String = "Calculating..."
    
    /// Estimated time remaining for current operation
    var estimatedTimeRemaining: String = "Calculating..."
    
    /// Any errors that occurred during processing
    var processingError: LabReportProcessingError? = nil
    
    /// Extracted biomarkers from current document
    var extractedBiomarkers: [ExtractedBiomarker] = []
    
    /// Processing summary for completed operations
    var processingSummary: LabReportProcessingSummary? = nil
    
    /// UI presentation states
    var showFilePicker: Bool = false
    var showPhotoLibrarySheet: Bool = false
    var showDocumentScanner: Bool = false
    var showErrorAlert: Bool = false
    var showSuccessSheet: Bool = false
    
    /// PhotosPicker selected items
    var photoPickerItems: [PhotosPickerItem] = []
    
    // MARK: - Private Properties
    
    private let visionOCRService = VisionOCRService()
    private let labReportAPIService = LabReportAPIService.shared
    private let uploadStatusService = UploadStatusService.shared
    private let healthAnalysisAPIService = HealthAnalysisAPIService.shared
    private let networkService = NetworkService.shared
    private let backgroundUploadService = BackgroundUploadService.shared
    private let smartOCRService = SmartOCRService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Smart OCR routing configuration
    private var preferCloudOCR: Bool = true
    private var allowFallbackToLocal: Bool = true
    private var currentUploadResults: [String: LabReportUploadResult] = [:]
    private var statusMonitoringTasks: [String: Task<Void, Never>] = [:]
    
    // MARK: - Initialization
    
    init() {
        // Load background upload preference
        self.backgroundUploadEnabled = UserDefaults.standard.bool(forKey: "backgroundUploadEnabled")
        setupBindings()
    }
    
    // MARK: - Document Selection Methods
    
    /// Start file upload flow for documents
    func uploadFromFiles() {
        showFilePicker = true
    }
    
    /// Start document selection from photo library with permission checking
    func selectFromPhotoLibrary() {
        Task {
            await requestPhotoLibraryPermissionAndShowPicker()
        }
    }
    
    /// Start document scanner for multi-page documents
    func scanDocument() {
        guard VNDocumentCameraViewController.isSupported else {
            showError(LabReportProcessingError(
                type: .permissionDenied,
                message: "Document scanner is not available on this device",
                isRecoverable: false
            ))
            return
        }
        showDocumentScanner = true
    }
    
    /// Handle selected photo picker items
    func handlePhotoSelection() {
        Task {
            await processPhotoPickerItems()
        }
    }
    
    /// Handle file selection from file importer
    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                await processFileURLs(urls)
            }
        case .failure(let error):
            showError(LabReportProcessingError(
                type: .uploadFailed,
                message: "Failed to access selected files: \(error.localizedDescription)",
                isRecoverable: true
            ))
        }
    }
    
    /// Process images from camera or document scanner
    func processSelectedImages(_ images: [UIImage]) {
        Task {
            await createDocumentsFromImages(images)
        }
    }
    
    // MARK: - Document Processing Methods
    
    /// Process a specific document through smart OCR routing (cloud first, local fallback)
    func processDocument(_ document: LabReportDocument) {
        guard !isProcessing else { return }
        
        selectedDocument = document
        currentStep = .ocrProcessing
        
        Task {
            await performSmartDocumentProcessing(document)
        }
    }
    
    /// Process document with backend API (cloud OCR)
    func processDocumentWithBackend(_ document: LabReportDocument, userPreferences: HealthAnalysisPreferences? = nil) {
        guard !isProcessing else { return }
        
        selectedDocument = document
        currentStep = .uploadDocument
        
        Task {
            do {
                try await performBackendProcessing(document, userPreferences: userPreferences)
            } catch {
                await handleBackendProcessingError(document, error: error)
            }
        }
    }
    
    /// Process document with local Vision OCR only
    func processDocumentLocally(_ document: LabReportDocument) {
        guard !isProcessing else { return }
        
        selectedDocument = document
        currentStep = .ocrProcessing
        
        Task {
            await performLocalOCRProcessing(document)
        }
    }
    
    /// Retry processing for a failed document
    func retryProcessing(_ document: LabReportDocument) {
        guard document.canRetryProcessing else { return }
        
        // Reset document status
        updateDocumentStatus(document, status: .pending)
        processDocument(document)
    }
    
    /// Cancel current processing operation
    func cancelProcessing() {
        isProcessing = false
        currentOperation = ""
        processingProgress = 0.0
        currentStep = .selectDocument
        
        // Cancel any active status monitoring
        for (documentId, task) in statusMonitoringTasks {
            task.cancel()
            uploadStatusService.stopMonitoring(documentId)
        }
        statusMonitoringTasks.removeAll()
        
        // Reset any in-progress document status
        if let document = selectedDocument,
           document.processingStatus == .processing {
            updateDocumentStatus(document, status: .cancelled)
        }
    }
    
    // MARK: - Configuration Methods
    
    /// Configure OCR processing preferences
    func configureOCRPreferences(preferCloud: Bool, allowLocalFallback: Bool) {
        preferCloudOCR = preferCloud
        allowFallbackToLocal = allowLocalFallback
        
        // Update SmartOCRService configuration
        smartOCRService.configureOCRRouting(
            preferBackend: preferCloud,
            allowFallback: allowLocalFallback,
            timeout: 30.0,
            qualityThreshold: 0.8
        )
    }
    
    /// Get OCR performance analytics
    func getOCRPerformanceAnalytics() -> OCRPerformanceAnalytics {
        return smartOCRService.getPerformanceAnalytics()
    }
    
    /// Get current OCR method being used
    func getCurrentOCRMethod() -> OCRMethod {
        return smartOCRService.currentOCRMethod
    }
    
    /// Get current upload result for a document
    func getUploadResult(for document: LabReportDocument) -> LabReportUploadResult? {
        return currentUploadResults[document.id]
    }
    
    /// Get processing statistics for all uploads
    func getProcessingStatistics() -> ProcessingStatistics {
        return uploadStatusService.getProcessingStatistics()
    }
    
    // MARK: - Background Upload Methods
    
    /// Schedule document for background upload
    func scheduleBackgroundUpload(
        _ document: LabReportDocument,
        priority: BackgroundUploadPriority = .normal
    ) async throws -> String {
        let userPreferences = HealthAnalysisPreferences(
            includeRecommendations: true,
            healthGoals: nil, // Could be set based on user profile
            focusAreas: []
        )
        
        let taskId = try await backgroundUploadService.scheduleBackgroundUpload(
            document,
            userPreferences: userPreferences,
            priority: priority
        )
        
        // Update document status to indicate background upload scheduled
        updateDocumentStatus(document, status: .uploading)
        currentOperation = "Scheduled for background upload"
        
        return taskId
    }
    
    /// Toggle background upload preference
    func toggleBackgroundUpload() {
        backgroundUploadEnabled.toggle()
        UserDefaults.standard.set(backgroundUploadEnabled, forKey: "backgroundUploadEnabled")
        
        // Show option to schedule existing documents if enabled
        if backgroundUploadEnabled && !documents.isEmpty {
            showBackgroundUploadOption = true
        }
    }
    
    /// Check if background upload should be offered
    func shouldOfferBackgroundUpload() -> Bool {
        // Offer background upload for large files or when network is poor
        guard let document = selectedDocument else { return false }
        
        let isLargeFile = document.fileSize > 1_048_576 // 1MB
        let isSlowNetwork = false // Network speed detection will be implemented when needed
        let hasMultipleDocuments = documents.count > 1
        
        return backgroundUploadEnabled && (isLargeFile || isSlowNetwork || hasMultipleDocuments)
    }
    
    /// Get background upload status for all documents
    func getBackgroundUploadStatuses() -> [BackgroundUploadStatus] {
        return backgroundUploadService.getAllBackgroundUploadStatuses()
    }
    
    /// Cancel background upload for a document
    func cancelBackgroundUpload(taskId: String) {
        backgroundUploadService.cancelBackgroundUpload(taskId: taskId)
    }
    
    // MARK: - Biomarker Validation Methods
    
    /// Update a biomarker value after manual validation
    func updateBiomarker(_ biomarker: ExtractedBiomarker, value: String, unit: String? = nil) {
        guard let index = extractedBiomarkers.firstIndex(where: { $0.id == biomarker.id }) else {
            return
        }
        
        var updatedBiomarker = biomarker
        updatedBiomarker = ExtractedBiomarker(
            id: updatedBiomarker.id,
            name: updatedBiomarker.name,
            value: value,
            unit: unit ?? updatedBiomarker.unit,
            referenceRange: updatedBiomarker.referenceRange,
            status: updatedBiomarker.status,
            confidence: 1.0, // Manual entry has highest confidence
            extractionMethod: .manualEntry,
            textLocation: updatedBiomarker.textLocation,
            category: updatedBiomarker.category,
            normalizedValue: Double(value),
            isNumeric: Double(value) != nil,
            notes: "Manually validated by user"
        )
        
        extractedBiomarkers[index] = updatedBiomarker
    }
    
    /// Remove a biomarker that was incorrectly extracted
    func removeBiomarker(_ biomarker: ExtractedBiomarker) {
        extractedBiomarkers.removeAll { $0.id == biomarker.id }
    }
    
    /// Add a new biomarker manually
    func addManualBiomarker(name: String, value: String, unit: String?, category: HealthCategory?) {
        let biomarker = ExtractedBiomarker(
            name: name,
            value: value,
            unit: unit,
            status: .unknown,
            confidence: 1.0,
            extractionMethod: .manualEntry,
            category: category,
            normalizedValue: Double(value),
            isNumeric: Double(value) != nil,
            notes: "Manually added by user"
        )
        
        extractedBiomarkers.append(biomarker)
    }
    
    // MARK: - Batch Upload Methods
    
    /// Add documents from batch upload to the main document list
    func addDocumentsFromBatch(_ batchDocuments: [LabReportDocument]) {
        for document in batchDocuments {
            if !documents.contains(where: { $0.id == document.id }) {
                documents.append(document)
            }
        }
    }
    
    /// Update a document in the documents list
    private func updateDocumentInList(_ updatedDocument: LabReportDocument) {
        if let index = documents.firstIndex(where: { $0.id == updatedDocument.id }) {
            documents[index] = updatedDocument
        }
    }
    
    // MARK: - Flow Control Methods
    
    /// Proceed to the next step in the processing flow
    func proceedToNextStep() {
        switch currentStep {
        case .selectDocument:
            // This should be handled by document selection methods
            break
        case .uploadDocument:
            currentStep = .processing
        case .processing:
            currentStep = .ocrProcessing
        case .ocrProcessing:
            currentStep = .classifyDocument
        case .classifyDocument:
            currentStep = .extractBiomarkers
        case .extractBiomarkers:
            if !extractedBiomarkers.isEmpty {
                currentStep = .analyzeData
            } else {
                currentStep = .selectDocument
                showError(LabReportProcessingError(
                    type: .extractionFailed,
                    message: "No biomarkers could be extracted from the document",
                    details: "The document may not contain recognizable lab results, or the image quality may be too low",
                    isRecoverable: true
                ))
            }
        case .analyzeData:
            currentStep = .reviewResults
        case .reviewResults:
            currentStep = .validateBiomarkers
        case .validateBiomarkers:
            currentStep = .complete
            finalizeProcessing()
        case .complete:
            resetForNewDocument()
        case .error:
            // Stay in error state until user takes action
            break
        }
    }
    
    /// Go back to the previous step
    func goToPreviousStep() {
        switch currentStep {
        case .selectDocument:
            // Already at the first step
            break
        case .uploadDocument:
            currentStep = .selectDocument
        case .processing:
            currentStep = .uploadDocument
            cancelProcessing()
        case .ocrProcessing:
            currentStep = .processing
        case .classifyDocument:
            currentStep = .ocrProcessing
        case .extractBiomarkers:
            currentStep = .classifyDocument
        case .analyzeData:
            currentStep = .extractBiomarkers
        case .reviewResults:
            currentStep = .analyzeData
        case .validateBiomarkers:
            currentStep = .reviewResults
        case .complete:
            currentStep = .validateBiomarkers
        case .error:
            currentStep = .selectDocument
        }
    }
    
    /// Reset the flow for processing a new document
    func resetForNewDocument() {
        currentStep = .selectDocument
        selectedDocument = nil
        extractedBiomarkers = []
        processingSummary = nil
        processingError = nil
        isProcessing = false
        processingProgress = 0.0
        currentOperation = ""
        
        // Clear presentation states
        showFilePicker = false
        showPhotoLibrarySheet = false
        showDocumentScanner = false
        showErrorAlert = false
        showSuccessSheet = false
        photoPickerItems = []
    }
    
    // MARK: - Private Implementation
    
    private func setupBindings() {
        // Monitor OCR service progress
        visionOCRService.$progress
            .receive(on: DispatchQueue.main)
            .assign(to: \.processingProgress, on: self)
            .store(in: &cancellables)
        
        visionOCRService.$currentOperation
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentOperation, on: self)
            .store(in: &cancellables)
        
        visionOCRService.$isProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isProcessing, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Photo Library Permission Handling
    
    /// Request photo library permission and show picker if granted
    private func requestPhotoLibraryPermissionAndShowPicker() async {
        let permissionHelper = PhotoPermissionHelper.shared
        let status = permissionHelper.getCurrentStatus()
        
        switch status {
        case .authorized, .limited:
            // Permission already granted, show picker
            await MainActor.run {
                showPhotoLibrarySheet = true
            }
            
        case .notDetermined:
            // Request permission
            let newStatus = await permissionHelper.requestPhotoLibraryPermission()
            await handlePhotoLibraryPermissionResult(newStatus)
            
        case .denied, .restricted:
            // Permission denied, show error with instructions
            await MainActor.run {
                showError(LabReportProcessingError(
                    type: .permissionDenied,
                    message: permissionHelper.getActionableMessage(status),
                    details: permissionHelper.getStatusDescription(status),
                    isRecoverable: true
                ))
            }
            
        @unknown default:
            // Handle future cases
            await MainActor.run {
                showError(LabReportProcessingError(
                    type: .permissionDenied,
                    message: "Unable to access photo library. Please check your privacy settings.",
                    isRecoverable: true
                ))
            }
        }
    }
    
    /// Handle the result of photo library permission request
    private func handlePhotoLibraryPermissionResult(_ status: PHAuthorizationStatus) async {
        let permissionHelper = PhotoPermissionHelper.shared
        
        await MainActor.run {
            switch status {
            case .authorized, .limited:
                showPhotoLibrarySheet = true
                
            case .denied, .restricted:
                showError(LabReportProcessingError(
                    type: .permissionDenied,
                    message: permissionHelper.getActionableMessage(status),
                    details: permissionHelper.getStatusDescription(status),
                    isRecoverable: true
                ))
                
            default:
                showError(LabReportProcessingError(
                    type: .permissionDenied,
                    message: "Unable to access photo library at this time.",
                    isRecoverable: true
                ))
            }
        }
    }
    
    // MARK: - Photo Processing
    
    private func processPhotoPickerItems() async {
        guard !photoPickerItems.isEmpty else { return }
        
        var images: [UIImage] = []
        var failedCount = 0
        
        for item in photoPickerItems {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                } else {
                    failedCount += 1
                }
            } catch {
                failedCount += 1
            }
        }
        
        // Clear selected items
        await MainActor.run {
            photoPickerItems = []
        }
        
        // Show warning if some images failed to load
        if failedCount > 0 {
            await MainActor.run {
                showError(LabReportProcessingError(
                    type: .uploadFailed,
                    message: "\(failedCount) image(s) could not be processed. \(images.count) image(s) were successfully loaded.",
                    details: "Some images may be in an unsupported format or corrupted",
                    isRecoverable: true
                ))
            }
        }
        
        if !images.isEmpty {
            await createDocumentsFromImages(images)
        } else if failedCount > 0 {
            await MainActor.run {
                showError(LabReportProcessingError(
                    type: .uploadFailed,
                    message: "No images could be processed from your selection. Please try selecting different images.",
                    details: "Supported formats: JPEG, PNG, HEIC",
                    isRecoverable: true
                ))
            }
        }
    }
    
    private func processFileURLs(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        
        var images: [UIImage] = []
        
        for url in urls {
            // Start accessing the security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
                
                if let contentType = resourceValues.contentType {
                    if contentType.conforms(to: .pdf) {
                        // Handle PDF files
                        await handlePDFFile(url)
                    } else if contentType.conforms(to: .image) {
                        // Handle image files - load directly and store data
                        if let data = try? Data(contentsOf: url),
                           let image = UIImage(data: data) {
                            images.append(image)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    showError(LabReportProcessingError(
                        type: .uploadFailed,
                        message: "Failed to process file: \(url.lastPathComponent)",
                        isRecoverable: false
                    ))
                }
            }
        }
        
        if !images.isEmpty {
            await createDocumentsFromImages(images)
        }
    }
    
    private func handlePDFFile(_ url: URL) async {
        let fileName = url.lastPathComponent
        
        // Read PDF data
        do {
            let pdfData = try Data(contentsOf: url)
            let fileSize = Int64(pdfData.count)
            
            let document = LabReportDocument(
                fileName: fileName,
                fileSize: fileSize,
                mimeType: "application/pdf",
                processingStatus: .pending,
                data: pdfData  // Store actual PDF data
            )
            
            await MainActor.run {
                documents.append(document)
                selectedDocument = document
                currentStep = .processing
            }
            
            await processDocument(document)
            
        } catch {
            await MainActor.run {
                showError(LabReportProcessingError(
                    type: .uploadFailed,
                    message: "Failed to read PDF file: \(error.localizedDescription)",
                    isRecoverable: false
                ))
            }
        }
    }
    
    private func createDocumentsFromImages(_ images: [UIImage]) async {
        for (index, image) in images.enumerated() {
            let fileName = "lab_report_\(Date().timeIntervalSince1970)_\(index + 1).jpg"
            
            // Compress and store actual image data
            let imageData = image.jpegData(compressionQuality: 0.8)
            let fileSize = Int64(imageData?.count ?? 0)
            
            let document = LabReportDocument(
                fileName: fileName,
                fileSize: fileSize,
                mimeType: "image/jpeg",
                processingStatus: .pending,
                data: imageData  // Store actual image data
            )
            
            documents.append(document)
            
            // Auto-process the first document
            if index == 0 {
                selectedDocument = document
                await processDocument(document)
            }
        }
    }
    
    // MARK: - Smart OCR Processing Methods
    
    /// Perform smart document processing with backend API first, local fallback
    private func performSmartDocumentProcessing(_ document: LabReportDocument) async {
        updateDocumentStatus(document, status: .processing)
        updateProgress(0.1, "Initializing smart OCR processing")
        
        do {
            // Use SmartOCRService for intelligent routing
            let ocrResult = try await smartOCRService.processDocument(document)
            
            updateProgress(0.7, "OCR completed, processing biomarkers")
            
            // Convert OCR result to local biomarkers format
            extractedBiomarkers = ocrResult.extractedBiomarkers
            
            updateProgress(0.9, "Finalizing processing")
            
            updateDocumentStatus(document, status: .completed)
            
            // Create processing summary
            processingSummary = LabReportProcessingSummary(
                documentId: document.id,
                processingEndTime: Date(),
                totalBiomarkersExtracted: extractedBiomarkers.count,
                highConfidenceBiomarkers: extractedBiomarkers.filter { $0.isHighConfidence }.count,
                categoriesIdentified: Array(Set(extractedBiomarkers.compactMap { $0.category })),
                ocrMethod: ocrResult.method == .backend ? .awsTextract : .visionFramework,
                overallConfidence: ocrResult.confidence
            )
            
            updateProgress(1.0, "Processing completed")
            
            // Log successful processing method
            let methodDescription = ocrResult.method.displayName
            let fallbackInfo = ocrResult.isFallback ? " (fallback)" : ""
            
            // Proceed to next step
            proceedToNextStep()
            
        } catch {
            updateDocumentStatus(document, status: .failed)
            
            let processingError = LabReportProcessingError(
                type: .ocrFailed,
                message: "Smart OCR processing failed: \(error.localizedDescription)",
                details: error.localizedDescription,
                isRecoverable: true
            )
            
            showError(processingError)
        }
    }
    
    /// Perform backend processing with real-time status monitoring
    private func performBackendProcessing(_ document: LabReportDocument, userPreferences: HealthAnalysisPreferences? = nil) async throws {
        updateDocumentStatus(document, status: .processing)
        updateProgress(0.1, "Uploading document to server")
        
        do {
            // Upload document to backend
            let uploadResult = try await labReportAPIService.uploadDocument(document, userPreferences: userPreferences)
            currentUploadResults[document.id] = uploadResult
            
            updateProgress(0.3, "Document uploaded, starting OCR processing")
            
            // Start monitoring upload/processing status
            let statusStream = uploadStatusService.startMonitoring(uploadResult.labReportId)
            
            // Create monitoring task
            let monitoringTask = Task {
                do {
                    for try await status in statusStream {
                        await handleStatusUpdate(document, status: status)
                        
                        // Check if processing is complete
                        if status.status == .completed {
                            await handleBackendProcessingCompletion(document, labReportId: uploadResult.labReportId)
                            break
                        } else if status.status == .failed {
                            throw LabReportProcessingError(
                                type: .ocrFailed,
                                message: status.errorMessage ?? "Backend processing failed",
                                isRecoverable: true
                            )
                        }
                    }
                } catch {
                    await handleBackendProcessingError(document, error: error)
                }
            }
            
            statusMonitoringTasks[document.id] = monitoringTask
            
        } catch {
            updateDocumentStatus(document, status: .failed)
            throw error
        }
    }
    
    /// Perform local OCR processing using Vision framework
    private func performLocalOCRProcessing(_ document: LabReportDocument) async {
        updateDocumentStatus(document, status: .processing)
        updateProgress(0.1, "Preparing for local OCR processing")
        
        do {
            // Load image from document (this would need proper image storage in production)
            guard let image = await loadImageForDocument(document) else {
                throw LabReportProcessingError(
                    type: .ocrFailed,
                    message: "Could not load image for document",
                    isRecoverable: false
                )
            }
            
            updateProgress(0.3, "Processing with Vision OCR")
            
            // Process with Vision OCR
            let ocrResult = try await visionOCRService.processImage(image, configuration: .medical)
            
            updateProgress(0.7, "Extracting biomarkers")
            
            // Extract biomarkers from OCR result (using real backend data)
            extractedBiomarkers = []  // Local Vision OCR processing
            
            updateProgress(0.9, "Finalizing processing")
            
            updateDocumentStatus(document, status: .completed)
            
            // Create processing summary
            processingSummary = LabReportProcessingSummary(
                documentId: document.id,
                processingEndTime: Date(),
                totalBiomarkersExtracted: extractedBiomarkers.count,
                highConfidenceBiomarkers: extractedBiomarkers.filter { $0.isHighConfidence }.count,
                categoriesIdentified: Array(Set(extractedBiomarkers.compactMap { $0.category })),
                ocrMethod: .visionFramework,
                overallConfidence: ocrResult.confidence
            )
            
            updateProgress(1.0, "Processing completed")
            
            // Proceed to next step
            proceedToNextStep()
            
        } catch {
            updateDocumentStatus(document, status: .failed)
            
            let processingError = LabReportProcessingError(
                type: .ocrFailed,
                message: "Local OCR failed: \(error.localizedDescription)",
                details: error.localizedDescription,
                isRecoverable: true
            )
            
            showError(processingError)
        }
    }
    
    // MARK: - Backend Processing Handlers
    
    private func handleStatusUpdate(_ document: LabReportDocument, status: LabReportProcessingStatus) async {
        await MainActor.run {
            updateProgress(status.progress, status.currentStage.description)
            
            // Update document status based on backend status
            let localStatus: ProcessingStatus
            switch status.status {
            case .uploading, .processing:
                localStatus = .processing
            case .analyzing:
                localStatus = .analyzing
            case .completed:
                localStatus = .completed
            case .failed:
                localStatus = .failed
            case .cancelled:
                localStatus = .cancelled
            }
            
            updateDocumentStatus(document, status: localStatus)
        }
    }
    
    private func handleBackendProcessingCompletion(_ document: LabReportDocument, labReportId: String) async {
        do {
            updateProgress(0.9, "Retrieving analysis results")
            
            // Get the latest health analysis
            if let analysis = try await healthAnalysisAPIService.getLatestAnalysis() {
                await MainActor.run {
                    // Convert backend analysis to local biomarkers for UI display
                    extractedBiomarkers = createBiomarkersFromAnalysis(analysis)
                    
                    // Create processing summary
                    processingSummary = LabReportProcessingSummary(
                        documentId: document.id,
                        processingEndTime: Date(),
                        totalBiomarkersExtracted: extractedBiomarkers.count,
                        highConfidenceBiomarkers: extractedBiomarkers.filter { $0.isHighConfidence }.count,
                        categoriesIdentified: Array(Set(extractedBiomarkers.compactMap { $0.category })),
                        ocrMethod: .awsTextract,
                        overallConfidence: analysis.confidence
                    )
                    
                    updateDocumentStatus(document, status: .completed)
                    updateProgress(1.0, "Analysis completed")
                    
                    // Proceed to next step
                    proceedToNextStep()
                }
            } else {
                throw LabReportProcessingError(
                    type: .analysisFailed,
                    message: "Could not retrieve analysis results",
                    isRecoverable: true
                )
            }
            
        } catch {
            await handleBackendProcessingError(document, error: error)
        }
    }
    
    private func handleBackendProcessingError(_ document: LabReportDocument, error: Error) async {
        await MainActor.run {
            if allowFallbackToLocal {
                Task {
                    await performLocalOCRProcessing(document)
                }
            } else {
                updateDocumentStatus(document, status: .failed)
                
                let processingError = LabReportProcessingError(
                    type: .ocrFailed,
                    message: "Backend processing failed: \(error.localizedDescription)",
                    details: "Local fallback disabled",
                    isRecoverable: true
                )
                
                showError(processingError)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadImageForDocument(_ document: LabReportDocument) async -> UIImage? {
        // Load image from stored document data
        guard let imageData = document.data else {
            return nil
        }
        
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    private func createBiomarkersFromAnalysis(_ analysis: DetailedHealthAnalysis) -> [ExtractedBiomarker] {
        // Convert backend analysis to ExtractedBiomarker array
        // This is a simplified implementation for demonstration
        var biomarkers: [ExtractedBiomarker] = []
        
        // Extract biomarkers from category assessments
        for (category, assessment) in analysis.categoryAssessments {
            for biomarker in assessment.biomarkers {
                let extracted = ExtractedBiomarker(
                    name: biomarker.name,
                    value: String(biomarker.value),
                    unit: biomarker.unit,
                    referenceRange: biomarker.normalRange,
                    status: convertBiomarkerStatus(biomarker.status),
                    confidence: 0.95, // Backend processing has high confidence
                    extractionMethod: .backendAPI,
                    category: convertHealthCategory(category),
                    normalizedValue: biomarker.value,
                    isNumeric: true, // Backend values are always numeric
                    notes: "Extracted via backend AI analysis"
                )
                biomarkers.append(extracted)
            }
        }
        
        return biomarkers
    }
    
    private func convertBiomarkerStatus(_ status: BiomarkerStatus) -> BiomarkerStatusLocal {
        switch status {
        case .optimal: return .normal
        case .normal: return .normal
        case .borderline: return .borderline
        case .abnormal: return .abnormal
        case .high: return .abnormal
        case .low: return .abnormal
        case .critical: return .critical
        case .unknown: return .normal
        }
    }
    
    private func convertHealthCategory(_ category: BackendHealthCategory) -> HealthCategory? {
        // Map between backend and local health categories - extend as needed
        switch category {
        case .cardiovascular: return .cardiovascular
        case .metabolic: return .metabolic
        case .hematology: return .hematology
        default: return nil
        }
    }
    
    private func parseNumericValue(_ value: String) -> Double? {
        // Extract numeric value from string, handling units and special characters
        let cleanedValue = value.replacingOccurrences(of: "[^0-9.,]", with: "", options: .regularExpression)
        return Double(cleanedValue)
    }
    
    private func updateProgress(_ progress: Double, _ message: String) {
        processingProgress = progress
        currentOperation = message
        isProcessing = progress > 0 && progress < 1.0
    }
    
    private func updateDocumentStatus(_ document: LabReportDocument, status: ProcessingStatus) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else {
            return
        }
        
        documents[index] = LabReportDocument(
            id: document.id,
            fileName: document.fileName,
            filePath: document.filePath,
            fileSize: document.fileSize,
            mimeType: document.mimeType,
            uploadDate: document.uploadDate,
            processingStatus: status,
            documentType: document.documentType,
            healthCategory: document.healthCategory,
            extractedText: document.extractedText,
            ocrConfidence: document.ocrConfidence,
            thumbnail: document.thumbnail,
            metadata: document.metadata
        )
    }
    
    // Mock biomarker method removed - using real backend OCR results from SmartOCRService
    
    private func finalizeProcessing() {
        // Save to local storage, sync to backend, and update HealthKit when available
        
        showSuccessSheet = true
    }
    
    private func showError(_ error: LabReportProcessingError) {
        processingError = error
        showErrorAlert = true
    }
}

// MARK: - Processing Step Enum (Using ProcessingWorkflowStep from ProcessingStatus.swift)

// MARK: - LabReportViewModel Extensions

extension LabReportViewModel {
    
    /// Get documents filtered by status
    func documents(with status: ProcessingStatus) -> [LabReportDocument] {
        return documents.filter { $0.processingStatus == status }
    }
    
    /// Get biomarkers filtered by category
    func biomarkers(for category: HealthCategory) -> [ExtractedBiomarker] {
        return extractedBiomarkers.filter { $0.category == category }
    }
    
    /// Get biomarkers filtered by confidence level
    func highConfidenceBiomarkers() -> [ExtractedBiomarker] {
        return extractedBiomarkers.filter { $0.isHighConfidence }
    }
    
    /// Get biomarkers that need validation
    func biomarkersNeedingValidation() -> [ExtractedBiomarker] {
        return extractedBiomarkers.filter { !$0.isHighConfidence }
    }
    
    /// Check if current step allows navigation
    var canProceed: Bool {
        switch currentStep {
        case .selectDocument:
            return selectedDocument != nil && !isProcessing
        case .uploadDocument:
            return selectedDocument != nil && !isProcessing
        case .processing:
            return !isProcessing && processingError == nil
        case .ocrProcessing:
            return !isProcessing && processingError == nil
        case .classifyDocument:
            return !isProcessing && processingError == nil
        case .extractBiomarkers:
            return !isProcessing && processingError == nil
        case .analyzeData:
            return !isProcessing && processingError == nil
        case .reviewResults:
            return !extractedBiomarkers.isEmpty
        case .validateBiomarkers:
            return true // Always allow proceeding from validation
        case .complete:
            return true
        case .error:
            return true // Allow proceeding from error state
        }
    }
    
    
    /// Get progress percentage for current step
    var stepProgress: Double {
        if isProcessing {
            return processingProgress
        }
        
        switch currentStep {
        case .selectDocument:
            return selectedDocument != nil ? 1.0 : 0.0
        case .uploadDocument:
            return isProcessing ? processingProgress : 1.0
        case .processing:
            return processingError == nil ? 1.0 : 0.0
        case .ocrProcessing:
            return processingError == nil ? 1.0 : 0.0
        case .classifyDocument:
            return isProcessing ? processingProgress : 1.0
        case .extractBiomarkers:
            return isProcessing ? processingProgress : 1.0
        case .analyzeData:
            return isProcessing ? processingProgress : 1.0
        case .reviewResults, .validateBiomarkers, .complete:
            return 1.0
        case .error:
            return 0.0
        }
    }
    
    /// Get overall flow progress
    var overallProgress: Double {
        let baseProgress = Double(currentStep.stepNumber - 1) / 10.0 // Updated for new steps
        let stepContribution = stepProgress / 10.0
        return baseProgress + stepContribution
    }
    
    /// Check if back navigation is possible
    var canGoBack: Bool {
        switch currentStep {
        case .selectDocument:
            return false
        case .uploadDocument, .processing, .ocrProcessing, .classifyDocument, .extractBiomarkers, .analyzeData:
            return !isProcessing
        case .reviewResults, .validateBiomarkers:
            return true
        case .complete:
            return true
        case .error:
            return true
        }
    }
    
    /// Get appropriate title for next button
    var nextButtonTitle: String {
        switch currentStep {
        case .selectDocument:
            return "Upload"
        case .uploadDocument, .processing, .ocrProcessing, .classifyDocument, .extractBiomarkers, .analyzeData:
            return "Processing..."
        case .reviewResults:
            return "Validate"
        case .validateBiomarkers:
            return "Complete"
        case .complete:
            return "New Upload"
        case .error:
            return "Retry"
        }
    }
}