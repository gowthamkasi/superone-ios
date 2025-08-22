//
//  UploadModels.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import Foundation

// MARK: - Upload Request Models
// Note: HealthAnalysisPreferences is defined in HealthAnalysisPreferences.swift

// MARK: - Upload Response Models
// Note: UploadResponse and BatchUploadResponse are defined in APIResponseModels.swift

// MARK: - Upload Status Models

/// Upload status API response wrapper
struct UploadStatusResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let data: LabReportProcessingStatus
    let timestamp: String
}

/// Detailed processing status for a lab report
struct LabReportProcessingStatus: Codable, Sendable {
    let labReportId: String
    let fileName: String
    let status: UploadStatus
    let progress: Double
    let currentStage: ProcessingStage
    let ocrResult: OCRProcessingResult?
    let analysisResult: AnalysisProcessingResult?
    let estimatedTimeRemaining: Int?
    let errorMessage: String?
    let createdAt: String
    let updatedAt: String
    let completedAt: String?
    let confidence: Double?
    let documentType: String?
}

// Note: DocumentClassificationResult is defined in DocumentClassification.swift

/// OCR processing result details
struct OCRProcessingResult: Codable, Sendable {
    let method: OCRMethod
    let confidence: Double
    let extractedText: String
    let textBlockCount: Int
    let processingTime: Double
    let language: String?
    let documentClassification: DocumentClassificationResult?
    let biomarkers: [ExtractedBiomarker]?
}

/// Analysis processing result details
struct AnalysisProcessingResult: Codable, Sendable {
    let analysisId: String
    let overallHealthScore: Int
    let categoriesAnalyzed: Int
    let totalRecommendations: Int
    let confidence: Double
    let riskLevel: String
    let healthTrend: String
    let processingTime: Double
}

// MARK: - Upload History Models
// Note: UploadHistoryResponse, UploadHistoryData, UploadHistoryItem are defined in APIResponseModels.swift
// Note: PaginationInfo is defined in NetworkModels.swift

// MARK: - Result Models for iOS App

/// Upload result for internal iOS app use
struct LabReportUploadResult: Identifiable, Sendable {
    let id = UUID()
    let uploadId: String
    let labReportId: String
    let fileName: String
    let fileSize: Int64
    let uploadStatus: UploadStatus
    let estimatedProcessingTime: Int
    let ocrMethod: OCRMethod
    let timestamp: Date
    let documentType: DocumentType?
    
    var isProcessing: Bool {
        switch uploadStatus {
        case .uploading, .processing, .analyzing:
            return true
        case .completed, .failed, .cancelled:
            return false
        }
    }
    
    var canRetry: Bool {
        switch uploadStatus {
        case .failed, .cancelled:
            return true
        case .uploading, .processing, .analyzing, .completed:
            return false
        }
    }
}

// MARK: - Enums

/// Upload and processing status
enum UploadStatus: String, Codable, CaseIterable, Sendable {
    case uploading = "uploading"
    case processing = "processing"
    case analyzing = "analyzing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .uploading: return "Uploading"
        case .processing: return "Processing"
        case .analyzing: return "Analyzing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var description: String {
        switch self {
        case .uploading: return "Uploading document to server"
        case .processing: return "Extracting text with OCR"
        case .analyzing: return "Analyzing health data with AI"
        case .completed: return "Processing completed successfully"
        case .failed: return "Processing failed"
        case .cancelled: return "Processing was cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .uploading: return "arrow.up.circle"
        case .processing: return "gear.circle"
        case .analyzing: return "brain.head.profile"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }
}

/// Batch upload status
enum BatchUploadStatus: String, Codable, CaseIterable, Sendable {
    case uploading = "uploading"
    case processing = "processing"
    case completed = "completed"
    case partiallyCompleted = "partially_completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .uploading: return "Uploading"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .partiallyCompleted: return "Partially Completed"
        case .failed: return "Failed"
        }
    }
}

/// OCR processing method
enum OCRMethod: String, Codable, CaseIterable, Sendable {
    case awsTextract = "aws_textract"
    case visionFramework = "vision_framework"
    case hybrid = "hybrid"
    case automatic = "automatic"
    case backend = "backend"
    case local = "local"
    case cloud = "cloud"
    
    var displayName: String {
        switch self {
        case .awsTextract: return "AWS Textract"
        case .visionFramework: return "Vision Framework"
        case .hybrid: return "Hybrid Processing"
        case .automatic: return "Automatic Selection"
        case .backend: return "Cloud OCR (AWS Textract)"
        case .local: return "Local OCR (Vision Framework)"
        case .cloud: return "Cloud Processing"
        }
    }
    
    var description: String {
        switch self {
        case .awsTextract: return "Cloud-based OCR with high accuracy"
        case .visionFramework: return "On-device OCR processing"
        case .hybrid: return "Combined cloud and local processing"
        case .automatic: return "Intelligent method selection based on content"
        case .backend: return "High accuracy OCR processing using AWS Textract"
        case .local: return "On-device OCR using Apple's Vision framework"
        case .cloud: return "Cloud-based processing with high accuracy"
        }
    }
}

/// Document processing stages
enum ProcessingStage: String, Codable, CaseIterable, Sendable {
    case uploaded = "uploaded"
    case ocrProcessing = "ocr_processing"
    case documentClassification = "document_classification"
    case biomarkerExtraction = "biomarker_extraction"
    case healthAnalysis = "health_analysis"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .uploaded: return "Uploaded"
        case .ocrProcessing: return "OCR Processing"
        case .documentClassification: return "Document Classification"
        case .biomarkerExtraction: return "Biomarker Extraction"
        case .healthAnalysis: return "Health Analysis"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    var icon: String {
        switch self {
        case .uploaded: return "checkmark.circle"
        case .ocrProcessing: return "doc.text.viewfinder"
        case .documentClassification: return "doc.badge.gearshape"
        case .biomarkerExtraction: return "chart.line.uptrend.xyaxis"
        case .healthAnalysis: return "brain.head.profile"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .uploaded: return "Document uploaded successfully"
        case .ocrProcessing: return "Extracting text from document"
        case .documentClassification: return "Identifying document type"
        case .biomarkerExtraction: return "Extracting health biomarkers"
        case .healthAnalysis: return "Generating health insights"
        case .completed: return "All processing completed"
        case .failed: return "Processing failed"
        }
    }
    
    var progressPercentage: Double {
        switch self {
        case .uploaded: return 0.1
        case .ocrProcessing: return 0.3
        case .documentClassification: return 0.5
        case .biomarkerExtraction: return 0.7
        case .healthAnalysis: return 0.9
        case .completed: return 1.0
        case .failed: return 0.0
        }
    }
}

// Note: DocumentType is defined in BackendModels.swift

// MARK: - Extensions

extension UploadStatus {
    var color: String {
        switch self {
        case .uploading, .processing, .analyzing:
            return "blue"
        case .completed:
            return "green"
        case .failed:
            return "red"
        case .cancelled:
            return "orange"
        }
    }
}