//
//  VisionOCRService.swift
//  SuperOne
//
//  Created by Claude Code on 7/27/25.
//

import Foundation
import Vision
import UIKit
import SwiftUI
import Combine

// MARK: - Vision OCR Service
@MainActor
final class VisionOCRService: ObservableObject, Sendable {
    
    // MARK: - Published Properties
    @Published private(set) var isProcessing = false
    @Published private(set) var progress: Double = 0.0
    @Published private(set) var currentOperation: String = ""
    
    // MARK: - Private Properties
    private let imageProcessor = ImageProcessor()
    private let textProcessor = TextProcessor()
    private var currentRequest: VNRequest?
    
    // MARK: - Configuration
    struct OCRConfiguration: Codable, Sendable {
        let recognitionLevel: VNRequestTextRecognitionLevel
        let recognitionLanguages: [String]
        let usesLanguageCorrection: Bool
        let minimumTextHeight: Float
        let customWords: [String]
        let enableAutomaticLocalization: Bool
        let enableRevision: Bool
        
        // Custom coding to handle VNRequestTextRecognitionLevel
        nonisolated enum CodingKeys: String, CodingKey {
            case recognitionLevel, recognitionLanguages, usesLanguageCorrection, minimumTextHeight, customWords, enableAutomaticLocalization, enableRevision
        }
        
        nonisolated enum RecognitionLevelCodable: String, Codable {
            case accurate = "accurate"
            case fast = "fast"
            
            var vnRecognitionLevel: VNRequestTextRecognitionLevel {
                switch self {
                case .accurate: return .accurate
                case .fast: return .fast
                }
            }
            
            init(_ level: VNRequestTextRecognitionLevel) {
                switch level {
                case .accurate: self = .accurate
                case .fast: self = .fast
                @unknown default: self = .accurate
                }
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(RecognitionLevelCodable(recognitionLevel), forKey: .recognitionLevel)
            try container.encode(recognitionLanguages, forKey: .recognitionLanguages)
            try container.encode(usesLanguageCorrection, forKey: .usesLanguageCorrection)
            try container.encode(minimumTextHeight, forKey: .minimumTextHeight)
            try container.encode(customWords, forKey: .customWords)
            try container.encode(enableAutomaticLocalization, forKey: .enableAutomaticLocalization)
            try container.encode(enableRevision, forKey: .enableRevision)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let levelCodable = try container.decode(RecognitionLevelCodable.self, forKey: .recognitionLevel)
            self.recognitionLevel = levelCodable.vnRecognitionLevel
            self.recognitionLanguages = try container.decode([String].self, forKey: .recognitionLanguages)
            self.usesLanguageCorrection = try container.decode(Bool.self, forKey: .usesLanguageCorrection)
            self.minimumTextHeight = try container.decode(Float.self, forKey: .minimumTextHeight)
            self.customWords = try container.decode([String].self, forKey: .customWords)
            self.enableAutomaticLocalization = try container.decode(Bool.self, forKey: .enableAutomaticLocalization)
            self.enableRevision = try container.decode(Bool.self, forKey: .enableRevision)
        }
        
        init(recognitionLevel: VNRequestTextRecognitionLevel, recognitionLanguages: [String], usesLanguageCorrection: Bool, minimumTextHeight: Float, customWords: [String], enableAutomaticLocalization: Bool, enableRevision: Bool) {
            self.recognitionLevel = recognitionLevel
            self.recognitionLanguages = recognitionLanguages
            self.usesLanguageCorrection = usesLanguageCorrection
            self.minimumTextHeight = minimumTextHeight
            self.customWords = customWords
            self.enableAutomaticLocalization = enableAutomaticLocalization
            self.enableRevision = enableRevision
        }
        
        static let `default` = OCRConfiguration(
            recognitionLevel: .accurate,
            recognitionLanguages: ["en-US"],
            usesLanguageCorrection: true,
            minimumTextHeight: 0.01,
            customWords: [],
            enableAutomaticLocalization: true,
            enableRevision: true
        )
        
        static let medical = OCRConfiguration(
            recognitionLevel: .accurate,
            recognitionLanguages: ["en-US"],
            usesLanguageCorrection: true,
            minimumTextHeight: 0.008,
            customWords: MedicalTerms.commonTerms,
            enableAutomaticLocalization: true,
            enableRevision: true
        )
        
        static let fast = OCRConfiguration(
            recognitionLevel: .fast,
            recognitionLanguages: ["en-US"],
            usesLanguageCorrection: false,
            minimumTextHeight: 0.02,
            customWords: [],
            enableAutomaticLocalization: false,
            enableRevision: false
        )
    }
    
