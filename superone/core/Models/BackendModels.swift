//
//  BackendModels.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import Foundation
import SwiftUI

// MARK: - Document and Status Types

enum DocumentType: String, Codable, CaseIterable, Sendable {
    case labReport = "lab_report"
    case bloodWork = "blood_work"
    case lipidPanel = "lipid_panel"
    case metabolicPanel = "metabolic_panel"
    case vitaminDeficiency = "vitamin_deficiency"
    case thyroidFunction = "thyroid_function"
    case liverFunction = "liver_function"  
    case kidneyFunction = "kidney_function"
    case diabetesScreening = "diabetes_screening"
    case cardiacMarkers = "cardiac_markers"
    case inflammatoryMarkers = "inflammatory_markers"
    case hormonalPanel = "hormonal_panel"
    case immunology = "immunology"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .labReport: return "Lab Report"
        case .bloodWork: return "Blood Work"
        case .lipidPanel: return "Lipid Panel"
        case .metabolicPanel: return "Metabolic Panel"
        case .vitaminDeficiency: return "Vitamin Deficiency"
        case .thyroidFunction: return "Thyroid Function"
        case .liverFunction: return "Liver Function"
        case .kidneyFunction: return "Kidney Function"
        case .diabetesScreening: return "Diabetes Screening"
        case .cardiacMarkers: return "Cardiac Markers"
        case .inflammatoryMarkers: return "Inflammatory Markers"
        case .hormonalPanel: return "Hormonal Panel"
        case .immunology: return "Immunology"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .labReport: return "doc.text"
        case .bloodWork: return "drop.fill"
        case .lipidPanel: return "heart.fill"
        case .metabolicPanel: return "leaf.fill"
        case .vitaminDeficiency: return "pill.fill"
        case .thyroidFunction, .hormonalPanel: return "person.circle.fill"
        case .liverFunction, .kidneyFunction: return "cross.fill"
        case .diabetesScreening: return "medical.thermometer"
        case .cardiacMarkers: return "heart.circle.fill"
        case .inflammatoryMarkers, .immunology: return "shield.fill"
        case .other: return "doc"
        }
    }
    
    var healthCategory: HealthCategory {
        switch self {
        case .bloodWork, .labReport: return .general
        case .lipidPanel, .cardiacMarkers: return .cardiovascular
        case .metabolicPanel, .diabetesScreening: return .metabolic
        case .vitaminDeficiency: return .nutritional
        case .thyroidFunction, .hormonalPanel: return .endocrine
        case .liverFunction, .kidneyFunction: return .hepaticRenal
        case .inflammatoryMarkers, .immunology: return .immune
        case .other: return .general
        }
    }
}

// Use the comprehensive version with proper Alamofire integration
// HTTPMethod is provided by Alamofire framework

/// Logging level enumeration
enum LogLevel: String, CaseIterable, Codable, Sendable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        case .critical: return "Critical"
        }
    }
}

/// Bounding box for text location
struct BoundingBox: Codable, Sendable, Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    
    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// Text location information
struct TextLocation: Codable, Sendable, Equatable {
    let boundingBox: BoundingBox
    let pageNumber: Int
    let confidence: Double
    
    init(boundingBox: BoundingBox, pageNumber: Int = 1, confidence: Double = 1.0) {
        self.boundingBox = boundingBox
        self.pageNumber = pageNumber
        self.confidence = confidence
    }
}

/// Health trend information
struct HealthTrend: Codable, Sendable, Equatable {
    let id: String
    let category: HealthCategory
    let trend: TrendDirection
    let changePercentage: Double
    let timeframe: String
    let description: String
    
    init(id: String = UUID().uuidString, category: HealthCategory, trend: TrendDirection, changePercentage: Double, timeframe: String, description: String) {
        self.id = id
        self.category = category
        self.trend = trend
        self.changePercentage = changePercentage
        self.timeframe = timeframe
        self.description = description
    }
}

enum TrendDirection: String, Codable, CaseIterable, Sendable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    case unknown = "unknown"
    
    var displayText: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        case .unknown: return "Unknown"
        }
    }
    
    var systemImage: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return HealthColors.healthGood
        case .stable: return HealthColors.healthNormal
        case .declining: return HealthColors.healthWarning
        case .unknown: return HealthColors.healthNeutral
        }
    }
}

/// Biomarker status enumeration
enum BiomarkerStatus: String, Codable, CaseIterable, Sendable, Equatable {
    case optimal = "optimal"
    case normal = "normal"
    case borderline = "borderline"
    case abnormal = "abnormal"
    case high = "high"
    case low = "low"
    case critical = "critical"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .optimal: return "Optimal"
        case .normal: return "Normal"
        case .borderline: return "Borderline"
        case .abnormal: return "Abnormal"
        case .high: return "High"
        case .low: return "Low"
        case .critical: return "Critical"
        case .unknown: return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .optimal: return "star.circle.fill"
        case .normal: return "checkmark.circle.fill"
        case .borderline: return "minus.circle.fill"
        case .abnormal: return "x.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .low: return "arrow.down.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .optimal: return HealthColors.healthExcellent
        case .normal: return HealthColors.healthGood
        case .borderline: return HealthColors.healthWarning
        case .abnormal: return HealthColors.healthWarning
        case .high: return HealthColors.healthWarning
        case .low: return HealthColors.healthWarning
        case .critical: return HealthColors.healthCritical
        case .unknown: return HealthColors.healthNeutral
        }
    }
}

/// Category score for health categories
struct CategoryScore: Codable, Sendable, Equatable {
    let category: HealthCategory
    let score: Int
    let trend: TrendDirection
    let lastUpdated: Date
    
    init(category: HealthCategory, score: Int, trend: TrendDirection = .stable, lastUpdated: Date = Date()) {
        self.category = category
        self.score = max(0, min(100, score))
        self.trend = trend
        self.lastUpdated = lastUpdated
    }
}

// HealthScoreData moved to APIResponseModels.swift

/// Lab report response structure
struct LabReportResponse: Codable, Sendable {
    let id: String
    let document: LabReportDocument
    let extractedBiomarkers: [ExtractedBiomarker]
    let healthAnalysis: HealthAnalysisResponse?
    let processingStatus: ProcessingStatus
    let createdAt: Date
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id, document
        case extractedBiomarkers = "extracted_biomarkers"
        case healthAnalysis = "health_analysis"
        case processingStatus = "processing_status"
        case createdAt = "created_at"
    }
    
    init(id: String = UUID().uuidString, document: LabReportDocument, extractedBiomarkers: [ExtractedBiomarker] = [], healthAnalysis: HealthAnalysisResponse? = nil, processingStatus: ProcessingStatus = .pending, createdAt: Date = Date()) {
        self.id = id
        self.document = document
        self.extractedBiomarkers = extractedBiomarkers
        self.healthAnalysis = healthAnalysis
        self.processingStatus = processingStatus
        self.createdAt = createdAt
    }
}

// HealthAnalysisResponse moved to APIResponseModels.swift

/// Gender enumeration
enum Gender: String, Codable, CaseIterable, Sendable {
    case male = "male"
    case female = "female"
    case other = "other"
    case preferNotToSay = "prefer_not_to_say"
    case notSpecified = "not_specified"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        case .notSpecified: return "Not specified"
        }
    }
}

// DocumentType enum is defined earlier in this file to avoid duplication

