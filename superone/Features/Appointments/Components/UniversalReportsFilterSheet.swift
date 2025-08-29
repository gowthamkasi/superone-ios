//
//  UniversalReportsFilterSheet.swift
//  SuperOne
//
//  Example Reports filter implementation using the Universal Filter Sheet component
//  Demonstrates advanced usage patterns and extensibility of the universal architecture
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Reports filter sheet using the universal filter component architecture
/// Demonstrates how to create complex filters for different feature areas
struct UniversalReportsFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasChanges = false
    
    // Report filter state
    @State private var selectedDateRange: DateRange = .all
    @State private var selectedReportTypes: Set<ReportType> = []
    @State private var selectedLabProviders: Set<LabProvider> = []
    @State private var selectedHealthCategories: Set<ReportHealthCategory> = []
    @State private var selectedStatusFilters: Set<ReportStatus> = []
    @State private var searchText: String = ""
    
    var body: some View {
        UniversalFilterSheet.withResetConfirmation(
            title: "Filter Reports",
            hasActiveFilters: hasActiveReportFilters,
            hasChanges: hasChanges,
            canReset: hasActiveReportFilters,
            activeFiltersContent: hasActiveReportFilters ? {
                AnyView(
                    UniversalActiveFiltersSummary(
                        title: "Active Filters",
                        activeFilterCount: activeReportFilterCount,
                        filtersContent: {
                            // Date range filter chip
                            if selectedDateRange != .all {
                                UniversalActiveFilterChip(
                                    title: selectedDateRange.displayName,
                                    icon: "calendar"
                                )
                            }
                            
                            // Report type filter chips
                            ForEach(Array(selectedReportTypes), id: \.self) { reportType in
                                UniversalActiveFilterChip(
                                    title: reportType.displayName,
                                    icon: reportType.icon
                                )
                            }
                            
                            // Lab provider filter chips
                            ForEach(Array(selectedLabProviders), id: \.self) { provider in
                                UniversalActiveFilterChip(
                                    title: provider.displayName,
                                    icon: "building.2"
                                )
                            }
                            
                            // Health category filter chips
                            ForEach(Array(selectedHealthCategories), id: \.self) { category in
                                UniversalActiveFilterChip(
                                    title: category.displayName,
                                    icon: category.icon
                                )
                            }
                            
                            // Status filter chips
                            ForEach(Array(selectedStatusFilters), id: \.self) { status in
                                UniversalActiveFilterChip(
                                    title: status.displayName,
                                    icon: status.icon
                                )
                            }
                            
                            // Search filter chip
                            if !searchText.isEmpty {
                                UniversalActiveFilterChip(
                                    title: "Search: \"\(searchText)\"",
                                    icon: "magnifyingglass",
                                    onRemove: {
                                        searchText = ""
                                        hasChanges = true
                                    }
                                )
                            }
                        }
                    )
                )
            } : nil,
            filterContent: {
                VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                    // Search Section
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        UniversalFilterSectionHeader(
                            "Search Reports",
                            subtitle: "Search by report name, test type, or keywords"
                        )
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(HealthColors.secondaryText)
                            
                            TextField("Search reports...", text: $searchText)
                                .font(HealthTypography.bodyRegular)
                                .onChange(of: searchText) { _, _ in
                                    hasChanges = true
                                }
                        }
                        .padding(.horizontal, HealthSpacing.md)
                        .padding(.vertical, HealthSpacing.sm)
                        .background(HealthColors.secondaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                                .strokeBorder(HealthColors.border, lineWidth: 1)
                        )
                        .cornerRadius(HealthCornerRadius.md)
                    }
                    
                    // Divider
                    Divider()
                        .background(HealthColors.border)
                    
                    // Date Range Section
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        UniversalFilterSectionHeader(
                            "Date Range",
                            subtitle: "Filter by report date"
                        )
                        
                        UniversalVerticalFilterChips {
                            ForEach(DateRange.allCases, id: \.self) { dateRange in
                                DateRangeFilterChip(
                                    dateRange: dateRange,
                                    isSelected: selectedDateRange == dateRange
                                ) {
                                    selectedDateRange = dateRange
                                    hasChanges = true
                                    HapticFeedback.soft()
                                }
                            }
                        }
                    }
                    
                    // Divider
                    Divider()
                        .background(HealthColors.border)
                    
                    // Report Types Section
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        UniversalFilterSectionHeader(
                            "Report Types",
                            subtitle: "Select the types of reports to show"
                        )
                        
                        UniversalFilterChipsContainer(columns: 2) {
                            ForEach(ReportType.allCases, id: \.self) { reportType in
                                ReportTypeFilterChip(
                                    reportType: reportType,
                                    isSelected: selectedReportTypes.contains(reportType)
                                ) {
                                    toggleReportType(reportType)
                                }
                            }
                        }
                    }
                    
                    // Divider
                    Divider()
                        .background(HealthColors.border)
                    
                    // Health Categories Section
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        UniversalFilterSectionHeader(
                            "Health Categories",
                            subtitle: "Filter by health focus areas"
                        )
                        
                        UniversalFilterChipsContainer(columns: 2) {
                            ForEach(ReportHealthCategory.allCases, id: \.self) { category in
                                HealthCategoryFilterChip(
                                    category: category,
                                    isSelected: selectedHealthCategories.contains(category)
                                ) {
                                    toggleHealthCategory(category)
                                }
                            }
                        }
                    }
                    
                    // Divider
                    Divider()
                        .background(HealthColors.border)
                    
                    // Status Section
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        UniversalFilterSectionHeader(
                            "Report Status",
                            subtitle: "Filter by processing status"
                        )
                        
                        UniversalVerticalFilterChips {
                            ForEach(ReportStatus.allCases, id: \.self) { status in
                                ReportStatusFilterChip(
                                    status: status,
                                    isSelected: selectedStatusFilters.contains(status)
                                ) {
                                    toggleReportStatus(status)
                                }
                            }
                        }
                    }
                }
            },
            onResetConfirmed: {
                resetAllReportFilters()
                hasChanges = true
            },
            onApply: {
                if hasChanges {
                    applyReportFilters()
                    HapticFeedback.success()
                }
                dismiss()
            },
            resetConfirmationMessage: "This will clear all report filter selections and show all available reports."
        )
    }
    
    // MARK: - Helper Methods
    
    private func toggleReportType(_ reportType: ReportType) {
        if selectedReportTypes.contains(reportType) {
            selectedReportTypes.remove(reportType)
        } else {
            selectedReportTypes.insert(reportType)
        }
        hasChanges = true
        HapticFeedback.soft()
    }
    
    private func toggleHealthCategory(_ category: ReportHealthCategory) {
        if selectedHealthCategories.contains(category) {
            selectedHealthCategories.remove(category)
        } else {
            selectedHealthCategories.insert(category)
        }
        hasChanges = true
        HapticFeedback.soft()
    }
    
    private func toggleReportStatus(_ status: ReportStatus) {
        if selectedStatusFilters.contains(status) {
            selectedStatusFilters.remove(status)
        } else {
            selectedStatusFilters.insert(status)
        }
        hasChanges = true
        HapticFeedback.soft()
    }
    
    private func resetAllReportFilters() {
        selectedDateRange = .all
        selectedReportTypes.removeAll()
        selectedLabProviders.removeAll()
        selectedHealthCategories.removeAll()
        selectedStatusFilters.removeAll()
        searchText = ""
    }
    
    private func applyReportFilters() {
        // Apply filters to the reports list
        // This would typically update a view model or call a service
        print("Applying report filters...")
        print("Date Range: \(selectedDateRange)")
        print("Report Types: \(selectedReportTypes)")
        print("Health Categories: \(selectedHealthCategories)")
        print("Status Filters: \(selectedStatusFilters)")
        print("Search Text: \(searchText)")
    }
    
    // MARK: - Computed Properties
    
    private var hasActiveReportFilters: Bool {
        selectedDateRange != .all ||
        !selectedReportTypes.isEmpty ||
        !selectedLabProviders.isEmpty ||
        !selectedHealthCategories.isEmpty ||
        !selectedStatusFilters.isEmpty ||
        !searchText.isEmpty
    }
    
    private var activeReportFilterCount: Int {
        var count = 0
        
        if selectedDateRange != .all {
            count += 1
        }
        
        count += selectedReportTypes.count
        count += selectedLabProviders.count
        count += selectedHealthCategories.count
        count += selectedStatusFilters.count
        
        if !searchText.isEmpty {
            count += 1
        }
        
        return count
    }
}