    // MARK: - Public Methods
    
    /// Process image using Vision framework OCR
    func processImage(_ image: UIImage, configuration: OCRConfiguration = .medical) async throws -> OCRResult {
        updateProgress(0.1, operation: "Initializing OCR processing")
        
        guard let cgImage = image.cgImage else {
            throw VisionOCRError.invalidImage
        }
        
        // Preprocess image for better OCR results
        updateProgress(0.2, operation: "Preprocessing image")
        let preprocessedImage = try await imageProcessor.enhanceForOCR(cgImage)
        
        // Create and configure text recognition request
        updateProgress(0.3, operation: "Configuring text recognition")
        let request = createTextRecognitionRequest(configuration: configuration)
        
        // Perform OCR
        updateProgress(0.5, operation: "Extracting text from image")
        let observations = try await performTextRecognition(
            image: preprocessedImage,
            request: request
        )
        
        // Process and clean extracted text
        updateProgress(0.8, operation: "Processing extracted text")
        let processedText = await textProcessor.processExtractedText(observations)
        
        // Create final result
        updateProgress(1.0, operation: "Finalizing results")
        let result = OCRResult(
            text: processedText.cleanedText,
            confidence: processedText.averageConfidence,
            language: nil,
            boundingBoxes: [],
            processingTime: Date().timeIntervalSince(Date()),
            method: .visionFramework,
            imageWidth: Int(image.size.width),
            imageHeight: Int(image.size.height),
            errorMessage: nil
        )
        
        updateProgress(0.0, operation: "")
        return result
    }
    
    /// Process multiple images in batch
    func processBatch(_ images: [UIImage], configuration: OCRConfiguration = .medical) async throws -> [OCRResult] {
        updateProgress(0.0, operation: "Starting batch processing")
        
        var results: [OCRResult] = []
        let totalImages = images.count
        
        for (index, image) in images.enumerated() {
            let progressBase = Double(index) / Double(totalImages)
            updateProgress(progressBase, operation: "Processing image \(index + 1) of \(totalImages)")
            
            do {
                let result = try await processImage(image, configuration: configuration)
                results.append(result)
            } catch {
                // Create error result for failed image
                let errorResult = OCRResult(
                    text: "",
                    confidence: 0.0,
                    language: nil,
                    boundingBoxes: [],
                    processingTime: 0.0,
                    method: .visionFramework,
                    imageWidth: Int(image.size.width),
                    imageHeight: Int(image.size.height),
                    errorMessage: error.localizedDescription
                )
                results.append(errorResult)
            }
        }
        
        updateProgress(0.0, operation: "")
        return results
    }
    
    /// Check if Vision framework is available and capable
    nonisolated func checkCapabilities() -> VisionCapabilities {
        let isAvailable = (try? VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision2).contains("en-US")) ?? false
        