/// Health status enumeration
enum HealthStatus: String, Codable, CaseIterable, Sendable {
    case excellent = "excellent"
    case good = "good"
    case normal = "normal"
    case fair = "fair"
    case monitor = "monitor"
    case needsAttention = "needs_attention"
    case poor = "poor"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .normal: return "Normal"
        case .fair: return "Fair"
        case .monitor: return "Monitor"
        case .needsAttention: return "Needs Attention"
        case .poor: return "Poor"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return HealthColors.healthExcellent
        case .good: return HealthColors.healthGood
        case .normal: return HealthColors.healthNormal
        case .fair: return HealthColors.healthWarning
        case .monitor: return HealthColors.healthWarning
        case .needsAttention: return HealthColors.healthWarning
        case .poor: return HealthColors.healthCritical
        case .critical: return HealthColors.healthCritical
        }
    }
}

/// Processing status enumeration
enum ProcessingStatus: String, Codable, CaseIterable, Sendable {
    case pending = "pending"
    case uploading = "uploading"
    case preprocessing = "preprocessing"
    case processing = "processing"
    case analyzing = "analyzing"
    case extracting = "extracting"
    case validating = "validating"
    case retrying = "retrying"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .uploading: return "Uploading"
        case .preprocessing: return "Preprocessing"
        case .processing: return "Processing"
        case .analyzing: return "Analyzing"
        case .extracting: return "Extracting"
        case .validating: return "Validating"
        case .retrying: return "Retrying"
        case .paused: return "Paused"
        case .completed: return "Completed"  
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "hourglass"
        case .uploading: return "arrow.up.circle"
        case .preprocessing: return "gearshape"
        case .processing: return "gear"
        case .analyzing: return "brain.head.profile"
        case .extracting: return "doc.text.magnifyingglass"
        case .validating: return "checkmark.shield"
        case .retrying: return "arrow.clockwise"
        case .paused: return "pause.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .uploading: return .blue
        case .preprocessing: return .orange
        case .processing: return .blue
        case .analyzing: return .purple
        case .extracting: return .indigo
        case .validating: return .mint
        case .retrying: return .yellow
        case .paused: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
    
    var isActive: Bool {
        switch self {
        case .pending, .uploading, .preprocessing, .processing, .analyzing, .extracting, .validating, .retrying:
            return true
        case .paused, .completed, .failed, .cancelled:
            return false
        }
    }
}

/// Processing error type enumeration
enum ProcessingErrorType: String, Codable, CaseIterable, Sendable {
    case uploadFailed = "upload_failed"
    case ocrFailed = "ocr_failed"
    case extractionFailed = "extraction_failed"
    case analysisFailed = "analysis_failed"
    case networkError = "network_error"
    case serverError = "server_error"
    case permissionDenied = "permission_denied"
    case invalidFormat = "invalid_format"
    case fileTooLarge = "file_too_large"
    case other = "other"
}

/// Processing workflow step enumeration
enum ProcessingWorkflowStep: String, Codable, CaseIterable, Sendable {
    case selectDocument = "select_document"
    case uploadDocument = "upload_document"
    case processing = "processing"
    case ocrProcessing = "ocr_processing"
    case classifyDocument = "classify_document"
    case extractBiomarkers = "extract_biomarkers"
    case analyzeData = "analyze_data"
    case reviewResults = "review_results"
    case validateBiomarkers = "validate_biomarkers"
    case complete = "complete"
    case error = "error"
    
    var stepNumber: Int {
        switch self {
        case .selectDocument: return 1
        case .uploadDocument: return 2
        case .processing: return 3
        case .ocrProcessing: return 4
        case .classifyDocument: return 5
        case .extractBiomarkers: return 6
        case .analyzeData: return 7
        case .reviewResults: return 8
        case .validateBiomarkers: return 9
        case .complete: return 10
        case .error: return 0
        }
    }
    
    var displayName: String {
        switch self {
        case .selectDocument: return "Select Document"
        case .uploadDocument: return "Upload Document"
        case .processing: return "Processing"
        case .ocrProcessing: return "OCR Processing"
        case .classifyDocument: return "Classify Document"
        case .extractBiomarkers: return "Extract Biomarkers"
        case .analyzeData: return "Analyze Data"
        case .reviewResults: return "Review Results"
        case .validateBiomarkers: return "Validate Biomarkers"
        case .complete: return "Complete"
        case .error: return "Error"
        }
    }
    
    var icon: String {
        switch self {
        case .selectDocument: return "doc.badge.plus"
        case .uploadDocument: return "icloud.and.arrow.up"
        case .processing: return "gearshape.2"
        case .ocrProcessing: return "doc.text.magnifyingglass"
        case .classifyDocument: return "folder"
        case .extractBiomarkers: return "text.line.first.and.arrowtriangle.forward"
        case .analyzeData: return "brain.head.profile"
        case .reviewResults: return "eye"
        case .validateBiomarkers: return "checkmark.seal"
        case .complete: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

/// Health category enumeration
enum HealthCategory: String, Codable, CaseIterable, Sendable {
    case general = "general"
    case cardiovascular = "cardiovascular"
    case metabolic = "metabolic"
    case hematology = "hematology"
    case liverFunction = "liver_function"
    case kidneyFunction = "kidney_function"
    case hepaticRenal = "hepatic_renal"
    case nutritional = "nutritional"
    case immune = "immune"
    case immuneSystem = "immune_system"
    case endocrine = "endocrine"
    case cancerScreening = "cancer_screening"
    case reproductiveHealth = "reproductive_health"
    case mentalHealth = "mental_health"
    case respiratory = "respiratory"
    case geneticMarkers = "genetic_markers"
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .cardiovascular: return "Cardiovascular"
        case .metabolic: return "Metabolic"
        case .hematology: return "Hematology"
        case .liverFunction: return "Liver Function"
        case .kidneyFunction: return "Kidney Function"
        case .hepaticRenal: return "Hepatic & Renal"
        case .nutritional: return "Nutritional"
        case .immune: return "Immune"
        case .immuneSystem: return "Immune System"
        case .endocrine: return "Endocrine"
        case .cancerScreening: return "Cancer Screening"
        case .reproductiveHealth: return "Reproductive Health"
        case .mentalHealth: return "Mental Health"
        case .respiratory: return "Respiratory"
        case .geneticMarkers: return "Genetic Markers"
        }
    }
    
    var color: Color {
        switch self {
        case .general: return HealthColors.healthNeutral
        case .cardiovascular: return HealthColors.healthCritical
        case .metabolic: return HealthColors.healthGood
        case .hematology: return HealthColors.healthExcellent
        case .liverFunction: return HealthColors.healthModerate
        case .kidneyFunction: return HealthColors.healthWarning
        case .hepaticRenal: return HealthColors.healthWarning
        case .nutritional: return HealthColors.healthNormal
        case .immune: return HealthColors.primary
        case .immuneSystem: return HealthColors.primary
        case .endocrine: return HealthColors.secondary
        case .cancerScreening: return HealthColors.accent
        case .reproductiveHealth: return Color(.systemPink)
        case .mentalHealth: return Color(.systemPurple)
        case .respiratory: return Color(.systemTeal)
        case .geneticMarkers: return Color(.systemIndigo)
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "heart.fill"
        case .cardiovascular: return "heart.circle.fill"
        case .metabolic: return "flame.fill"
        case .hematology: return "drop.circle.fill"
        case .liverFunction: return "liver.fill"
        case .kidneyFunction: return "kidneys.fill"
        case .hepaticRenal: return "liver.fill"
        case .nutritional: return "leaf.fill"
        case .immune: return "shield.fill"
        case .immuneSystem: return "shield.fill"
        case .endocrine: return "gland.fill"
        case .cancerScreening: return "magnifyingglass.circle.fill"
        case .reproductiveHealth: return "figure.2.circle.fill"
        case .mentalHealth: return "brain.head.profile.fill"
        case .respiratory: return "lungs.fill"
        case .geneticMarkers: return "dna.fill"
        }
    }
}

/// Extracted biomarker model
struct ExtractedBiomarker: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let value: String
    let unit: String?
    let referenceRange: String?
    let status: BiomarkerStatus
    let confidence: Double
    let extractionMethod: ExtractionMethod
    let textLocation: String?
    let category: HealthCategory?
    let normalizedValue: Double?
    let isNumeric: Bool
    let notes: String?
    
