//
//  UploadHistoryViewModel.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import Foundation
import Combine

/// ViewModel for managing upload history and statistics
@MainActor
@Observable
final class UploadHistoryViewModel {
    
    // MARK: - Published Properties
    
    /// All history items
    var allHistory: [HistoryItem] = []
    
    /// Filtered history based on current filters
    var filteredHistory: [HistoryItem] = []
    
    /// Overall statistics
    var statistics: UploadStatistics = UploadStatistics()
    
    /// Loading state
    var isLoading: Bool = false
    var loadingError: HistoryError? = nil
    
    /// Filter settings
    var selectedTimeRange: HistoryTimeRange = .lastMonth {
        didSet { applyFilters() }
    }
    
    var selectedFilter: UploadHistoryFilter = .all {
        didSet { applyFilters() }
    }
    
    var searchText: String = "" {
        didSet { applyFilters() }
    }
    
    // MARK: - Private Properties
    
    private let labReportAPIService = LabReportAPIService.shared
    private let uploadStatusService = UploadStatusService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Pagination
    private var currentPage = 1
    private let itemsPerPage = 20
    private var hasMoreItems = true
    
    // Cache
    private var cacheExpiryDate: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Load upload history from the server
    func loadHistory() async {
        guard !isLoading else { return }
        
        isLoading = true
        loadingError = nil
        
        do {
            // Check cache first
            if isCacheValid() {
                isLoading = false
                return
            }
            
            // Load from API
            let historyResponse = try await labReportAPIService.getUploadHistory(
                page: 1,
                limit: itemsPerPage * 3 // Load more initially
            )
            
            allHistory = historyResponse.uploads.map { convertToHistoryItem($0) }
            
            // Calculate statistics
            await calculateStatistics()
            
            // Apply current filters
            applyFilters()
            
            // Update cache
            updateCache()
            
        } catch {
            loadingError = HistoryError.loadFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// Refresh history data
    func refreshHistory() async {
        clearCache()
        currentPage = 1
        hasMoreItems = true
        await loadHistory()
    }
    
    /// Load more history items (pagination)
    func loadMoreIfNeeded() async {
        guard hasMoreItems && !isLoading else { return }
        
        do {
            currentPage += 1
            let historyResponse = try await labReportAPIService.getUploadHistory(
                page: currentPage,
                limit: itemsPerPage
            )
            
            allHistory.append(contentsOf: historyResponse.uploads.map { convertToHistoryItem($0) })
            hasMoreItems = historyResponse.pagination.currentPage < historyResponse.pagination.totalPages
            
            applyFilters()
            
        } catch {
            currentPage -= 1 // Revert page increment
        }
    }
    
    /// Delete a specific history item
    func deleteHistoryItem(_ item: HistoryItem) async {
        do {
            try await labReportAPIService.deleteUpload(item.labReportId)
            
            // Remove from local arrays
            allHistory.removeAll { $0.id == item.id }
            filteredHistory.removeAll { $0.id == item.id }
            
            // Recalculate statistics
            await calculateStatistics()
            
        } catch {
            loadingError = HistoryError.deleteFailed(error.localizedDescription)
        }
    }
    
    /// Clear all upload history
    func clearAllHistory() async {
        do {
            // Delete all items from server
            for item in allHistory {
                try await labReportAPIService.deleteUpload(item.labReportId)
            }
            
            // Clear local data
            allHistory.removeAll()
            filteredHistory.removeAll()
            statistics = UploadStatistics()
            
            clearCache()
            
        } catch {
            loadingError = HistoryError.clearFailed(error.localizedDescription)
        }
    }
    
    /// Reprocess a failed document
    func reprocessDocument(_ item: HistoryItem) async {
        // This would trigger reprocessing on the server
        // For now, we'll simulate it by updating the status
        
        if let index = allHistory.firstIndex(where: { $0.id == item.id }) {
            allHistory[index] = item.withStatus(.processing)
            applyFilters()
        }
        
        // In a real implementation, this would call the reprocess API
        // try await labReportAPIService.reprocessDocument(item.labReportId)
    }
    
    /// Get count for a specific filter
    func getCount(for filter: UploadHistoryFilter) -> Int {
        switch filter {
        case .all:
            return allHistory.count
        case .completed:
            return allHistory.filter { $0.status == .completed }.count
        case .failed:
            return allHistory.filter { $0.status == .failed }.count
        case .processing:
            return allHistory.filter { $0.status == .processing }.count
        }
    }
    
    /// Export history data
    func exportHistory(format: ExportFormat) -> Data? {
        switch format {
        case .csv:
            return exportToCSV()
        case .json:
            return exportToJSON()
        case .pdf:
            return exportToPDF()
        default:
            return nil
        }
    }
    
    // MARK: - Private Implementation
    
    private func setupBindings() {
        // Listen for new uploads to update history
        NotificationCenter.default.publisher(for: .newUploadCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let uploadResult = notification.object as? LabReportUploadResult {
                    self?.addNewHistoryItem(from: uploadResult)
                }
            }
            .store(in: &cancellables)
    }
    
    private func applyFilters() {
        var filtered = allHistory
        
        // Apply time range filter
        let timeRangeDate = selectedTimeRange.startDate
        filtered = filtered.filter { $0.uploadDate >= timeRangeDate }
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break // No status filter
        case .completed:
            filtered = filtered.filter { $0.status == .completed }
        case .failed:
            filtered = filtered.filter { $0.status == .failed }
        case .processing:
            filtered = filtered.filter { $0.status == .processing }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.fileName.localizedCaseInsensitiveContains(searchText) ||
                item.documentType?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Sort by upload date (newest first)
        filtered.sort { $0.uploadDate > $1.uploadDate }
        
        filteredHistory = filtered
    }
    
    private func calculateStatistics() async {
        let total = allHistory.count
        let completed = allHistory.filter { $0.status == .completed }.count
        let failed = allHistory.filter { $0.status == .failed }.count
        
        let successRate = total > 0 ? Double(completed) / Double(total) : 0.0
        
        let totalSize = allHistory.reduce(0) { $0 + $1.fileSize }
        
        let processingTimes = allHistory.compactMap { $0.processingTime }
        let averageProcessingTime = processingTimes.isEmpty ? 0 : processingTimes.reduce(0, +) / processingTimes.count
        
        let thisMonthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        let uploadsThisMonth = allHistory.filter { $0.uploadDate >= thisMonthStart }.count
        
        statistics = UploadStatistics(
            totalUploads: total,
            completedUploads: completed,
            failedUploads: failed,
            successRate: successRate,
            totalDataProcessed: totalSize,
            averageProcessingTime: averageProcessingTime,
            uploadsThisMonth: uploadsThisMonth
        )
    }
    
    private func addNewHistoryItem(from uploadResult: LabReportUploadResult) {
        let historyItem = HistoryItem(
            id: UUID().uuidString,
            labReportId: uploadResult.labReportId,
            fileName: uploadResult.fileName,
            fileSize: uploadResult.fileSize,
            uploadDate: uploadResult.timestamp,
            status: HistoryItemStatus(from: uploadResult.uploadStatus),
            documentType: uploadResult.documentType?.rawValue,
            processingTime: nil, // Will be updated when processing completes
            biomarkerCount: nil,
            errorMessage: nil
        )
        
        allHistory.insert(historyItem, at: 0) // Add to beginning
        applyFilters()
        
        Task {
            await calculateStatistics()
        }
    }
    
    // MARK: - Cache Management
    
    private func isCacheValid() -> Bool {
        guard let expiryDate = cacheExpiryDate else { return false }
        return Date() < expiryDate && !allHistory.isEmpty
    }
    
    private func updateCache() {
        cacheExpiryDate = Date().addingTimeInterval(cacheValidityDuration)
    }
    
    private func clearCache() {
        cacheExpiryDate = nil
    }
    
    // MARK: - Export Methods
    
    private func exportToCSV() -> Data? {
        var csvString = "File Name,Upload Date,Status,File Size,Processing Time,Biomarkers\n"
        
        for item in filteredHistory {
            let processingTimeStr = item.processingTime.map { "\($0)s" } ?? ""
            let biomarkerCountStr = item.biomarkerCount.map { "\($0)" } ?? ""
            
            csvString += "\"\(item.fileName)\",\(item.uploadDate),\(item.status.rawValue),\(item.fileSize),\(processingTimeStr),\(biomarkerCountStr)\n"
        }
        
        return csvString.data(using: .utf8)
    }
    
    private func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let exportData = HistoryExportData(
            exportDate: Date(),
            statistics: statistics,
            history: filteredHistory
        )
        
        return try? encoder.encode(exportData)
    }
    
    private func exportToPDF() -> Data? {
        // This would generate a PDF report
        // For now, return nil as PDF generation would require additional libraries
        return nil
    }
    
    private func convertToHistoryItem(_ response: LabReportResponse) -> HistoryItem {
        return HistoryItem(
            id: response.id,
            labReportId: response.id,
            fileName: response.document.fileName,
            fileSize: response.document.fileSize,
            uploadDate: response.createdAt,
            status: HistoryItemStatus.fromProcessingStatus(response.processingStatus.rawValue),
            documentType: response.document.documentType?.rawValue,
            processingTime: nil, // Calculate from processing duration if available
            biomarkerCount: response.extractedBiomarkers.count,
            errorMessage: nil
        )
    }
}

// MARK: - Supporting Types

enum HistoryTimeRange: String, CaseIterable {
    case lastWeek = "last_week"
    case lastMonth = "last_month"
    case last3Months = "last_3_months"
    case last6Months = "last_6_months"
    case lastYear = "last_year"
    case allTime = "all_time"
    
