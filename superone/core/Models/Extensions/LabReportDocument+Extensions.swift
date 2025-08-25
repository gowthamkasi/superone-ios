//
//  LabReportDocument+Extensions.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import Foundation
import SwiftUI

extension LabReportDocument {
    
    /// Formatted file size for display
    var fileSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    /// Check if document can be processed
    var canProcess: Bool {
        return processingStatus == .pending || processingStatus == .failed
    }
    
    // Note: canRetryProcessing and isProcessing are already defined in the main LabReportDocument struct
    
    /// Check if document processing is complete
    var isCompleted: Bool {
        return processingStatus == .completed
    }
    
    /// Check if document processing failed
    var hasFailed: Bool {
        return processingStatus == .failed
    }
    
    /// Get file type icon name
    var fileTypeIcon: String {
        switch mimeType {
        case "application/pdf":
            return "doc.fill"
        case "image/jpeg", "image/png", "image/heic":
            return "photo.fill"
        default:
            return "doc.fill"
        }
    }
    
    /// Get file type display name
    var fileTypeDisplayName: String {
        switch mimeType {
        case "application/pdf":
            return "PDF Document"
        case "image/jpeg":
            return "JPEG Image"
        case "image/png":
            return "PNG Image"
        case "image/heic":
            return "HEIC Image"
        default:
            return "Document"
        }
    }
    
    /// Check if document has data loaded
    var hasData: Bool {
        return data != nil && data!.count > 0
    }
    
    /// Get upload date formatted for display
    var uploadDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: uploadDate)
    }
    
    /// Get relative upload date (e.g., "2 hours ago")
    var uploadDateRelative: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: uploadDate, relativeTo: Date())
    }
    
    /// Check if document is a PDF
    var isPDF: Bool {
        return mimeType == "application/pdf"
    }
    
    /// Check if document is an image
    var isImage: Bool {
        return mimeType.hasPrefix("image/")
    }
    
    /// Get processing duration if available
    var processingDuration: TimeInterval? {
        // This would need to be calculated based on processing start/end times
        // For now, return nil as this data isn't stored in the model
        return nil
    }
    
    /// AI-generated insights for the document (computed property)
    var aiInsights: [String]? {
        // This would be populated from analysis results
        // For now, return mock data based on document type and health category
        guard processingStatus == .completed else { return nil }
        
        return [
            "Your cholesterol levels show improvement from last test",
            "Vitamin D levels are below optimal range",
            "Blood sugar levels are within normal range"
        ]
    }
    
    /// Key biomarkers extracted from the document (computed property)
    var keyBiomarkers: [BiomarkerResult]? {
        // This would be populated from extracted biomarkers
        // For now, return mock data for UI development
        guard processingStatus == .completed else { return nil }
        
        return [
            BiomarkerResult(name: "Total Cholesterol", value: "185", unit: "mg/dL", status: .normal),
            BiomarkerResult(name: "HDL Cholesterol", value: "45", unit: "mg/dL", status: .normal),
            BiomarkerResult(name: "Glucose", value: "95", unit: "mg/dL", status: .normal)
        ]
    }
    
    /// Validate document for upload
    func validateForUpload() throws {
        // Check if file has data
        guard hasData else {
            throw DocumentValidationError.noData
        }
        
        // Check file size (10MB limit)
        let maxSize: Int64 = 10 * 1024 * 1024
        guard fileSize <= maxSize else {
            throw DocumentValidationError.fileTooLarge(fileSize, maxSize)
        }
        
        // Check MIME type
        let allowedTypes = ["application/pdf", "image/jpeg", "image/png", "image/heic"]
        guard allowedTypes.contains(mimeType) else {
            throw DocumentValidationError.unsupportedFileType(mimeType)
        }
        
        // Check file name
        guard !fileName.isEmpty else {
            throw DocumentValidationError.invalidFileName
        }
    }
    
    /// Create a copy of the document with updated status
    func withUpdatedStatus(_ status: ProcessingStatus) -> LabReportDocument {
        return LabReportDocument(
            id: self.id,
            fileName: self.fileName,
            filePath: self.filePath,
            fileSize: self.fileSize,
            mimeType: self.mimeType,
            uploadDate: self.uploadDate,
            processingStatus: status,
            documentType: self.documentType,
            healthCategory: self.healthCategory,
            extractedText: self.extractedText,
            ocrConfidence: self.ocrConfidence,
            thumbnail: self.thumbnail,
            metadata: self.metadata,
            data: self.data
        )
    }
    
    /// Create a copy of the document with updated extracted text
    func withExtractedText(_ text: String, confidence: Double) -> LabReportDocument {
        return LabReportDocument(
            id: self.id,
            fileName: self.fileName,
            filePath: self.filePath,
            fileSize: self.fileSize,
            mimeType: self.mimeType,
            uploadDate: self.uploadDate,
            processingStatus: self.processingStatus,
            documentType: self.documentType,
            healthCategory: self.healthCategory,
            extractedText: text,
            ocrConfidence: confidence,
            thumbnail: self.thumbnail,
            metadata: self.metadata,
            data: self.data
        )
    }
}

// MARK: - ProcessingStatus Extensions

