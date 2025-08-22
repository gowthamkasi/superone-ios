//
//  SmartOCRService.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import Foundation
import UIKit
import Vision
import VisionKit
import Network
import Combine

/// Intelligent OCR service that routes between backend AWS Textract and local Vision framework
@MainActor
final class SmartOCRService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = SmartOCRService()
    
    // MARK: - Published Properties
    @Published private(set) var currentOCRMethod: OCRMethod = .automatic
    @Published private(set) var isProcessing = false
    @Published private(set) var ocrProgress: Double = 0.0
    @Published private(set) var lastSmartOCRResult: SmartOCRResult?
    @Published private(set) var ocrError: OCRError?
    
    // MARK: - Private Properties
    private let labReportAPIService = LabReportAPIService.shared
    private let healthAnalysisAPIService = HealthAnalysisAPIService.shared
    private let visionOCRService = VisionOCRService()
    private let networkMonitor = NetworkMonitor.shared
    private let healthcheck = HealthCheckService.shared
    
    // OCR routing configuration - Backend only
    private var preferBackendOCR: Bool = true
    private var allowFallbackToLocal: Bool = false  // Disable local fallback - backend only
    private var fallbackTimeout: TimeInterval = 60.0  // Longer timeout for backend processing
    private var qualityThreshold: Double = 0.8
    
    // Performance tracking
    private var ocrPerformanceMetrics: [OCRPerformanceMetric] = []
    private var backendOCRFailureCount: Int = 0
    private var localOCRFailureCount: Int = 0
    private let maxFailuresBeforeSwitch: Int = 3
    
    // MARK: - Initialization
    
    private init() {
        setupConfiguration()
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Process document with smart OCR routing
    /// - Parameters:
    ///   - document: The lab report document to process
    ///   - preferredMethod: Optional preferred OCR method
    /// - Returns: OCR processing result
    func processDocument(
        _ document: LabReportDocument,
        preferredMethod: OCRMethod? = nil
    ) async throws -> SmartOCRResult {
        
        isProcessing = true
        ocrProgress = 0.0
        ocrError = nil
        
        let startTime = Date()
        let chosenMethod: OCRMethod
        if let preferredMethod = preferredMethod {
            chosenMethod = preferredMethod
        } else {
            chosenMethod = await determineOptimalOCRMethod(for: document)
        }
        currentOCRMethod = chosenMethod
        
        defer {
            isProcessing = false
            ocrProgress = 1.0
        }
        
        do {
            let result = try await performOCR(document: document, method: chosenMethod)
            
            // Track performance metrics
            let metric = OCRPerformanceMetric(
                method: chosenMethod,
                documentSize: document.fileSize,
                processingTime: Date().timeIntervalSince(startTime),
                success: true,
                qualityScore: result.qualityScore,
                extractedTextLength: result.extractedText.count,
                biomarkerCount: result.extractedBiomarkers.count
            )
            addPerformanceMetric(metric)
            
            lastSmartOCRResult = result
            resetFailureCount(for: chosenMethod)
            
            return result
            
        } catch {
            // Track failure
            incrementFailureCount(for: chosenMethod)
            
            let metric = OCRPerformanceMetric(
                method: chosenMethod,
                documentSize: document.fileSize,
                processingTime: Date().timeIntervalSince(startTime),
                success: false,
                qualityScore: 0.0,
                extractedTextLength: 0,
                biomarkerCount: 0
            )
            addPerformanceMetric(metric)
            
            // No fallback - backend-only processing
            ocrError = OCRError.backendProcessingFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Configure OCR routing preferences
    /// - Parameters:
    ///   - preferBackend: Whether to prefer backend OCR
    ///   - allowFallback: Whether to allow fallback to local Vision
    ///   - timeout: Timeout for backend OCR before fallback
    ///   - qualityThreshold: Minimum quality score to accept results
    func configureOCRRouting(
        preferBackend: Bool,
        allowFallback: Bool,
        timeout: TimeInterval,
        qualityThreshold: Double
    ) {
        self.preferBackendOCR = preferBackend
        self.allowFallbackToLocal = allowFallback
        self.fallbackTimeout = timeout
        self.qualityThreshold = qualityThreshold
        
        // Save to UserDefaults
        UserDefaults.standard.set(preferBackend, forKey: "preferBackendOCR")
        UserDefaults.standard.set(allowFallback, forKey: "allowFallbackToLocal")
        UserDefaults.standard.set(timeout, forKey: "fallbackTimeout")
        UserDefaults.standard.set(qualityThreshold, forKey: "qualityThreshold")
    }
    
    /// Get OCR performance analytics
    /// - Returns: Performance analytics data
    func getPerformanceAnalytics() -> OCRPerformanceAnalytics {
        let recentMetrics = Array(ocrPerformanceMetrics.suffix(50)) // Last 50 operations
        
        let backendMetrics = recentMetrics.filter { $0.method == .backend }
        let localMetrics = recentMetrics.filter { $0.method == .local }
        
        return OCRPerformanceAnalytics(
            totalOperations: recentMetrics.count,
            backendOperations: backendMetrics.count,
            localOperations: localMetrics.count,
            backendSuccessRate: calculateSuccessRate(backendMetrics),
            localSuccessRate: calculateSuccessRate(localMetrics),
            averageBackendTime: calculateAverageTime(backendMetrics),
            averageLocalTime: calculateAverageTime(localMetrics),
            averageBackendQuality: calculateAverageQuality(backendMetrics),
            averageLocalQuality: calculateAverageQuality(localMetrics),
            backendFailureCount: backendOCRFailureCount,
            localFailureCount: localOCRFailureCount,
            recommendedMethod: getRecommendedMethod()
        )
    }
    
    /// Force a specific OCR method for testing
    /// - Parameter method: The OCR method to use
    func forceOCRMethod(_ method: OCRMethod) {
        currentOCRMethod = method
        preferBackendOCR = (method == .backend)
    }
    
    /// Reset performance tracking
    func resetPerformanceTracking() {
        ocrPerformanceMetrics.removeAll()
        backendOCRFailureCount = 0
        localOCRFailureCount = 0
    }
    
    // MARK: - Private Implementation
    
    private func setupConfiguration() {
        // Force backend-only configuration - no user preferences override
        preferBackendOCR = true
        allowFallbackToLocal = false  // Force backend-only processing
        fallbackTimeout = 60.0  // Longer timeout for AWS Textract processing
        qualityThreshold = 0.8
        
        // Save the backend-only configuration
        UserDefaults.standard.set(true, forKey: "preferBackendOCR")
        UserDefaults.standard.set(false, forKey: "allowFallbackToLocal")
        UserDefaults.standard.set(60.0, forKey: "fallbackTimeout")
        UserDefaults.standard.set(0.8, forKey: "qualityThreshold")
    }
    
    private func setupNetworkMonitoring() {
        // Monitor network changes to adjust OCR routing
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged),
            name: .networkStatusChanged,
            object: nil
        )
    }
    
    @objc private func networkStatusChanged() {
        // Reevaluate OCR method preference based on network status
        Task { @MainActor in
            if !networkMonitor.isConnected {
                currentOCRMethod = .local
            } else if networkMonitor.isConnected && preferBackendOCR {
                currentOCRMethod = .backend
            }
        }
    }
    
    private func determineOptimalOCRMethod(for document: LabReportDocument) async -> OCRMethod {
        // Always use backend OCR - no local fallback
        return .backend
    }
    
    private func analyzeDocumentForOCR(_ document: LabReportDocument) -> DocumentOCRFactors {
        var factors = DocumentOCRFactors()
        
        // File size consideration (larger files may benefit from backend processing)
        factors.sizeScore = min(1.0, Double(document.fileSize) / 5_000_000) // 5MB max
        
        // File type consideration
        switch document.mimeType {
        case "application/pdf":
            factors.typeScore = 0.9 // PDFs work well with backend
        case "image/jpeg", "image/png":
            factors.typeScore = 0.7 // Images work with both
        case "image/heic":
            factors.typeScore = 0.5 // HEIC might need local processing
        default:
            factors.typeScore = 0.6
        }
        
        // Quality consideration (would need image analysis)
        factors.qualityScore = 0.8 // Default assumption
        
        return factors
    }
    
    private func calculateBackendOCRScore(
        documentFactors: DocumentOCRFactors,
        networkFactor: Double
    ) -> Double {
        let recentMetrics = ocrPerformanceMetrics.suffix(10)
        let backendMetrics = recentMetrics.filter { $0.method == .backend && $0.success }
        
        let historicalScore = backendMetrics.isEmpty ? 0.5 : 
            backendMetrics.map { $0.qualityScore }.reduce(0, +) / Double(backendMetrics.count)
        
        // Weighted combination of factors
        return (documentFactors.sizeScore * 0.3 +
                documentFactors.typeScore * 0.2 +
                documentFactors.qualityScore * 0.2 +
                networkFactor * 0.2 +
                historicalScore * 0.1)
    }
    
    private func performOCR(document: LabReportDocument, method: OCRMethod) async throws -> SmartOCRResult {
        ocrProgress = 0.1
        
        switch method {
        case .backend, .awsTextract, .cloud, .automatic:
            return try await performBackendOCR(document: document)
        case .local, .visionFramework:
            throw OCRError.backendUnavailable
        case .hybrid:
            // Hybrid now means backend-only (no local fallback)
            return try await performBackendOCR(document: document)
        }
    }
    
    private func performBackendOCR(document: LabReportDocument) async throws -> SmartOCRResult {
        ocrProgress = 0.2
        
        // Upload document and get OCR processing
        let uploadResult = try await labReportAPIService.uploadDocument(document)
        ocrProgress = 0.6
        
        // Monitor processing status
        var attempts = 0
        let maxAttempts = Int(fallbackTimeout / 2) // Check every 2 seconds
        
        while attempts < maxAttempts {
            let status = try await labReportAPIService.getProcessingStatus(for: uploadResult.labReportId)
            ocrProgress = 0.6 + (0.3 * Double(attempts) / Double(maxAttempts))
            
            switch status.status {
            case .completed:
                // Parse real OCR results from backend response
                guard let ocrResult = status.ocrResult else {
                    throw OCRError.noTextDetected
                }
                
                // Use biomarkers directly from backend (already in correct format)
                let extractedBiomarkers = ocrResult.biomarkers ?? []
                
                return SmartOCRResult(
                    method: .backend,
                    extractedText: ocrResult.extractedText,
                    extractedBiomarkers: extractedBiomarkers,
                    confidence: ocrResult.confidence,
                    processingTime: Date().timeIntervalSince(uploadResult.timestamp),
                    qualityScore: calculateQualityScore(
                        textLength: ocrResult.extractedText.count,
                        biomarkerCount: extractedBiomarkers.count
                    ),
                    metadata: SmartOCRResultMetadata(
                        documentType: status.documentType,
                        pageCount: 1,
                        resolution: nil,
                        fileSize: document.fileSize
                    )
                )
                
            case .failed:
                throw OCRError.backendProcessingFailed(status.errorMessage ?? "Unknown error")
                
            case .processing, .analyzing:
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                attempts += 1
                continue
                
            default:
                throw OCRError.unexpectedStatus(status.status.rawValue)
            }
        }
        
        throw OCRError.timeoutExceeded(fallbackTimeout)
    }
    
    private func performLocalOCR(document: LabReportDocument) async throws -> SmartOCRResult {
        ocrProgress = 0.3
        
        guard let image = createImage(from: document) else {
            throw OCRError.invalidImageData
        }
        
        ocrProgress = 0.5
        
        // Use Vision framework for text recognition
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        try handler.perform([request])
        
        ocrProgress = 0.8
        
        guard let observations = request.results else {
            throw OCRError.noTextDetected
        }
        
        // Extract text
        let extractedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")
        
        ocrProgress = 0.9
        
        // Extract biomarkers using local pattern matching
        let biomarkers = await visionOCRService.extractBiomarkers(from: extractedText)
        
        let result = SmartOCRResult(
            method: .local,
            extractedText: extractedText,
            extractedBiomarkers: biomarkers,
            confidence: calculateAverageConfidence(observations),
            processingTime: 0, // Set by caller
            qualityScore: calculateQualityScore(
                textLength: extractedText.count,
                biomarkerCount: biomarkers.count
            ),
            metadata: SmartOCRResultMetadata(
                documentType: detectDocumentType(from: extractedText),
                pageCount: 1,
                resolution: Int(image.size.width * image.scale),
                fileSize: document.fileSize
            )
        )
        
        return result
    }
    
    private func performHybridOCR(document: LabReportDocument) async throws -> SmartOCRResult {
        // Hybrid is now backend-only processing
        return try await performBackendOCR(document: document)
    }
    
    private func performFallbackOCR(document: LabReportDocument, originalError: Error) async throws -> SmartOCRResult {
        // No fallback - throw the original backend error
        throw OCRError.backendProcessingFailed("Backend OCR failed: \(originalError.localizedDescription)")
    }
    
    // MARK: - Helper Methods
    
    
    private func createImage(from document: LabReportDocument) -> UIImage? {
        guard let data = document.data else { return nil }
        
        if document.mimeType == "application/pdf" {
            // Convert PDF to image
            return convertPDFToImage(data: data)
        } else {
            return UIImage(data: data)
        }
    }
    
    private func convertPDFToImage(data: Data) -> UIImage? {
        guard let provider = CGDataProvider(data: data as CFData),
              let pdfDoc = CGPDFDocument(provider),
              let pdfPage = pdfDoc.page(at: 1) else {
            return nil
        }
        
        let pageRect = pdfPage.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            
            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            ctx.cgContext.drawPDFPage(pdfPage)
        }
    }
    
    private func calculateAverageConfidence(_ observations: [VNRecognizedTextObservation]) -> Double {
        guard !observations.isEmpty else { return 0.0 }
        
        let totalConfidence = observations.compactMap { observation in
            observation.topCandidates(1).first?.confidence
        }.reduce(0, +)
        
        return Double(totalConfidence) / Double(observations.count)
    }
    
    private func calculateQualityScore(textLength: Int, biomarkerCount: Int) -> Double {
        // Simple quality scoring based on extracted content
        let textScore = min(1.0, Double(textLength) / 1000.0) * 0.6
        let biomarkerScore = min(1.0, Double(biomarkerCount) / 10.0) * 0.4
        return textScore + biomarkerScore
    }
    
    private func detectDocumentType(from text: String) -> String? {
        let lowercaseText = text.lowercased()
        
        if lowercaseText.contains("complete blood count") || lowercaseText.contains("cbc") {
            return "Complete Blood Count"
        } else if lowercaseText.contains("lipid") || lowercaseText.contains("cholesterol") {
            return "Lipid Panel"
        } else if lowercaseText.contains("metabolic") || lowercaseText.contains("cmp") {
            return "Comprehensive Metabolic Panel"
        } else if lowercaseText.contains("thyroid") || lowercaseText.contains("tsh") {
            return "Thyroid Function Test"
        }
        
        return "Lab Report"
    }
    
    private func addPerformanceMetric(_ metric: OCRPerformanceMetric) {
        ocrPerformanceMetrics.append(metric)
        
        // Keep only recent metrics (last 100)
        if ocrPerformanceMetrics.count > 100 {
            ocrPerformanceMetrics.removeFirst()
        }
    }
    
    private func incrementFailureCount(for method: OCRMethod) {
        switch method {
        case .backend, .awsTextract, .cloud:
            backendOCRFailureCount += 1
        case .local, .visionFramework:
            localOCRFailureCount += 1
        case .hybrid:
            backendOCRFailureCount += 1
            localOCRFailureCount += 1
        case .automatic:
            break
        }
    }
    
    private func resetFailureCount(for method: OCRMethod) {
        switch method {
        case .backend, .awsTextract, .cloud:
            backendOCRFailureCount = 0
        case .local, .visionFramework:
            localOCRFailureCount = 0
        case .hybrid:
            backendOCRFailureCount = 0
            localOCRFailureCount = 0
        case .automatic:
            break
        }
    }
    
    private func calculateSuccessRate(_ metrics: [OCRPerformanceMetric]) -> Double {
        guard !metrics.isEmpty else { return 0.0 }
        let successCount = metrics.filter { $0.success }.count
        return Double(successCount) / Double(metrics.count)
    }
    
    private func calculateAverageTime(_ metrics: [OCRPerformanceMetric]) -> TimeInterval {
        guard !metrics.isEmpty else { return 0.0 }
        let totalTime = metrics.map { $0.processingTime }.reduce(0, +)
        return totalTime / Double(metrics.count)
    }
    
    private func calculateAverageQuality(_ metrics: [OCRPerformanceMetric]) -> Double {
        guard !metrics.isEmpty else { return 0.0 }
        let totalQuality = metrics.map { $0.qualityScore }.reduce(0, +)
        return totalQuality / Double(metrics.count)
    }
    
    private func getRecommendedMethod() -> OCRMethod {
        // Always recommend backend - no local processing
        return .backend
    }
}