// MARK: - Report Filter Data Models

enum DateRange: String, CaseIterable {
    case all = "all"
    case lastWeek = "last_week"
    case lastMonth = "last_month"
    case lastThreeMonths = "last_three_months"
    case lastSixMonths = "last_six_months"
    case lastYear = "last_year"
    
    var displayName: String {
        switch self {
        case .all: return "All Time"
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .lastThreeMonths: return "Last 3 Months"
        case .lastSixMonths: return "Last 6 Months"
        case .lastYear: return "Last Year"
        }
    }
}

enum ReportType: String, CaseIterable {
    case bloodWork = "blood_work"
    case imaging = "imaging"
    case pathology = "pathology"
    case specialty = "specialty"
    case wellness = "wellness"
    case screening = "screening"
    
    var displayName: String {
        switch self {
        case .bloodWork: return "Blood Work"
        case .imaging: return "Imaging"
        case .pathology: return "Pathology"
        case .specialty: return "Specialty"
        case .wellness: return "Wellness"
        case .screening: return "Screening"
        }
    }
    
    var icon: String {
        switch self {
        case .bloodWork: return "drop.fill"
        case .imaging: return "photo"
        case .pathology: return "cross.fill"
        case .specialty: return "stethoscope"
        case .wellness: return "heart.fill"
        case .screening: return "checkmark.shield"
        }
    }
}