    init(id: String = UUID().uuidString, name: String, value: String, unit: String? = nil, referenceRange: String? = nil, status: BiomarkerStatus = .unknown, confidence: Double, extractionMethod: ExtractionMethod, textLocation: String? = nil, category: HealthCategory? = nil, normalizedValue: Double? = nil, isNumeric: Bool = false, notes: String? = nil) {
        self.id = id
        self.name = name
        self.value = value
        self.unit = unit
        self.referenceRange = referenceRange
        self.status = status
        self.confidence = confidence
        self.extractionMethod = extractionMethod
        self.textLocation = textLocation
        self.category = category
        self.normalizedValue = normalizedValue
        self.isNumeric = isNumeric
        self.notes = notes
    }
    
    /// Check if biomarker has high confidence and doesn't need validation
    var isHighConfidence: Bool {
        return confidence >= 0.8
    }
    
    /// Check if biomarker needs manual validation
    var needsValidation: Bool {
        return confidence < 0.8 || status == .unknown
    }
    
    /// Display-friendly confidence level
    var confidenceLevel: String {
        if confidence >= 0.9 {
            return "Very High"
        } else if confidence >= 0.8 {
            return "High"
        } else if confidence >= 0.6 {
            return "Medium"
        } else {
            return "Low"
        }
    }
    
    
    var displayName: String {
        return name
    }
    
    var formattedValue: String {
        if let unit = unit {
            return "\(value) \(unit)"
        } else {
            return value
        }
    }
}

/// Biomarker result for display in reports UI
struct BiomarkerResult: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let value: String
    let unit: String?
    let status: BiomarkerStatus
    let displayValue: String
    
    init(id: String = UUID().uuidString, name: String, value: String, unit: String? = nil, status: BiomarkerStatus = .unknown) {
        self.id = id
        self.name = name
        self.value = value
        self.unit = unit
        self.status = status
        
        if let unit = unit {
            self.displayValue = "\(value) \(unit)"
        } else {
            self.displayValue = value
        }
    }
    
    /// Initialize from ExtractedBiomarker
    init(from extractedBiomarker: ExtractedBiomarker) {
        self.id = extractedBiomarker.id
        self.name = extractedBiomarker.name
        self.value = extractedBiomarker.value
        self.unit = extractedBiomarker.unit
        self.status = extractedBiomarker.status
        
        if let unit = extractedBiomarker.unit {
            self.displayValue = "\(extractedBiomarker.value) \(unit)"
        } else {
            self.displayValue = extractedBiomarker.value
        }
    }
}

/// Extraction method enumeration
enum ExtractionMethod: String, Codable, CaseIterable, Sendable {
    case visionFramework = "vision_framework"
    case awsTextract = "aws_textract"
    case backendAPI = "backend_api"
    case manualEntry = "manual_entry"
    case hybrid = "hybrid"
    case aiPatternMatching = "ai_pattern_matching"
    case regex = "regex"
    
    var displayName: String {
        switch self {
        case .visionFramework: return "Vision Framework"
        case .awsTextract: return "AWS Textract"
        case .backendAPI: return "Backend API"
        case .manualEntry: return "Manual Entry"
        case .hybrid: return "Hybrid"
        case .aiPatternMatching: return "AI Pattern Matching"
        case .regex: return "Regular Expression"
        }
    }
}

/// Service type enumeration
enum ServiceType: String, Codable, CaseIterable, Sendable, Equatable {
    case bloodWork = "blood_work"
    case urinalysis = "urinalysis"
    case lipidPanel = "lipid_panel"
    case metabolicPanel = "metabolic_panel"
    case thyroidFunction = "thyroid_function"
    case diabeticPanel = "diabetic_panel"
    case hormonalPanel = "hormonal_panel"
    case allergyPanel = "allergy_panel"
    case inflammatoryMarkers = "inflammatory_markers"
    case tumorMarkers = "tumor_markers"
    case imaging = "imaging" 
    case consultation = "consultation"
    case vaccination = "vaccination"
    case physicalExam = "physical_exam"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .bloodWork: return "Blood Work"
        case .urinalysis: return "Urinalysis"
        case .lipidPanel: return "Lipid Panel"
        case .metabolicPanel: return "Metabolic Panel"
        case .thyroidFunction: return "Thyroid Function"
        case .diabeticPanel: return "Diabetic Panel"
        case .hormonalPanel: return "Hormonal Panel"
        case .allergyPanel: return "Allergy Panel"
        case .inflammatoryMarkers: return "Inflammatory Markers"
        case .tumorMarkers: return "Tumor Markers"
        case .imaging: return "Imaging"
        case .consultation: return "Consultation"
        case .vaccination: return "Vaccination"
        case .physicalExam: return "Physical Exam"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .bloodWork: return "drop.fill"
        case .urinalysis: return "testtube.2"
        case .lipidPanel: return "heart.fill"
        case .metabolicPanel: return "waveform.path.ecg"
        case .thyroidFunction: return "windmill"
        case .diabeticPanel: return "chart.line.uptrend.xyaxis"
        case .hormonalPanel: return "circle.hexagongrid.fill"
        case .allergyPanel: return "leaf.fill"
        case .inflammatoryMarkers: return "thermometer"
        case .tumorMarkers: return "magnifyingglass"
        case .imaging: return "xmark.rectangle"
        case .consultation: return "stethoscope"
        case .vaccination: return "syringe"
        case .physicalExam: return "person.fill.checkmark"
        case .other: return "ellipsis.circle"
        }
    }
}

/// Appointment status enumeration
enum AppointmentStatus: String, Codable, CaseIterable, Sendable, Equatable {
    case pending = "pending"
    case scheduled = "scheduled"
    case confirmed = "confirmed"
    case checkedIn = "checked_in"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    case noShow = "no_show"
    case rescheduled = "rescheduled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .scheduled: return "Scheduled"
        case .confirmed: return "Confirmed"
        case .checkedIn: return "Checked In"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .noShow: return "No Show"
        case .rescheduled: return "Rescheduled"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "hourglass"
        case .scheduled: return "calendar"
        case .confirmed: return "checkmark.circle"
        case .checkedIn: return "person.fill.checkmark"
        case .inProgress: return "clock.arrow.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .noShow: return "exclamationmark.triangle.fill"
        case .rescheduled: return "calendar.badge.clock"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .scheduled: return .blue
        case .confirmed: return .green
        case .checkedIn: return .orange
        case .inProgress: return .yellow
        case .completed: return .green
        case .cancelled: return .red
        case .noShow: return .red
        case .rescheduled: return .orange
        }
    }
}

