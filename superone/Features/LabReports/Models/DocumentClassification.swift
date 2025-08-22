//
//  DocumentClassification.swift
//  SuperOne
//
//  Created by Claude Code on 7/27/25.
//

import Foundation
import SwiftUI

// MARK: - Document Classification Result
struct DocumentClassificationResult: Codable, Sendable {
    let documentId: String
    let primaryType: DocumentType
    let secondaryTypes: [DocumentType]
    let healthCategories: [HealthCategory]
    let confidence: Double
    let classificationMethod: ClassificationMethod
    let features: [ClassificationFeature]
    let suggestedProcessingPipeline: ProcessingPipeline
    let timestamp: Date
    
    init(
        documentId: String,
        primaryType: DocumentType,
        secondaryTypes: [DocumentType] = [],
        healthCategories: [HealthCategory] = [],
        confidence: Double,
        classificationMethod: ClassificationMethod,
        features: [ClassificationFeature] = [],
        suggestedProcessingPipeline: ProcessingPipeline,
        timestamp: Date = Date()
    ) {
        self.documentId = documentId
        self.primaryType = primaryType
        self.secondaryTypes = secondaryTypes
        self.healthCategories = healthCategories
        self.confidence = confidence
        self.classificationMethod = classificationMethod
        self.features = features
        self.suggestedProcessingPipeline = suggestedProcessingPipeline
        self.timestamp = timestamp
    }
    
    var isHighConfidence: Bool {
        return confidence >= 0.8
    }
    
    var needsManualReview: Bool {
        return confidence < 0.7 || primaryType == .other
    }
    
    var combinedCategories: [HealthCategory] {
        var categories = healthCategories
        if !categories.contains(primaryType.healthCategory) {
            categories.append(primaryType.healthCategory)
        }
        return categories.removingDuplicates()
    }
}

// MARK: - Classification Method
enum ClassificationMethod: String, CaseIterable, Codable, Sendable {
    case aiLocal = "ai_local"
    case aiCloud = "ai_cloud"
    case keywordMatching = "keyword_matching"
    case templateMatching = "template_matching"
    case headerAnalysis = "header_analysis"
    case contextAnalysis = "context_analysis"
    case hybrid = "hybrid"
    
    var displayName: String {
        switch self {
        case .aiLocal: return "Local AI Classification"
        case .aiCloud: return "Cloud AI Classification"
        case .keywordMatching: return "Keyword Matching"
        case .templateMatching: return "Template Matching"
        case .headerAnalysis: return "Header Analysis"
        case .contextAnalysis: return "Context Analysis"
        case .hybrid: return "Hybrid Classification"
        }
    }
    
    var reliability: Double {
        switch self {
        case .aiLocal: return 0.85
        case .aiCloud: return 0.95
        case .keywordMatching: return 0.70
        case .templateMatching: return 0.80
        case .headerAnalysis: return 0.75
        case .contextAnalysis: return 0.82
        case .hybrid: return 0.90
        }
    }
    
    var processingTime: TimeInterval {
        switch self {
        case .aiLocal: return 2.0
        case .aiCloud: return 5.0
        case .keywordMatching: return 0.5
        case .templateMatching: return 1.0
        case .headerAnalysis: return 0.8
        case .contextAnalysis: return 1.5
        case .hybrid: return 3.0
        }
    }
}

// MARK: - Classification Feature
struct ClassificationFeature: Codable, Identifiable, Sendable {
    let id: String
    let type: FeatureType
    let value: String
    let confidence: Double
    let weight: Double
    let textLocation: TextLocation?
    
    init(
        id: String = UUID().uuidString,
        type: FeatureType,
        value: String,
        confidence: Double,
        weight: Double,
        textLocation: TextLocation? = nil
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.confidence = confidence
        self.weight = weight
        self.textLocation = textLocation
    }
}

enum FeatureType: String, CaseIterable, Codable, Sendable {
    case header = "header"
    case keyword = "keyword"
    case testName = "test_name"
    case labName = "lab_name"
    case documentStructure = "document_structure"
    case valuePattern = "value_pattern"
    case unitPattern = "unit_pattern"
    case referenceRange = "reference_range"
    case datePattern = "date_pattern"
    case logoDetection = "logo_detection"
    