// MARK: - Supporting Types

// Note: OCRMethod enum is defined in UploadModels.swift to avoid conflicts

struct SmartOCRResult {
    let method: OCRMethod
    let extractedText: String
    let extractedBiomarkers: [ExtractedBiomarker]
    let confidence: Double
    let processingTime: TimeInterval
    let qualityScore: Double
    let metadata: SmartOCRResultMetadata
    
    // Fallback information
    var isFallback: Bool = false
    var fallbackReason: String?
}

struct SmartOCRResultMetadata {
    let documentType: String?
    let pageCount: Int
    let resolution: Int?
    let fileSize: Int64
}

struct OCRPerformanceMetric {
    let method: OCRMethod
    let documentSize: Int64
    let processingTime: TimeInterval
    let success: Bool
    let qualityScore: Double
    let extractedTextLength: Int
    let biomarkerCount: Int
    let timestamp: Date = Date()
}

struct OCRPerformanceAnalytics {
    let totalOperations: Int
    let backendOperations: Int
    let localOperations: Int
    let backendSuccessRate: Double
    let localSuccessRate: Double
    let averageBackendTime: TimeInterval
    let averageLocalTime: TimeInterval
    let averageBackendQuality: Double
    let averageLocalQuality: Double
    let backendFailureCount: Int
    let localFailureCount: Int
    let recommendedMethod: OCRMethod
}