/// Lab report document model
struct LabReportDocument: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let fileName: String
    let filePath: String?
    let fileSize: Int64
    let mimeType: String
    let uploadDate: Date
    let processingStatus: ProcessingStatus
    let documentType: DocumentType?
    let healthCategory: HealthCategory?
    let extractedText: String?
    let ocrConfidence: Double?
    let thumbnail: Data?
    let metadata: [String: String]?
    let data: Data?
    
    init(id: String = UUID().uuidString, fileName: String, filePath: String? = nil, fileSize: Int64, mimeType: String, uploadDate: Date = Date(), processingStatus: ProcessingStatus, documentType: DocumentType? = nil, healthCategory: HealthCategory? = nil, extractedText: String? = nil, ocrConfidence: Double? = nil, thumbnail: Data? = nil, metadata: [String: String]? = nil, data: Data? = nil) {
        self.id = id
        self.fileName = fileName
        self.filePath = filePath
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.uploadDate = uploadDate
        self.processingStatus = processingStatus
        self.documentType = documentType
        self.healthCategory = healthCategory
        self.extractedText = extractedText
        self.ocrConfidence = ocrConfidence
        self.thumbnail = thumbnail
        self.metadata = metadata
        self.data = data
    }
    
    /// Check if document processing can be retried
    var canRetryProcessing: Bool {
        return processingStatus == .failed || processingStatus == .cancelled
    }
    
    /// Check if document is currently being processed
    var isProcessing: Bool {
        return processingStatus.isActive
    }
    
    /// Display-friendly file size
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var displayFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

/// Lab report processing summary
struct LabReportProcessingSummary: Codable, Sendable, Equatable {
    let documentId: String
    let processingStartTime: Date
    let processingEndTime: Date
    let totalBiomarkersExtracted: Int
    let highConfidenceBiomarkers: Int
    let categoriesIdentified: [HealthCategory]
    let ocrMethod: ExtractionMethod
    let overallConfidence: Double
    let processingDuration: TimeInterval
    
    init(documentId: String, processingStartTime: Date = Date(), processingEndTime: Date, totalBiomarkersExtracted: Int, highConfidenceBiomarkers: Int, categoriesIdentified: [HealthCategory], ocrMethod: ExtractionMethod, overallConfidence: Double) {
        self.documentId = documentId
        self.processingStartTime = processingStartTime
        self.processingEndTime = processingEndTime
        self.totalBiomarkersExtracted = totalBiomarkersExtracted
        self.highConfidenceBiomarkers = highConfidenceBiomarkers
        self.categoriesIdentified = categoriesIdentified
        self.ocrMethod = ocrMethod
        self.overallConfidence = overallConfidence
        self.processingDuration = processingEndTime.timeIntervalSince(processingStartTime)
    }
}

/// OCR result model
struct OCRResult: Codable, Sendable, Equatable {
    let text: String
    let confidence: Double
    let language: String?
    let boundingBoxes: [TextBoundingBox]?
    let processingTime: TimeInterval
    let method: ExtractionMethod
    let imageWidth: Int?
    let imageHeight: Int?
    let errorMessage: String?
    
    var isSuccessful: Bool {
        return errorMessage == nil && !text.isEmpty
    }
    
    var wordCount: Int {
        return text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
    
    var characterCount: Int {
        return text.count
    }
    
    init(text: String, confidence: Double, language: String? = nil, boundingBoxes: [TextBoundingBox]? = nil, processingTime: TimeInterval, method: ExtractionMethod, imageWidth: Int? = nil, imageHeight: Int? = nil, errorMessage: String? = nil) {
        self.text = text
        self.confidence = confidence
        self.language = language
        self.boundingBoxes = boundingBoxes
        self.processingTime = processingTime
        self.method = method
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.errorMessage = errorMessage
    }
}

/// Text bounding box model
struct TextBoundingBox: Codable, Sendable, Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let text: String
    let confidence: Double
    
    init(x: Double, y: Double, width: Double, height: Double, text: String, confidence: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.text = text
        self.confidence = confidence
    }
}

// MARK: - Authentication Models

struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
    let deviceId: String?
    let rememberMe: Bool
    
    nonisolated enum CodingKeys: String, CodingKey {
        case email
        case password
        case deviceId = "device_id"
        case rememberMe = "remember_me"
    }
    
    init(email: String, password: String, deviceId: String? = nil, rememberMe: Bool = false) {
        self.email = email
        self.password = password
        self.deviceId = deviceId
        self.rememberMe = rememberMe
    }
}

struct RegisterRequest: Codable, Sendable {
    let email: String
    let password: String
    let name: String
    let dateOfBirth: Date?
    let phoneNumber: String?
    let deviceId: String?
    let acceptedTerms: Bool
    let acceptedPrivacy: Bool
    
    nonisolated enum CodingKeys: String, CodingKey {
        case email
        case password
        case name
        case dateOfBirth = "date_of_birth"
        case phoneNumber = "phone_number"
        case deviceId = "device_id"
        case acceptedTerms = "accepted_terms"
        case acceptedPrivacy = "accepted_privacy"
    }
    
    init(email: String, password: String, name: String, dateOfBirth: Date? = nil, phoneNumber: String? = nil, deviceId: String? = nil, acceptedTerms: Bool = true, acceptedPrivacy: Bool = true) {
        self.email = email
        self.password = password
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.phoneNumber = phoneNumber
        self.deviceId = deviceId
        self.acceptedTerms = acceptedTerms
        self.acceptedPrivacy = acceptedPrivacy
    }
}

// Note: AuthResponse is now defined in APIResponseModels.swift to avoid duplication


// MARK: - Profile Update Models

/// Profile update request matching the exact API contract
nonisolated struct UpdateProfileRequest: Codable, Sendable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let mobileNumber: String?
    let profilePicture: String?
    let dob: Date?
    let gender: String?
    let height: Double?
    let weight: Double?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        case email
        case mobileNumber
        case profilePicture
        case dob
        case gender
        case height
        case weight
    }
    
    init(
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        mobileNumber: String? = nil,
        profilePicture: String? = nil,
        dob: Date? = nil,
        gender: String? = nil,
        height: Double? = nil,
        weight: Double? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.mobileNumber = mobileNumber
        self.profilePicture = profilePicture
        self.dob = dob
        self.gender = gender
        self.height = height
        self.weight = weight
    }
}

/// Profile update response matching the exact API contract
nonisolated struct UpdateProfileResponse: Codable, Sendable {
    let success: Bool
    let data: ProfileUpdateData?
    let message: String
    let timestamp: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
        case timestamp
    }
}

/// Profile update data structure
nonisolated struct ProfileUpdateData: Codable, Sendable {
    let user: UpdatedUserProfile
    
    nonisolated enum CodingKeys: String, CodingKey {
        case user
    }
}