    var displayName: String {
        switch self {
        case .header: return "Document Header"
        case .keyword: return "Medical Keyword"
        case .testName: return "Test Name"
        case .labName: return "Laboratory Name"
        case .documentStructure: return "Document Structure"
        case .valuePattern: return "Value Pattern"
        case .unitPattern: return "Unit Pattern"
        case .referenceRange: return "Reference Range"
        case .datePattern: return "Date Pattern"
        case .logoDetection: return "Logo Detection"
        }
    }
}

// MARK: - Processing Pipeline
struct ProcessingPipeline: Codable, Sendable {
    let steps: [ProcessingStep]
    let estimatedDuration: TimeInterval
    let recommendedSettings: ProcessingSettings
    let fallbackStrategy: FallbackStrategy
    
    init(
        steps: [ProcessingStep],
        estimatedDuration: TimeInterval,
        recommendedSettings: ProcessingSettings,
        fallbackStrategy: FallbackStrategy
    ) {
        self.steps = steps
        self.estimatedDuration = estimatedDuration
        self.recommendedSettings = recommendedSettings
        self.fallbackStrategy = fallbackStrategy
    }
    
    static var `default`: ProcessingPipeline {
        ProcessingPipeline(
            steps: [
                ProcessingStep(type: .imagePreprocessing, estimatedDuration: 1.0),
                ProcessingStep(type: .ocrExtraction, estimatedDuration: 3.0),
                ProcessingStep(type: .textCleaning, estimatedDuration: 0.5),
                ProcessingStep(type: .biomarkerExtraction, estimatedDuration: 2.0),
                ProcessingStep(type: .dataValidation, estimatedDuration: 1.0),
                ProcessingStep(type: .resultSynthesis, estimatedDuration: 0.5)
            ],
            estimatedDuration: 8.0,
            recommendedSettings: ProcessingSettings.default,
            fallbackStrategy: .retryWithDifferentMethod
        )
    }
}

struct ProcessingStep: Codable, Identifiable, Sendable {
    let id: String
    let type: ProcessingStepType
    let estimatedDuration: TimeInterval
    let isOptional: Bool
    let dependencies: [String]
    
    init(
        id: String = UUID().uuidString,
        type: ProcessingStepType,
        estimatedDuration: TimeInterval,
        isOptional: Bool = false,
        dependencies: [String] = []
    ) {
        self.id = id
        self.type = type
        self.estimatedDuration = estimatedDuration
        self.isOptional = isOptional
        self.dependencies = dependencies
    }
}

enum ProcessingStepType: String, CaseIterable, Codable, Sendable {
    case imagePreprocessing = "image_preprocessing"
    case ocrExtraction = "ocr_extraction"
    case textCleaning = "text_cleaning"
    case documentClassification = "document_classification"
    case biomarkerExtraction = "biomarker_extraction"
    case dataValidation = "data_validation"
    case categoryMapping = "category_mapping"
    case referenceRangeAnalysis = "reference_range_analysis"
    case qualityAssurance = "quality_assurance"
    case resultSynthesis = "result_synthesis"
    
    var displayName: String {
        switch self {
        case .imagePreprocessing: return "Image Preprocessing"
        case .ocrExtraction: return "OCR Text Extraction"
        case .textCleaning: return "Text Cleaning"
        case .documentClassification: return "Document Classification"
        case .biomarkerExtraction: return "Biomarker Extraction"
        case .dataValidation: return "Data Validation"
        case .categoryMapping: return "Category Mapping"
        case .referenceRangeAnalysis: return "Reference Range Analysis"
        case .qualityAssurance: return "Quality Assurance"
        case .resultSynthesis: return "Result Synthesis"
        }
    }
    
    var icon: String {
        switch self {
        case .imagePreprocessing: return "camera.filters"
        case .ocrExtraction: return "doc.text.magnifyingglass"
        case .textCleaning: return "text.magnifyingglass"
        case .documentClassification: return "folder"
        case .biomarkerExtraction: return "text.line.first.and.arrowtriangle.forward"
        case .dataValidation: return "checkmark.seal"
        case .categoryMapping: return "tag"
        case .referenceRangeAnalysis: return "chart.bar"
        case .qualityAssurance: return "checkmark.circle"
        case .resultSynthesis: return "doc.text"
        }
    }
}