// Note: ProcessingStatus.displayName is already defined in BackendModels.swift

extension ProcessingStatus {
    
    /// Description of what the status means
    var description: String {
        switch self {
        case .pending:
            return "Waiting to be processed"
        case .uploading:
            return "Uploading document"
        case .preprocessing:
            return "Preparing document for processing"
        case .processing:
            return "Document is being processed"
        case .analyzing:
            return "Analyzing extracted data"
        case .extracting:
            return "Extracting biomarkers"
        case .validating:
            return "Validating extracted data"
        case .retrying:
            return "Retrying processing"
        case .paused:
            return "Processing paused"
        case .completed:
            return "Processing completed successfully"
        case .failed:
            return "Processing failed"
        case .cancelled:
            return "Processing was cancelled"
        }
    }
    
    /// Check if status indicates processing is in progress
    var isInProgress: Bool {
        return self == .uploading || self == .preprocessing || self == .processing || self == .analyzing || self == .extracting || self == .validating || self == .retrying
    }
    
    /// Check if status indicates completion (success or failure)
    var isTerminal: Bool {
        return self == .completed || self == .failed || self == .cancelled
    }
    
    /// Check if status allows retry
    var allowsRetry: Bool {
        return self == .failed || self == .cancelled
    }
}

// MARK: - Document Validation Errors

enum DocumentValidationError: Error, LocalizedError {
    case noData
    case fileTooLarge(Int64, Int64)
    case unsupportedFileType(String)
    case invalidFileName
    case corruptedData
    
    nonisolated var errorDescription: String? {
        switch self {
        case .noData:
            return "Document has no data"
        case .fileTooLarge(let size, let maxSize):
            let sizeStr = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            let maxSizeStr = ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)
            return "File size (\(sizeStr)) exceeds maximum allowed (\(maxSizeStr))"
        case .unsupportedFileType(let type):
            return "File type '\(type)' is not supported"
        case .invalidFileName:
            return "Invalid or empty file name"
        case .corruptedData:
            return "File data appears to be corrupted"
        }
    }
}

// MARK: - Collection Extensions

extension Array where Element == LabReportDocument {
    
    /// Filter documents by processing status
    func withStatus(_ status: ProcessingStatus) -> [LabReportDocument] {
        return self.filter { $0.processingStatus == status }
    }
    
    /// Get pending documents
    var pending: [LabReportDocument] {
        return withStatus(.pending)
    }
    
    /// Get processing documents
    var processing: [LabReportDocument] {
        return self.filter { $0.isProcessing }
    }
    
    /// Get completed documents
    var completed: [LabReportDocument] {
        return withStatus(.completed)
    }
    
    /// Get failed documents
    var failed: [LabReportDocument] {
        return withStatus(.failed)
    }
    
    /// Get documents that can be retried
    var retriable: [LabReportDocument] {
        return self.filter { $0.canRetryProcessing }
    }
    
    /// Get total file size of all documents
    var totalFileSize: Int64 {
        return self.reduce(0) { $0 + $1.fileSize }
    }
    
    /// Get formatted total file size
    var totalFileSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: totalFileSize, countStyle: .file)
    }
    
    /// Sort documents by upload date (newest first)
    var sortedByUploadDate: [LabReportDocument] {
        return self.sorted { $0.uploadDate > $1.uploadDate }
    }
    
    /// Sort documents by file name
    var sortedByFileName: [LabReportDocument] {
        return self.sorted { $0.fileName.localizedCaseInsensitiveCompare($1.fileName) == .orderedAscending }
    }
    
    /// Sort documents by file size (largest first)
    var sortedByFileSize: [LabReportDocument] {
        return self.sorted { $0.fileSize > $1.fileSize }
    }
    
    /// Group documents by processing status
    var groupedByStatus: [ProcessingStatus: [LabReportDocument]] {
        return Dictionary(grouping: self) { $0.processingStatus }
    }
    
    /// Get processing statistics
    var processingStats: DocumentProcessingStatistics {
        let statusCounts = groupedByStatus.mapValues { $0.count }
        return DocumentProcessingStatistics(
            total: self.count,
            pending: statusCounts[.pending] ?? 0,
            processing: statusCounts[.processing] ?? 0,
            analyzing: statusCounts[.analyzing] ?? 0,
            completed: statusCounts[.completed] ?? 0,
            failed: statusCounts[.failed] ?? 0,
            cancelled: statusCounts[.cancelled] ?? 0,
            totalFileSize: totalFileSize
        )
    }
}

// MARK: - Document Processing Statistics

struct DocumentProcessingStatistics {
    let total: Int
    let pending: Int
    let processing: Int
    let analyzing: Int
    let completed: Int
    let failed: Int
    let cancelled: Int
    let totalFileSize: Int64
    
    var inProgress: Int {
        return processing + analyzing
    }
    
    var terminal: Int {
        return completed + failed + cancelled
    }
    
    var successRate: Double {
        guard total > 0 else { return 0.0 }
        return Double(completed) / Double(total)
    }
    
    var failureRate: Double {
        guard total > 0 else { return 0.0 }
        return Double(failed) / Double(total)
    }
    
    var totalFileSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: totalFileSize, countStyle: .file)
    }
}