/// Updated user profile from API response
nonisolated struct UpdatedUserProfile: Codable, Sendable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let mobileNumber: String?
    let dob: Date?
    let gender: String?
    let height: Double?
    let weight: Double?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName
        case lastName
        case mobileNumber
        case dob
        case gender
        case height
        case weight
    }
    
    // Custom initializer to handle Int to Double conversion for height/weight
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        print("🔍 UpdatedUserProfile decoding debug:")
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        mobileNumber = try container.decodeIfPresent(String.self, forKey: .mobileNumber)
        dob = try container.decodeIfPresent(Date.self, forKey: .dob)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        
        print("   Basic fields decoded successfully")
        
        // Handle height - could be Int or Double from backend
        if container.contains(.height) {
            do {
                height = try container.decodeIfPresent(Double.self, forKey: .height)
                print("   height decoded as Double: \(height?.description ?? "nil")")
            } catch {
                print("   height Double decode failed, trying Int: \(error)")
                let heightInt = try container.decodeIfPresent(Int.self, forKey: .height)
                height = heightInt.map { Double($0) }
                print("   height decoded as Int->Double: \(height?.description ?? "nil")")
            }
        } else {
            height = nil
            print("   height field not present")
        }
        
        // Handle weight - could be Int or Double from backend
        if container.contains(.weight) {
            do {
                weight = try container.decodeIfPresent(Double.self, forKey: .weight)
                print("   weight decoded as Double: \(weight?.description ?? "nil")")
            } catch {
                print("   weight Double decode failed, trying Int: \(error)")
                let weightInt = try container.decodeIfPresent(Int.self, forKey: .weight)
                weight = weightInt.map { Double($0) }
                print("   weight decoded as Int->Double: \(weight?.description ?? "nil")")
            }
        } else {
            weight = nil
            print("   weight field not present")
        }
        
        print("✅ UpdatedUserProfile decoded successfully")
    }
}

// MARK: - User Models

nonisolated struct User: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let email: String
    let name: String
    let firstName: String?
    let lastName: String?
    let profileImageURL: String?
    let phoneNumber: String?
    let mobileNumber: String? // Added mobile number field that was missing
    let dateOfBirth: Date?
    let gender: Gender?
    let height: Double?
    let weight: Double?
    let activityLevel: ActivityLevel?
    let healthGoals: [HealthGoal]?
    let medicalConditions: [String]?
    let medications: [String]?
    let allergies: [String]?
    let labloopPatientId: String?
    let createdAt: Date
    let updatedAt: Date
    let emailVerified: Bool
    let phoneVerified: Bool
    let twoFactorEnabled: Bool
    let profile: UserProfile?
    let preferences: UserPreferences?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email, name
        case firstName = "first_name"
        case lastName = "last_name"
        case profileImageURL = "profile_image_url"
        case phoneNumber = "phone_number"
        case mobileNumber = "mobile_number" // Added mobile number field
        case dateOfBirth = "date_of_birth"
        case gender
        case height, weight
        case activityLevel = "activity_level"
        case healthGoals = "health_goals"
        case medicalConditions = "medical_conditions"
        case medications, allergies
        case labloopPatientId = "labloop_patient_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case emailVerified = "email_verified"
        case phoneVerified = "phone_verified"
        case twoFactorEnabled = "two_factor_enabled"
        case profile, preferences
    }
    
    init(id: String, email: String, name: String, firstName: String? = nil, lastName: String? = nil, profileImageURL: String? = nil, phoneNumber: String? = nil, mobileNumber: String? = nil, dateOfBirth: Date? = nil, gender: Gender? = nil, height: Double? = nil, weight: Double? = nil, activityLevel: ActivityLevel? = nil, healthGoals: [HealthGoal]? = nil, medicalConditions: [String]? = nil, medications: [String]? = nil, allergies: [String]? = nil, labloopPatientId: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date(), emailVerified: Bool = false, phoneVerified: Bool = false, twoFactorEnabled: Bool = false, profile: UserProfile? = nil, preferences: UserPreferences? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageURL = profileImageURL
        self.phoneNumber = phoneNumber
        self.mobileNumber = mobileNumber // Added mobile number field
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.height = height
        self.weight = weight
        self.activityLevel = activityLevel
        self.healthGoals = healthGoals
        self.medicalConditions = medicalConditions
        self.medications = medications
        self.allergies = allergies
        self.labloopPatientId = labloopPatientId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.emailVerified = emailVerified
        self.phoneVerified = phoneVerified
        self.twoFactorEnabled = twoFactorEnabled
        self.profile = profile
        self.preferences = preferences
    }
}

nonisolated struct UserProfile: Codable, Sendable, Equatable {
    let dateOfBirth: Date?
    let gender: Gender?
    let height: Double? // in cm
    let weight: Double? // in kg
    let activityLevel: ActivityLevel?
    let healthGoals: [HealthGoal]?
    let medicalConditions: [String]?
    let medications: [String]?
    let allergies: [String]?
    let emergencyContact: EmergencyContact?
    let profileImageURL: String?
    let labloopPatientId: String? // Integration with LabLoop
    
    nonisolated enum CodingKeys: String, CodingKey {
        case dateOfBirth = "date_of_birth"
        case gender
        case height, weight
        case activityLevel = "activity_level"
        case healthGoals = "health_goals"
        case medicalConditions = "medical_conditions"
        case medications, allergies
        case emergencyContact = "emergency_contact"
        case profileImageURL = "profile_image_url"
        case labloopPatientId = "labloop_patient_id"
    }
    
    init(
        dateOfBirth: Date? = nil,
        gender: Gender? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        activityLevel: ActivityLevel? = nil,
        healthGoals: [HealthGoal]? = nil,
        medicalConditions: [String]? = nil,
        medications: [String]? = nil,
        allergies: [String]? = nil,
        emergencyContact: EmergencyContact? = nil,
        profileImageURL: String? = nil,
        labloopPatientId: String? = nil
    ) {
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.height = height
        self.weight = weight
        self.activityLevel = activityLevel
        self.healthGoals = healthGoals
        self.medicalConditions = medicalConditions
        self.medications = medications
        self.allergies = allergies
        self.emergencyContact = emergencyContact
        self.profileImageURL = profileImageURL
        self.labloopPatientId = labloopPatientId
    }
}

nonisolated struct UserPreferences: Codable, Sendable, Equatable {
    let notifications: NotificationPreferences
    let privacy: PrivacyPreferences
    let units: UnitPreferences
    let theme: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case notifications, privacy, units, theme
    }
    
    init(notifications: NotificationPreferences, privacy: PrivacyPreferences, units: UnitPreferences, theme: String = "system") {
        self.notifications = notifications
        self.privacy = privacy
        self.units = units
        self.theme = theme
    }
}

nonisolated struct EmergencyContact: Codable, Sendable, Equatable {
    let name: String
    let relationship: String
    let phoneNumber: String
    let email: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case name, relationship
        case phoneNumber = "phone_number"
        case email
    }
    
    init(name: String, relationship: String, phoneNumber: String, email: String? = nil) {
        self.name = name
        self.relationship = relationship
        self.phoneNumber = phoneNumber
        self.email = email
    }
}

enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case sedentary = "sedentary"
    case lightlyActive = "lightly_active"
    case moderatelyActive = "moderately_active"
    case veryActive = "very_active"
    case extraActive = "extra_active"
    
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive: return "Very Active"
        case .extraActive: return "Extra Active"
        }
    }
}