// MARK: - Processing Settings
struct ProcessingSettings: Codable, Sendable {
    let ocrMethod: ExtractionMethod
    let imageQualityThreshold: Double
    let confidenceThreshold: Double
    let enableAdvancedPatterns: Bool
    let enableManualReview: Bool
    let maxProcessingTime: TimeInterval
    let retryAttempts: Int
    let enableParallelProcessing: Bool
    
    init(
        ocrMethod: ExtractionMethod = .visionFramework,
        imageQualityThreshold: Double = 0.7,
        confidenceThreshold: Double = 0.6,
        enableAdvancedPatterns: Bool = true,
        enableManualReview: Bool = true,
        maxProcessingTime: TimeInterval = 30.0,
        retryAttempts: Int = 2,
        enableParallelProcessing: Bool = true
    ) {
        self.ocrMethod = ocrMethod
        self.imageQualityThreshold = imageQualityThreshold
        self.confidenceThreshold = confidenceThreshold
        self.enableAdvancedPatterns = enableAdvancedPatterns
        self.enableManualReview = enableManualReview
        self.maxProcessingTime = maxProcessingTime
        self.retryAttempts = retryAttempts
        self.enableParallelProcessing = enableParallelProcessing
    }
    
    static var `default`: ProcessingSettings {
        ProcessingSettings()
    }
    
    static var highAccuracy: ProcessingSettings {
        ProcessingSettings(
            ocrMethod: .visionFramework,
            imageQualityThreshold: 0.8,
            confidenceThreshold: 0.8,
            enableAdvancedPatterns: true,
            enableManualReview: true,
            maxProcessingTime: 60.0,
            retryAttempts: 3,
            enableParallelProcessing: true
        )
    }
    
    static var fastProcessing: ProcessingSettings {
        ProcessingSettings(
            ocrMethod: .visionFramework,
            imageQualityThreshold: 0.6,
            confidenceThreshold: 0.5,
            enableAdvancedPatterns: false,
            enableManualReview: false,
            maxProcessingTime: 15.0,
            retryAttempts: 1,
            enableParallelProcessing: true
        )
    }
}

// MARK: - Fallback Strategy
enum FallbackStrategy: String, CaseIterable, Codable, Sendable {
    case retryWithDifferentMethod = "retry_different_method"
    case lowerQualityThreshold = "lower_quality_threshold"
    case manualClassification = "manual_classification"
    case useDefaultTemplate = "use_default_template"
    case skipClassification = "skip_classification"
    
    var displayName: String {
        switch self {
        case .retryWithDifferentMethod: return "Try Different OCR Method"
        case .lowerQualityThreshold: return "Lower Quality Threshold"
        case .manualClassification: return "Manual Classification Required"
        case .useDefaultTemplate: return "Use Default Template"
        case .skipClassification: return "Skip Classification"
        }
    }
    
    var description: String {
        switch self {
        case .retryWithDifferentMethod:
            return "Automatically retry with a different OCR method if the primary method fails"
        case .lowerQualityThreshold:
            return "Reduce quality thresholds to accept lower confidence results"
        case .manualClassification:
            return "Present the document to the user for manual classification"
        case .useDefaultTemplate:
            return "Apply a generic template for basic biomarker extraction"
        case .skipClassification:
            return "Skip classification and proceed with general processing"
        }
    }
}

// MARK: - Document Template
struct DocumentTemplate: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let documentType: DocumentType
    let labName: String?
    let version: String
    let patterns: [BiomarkerPattern]
    let layout: TemplateLayout
    let isActive: Bool
    let confidence: Double
    let usageCount: Int
    let lastUsed: Date?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        documentType: DocumentType,
        labName: String? = nil,
        version: String = "1.0",
        patterns: [BiomarkerPattern] = [],
        layout: TemplateLayout,
        isActive: Bool = true,
        confidence: Double = 0.0,
        usageCount: Int = 0,
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.documentType = documentType
        self.labName = labName
        self.version = version
        self.patterns = patterns
        self.layout = layout
        self.isActive = isActive
        self.confidence = confidence
        self.usageCount = usageCount
        self.lastUsed = lastUsed
    }
}

struct TemplateLayout: Codable, Sendable {
    let headerRegion: BoundingBox
    let dataRegion: BoundingBox
    let footerRegion: BoundingBox?
    let columnLayout: ColumnLayout
    let textOrientation: TextOrientation
    