        return VisionCapabilities(
            isAvailable: isAvailable,
            supportedLanguages: (try? VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision2)) ?? [],
            supportsAccurateRecognition: true,
            supportsFastRecognition: true,
            maxImageWidth: 4096,
            maxImageHeight: 4096,
            supportedFormats: ["JPEG", "PNG", "HEIC", "TIFF"]
        )
    }
    
    // MARK: - Private Methods
    
    private func createTextRecognitionRequest(configuration: OCRConfiguration) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        
        // Configure recognition level
        request.recognitionLevel = configuration.recognitionLevel
        
        // Set recognition languages
        request.recognitionLanguages = configuration.recognitionLanguages
        
        // Configure language correction
        request.usesLanguageCorrection = configuration.usesLanguageCorrection
        
        // Set minimum text height
        request.minimumTextHeight = configuration.minimumTextHeight
        
        // Add custom words for better medical term recognition
        if !configuration.customWords.isEmpty {
            request.customWords = configuration.customWords
        }
        
        // Configure automatic language detection
        request.automaticallyDetectsLanguage = configuration.enableAutomaticLocalization
        
        // Set revision for latest features
        if configuration.enableRevision {
            request.revision = VNRecognizeTextRequestRevision3
        }
        
        return request
    }
    
    private nonisolated func performTextRecognition(image: CGImage, request: VNRecognizeTextRequest) async throws -> [SendableTextObservation] {
        return try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            // Create a new request with completion handler since completionHandler is read-only
            let recognitionRequest = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: VisionOCRError.recognitionFailed(error.localizedDescription))
                } else {
                    let textRequest = request as! VNRecognizeTextRequest
                    let observations = textRequest.results as? [VNRecognizedTextObservation] ?? []
                    let sendableObservations = observations.map { SendableTextObservation(from: $0) }
                    continuation.resume(returning: sendableObservations)
                }
            }
            
            // Copy configuration from the original request
            recognitionRequest.recognitionLevel = request.recognitionLevel
            recognitionRequest.recognitionLanguages = request.recognitionLanguages
            recognitionRequest.usesLanguageCorrection = request.usesLanguageCorrection
            recognitionRequest.minimumTextHeight = request.minimumTextHeight
            recognitionRequest.customWords = request.customWords
            recognitionRequest.automaticallyDetectsLanguage = request.automaticallyDetectsLanguage
            recognitionRequest.revision = request.revision
            
            do {
                try handler.perform([recognitionRequest])
            } catch {
                continuation.resume(throwing: VisionOCRError.requestFailed(error.localizedDescription))
            }
        }
    }
    
    private func updateProgress(_ progress: Double, operation: String) {
        Task { @MainActor in
            self.progress = progress
            self.currentOperation = operation
            self.isProcessing = progress > 0 && progress < 1.0
        }
    }
    
    private func getVisionFrameworkVersion() -> String {
        return "iOS Vision Framework \(UIDevice.current.systemVersion)"
    }
    
    /// Extract biomarkers from text using pattern matching
    func extractBiomarkers(from text: String) async -> [ExtractedBiomarker] {
        let biomarkerService = BiomarkerExtractionService()
        do {
            let result = try await biomarkerService.extractBiomarkers(from: text)
            return result.biomarkers
        } catch {
            return []
        }
    }
}

// MARK: - OCR Result Consolidation
// OCRResult is now defined in BackendModels.swift to avoid duplication
// Use the consolidated version with proper Sendable conformance and comprehensive properties

// MARK: - Text Block
struct TextBlock: Codable, Identifiable, Sendable {
    let id: String
    let text: String
    let confidence: Double
    let boundingBox: BoundingBox
    let recognizedLanguage: String?
    let isTitle: Bool
    let fontSize: Double?
    
    nonisolated init(
        id: String = UUID().uuidString,
        text: String,
        confidence: Double,
        boundingBox: BoundingBox,
        recognizedLanguage: String? = nil,
        isTitle: Bool = false,
        fontSize: Double? = nil
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.recognizedLanguage = recognizedLanguage
        self.isTitle = isTitle
        self.fontSize = fontSize
    }
}

// MARK: - OCR Metadata
struct OCRMetadata: Codable, Sendable {
    let ocrVersion: String
    let configuration: VisionOCRService.OCRConfiguration
    let imageQuality: ImageQualityAssessment
    let processingDevice: String
    let timestamp: Date
    
    init(ocrVersion: String, configuration: VisionOCRService.OCRConfiguration, imageQuality: ImageQualityAssessment, processingDevice: String) {
        self.ocrVersion = ocrVersion
        self.configuration = configuration
        self.imageQuality = imageQuality
        self.processingDevice = processingDevice
        self.timestamp = Date()
    }
}

// MARK: - Vision Capabilities
struct VisionCapabilities: Codable, Sendable {
    let isAvailable: Bool
    let supportedLanguages: [String]
    let supportsAccurateRecognition: Bool
    let supportsFastRecognition: Bool
    let maxImageWidth: Int
    let maxImageHeight: Int
    let supportedFormats: [String]
    
    var formattedCapabilities: String {
        var capabilities: [String] = []
        
        if supportsAccurateRecognition {
            capabilities.append("Accurate OCR")
        }
        if supportsFastRecognition {
            capabilities.append("Fast OCR")
        }
        capabilities.append("\(supportedLanguages.count) languages")
        capabilities.append("Max: \(maxImageWidth)x\(maxImageHeight)")
        
        return capabilities.joined(separator: ", ")
    }
}

// MARK: - Vision OCR Errors
enum VisionOCRError: Error, LocalizedError {
    case invalidImage
    case recognitionFailed(String)
    case requestFailed(String)
    case processingTimeout
    case insufficientMemory
    case unsupportedLanguage(String)
    case imageQualityTooLow
    case imageSizeExceeded
    