enum HealthGoal: String, Codable, CaseIterable, Sendable {
    case weightLoss = "weight_loss"
    case weightGain = "weight_gain"
    case muscleGain = "muscle_gain"
    case cardiovascularHealth = "cardiovascular_health"
    case diabetes = "diabetes_management"
    case cholesterol = "cholesterol_management"
    case bloodPressure = "blood_pressure_management"
    case general = "general_wellness"
    case energy = "increase_energy"
    case sleep = "improve_sleep"
    case stress = "manage_stress"
    case nutrition = "improve_nutrition"
    
    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .weightGain: return "Weight Gain"
        case .muscleGain: return "Muscle Gain"
        case .cardiovascularHealth: return "Heart Health"
        case .diabetes: return "Diabetes Management"
        case .cholesterol: return "Cholesterol Control"
        case .bloodPressure: return "Blood Pressure"
        case .general: return "General Wellness"
        case .energy: return "Increase Energy"
        case .sleep: return "Better Sleep"
        case .stress: return "Stress Management"
        case .nutrition: return "Better Nutrition"
        }
    }
    
    var icon: String {
        switch self {
        case .weightLoss: return "figure.walk"
        case .weightGain: return "figure.strengthtraining.traditional"
        case .muscleGain: return "dumbbell"
        case .cardiovascularHealth: return "heart.fill"
        case .diabetes: return "drop.fill"
        case .cholesterol: return "heart.text.square"
        case .bloodPressure: return "heart.circle"
        case .general: return "leaf.fill"
        case .energy: return "bolt.fill"
        case .sleep: return "bed.double.fill"
        case .stress: return "brain.head.profile"
        case .nutrition: return "fork.knife"
        }
    }
}

// MARK: - Preferences Models

nonisolated struct NotificationPreferences: Codable, Sendable, Equatable {
    let healthAlerts: Bool
    let appointmentReminders: Bool
    let reportReady: Bool
    let recommendations: Bool
    let weeklyDigest: Bool
    let monthlyReport: Bool
    let pushEnabled: Bool
    let emailEnabled: Bool
    let smsEnabled: Bool
    let quietHours: QuietHours?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case healthAlerts = "health_alerts"
        case appointmentReminders = "appointment_reminders"
        case reportReady = "report_ready"
        case recommendations
        case weeklyDigest = "weekly_digest"
        case monthlyReport = "monthly_report"
        case pushEnabled = "push_enabled"
        case emailEnabled = "email_enabled"
        case smsEnabled = "sms_enabled"
        case quietHours = "quiet_hours"
    }
}

nonisolated struct PrivacyPreferences: Codable, Sendable, Equatable {
    let shareDataWithProviders: Bool
    let shareDataForResearch: Bool
    let allowAnalytics: Bool
    let allowMarketing: Bool
    let dataRetentionPeriod: Int // in days
    
    nonisolated enum CodingKeys: String, CodingKey {
        case shareDataWithProviders = "share_data_with_providers"
        case shareDataForResearch = "share_data_for_research"
        case allowAnalytics = "allow_analytics"
        case allowMarketing = "allow_marketing"
        case dataRetentionPeriod = "data_retention_period"
    }
}

nonisolated struct UnitPreferences: Codable, Sendable, Equatable {
    let weightUnit: WeightUnit
    let heightUnit: HeightUnit
    let temperatureUnit: TemperatureUnit
    let dateFormat: DateFormat
    
    nonisolated enum CodingKeys: String, CodingKey {
        case weightUnit = "weight_unit"
        case heightUnit = "height_unit"
        case temperatureUnit = "temperature_unit"
        case dateFormat = "date_format"
    }
}

nonisolated struct QuietHours: Codable, Sendable, Equatable {
    let enabled: Bool
    let startTime: String // HH:mm format
    let endTime: String   // HH:mm format
    
    nonisolated enum CodingKeys: String, CodingKey {
        case enabled
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case kg = "kg"
    case lbs = "lbs"
    
    var displayName: String {
        switch self {
        case .kg: return "Kilograms"
        case .lbs: return "Pounds"
        }
    }
}

// MARK: - Health Trend and Direction Types


// MARK: - Score and Analysis Types




// Duplicate removed - using original HealthAnalysisResponse definition above

struct DashboardResponse: Codable, Sendable {
    let healthScore: HealthScoreData
    let recentReports: [LabReportResponse]
    let upcomingAppointments: [Appointment]
    let healthAlerts: [HealthAlert]
    let lastSyncDate: Date
    
    struct HealthAlert: Codable, Sendable, Equatable {
        let id: String
        let type: AlertType
        let severity: Severity
        let title: String
        let message: String
        let category: HealthCategory
        let createdAt: Date
        let actionRequired: Bool
        
        enum AlertType: String, Codable, CaseIterable, Sendable {
            case abnormalResult = "abnormal_result"
            case trendChange = "trend_change"
            case appointment = "appointment"
            case recommendation = "recommendation"
        }
        
        enum Severity: String, Codable, CaseIterable, Sendable {
            case info = "info"
            case warning = "warning"
            case critical = "critical"
        }
    }
}

enum HeightUnit: String, Codable, CaseIterable, Sendable {
    case cm = "cm"
    case ft = "ft"
    
    var displayName: String {
        switch self {
        case .cm: return "Centimeters"
        case .ft: return "Feet/Inches"
        }
    }
}

enum TemperatureUnit: String, Codable, CaseIterable, Sendable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"
    
    var displayName: String {
        switch self {
        case .celsius: return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        }
    }
}

enum DateFormat: String, Codable, CaseIterable, Sendable {
    case mmddyyyy = "MM/dd/yyyy"
    case ddmmyyyy = "dd/MM/yyyy"
    case yyyymmdd = "yyyy-MM-dd"
    
    var displayName: String {
        switch self {
        case .mmddyyyy: return "MM/DD/YYYY"
        case .ddmmyyyy: return "DD/MM/YYYY"
        case .yyyymmdd: return "YYYY-MM-DD"
        }
    }
}

// MARK: - Lab Report Models

struct LabReportUploadRequest: Codable {
    let fileName: String
    let fileSize: Int
    let mimeType: String
    let documentType: DocumentType?
    let expectedCategory: HealthCategory?
}

struct LabReportUploadResponse: Codable {
    let reportId: String
    let uploadUrl: String?
    let status: ProcessingStatus
    let message: String?
}


// ProcessingError moved to APIResponseModels.swift

// MARK: - Health Analysis Models

// Duplicate removed - using original HealthAnalysisResponse definition above


struct HealthInsight: Codable, Identifiable {
    let id: String
    let category: HealthCategory
    let title: String
    let description: String
    let severity: InsightSeverity
    let actionRequired: Bool
    let relatedBiomarkers: [String]
}

struct HealthRecommendation: Codable {
    let id: String
    let category: RecommendationCategory
    let title: String
    let description: String
    let priority: RecommendationPriority
    let actionSteps: [String]
    let timeframe: String?
    let expectedOutcome: String?
    let relatedInsights: [String]
}

struct RiskFactor: Codable {
    let id: String
    let name: String
    let level: RiskLevel
    let description: String
    let contributingFactors: [String]
    let preventionSteps: [String]
}


struct ComparisonData: Codable {
    let previousReport: ComparisonReport?
    let populationAverage: PopulationData?
    let targetRanges: [String: TargetRange]
}