    init(
        headerRegion: BoundingBox,
        dataRegion: BoundingBox,
        footerRegion: BoundingBox? = nil,
        columnLayout: ColumnLayout,
        textOrientation: TextOrientation = .horizontal
    ) {
        self.headerRegion = headerRegion
        self.dataRegion = dataRegion
        self.footerRegion = footerRegion
        self.columnLayout = columnLayout
        self.textOrientation = textOrientation
    }
}

enum ColumnLayout: String, CaseIterable, Codable, Sendable {
    case singleColumn = "single_column"
    case twoColumn = "two_column"
    case threeColumn = "three_column"
    case table = "table"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .singleColumn: return "Single Column"
        case .twoColumn: return "Two Columns"
        case .threeColumn: return "Three Columns"
        case .table: return "Table Format"
        case .mixed: return "Mixed Layout"
        }
    }
}

enum TextOrientation: String, CaseIterable, Codable, Sendable {
    case horizontal = "horizontal"
    case vertical = "vertical"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .horizontal: return "Horizontal Text"
        case .vertical: return "Vertical Text"
        case .mixed: return "Mixed Orientation"
        }
    }
}

// MARK: - Biomarker Pattern
struct BiomarkerPattern: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let aliases: [String]
    let regex: String
    let unitPatterns: [String]
    let referenceRangePattern: String?
    let category: HealthCategory
    let expectedDataType: BiomarkerDataType
    let normalRange: NormalRange?
    let priority: PatternPriority
    
    init(
        id: String = UUID().uuidString,
        name: String,
        aliases: [String] = [],
        regex: String,
        unitPatterns: [String] = [],
        referenceRangePattern: String? = nil,
        category: HealthCategory,
        expectedDataType: BiomarkerDataType,
        normalRange: NormalRange? = nil,
        priority: PatternPriority = .medium
    ) {
        self.id = id
        self.name = name
        self.aliases = aliases
        self.regex = regex
        self.unitPatterns = unitPatterns
        self.referenceRangePattern = referenceRangePattern
        self.category = category
        self.expectedDataType = expectedDataType
        self.normalRange = normalRange
        self.priority = priority
    }
}

enum BiomarkerDataType: String, CaseIterable, Codable, Sendable {
    case numeric = "numeric"
    case categorical = "categorical"
    case text = "text"
    case boolean = "boolean"
    case range = "range"
    
    var displayName: String {
        switch self {
        case .numeric: return "Numeric Value"
        case .categorical: return "Category"
        case .text: return "Text"
        case .boolean: return "Yes/No"
        case .range: return "Range"
        }
    }
}

struct NormalRange: Codable, Sendable {
    let minValue: Double?
    let maxValue: Double?
    let unit: String
    let ageSpecific: [AgeRange]?
    let genderSpecific: [GenderRange]?
    
    init(
        minValue: Double? = nil,
        maxValue: Double? = nil,
        unit: String,
        ageSpecific: [AgeRange]? = nil,
        genderSpecific: [GenderRange]? = nil
    ) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.unit = unit
        self.ageSpecific = ageSpecific
        self.genderSpecific = genderSpecific
    }
}

struct AgeRange: Codable, Sendable {
    let minAge: Int
    let maxAge: Int
    let minValue: Double?
    let maxValue: Double?
    
    init(minAge: Int, maxAge: Int, minValue: Double? = nil, maxValue: Double? = nil) {
        self.minAge = minAge
        self.maxAge = maxAge
        self.minValue = minValue
        self.maxValue = maxValue
    }
}

struct GenderRange: Codable, Sendable {
    let gender: Gender
    let minValue: Double?
    let maxValue: Double?
    
    init(gender: Gender, minValue: Double? = nil, maxValue: Double? = nil) {
        self.gender = gender
        self.minValue = minValue
        self.maxValue = maxValue
    }
}

enum PatternPriority: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var weight: Double {
        switch self {
        case .low: return 0.25
        case .medium: return 0.50
        case .high: return 0.75
        case .critical: return 1.0
        }
    }
}


// MARK: - Array Extension for Removing Duplicates
extension Array where Element: Equatable {
    func removingDuplicates() -> [Element] {
        var result: [Element] = []
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}