struct DocumentOCRFactors {
    var sizeScore: Double = 0.0
    var typeScore: Double = 0.0
    var qualityScore: Double = 0.0
}

enum OCRError: Error, LocalizedError {
    case processingFailed(String)
    case backendProcessingFailed(String)
    case invalidImageData
    case noTextDetected
    case timeoutExceeded(TimeInterval)
    case unexpectedStatus(String)
    case networkUnavailable
    case backendUnavailable
    
    nonisolated var errorDescription: String? {
        switch self {
        case .processingFailed(let message):
            return "OCR processing failed: \(message)"
        case .backendProcessingFailed(let message):
            return "Backend OCR failed: \(message)"
        case .invalidImageData:
            return "Invalid image data for OCR processing"
        case .noTextDetected:
            return "No text detected in the document"
        case .timeoutExceeded(let timeout):
            return "OCR processing timed out after \(timeout) seconds"
        case .unexpectedStatus(let status):
            return "Unexpected processing status: \(status)"
        case .networkUnavailable:
            return "Network connection required for cloud OCR"
        case .backendUnavailable:
            return "Cloud OCR service is currently unavailable"
        }
    }
}

// MARK: - Health Check Service

final class HealthCheckService: ObservableObject {
    static let shared = HealthCheckService()
    
    private init() {}
    
    func isBackendHealthy() async -> Bool {
        // Implementation would check backend health endpoint
        // For now, return true
        return true
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}