    var displayName: String {
        switch self {
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .last3Months: return "Last 3 Months"
        case .last6Months: return "Last 6 Months"
        case .lastYear: return "Last Year"
        case .allTime: return "All Time"
        }
    }
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .lastWeek:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .lastMonth:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .last3Months:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .last6Months:
            return calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .lastYear:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .allTime:
            return Date(timeIntervalSince1970: 0)
        }
    }
}

enum UploadHistoryFilter: String, CaseIterable {
    case all = "all"
    case completed = "completed"
    case failed = "failed"
    case processing = "processing"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .processing: return "Processing"
        }
    }
}

struct UploadStatistics: Codable {
    let totalUploads: Int
    let completedUploads: Int
    let failedUploads: Int
    let successRate: Double
    let totalDataProcessed: Int64
    let averageProcessingTime: Int
    let uploadsThisMonth: Int
    
    init() {
        self.totalUploads = 0
        self.completedUploads = 0
        self.failedUploads = 0
        self.successRate = 0.0
        self.totalDataProcessed = 0
        self.averageProcessingTime = 0
        self.uploadsThisMonth = 0
    }
    
    init(totalUploads: Int, completedUploads: Int, failedUploads: Int, successRate: Double, totalDataProcessed: Int64, averageProcessingTime: Int, uploadsThisMonth: Int) {
        self.totalUploads = totalUploads
        self.completedUploads = completedUploads
        self.failedUploads = failedUploads
        self.successRate = successRate
        self.totalDataProcessed = totalDataProcessed
        self.averageProcessingTime = averageProcessingTime
        self.uploadsThisMonth = uploadsThisMonth
    }
    