    nonisolated var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image is invalid or corrupted"
        case .recognitionFailed(let message):
            return "Text recognition failed: \(message)"
        case .requestFailed(let message):
            return "OCR request failed: \(message)"
        case .processingTimeout:
            return "OCR processing timed out"
        case .insufficientMemory:
            return "Insufficient memory for OCR processing"
        case .unsupportedLanguage(let language):
            return "Language '\(language)' is not supported"
        case .imageQualityTooLow:
            return "Image quality is too low for reliable OCR"
        case .imageSizeExceeded:
            return "Image size exceeds maximum supported dimensions"
        }
    }
    
    nonisolated var recoverySuggestion: String? {
        switch self {
        case .invalidImage:
            return "Please select a different image"
        case .recognitionFailed, .requestFailed:
            return "Try again with a clearer image or different settings"
        case .processingTimeout:
            return "Try processing a smaller image or use fast recognition mode"
        case .insufficientMemory:
            return "Close other apps and try again"
        case .unsupportedLanguage:
            return "Change the recognition language to a supported one"
        case .imageQualityTooLow:
            return "Take a clearer photo or adjust lighting conditions"
        case .imageSizeExceeded:
            return "Reduce the image size and try again"
        }
    }
}

// MARK: - Image Processor
private actor ImageProcessor {
    
    nonisolated func enhanceForOCR(_ image: CGImage) async throws -> CGImage {
        // Apply image enhancements for better OCR
        guard let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            throw VisionOCRError.invalidImage
        }
        
        // Convert to grayscale for better text recognition
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        
        guard let enhancedImage = context.makeImage() else {
            throw VisionOCRError.invalidImage
        }
        
        return enhancedImage
    }
    
    nonisolated func assessImageQuality(_ image: CGImage) async throws -> ImageQualityAssessment {
        let width = image.width
        let height = image.height
        let pixelCount = width * height
        
        // Basic quality assessment
        let resolution = Double(pixelCount) / 1_000_000 // Megapixels
        let aspectRatio = Double(width) / Double(height)
        
        var qualityScore = 0.0
        var issues: [String] = []
        
        // Resolution check
        if resolution >= 2.0 {
            qualityScore += 0.4
        } else if resolution >= 1.0 {
            qualityScore += 0.3
        } else {
            qualityScore += 0.1
            issues.append("Low resolution")
        }
        
        // Aspect ratio check (avoid extremely elongated images)
        if aspectRatio >= 0.5 && aspectRatio <= 2.0 {
            qualityScore += 0.2
        } else {
            issues.append("Unusual aspect ratio")
        }
        
        // Size check
        if width >= 1000 && height >= 1000 {
            qualityScore += 0.2
        } else if width >= 500 && height >= 500 {
            qualityScore += 0.1
        } else {
            issues.append("Image too small")
        }
        
        // Basic sharpness estimation (simplified)
        qualityScore += 0.2 // Placeholder for actual sharpness analysis
        
        let quality: ImageQuality = {
            if qualityScore >= 0.8 { return .excellent }
            else if qualityScore >= 0.6 { return .good }
            else if qualityScore >= 0.4 { return .fair }
            else { return .poor }
        }()
        
        return ImageQualityAssessment(
            overallQuality: quality,
            score: qualityScore,
            resolution: resolution,
            imageWidth: width,
            imageHeight: height,
            issues: issues,
            recommendations: generateRecommendations(for: issues)
        )
    }
    
    private nonisolated func generateRecommendations(for issues: [String]) -> [String] {
        var recommendations: [String] = []
        
        for issue in issues {
            switch issue {
            case "Low resolution":
                recommendations.append("Take a higher resolution photo")
            case "Unusual aspect ratio":
                recommendations.append("Crop the image to focus on the document")
            case "Image too small":
                recommendations.append("Move closer or use a higher resolution camera")
            default:
                break
            }
        }
        
        if recommendations.isEmpty {
            recommendations.append("Image quality is sufficient for OCR processing")
        }
        
        return recommendations
    }
}

