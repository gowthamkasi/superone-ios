//
//  UploadHistoryModels.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import Foundation
import SwiftUI

// MARK: - Extended Upload History Models
// Note: Core models like UploadHistoryResponse and PaginationInfo are defined in UploadModels.swift
// This file contains additional models specific to upload history management

// MARK: - Supporting Enums
// MARK: - Type References
// Note: HistoryTimeRange, UploadHistoryFilter, HistoryItem, and UploadStatistics 
// are defined in UploadHistoryViewModel.swift to avoid circular dependencies

/// Backend processing statistics response model
struct BackendProcessingStatisticsResponse: Codable {
    let success: Bool
    let data: BackendProcessingStatistics
    let message: String?
}

/// Backend processing statistics data structure
struct BackendProcessingStatistics: Codable {
    let total: Int
    let completed: Int
    let failed: Int
    let inProgress: Int
    let cancelled: Int
    let totalFileSize: Int64
}

/// Detailed upload metrics for analytics
struct UploadMetrics: Codable {
    let totalUploads: Int
    let completedUploads: Int
    let failedUploads: Int
    let processingUploads: Int
    let cancelledUploads: Int
    
    let totalDataSize: Int64
    let averageFileSize: Int64
    let largestFileSize: Int64
    let smallestFileSize: Int64
    
    let averageProcessingTime: Double
    let fastestProcessingTime: Double
    let slowestProcessingTime: Double
    
    let uploadsByFileType: [String: Int]
    let uploadsByDocumentType: [String: Int]
    let uploadsByHealthCategory: [String: Int]
    
    let dailyUploads: [DailyUploadCount]
    let monthlyUploads: [MonthlyUploadCount]
    
    let successRateByFileType: [String: Double]
    let errorCategories: [String: Int]
    
    var overallSuccessRate: Double {
        guard totalUploads > 0 else { return 0.0 }
        return Double(completedUploads) / Double(totalUploads)
    }
    
    var totalDataSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: totalDataSize, countStyle: .file)
    }
    
    var averageFileSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: averageFileSize, countStyle: .file)
    }
}

/// Daily upload count for analytics
struct DailyUploadCount: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let successCount: Int
    let failureCount: Int
    
    nonisolated private enum CodingKeys: String, CodingKey {
        case date, count, successCount, failureCount
    }
    
    var successRate: Double {
        guard count > 0 else { return 0.0 }
        return Double(successCount) / Double(count)
    }
}

/// Monthly upload count for analytics
struct MonthlyUploadCount: Codable, Identifiable {
    let id = UUID()
    let year: Int
    let month: Int
    let count: Int
    let successCount: Int
    let failureCount: Int
    let totalDataSize: Int64
    
    nonisolated private enum CodingKeys: String, CodingKey {
        case year, month, count, successCount, failureCount, totalDataSize
    }
    
    var date: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return calendar.date(from: components) ?? Date()
    }
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    var successRate: Double {
        guard count > 0 else { return 0.0 }
        return Double(successCount) / Double(count)
    }
    
    var totalDataSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: totalDataSize, countStyle: .file)
    }
}

// MARK: - History Filter Models

/// Request model for filtering upload history
struct HistoryFilterRequest: Codable, Sendable {
    let timeRange: String?  // Use String instead of enum to avoid circular dependencies
    let status: String?     // Use String instead of enum to avoid circular dependencies
    let documentTypes: [String]?
    let healthCategories: [String]?
    let minFileSize: Int64?
    let maxFileSize: Int64?
    let searchQuery: String?
    let sortBy: HistorySortOption?
    let sortOrder: SortOrder?
    
    enum HistorySortOption: String, CaseIterable, Codable {
        case uploadDate = "upload_date"
        case fileName = "file_name"
        case fileSize = "file_size"
        case processingTime = "processing_time"
        case status = "status"
        
        var displayName: String {
            switch self {
            case .uploadDate: return "Upload Date"
            case .fileName: return "File Name"
            case .fileSize: return "File Size"
            case .processingTime: return "Processing Time"
            case .status: return "Status"
            }
        }
    }
    
    enum SortOrder: String, CaseIterable, Codable {
        case ascending = "asc"
        case descending = "desc"
        
        var displayName: String {
            switch self {
            case .ascending: return "Ascending"
            case .descending: return "Descending"
            }
        }
    }
}

// MARK: - Batch History Operations

/// Request model for batch operations on history items
struct BatchHistoryOperationRequest: Codable {
    let operation: BatchOperation
    let itemIds: [String]
    let filters: HistoryFilterRequest?
    
    enum BatchOperation: String, Codable {
        case delete = "delete"
        case reprocess = "reprocess"
        case archive = "archive"
        case export = "export"
    }
}

/// Response model for batch operations
struct BatchHistoryOperationResponse: Codable {
    let success: Bool
    let data: BatchOperationResult
    let message: String?
    