struct ComparisonReport: Codable {
    let reportId: String
    let date: Date
    let overallScore: Int
    let scoreDifference: Int
}

struct PopulationData: Codable {
    let ageGroup: String
    let gender: String
    let averageScore: Int
    let percentile: Int
}

struct TargetRange: Codable {
    let min: Double
    let max: Double
    let unit: String
    let ageSpecific: Bool
    let genderSpecific: Bool
}

// MARK: - Appointment Models

struct AppointmentBookingRequest: Codable {
    let facilityId: String
    let serviceType: ServiceType
    let preferredDate: Date
    let preferredTime: String
    let notes: String?
    let insuranceProvider: String?
    let emergencyContact: EmergencyContact?
}

struct AppointmentResponse: Codable {
    let id: String
    let userId: String
    let facilityId: String
    let facilityName: String
    let location: String
    let serviceType: ServiceType
    let appointmentDate: Date
    let appointmentTime: String
    let status: AppointmentStatus
    let confirmationNumber: String
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, facilityId, facilityName, location, serviceType
        case appointmentDate, appointmentTime, status, confirmationNumber
        case notes, createdAt, updatedAt
    }
}

struct LabFacilityResponse: Codable {
    let id: String
    let name: String
    let location: String
    let address: Address
    let phoneNumber: String
    let email: String?
    let website: String?
    let services: [ServiceType]
    let operatingHours: [OperatingHour]
    let rating: Double
    let reviewCount: Int
    let acceptsInsurance: Bool
    let acceptsWalkIns: Bool
    let averageWaitTime: Int // in minutes
    let distance: Double? // in kilometers
    let amenities: [String]
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, location, address, phoneNumber, email, website
        case services, operatingHours, rating, reviewCount
        case acceptsInsurance, acceptsWalkIns, averageWaitTime, distance, amenities
    }
}

struct Address: Codable {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let coordinates: Coordinates?
}

struct Coordinates: Codable {
    let latitude: Double
    let longitude: Double
}

struct OperatingHour: Codable {
    let dayOfWeek: Int // 0 = Sunday, 6 = Saturday
    let openTime: String // HH:mm format
    let closeTime: String // HH:mm format
    let isClosed: Bool
}

// MARK: - Dashboard Models

// Duplicate removed - using original DashboardResponse definition above


struct HistoricalScore: Codable {
    let date: Date
    let score: Int
    let reportCount: Int
}

// QuickStatsData moved to APIResponseModels.swift

struct ActivityItem: Codable {
    let id: String
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date
    let category: HealthCategory?
    let metadata: [String: String]?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type, title, description, timestamp, category, metadata
    }
}

// HealthAlert moved to APIResponseModels.swift

// MARK: - Enums

enum ActivityType: String, Codable {
    case reportUploaded = "report_uploaded"
    case analysisCompleted = "analysis_completed"
    case appointmentBooked = "appointment_booked"
    case appointmentCompleted = "appointment_completed"
    case recommendationGenerated = "recommendation_generated"
    case healthScoreUpdated = "health_score_updated"
    case profileUpdated = "profile_updated"
}

enum AlertType: String, Codable {
    case criticalValue = "critical_value"
    case trendAlert = "trend_alert"
    case appointmentReminder = "appointment_reminder"
    case missedTest = "missed_test"
    case recommendation = "recommendation"
    case systemNotification = "system_notification"
}

enum AlertSeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

enum InsightSeverity: String, Codable {
    case info = "info"
    case warning = "warning"
    case critical = "critical"
}

enum RecommendationCategory: String, Codable {
    case lifestyle = "lifestyle"
    case diet = "diet"
    case exercise = "exercise"
    case medical = "medical"
    case preventive = "preventive"
    case followUp = "follow_up"
}

enum RecommendationPriority: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
}

enum RiskLevel: String, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case severe = "severe"
}


enum TrendSignificance: String, Codable {
    case insignificant = "insignificant"
    case minor = "minor"
    case moderate = "moderate"
    case major = "major"
}

// MARK: - Extensions

extension Date {
    var iso8601String: String {
        // Thread-safe static formatter to avoid threading issues in Alamofire calls
        return DateFormatterCache.iso8601Formatter.string(from: self)
    }
    
    var dateOnlyString: String {
        // Backend-compatible date format (YYYY-MM-DD) for JSON Schema 'date' fields
        return DateFormatterCache.dateOnlyFormatter.string(from: self)
    }
}

// MARK: - Thread-Safe Date Formatter Cache

private struct DateFormatterCache {
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension String {
    var iso8601Date: Date? {
        // Use the same thread-safe formatter
        return DateFormatterCache.iso8601Formatter.date(from: self)
    }
}

// MARK: - Type Aliases for Backend Integration

/// Type alias for local biomarker status to maintain compatibility
typealias BiomarkerStatusLocal = BiomarkerStatus

/// Analysis processing error types for backend integration
enum AnalysisProcessingErrorType: String, Codable, CaseIterable, Sendable {
    case analysisNotFound = "analysis_not_found"
    case analysisTimeout = "analysis_timeout"
    case insufficientData = "insufficient_data"
    case processingFailed = "processing_failed"
    case networkError = "network_error"
    case authenticationFailed = "authentication_failed"
    
    var displayName: String {
        switch self {
        case .analysisNotFound: return "Analysis Not Found"
        case .analysisTimeout: return "Analysis Timeout"
        case .insufficientData: return "Insufficient Data"
        case .processingFailed: return "Processing Failed"
        case .networkError: return "Network Error"
        case .authenticationFailed: return "Authentication Failed"
        }
    }
}

/// Simple network service check interface
protocol NetworkServiceProtocol {
    var isConnected: Bool { get async }
}

// MARK: - Health Assessment Models

/// Biomarker data for health analysis
struct BiomarkerData: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let value: Double
    let unit: String
    let status: BiomarkerStatus
    let normalRange: String?
    let category: HealthCategory
    let lastUpdated: Date
    
    init(id: String = UUID().uuidString, name: String, value: Double, unit: String, status: BiomarkerStatus, normalRange: String? = nil, category: HealthCategory, lastUpdated: Date = Date()) {
        self.id = id
        self.name = name
        self.value = value
        self.unit = unit
        self.status = status
        self.normalRange = normalRange
        self.category = category
        self.lastUpdated = lastUpdated
    }
}

/// Category health assessment for dashboard display
struct CategoryHealthAssessment: Codable, Sendable {
    let score: Int
    let status: HealthStatus
    let biomarkers: [BiomarkerData]
    let trends: [BiomarkerTrendData]?
    let lastUpdated: Date
    
    init(score: Int, status: HealthStatus, biomarkers: [BiomarkerData] = [], trends: [BiomarkerTrendData]? = nil, lastUpdated: Date = Date()) {
        self.score = score
        self.status = status
        self.biomarkers = biomarkers
        self.trends = trends
        self.lastUpdated = lastUpdated
    }
}

/// Detailed health analysis for comprehensive health insights
struct DetailedHealthAnalysis: Codable, Identifiable, Sendable {
    let id: String
    let overallHealthScore: Int
    let healthTrend: TrendDirection
    let riskLevel: RiskLevel
    let categoryAssessments: [BackendHealthCategory: CategoryHealthAssessment]
    let integratedAssessment: IntegratedAssessment
    let recommendations: HealthRecommendations
    let confidence: Double
    let analysisDate: Date
    let summary: AnalysisSummary
    let highPriorityRecommendations: [HealthRecommendation]
    let insights: [HealthInsight]
    let alerts: [HealthAlert]
    