    var totalDataProcessedFormatted: String {
        return ByteCountFormatter.string(fromByteCount: totalDataProcessed, countStyle: .file)
    }
    
    var averageProcessingTimeFormatted: String {
        if averageProcessingTime < 60 {
            return "\(averageProcessingTime)s"
        } else {
            let minutes = averageProcessingTime / 60
            return "\(minutes)m"
        }
    }
}

struct HistoryItem: Identifiable, Codable {
    let id: String
    let labReportId: String
    let fileName: String
    let fileSize: Int64
    let uploadDate: Date
    var status: HistoryItemStatus
    let documentType: String?
    let processingTime: Int? // seconds
    let biomarkerCount: Int?
    let errorMessage: String?
    
    var fileSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var uploadDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: uploadDate)
    }
    
    func withStatus(_ newStatus: HistoryItemStatus) -> HistoryItem {
        return HistoryItem(
            id: self.id,
            labReportId: self.labReportId,
            fileName: self.fileName,
            fileSize: self.fileSize,
            uploadDate: self.uploadDate,
            status: newStatus,
            documentType: self.documentType,
            processingTime: self.processingTime,
            biomarkerCount: self.biomarkerCount,
            errorMessage: self.errorMessage
        )
    }
}

enum HistoryItemStatus: String, Codable {
    case completed = "completed"
    case failed = "failed"
    case processing = "processing"
    case cancelled = "cancelled"
    
    init(from uploadStatus: UploadStatus) {
        switch uploadStatus {
        case .completed: self = .completed
        case .failed: self = .failed
        case .uploading, .processing, .analyzing: self = .processing
        case .cancelled: self = .cancelled
        }
    }
    
    static func fromProcessingStatus(_ status: String) -> HistoryItemStatus {
        switch status.lowercased() {
        case "completed": return .completed
        case "failed": return .failed
        case "processing", "uploading", "analyzing": return .processing
        case "cancelled": return .cancelled
        default: return .processing
        }
    }
    
    func toProcessingStatus() -> ProcessingStatus {
        switch self {
        case .completed: return .completed
        case .failed: return .failed
        case .processing: return .processing
        case .cancelled: return .cancelled
        }
    }
}

struct HistoryExportData: Codable {
    let exportDate: Date
    let statistics: UploadStatistics
    let history: [HistoryItem]
}

enum HistoryError: Error, LocalizedError {
    case loadFailed(String)
    case deleteFailed(String)
    case clearFailed(String)
    case exportFailed(String)
    
    nonisolated var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return "Failed to load history: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete item: \(message)"
        case .clearFailed(let message):
            return "Failed to clear history: \(message)"
        case .exportFailed(let message):
            return "Failed to export data: \(message)"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let newUploadCompleted = Notification.Name("newUploadCompleted")
}