enum LabProvider: String, CaseIterable {
    case superOne = "super_one"
    case apollo = "apollo"
    case thyrocare = "thyrocare"
    case metropolis = "metropolis"
    case drLal = "dr_lal"
    case srl = "srl"
    
    var displayName: String {
        switch self {
        case .superOne: return "Super One"
        case .apollo: return "Apollo"
        case .thyrocare: return "Thyrocare"
        case .metropolis: return "Metropolis"
        case .drLal: return "Dr. Lal PathLabs"
        case .srl: return "SRL Diagnostics"
        }
    }
}

enum ReportHealthCategory: String, CaseIterable {
    case cardiovascular = "cardiovascular"
    case metabolic = "metabolic"
    case hematology = "hematology"
    case liver = "liver"
    case kidney = "kidney"
    case thyroid = "thyroid"
    case hormonal = "hormonal"
    case nutritional = "nutritional"
    case immune = "immune"
    case reproductive = "reproductive"
    
    var displayName: String {
        switch self {
        case .cardiovascular: return "Heart Health"
        case .metabolic: return "Metabolic"
        case .hematology: return "Blood Health"
        case .liver: return "Liver Function"
        case .kidney: return "Kidney Function"
        case .thyroid: return "Thyroid"
        case .hormonal: return "Hormonal"
        case .nutritional: return "Vitamins & Minerals"
        case .immune: return "Immune System"
        case .reproductive: return "Reproductive Health"
        }
    }
    
    var icon: String {
        switch self {
        case .cardiovascular: return "heart.fill"
        case .metabolic: return "flame.fill"
        case .hematology: return "drop.fill"
        case .liver: return "oval.fill"
        case .kidney: return "kidney.fill"
        case .thyroid: return "lungs.fill"
        case .hormonal: return "brain.filled"
        case .nutritional: return "pills.fill"
        case .immune: return "shield.fill"
        case .reproductive: return "person.2.fill"
        }
    }
}

enum ReportStatus: String, CaseIterable {
    case processing = "processing"
    case completed = "completed"
    case analyzed = "analyzed"
    case flagged = "flagged"
    
    var displayName: String {
        switch self {
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .analyzed: return "AI Analyzed"
        case .flagged: return "Needs Attention"
        }
    }
    
    var icon: String {
        switch self {
        case .processing: return "clock"
        case .completed: return "checkmark.circle"
        case .analyzed: return "brain.filled"
        case .flagged: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Filter Chip Components

struct DateRangeFilterChip: View {
    let dateRange: DateRange
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                
                Text(dateRange.displayName)
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(HealthColors.primary)
                }
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .fill(isSelected ? HealthColors.primary.opacity(0.1) : HealthColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                            .strokeBorder(
                                isSelected ? HealthColors.primary.opacity(0.3) : HealthColors.border,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReportTypeFilterChip: View {
    let reportType: ReportType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HealthSpacing.xs) {
                Image(systemName: reportType.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                
                Text(reportType.displayName)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, HealthSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .fill(isSelected ? HealthColors.primary.opacity(0.1) : HealthColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                            .strokeBorder(
                                isSelected ? HealthColors.primary.opacity(0.3) : HealthColors.border,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HealthCategoryFilterChip: View {
    let category: ReportHealthCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HealthSpacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                
                Text(category.displayName)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .padding(.horizontal, HealthSpacing.xs)
            .padding(.vertical, HealthSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .fill(isSelected ? HealthColors.primary.opacity(0.1) : HealthColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                            .strokeBorder(
                                isSelected ? HealthColors.primary.opacity(0.3) : HealthColors.border,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReportStatusFilterChip: View {
    let status: ReportStatus
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: status.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                
                Text(status.displayName)
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .fill(isSelected ? HealthColors.primary.opacity(0.1) : HealthColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                            .strokeBorder(
                                isSelected ? HealthColors.primary.opacity(0.3) : HealthColors.border,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Universal Reports Filter - Empty") {
    UniversalReportsFilterSheet()
}

#Preview("Universal Reports Filter - With Selections") {
    UniversalReportsFilterSheet()
}