    init(id: String = UUID().uuidString, overallHealthScore: Int, healthTrend: TrendDirection = .stable, riskLevel: RiskLevel, categoryAssessments: [BackendHealthCategory: CategoryHealthAssessment], integratedAssessment: IntegratedAssessment, recommendations: HealthRecommendations, confidence: Double, analysisDate: Date = Date(), summary: AnalysisSummary, highPriorityRecommendations: [HealthRecommendation], insights: [HealthInsight] = [], alerts: [HealthAlert] = []) {
        self.id = id
        self.overallHealthScore = overallHealthScore
        self.healthTrend = healthTrend
        self.riskLevel = riskLevel
        self.categoryAssessments = categoryAssessments
        self.integratedAssessment = integratedAssessment
        self.recommendations = recommendations
        self.confidence = confidence
        self.analysisDate = analysisDate
        self.summary = summary
        self.highPriorityRecommendations = highPriorityRecommendations
        self.insights = insights
        self.alerts = alerts
    }
    
    // Custom Codable implementation for dictionary with enum keys
    nonisolated enum CodingKeys: String, CodingKey {
        case id, overallHealthScore, healthTrend, riskLevel, categoryAssessments
        case integratedAssessment, recommendations, confidence, analysisDate
        case summary, highPriorityRecommendations, insights, alerts
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        overallHealthScore = try container.decode(Int.self, forKey: .overallHealthScore)
        healthTrend = try container.decode(TrendDirection.self, forKey: .healthTrend)
        riskLevel = try container.decode(RiskLevel.self, forKey: .riskLevel)
        
        // Decode dictionary with string keys and convert to enum keys
        let assessmentDict = try container.decode([String: CategoryHealthAssessment].self, forKey: .categoryAssessments)
        var categoryDict: [BackendHealthCategory: CategoryHealthAssessment] = [:]
        for (key, value) in assessmentDict {
            if let category = BackendHealthCategory(rawValue: key) {
                categoryDict[category] = value
            }
        }
        categoryAssessments = categoryDict
        
        integratedAssessment = try container.decode(IntegratedAssessment.self, forKey: .integratedAssessment)
        recommendations = try container.decode(HealthRecommendations.self, forKey: .recommendations)
        confidence = try container.decode(Double.self, forKey: .confidence)
        analysisDate = try container.decode(Date.self, forKey: .analysisDate)
        summary = try container.decode(AnalysisSummary.self, forKey: .summary)
        highPriorityRecommendations = try container.decode([HealthRecommendation].self, forKey: .highPriorityRecommendations)
        insights = try container.decode([HealthInsight].self, forKey: .insights)
        alerts = try container.decode([HealthAlert].self, forKey: .alerts)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(overallHealthScore, forKey: .overallHealthScore)
        try container.encode(healthTrend, forKey: .healthTrend)
        try container.encode(riskLevel, forKey: .riskLevel)
        
        // Encode dictionary by converting enum keys to string keys
        let assessmentDict = Dictionary(uniqueKeysWithValues: categoryAssessments.map { (key, value) in
            (key.rawValue, value)
        })
        try container.encode(assessmentDict, forKey: .categoryAssessments)
        
        try container.encode(integratedAssessment, forKey: .integratedAssessment)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(analysisDate, forKey: .analysisDate)
        try container.encode(summary, forKey: .summary)
        try container.encode(highPriorityRecommendations, forKey: .highPriorityRecommendations)
        try container.encode(insights, forKey: .insights)
        try container.encode(alerts, forKey: .alerts)
    }
}

/// Backend health category enumeration (subset for backend compatibility)
enum BackendHealthCategory: String, Codable, CaseIterable, Sendable {
    case cardiovascular = "cardiovascular"
    case metabolic = "metabolic"
    case hematology = "hematology"
    case hepaticRenal = "hepatic_renal"
    case nutritional = "nutritional"
    case immune = "immune"
    case endocrine = "endocrine"
    case cancerScreening = "cancer_screening"
    case reproductiveHealth = "reproductive_health"
    case mentalHealth = "mental_health"
    case respiratory = "respiratory"
    case geneticMarkers = "genetic_markers"
    
    var displayName: String {
        switch self {
        case .cardiovascular: return "Cardiovascular"
        case .metabolic: return "Metabolic"
        case .hematology: return "Hematology"
        case .hepaticRenal: return "Hepatic & Renal"
        case .nutritional: return "Nutritional"
        case .immune: return "Immune"
        case .endocrine: return "Endocrine"
        case .cancerScreening: return "Cancer Screening"
        case .reproductiveHealth: return "Reproductive Health"
        case .mentalHealth: return "Mental Health"
        case .respiratory: return "Respiratory"
        case .geneticMarkers: return "Genetic Markers"
        }
    }
}

/// Integrated health assessment
struct IntegratedAssessment: Codable, Sendable {
    let overallRisk: RiskLevel
    let keyFindings: [String]
    let correlations: [String]
    let systemicConcerns: [String]
    let preventiveActions: [String]
    let monitoringRecommendations: [String]
}

/// Health recommendations structure
struct HealthRecommendations: Codable, Sendable {
    let immediate: [ImmediateRecommendation]
    let shortTerm: [HealthRecommendation]
    let longTerm: [HealthRecommendation]
    let lifestyle: [HealthRecommendation]
    let medical: [HealthRecommendation]
    let monitoring: [HealthRecommendation]
}

/// Immediate recommendation
struct ImmediateRecommendation: Codable, Sendable {
    let recommendation: String
    let priority: RecommendationPriority
    let timeframe: String
    let reason: String
    let actionSteps: [String]
}

/// Analysis summary
struct AnalysisSummary: Codable, Sendable {
    let keyInsights: [String]
    let primaryConcerns: [String]
    let positiveFindings: [String]
    let actionRequired: Bool
    let urgencyLevel: UrgencyLevel
    let nextSteps: [String]
}

/// Urgency level enumeration
enum UrgencyLevel: String, Codable, CaseIterable, Sendable {
    case routine = "routine"
    case moderate = "moderate"
    case urgent = "urgent"
    case immediate = "immediate"
    
    var displayName: String {
        switch self {
        case .routine: return "Routine"
        case .moderate: return "Moderate"
        case .urgent: return "Urgent"
        case .immediate: return "Immediate"
        }
    }
}

// HealthAnalysisPreferences is now defined in core/Models/APIModels/HealthAnalysisPreferences.swift

/// Risk tolerance level
enum RiskTolerance: String, Codable, CaseIterable, Sendable {
    case conservative = "conservative"
    case moderate = "moderate"
    case aggressive = "aggressive"
    
    var displayName: String {
        switch self {
        case .conservative: return "Conservative"
        case .moderate: return "Moderate"
        case .aggressive: return "Aggressive"
        }
    }
}

/// Analysis detail level
enum DetailLevel: String, Codable, CaseIterable, Sendable {
    case basic = "basic"
    case standard = "standard"
    case comprehensive = "comprehensive"
    
    var displayName: String {
        switch self {
        case .basic: return "Basic"
        case .standard: return "Standard"
        case .comprehensive: return "Comprehensive"
        }
    }
}