    struct BatchOperationResult: Codable {
        let operation: BatchHistoryOperationRequest.BatchOperation
        let processedCount: Int
        let failedCount: Int
        let failedItems: [BatchFailedItem]?
        let exportUrl: String? // For export operations
    }
    
    struct BatchFailedItem: Codable {
        let itemId: String
        let fileName: String
        let error: String
    }
}

// MARK: - Upload Trends and Analytics

/// Upload trends data for dashboard charts
struct UploadTrendsData: Codable, Sendable {
    let timeRange: String  // Use String instead of enum to avoid circular dependencies
    let dataPoints: [TrendDataPoint]
    let summary: TrendSummary
    
    struct TrendDataPoint: Codable, Identifiable {
        let id = UUID()
        let date: Date
        let uploads: Int
        let successfulUploads: Int
        let failedUploads: Int
        let totalDataSize: Int64
        let averageProcessingTime: Double
        
        nonisolated private enum CodingKeys: String, CodingKey {
            case date, uploads, successfulUploads, failedUploads, totalDataSize, averageProcessingTime
        }
        
        var successRate: Double {
            guard uploads > 0 else { return 0.0 }
            return Double(successfulUploads) / Double(uploads)
        }
    }
    
    struct TrendSummary: Codable {
        let totalUploads: Int
        let averageUploadsPerDay: Double
        let peakUploadDay: Date?
        let peakUploadCount: Int
        let improvementPercentage: Double // Compared to previous period
        let mostCommonFileType: String?
        let mostCommonDocumentType: String?
    }
}

/// Health insights derived from upload history
struct UploadHealthInsights: Codable {
    let totalLabReportsAnalyzed: Int
    let healthCategoriesCovered: [String]
    let biomarkersTracked: [String]
    let trendsIdentified: [HealthTrendInsight]
    let recommendations: [UploadRecommendation]
    
    struct HealthTrendInsight: Codable, Identifiable {
        let id = UUID()
        let category: String
        let trend: String // "improving", "stable", "declining"
        let description: String
        let confidenceLevel: Double
        let biomarkers: [String]
        
        nonisolated private enum CodingKeys: String, CodingKey {
            case category, trend, description, confidenceLevel, biomarkers
        }
    }
    
    struct UploadRecommendation: Codable, Identifiable {
        let id = UUID()
        let type: RecommendationType
        let title: String
        let description: String
        let priority: Priority
        let actionUrl: String?
        
        nonisolated private enum CodingKeys: String, CodingKey {
            case type, title, description, priority, actionUrl
        }
        
        enum RecommendationType: String, Codable {
            case uploadFrequency = "upload_frequency"
            case documentQuality = "document_quality"
            case healthCategory = "health_category"
            case followUp = "follow_up"
        }
        
        enum Priority: String, Codable {
            case low = "low"
            case medium = "medium"
            case high = "high"
        }
    }
}

// MARK: - Error Models

/// Detailed error information for history operations
struct HistoryErrorDetails: Codable {
    let errorCode: String
    let errorType: HistoryErrorType
    let message: String
    let details: String?
    let timestamp: Date
    let retryable: Bool
    let suggestedAction: String?
    
    enum HistoryErrorType: String, Codable {
        case networkError = "network_error"
        case authenticationError = "authentication_error"
        case validationError = "validation_error"
        case notFoundError = "not_found_error"
        case serverError = "server_error"
        case rateLimitError = "rate_limit_error"
        case storageError = "storage_error"
    }
}

// MARK: - Cache Models

/// Cache metadata for upload history
struct HistoryCacheMetadata: Codable {
    let lastUpdated: Date
    let cacheVersion: String
    let itemCount: Int
    let totalSize: Int64
    let expiryDate: Date
    let checksumHash: String
    
    var isExpired: Bool {
        return Date() > expiryDate
    }
    
    var ageInMinutes: Int {
        return Int(Date().timeIntervalSince(lastUpdated) / 60)
    }
}

/// Cached history data structure
struct CachedHistoryData: Codable, Sendable {
    let metadata: HistoryCacheMetadata
    let items: [String]  // Use String array for item IDs to avoid circular dependencies
    let statistics: String?  // Use String to serialize statistics JSON
    let filters: HistoryFilterRequest?
    
    func isValid() -> Bool {
        return !metadata.isExpired && !items.isEmpty
    }
}

// MARK: - Extensions

// Extension removed to avoid type ambiguity - use items property directly

// Note: HistoryItem extension moved to UploadHistoryViewModel.swift to avoid circular dependencies

// Note: UploadStatus extension moved to UploadHistoryViewModel.swift to avoid circular dependencies

// MARK: - Helper Extensions

// Note: Array extensions for HistoryItem moved to UploadHistoryViewModel.swift to avoid circular dependencies