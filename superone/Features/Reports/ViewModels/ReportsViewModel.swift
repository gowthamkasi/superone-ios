//
//  ReportsViewModel.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import Foundation
import SwiftUI

/// ViewModel for managing lab reports display and interactions
@MainActor
@Observable
final class ReportsViewModel {
    
    // MARK: - Published Properties
    
    /// All lab reports
    var reports: [LabReportDocument] = []
    
    /// Filtered reports based on search and filters
    var filteredReports: [LabReportDocument] = []
    
    /// Loading state
    var isLoading: Bool = false
    
    /// Error handling
    var errorMessage: String?
    var showError: Bool = false
    
    /// Search and filter state
    var searchText: String = "" {
        didSet {
            applyFilters()
        }
    }
    
    var selectedCategory: HealthCategory? = nil {
        didSet {
            applyFilters()
        }
    }
    
    var selectedStatus: ProcessingStatus? = nil {
        didSet {
            applyFilters()
        }
    }
    
    var sortOrder: SortOrder = .dateNewest {
        didSet {
            applySorting()
        }
    }
    
    /// View state
    var selectedReport: LabReportDocument? = nil
    var showReportDetail: Bool = false
    var showFilterSheet: Bool = false
    
    // MARK: - Private Properties
    
    private let networkService = NetworkService.shared
    
    // MARK: - Initialization
    
    init() {
        applyFilters()
    }
    
    // MARK: - Public Methods
    
    /// Load reports from backend/local storage
    func loadReports() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Implement actual data loading from backend API using LabReportAPIService to fetch user's lab reports
            reports = []
            applyFilters()
        } catch {
            errorMessage = "Failed to load reports: \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Refresh reports data
    func refreshReports() async {
        await loadReports()
    }
    
    /// Select a report for detail view
    func selectReport(_ report: LabReportDocument) {
        selectedReport = report
        showReportDetail = true
    }
    
    /// Clear filters
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedStatus = nil
        sortOrder = .dateNewest
        applyFilters()
    }
    
    /// Get reports count by status
    func getReportsCount(for status: ProcessingStatus) -> Int {
        return reports.filter { $0.processingStatus == status }.count
    }
    
    /// Export report as PDF
    func exportReport(_ report: LabReportDocument) {
        // PDF export functionality will be implemented with backend integration
    }
    
    /// Share report
    func shareReport(_ report: LabReportDocument) {
        // Share functionality will be implemented
    }
    
    /// Delete report
    func deleteReport(_ report: LabReportDocument) {
        reports.removeAll { $0.id == report.id }
        applyFilters()
    }
    
    // MARK: - Private Methods
    
    private func applyFilters() {
        var filtered = reports
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { report in
                report.fileName.localizedCaseInsensitiveContains(searchText) ||
                report.documentType?.displayName.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.healthCategory == category }
        }
        
        // Apply status filter
        if let status = selectedStatus {
            filtered = filtered.filter { $0.processingStatus == status }
        }
        
        filteredReports = filtered
        applySorting()
    }
    
    private func applySorting() {
        switch sortOrder {
        case .dateNewest:
            filteredReports.sort { $0.uploadDate > $1.uploadDate }
        case .dateOldest:
            filteredReports.sort { $0.uploadDate < $1.uploadDate }
        case .nameAZ:
            filteredReports.sort { $0.fileName < $1.fileName }
        case .nameZA:
            filteredReports.sort { $0.fileName > $1.fileName }
        case .status:
            filteredReports.sort { $0.processingStatus.rawValue < $1.processingStatus.rawValue }
        }
    }
    
}

// MARK: - Supporting Types

enum SortOrder: String, CaseIterable {
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    case nameAZ = "Name (A-Z)"
    case nameZA = "Name (Z-A)"
    case status = "Status"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .dateNewest: return "arrow.down"
        case .dateOldest: return "arrow.up"
        case .nameAZ: return "textformat.abc"
        case .nameZA: return "textformat.abc"
        case .status: return "checkmark.circle"
        }
    }
}