// MARK: - Text Processor
private actor TextProcessor {
    
    nonisolated func processExtractedText(_ observations: [SendableTextObservation]) async -> ProcessedTextResult {
        
        var allText: [String] = []
        var textBlocks: [TextBlock] = []
        var confidences: [Double] = []
        
        for observation in observations {
            let text = observation.text
            let confidence = observation.confidence
            
            // Convert VisionKit bounding box to our format
            let visionBox = observation.boundingBox
            let boundingBox = await MainActor.run {
                BoundingBox(
                    x: Double(visionBox.origin.x),
                    y: Double(visionBox.origin.y),
                    width: Double(visionBox.size.width),
                    height: Double(visionBox.size.height)
                )
            }
            
            let textBlock = TextBlock(
                text: text,
                confidence: confidence,
                boundingBox: boundingBox,
                recognizedLanguage: "en-US",
                isTitle: isLikelyTitle(text),
                fontSize: estimateFontSize(from: visionBox)
            )
            
            textBlocks.append(textBlock)
            allText.append(text)
            confidences.append(confidence)
        }
        
        let cleanedText = cleanAndFormatText(allText)
        let averageConfidence = confidences.isEmpty ? 0.0 : confidences.reduce(0, +) / Double(confidences.count)
        
        return ProcessedTextResult(
            cleanedText: cleanedText,
            averageConfidence: averageConfidence,
            textBlocks: textBlocks
        )
    }
    
    private nonisolated func cleanAndFormatText(_ textArray: [String]) -> String {
        let combinedText = textArray.joined(separator: "\n")
        
        // Basic text cleaning
        var cleanedText = combinedText
            .replacingOccurrences(of: "\n\n+", with: "\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove artifacts common in medical documents
        cleanedText = cleanedText
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "[\\s]*\\|[\\s]*", with: " | ", options: .regularExpression)
        
        return cleanedText
    }
    
    private nonisolated func isLikelyTitle(_ text: String) -> Bool {
        // Simple heuristic for title detection
        let uppercaseRatio = Double(text.filter { $0.isUppercase }.count) / Double(text.count)
        return uppercaseRatio > 0.5 && text.count < 50
    }
    
    private nonisolated func estimateFontSize(from boundingBox: CGRect) -> Double {
        // Rough estimation based on bounding box height
        return Double(boundingBox.height) * 72 // Approximate points
    }
}

// MARK: - Supporting Types
struct ProcessedTextResult: Sendable {
    let cleanedText: String
    let averageConfidence: Double
    let textBlocks: [TextBlock]
}

// Sendable wrapper for Vision text observations
struct SendableTextObservation: Sendable {
    let text: String
    let confidence: Double
    let boundingBox: CGRect
    
    nonisolated init(from observation: VNRecognizedTextObservation) {
        if let topCandidate = observation.topCandidates(1).first {
            self.text = topCandidate.string
            self.confidence = Double(topCandidate.confidence)
        } else {
            self.text = ""
            self.confidence = 0.0
        }
        self.boundingBox = observation.boundingBox
    }
}

struct ImageQualityAssessment: Codable, Sendable {
    let overallQuality: ImageQuality
    let score: Double
    let resolution: Double
    let imageWidth: Int
    let imageHeight: Int
    let issues: [String]
    let recommendations: [String]
}

enum ImageQuality: String, CaseIterable, Codable, Sendable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return HealthColors.healthExcellent
        case .good: return HealthColors.healthGood
        case .fair: return HealthColors.healthWarning
        case .poor: return HealthColors.healthCritical
        }
    }
}

// MARK: - Medical Terms for OCR Enhancement
struct MedicalTerms {
    static let commonTerms: [String] = [
        // Common lab test names
        "hemoglobin", "hematocrit", "glucose", "cholesterol", "triglycerides",
        "creatinine", "albumin", "bilirubin", "alkaline", "phosphatase",
        "transaminase", "thyroid", "testosterone", "estrogen", "cortisol",
        
        // Units
        "mg/dL", "mmol/L", "ng/mL", "pg/mL", "mIU/L", "IU/L", "g/dL",
        "mcg/dL", "pmol/L", "nmol/L", "mEq/L", "cells/uL", "K/uL",
        
        // Reference terms
        "reference", "range", "normal", "abnormal", "high", "low",
        "critical", "borderline", "elevated", "decreased",
        
        // Medical abbreviations
        "CBC", "CMP", "BMP", "TSH", "T3", "T4", "PSA", "HbA1c",
        "LDL", "HDL", "ALT", "AST", "BUN", "GFR", "ESR", "CRP"
    ]
}
