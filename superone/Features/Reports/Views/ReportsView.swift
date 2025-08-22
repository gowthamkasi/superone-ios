//
//  ReportsView.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Main screen for viewing and managing lab reports
struct ReportsView: View {
    
    // MARK: - Properties
    
    @State private var viewModel = ReportsViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter header
                searchAndFilterHeader
                
                // Reports list
                if viewModel.isLoading && viewModel.filteredReports.isEmpty {
                    loadingView
                } else if viewModel.filteredReports.isEmpty {
                    emptyStateView
                } else {
                    reportsListView
                }
            }
            .background(HealthColors.background.ignoresSafeArea())
            .navigationTitle("Lab Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showFilterSheet = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(HealthColors.primary)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshReports()
            }
            .sheet(isPresented: $viewModel.showFilterSheet) {
                FilterSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showReportDetail) {
                if let report = viewModel.selectedReport {
                    ReportDetailView(report: report)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
        .task {
            await viewModel.loadReports()
        }
    }
    
    // MARK: - Search and Filter Header
    
    private var searchAndFilterHeader: some View {
        VStack(spacing: HealthSpacing.md) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(HealthColors.secondaryText)
                
                TextField("Search reports...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(HealthTypography.body)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
            }
            .padding(.horizontal, HealthSpacing.lg)
            .padding(.vertical, HealthSpacing.md)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.button)
            
            // Quick stats
            if !viewModel.reports.isEmpty {
                quickStatsView
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
        .padding(.vertical, HealthSpacing.md)
    }
    
    // MARK: - Quick Stats
    
    private var quickStatsView: some View {
        HStack(spacing: HealthSpacing.md) {
            StatCard(
                title: "Total",
                value: "\(viewModel.reports.count)",
                color: HealthColors.primary
            )
            
            StatCard(
                title: "Completed",
                value: "\(viewModel.getReportsCount(for: .completed))",
                color: HealthColors.healthGood
            )
            
            StatCard(
                title: "Processing",
                value: "\(viewModel.getReportsCount(for: .processing))",
                color: HealthColors.healthWarning
            )
            
            StatCard(
                title: "Failed",
                value: "\(viewModel.getReportsCount(for: .failed))",
                color: HealthColors.healthCritical
            )
        }
    }
    
    // MARK: - Reports List
    
    private var reportsListView: some View {
        ScrollView {
            LazyVStack(spacing: HealthSpacing.md) {
                ForEach(viewModel.filteredReports) { report in
                    ReportCard(
                        report: report,
                        onTap: {
                            viewModel.selectReport(report)
                        },
                        onShare: {
                            viewModel.shareReport(report)
                        },
                        onDelete: {
                            viewModel.deleteReport(report)
                        }
                    )
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.bottom, HealthSpacing.xl)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: HealthSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(HealthColors.primary)
            
            Text("Loading reports...")
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: HealthSpacing.xl) {
            VStack(spacing: HealthSpacing.lg) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(HealthColors.primary)
                
                VStack(spacing: HealthSpacing.sm) {
                    Text(emptyStateTitle)
                        .font(HealthTypography.headline)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text(emptyStateMessage)
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HealthSpacing.xl)
                }
            }
            
            if !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil || viewModel.selectedStatus != nil {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .foregroundColor(HealthColors.primary)
                .font(HealthTypography.bodyMedium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var emptyStateTitle: String {
        if !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil || viewModel.selectedStatus != nil {
            return "No Matching Reports"
        } else if viewModel.reports.isEmpty {
            return "No Reports Yet"
        } else {
            return "No Reports Found"
        }
    }
    
    private var emptyStateMessage: String {
        if !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil || viewModel.selectedStatus != nil {
            return "Try adjusting your search terms or filters to find what you're looking for."
        } else if viewModel.reports.isEmpty {
            return ""
            // return "Upload your first lab report to get started with AI-powered health insights."
        } else {
            return "Unable to load your reports at this time. Please try again."
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: HealthSpacing.xs) {
            Text(value)
                .font(HealthTypography.headingSmall)
                .foregroundColor(color)
            
            Text(title)
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HealthSpacing.sm)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Bindable var viewModel: ReportsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: HealthSpacing.xl) {
                // Sort options
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    Text("Sort By")
                        .font(HealthTypography.headingSmall)
                        .foregroundColor(HealthColors.primaryText)
                    
                    ForEach(SortOrder.allCases, id: \.self) { sortOrder in
                        Button(action: {
                            viewModel.sortOrder = sortOrder
                        }) {
                            HStack {
                                Image(systemName: sortOrder.icon)
                                    .foregroundColor(HealthColors.primary)
                                
                                Text(sortOrder.displayName)
                                    .font(HealthTypography.body)
                                    .foregroundColor(HealthColors.primaryText)
                                
                                Spacer()
                                
                                if viewModel.sortOrder == sortOrder {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(HealthColors.primary)
                                }
                            }
                            .padding(.vertical, HealthSpacing.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Divider()
                
                // Category filter
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    Text("Health Category")
                        .font(HealthTypography.headingSmall)
                        .foregroundColor(HealthColors.primaryText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: HealthSpacing.sm) {
                            ReportFilterChip(
                                title: "All Categories",
                                isSelected: viewModel.selectedCategory == nil,
                                color: HealthColors.primary
                            ) {
                                viewModel.selectedCategory = nil
                            }
                            
                            ForEach(HealthCategory.allCases, id: \.self) { category in
                                ReportFilterChip(
                                    title: category.displayName,
                                    isSelected: viewModel.selectedCategory == category,
                                    color: category.color
                                ) {
                                    viewModel.selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal, HealthSpacing.screenPadding)
                    }
                }
                
                Divider()
                
                // Status filter
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    Text("Processing Status")
                        .font(HealthTypography.headingSmall)
                        .foregroundColor(HealthColors.primaryText)
                    
                    HStack(spacing: HealthSpacing.sm) {
                        ReportFilterChip(
                            title: "All Status",
                            isSelected: viewModel.selectedStatus == nil,
                            color: HealthColors.primary
                        ) {
                            viewModel.selectedStatus = nil
                        }
                        
                        ReportFilterChip(
                            title: "Completed",
                            isSelected: viewModel.selectedStatus == .completed,
                            color: HealthColors.healthGood
                        ) {
                            viewModel.selectedStatus = .completed
                        }
                        
                        ReportFilterChip(
                            title: "Processing",
                            isSelected: viewModel.selectedStatus == .processing,
                            color: HealthColors.healthWarning
                        ) {
                            viewModel.selectedStatus = .processing
                        }
                        
                        ReportFilterChip(
                            title: "Failed",
                            isSelected: viewModel.selectedStatus == .failed,
                            color: HealthColors.healthCritical
                        ) {
                            viewModel.selectedStatus = .failed
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // Clear filters button
                Button("Clear All Filters") {
                    viewModel.clearFilters()
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primary)
            }
            .padding(HealthSpacing.screenPadding)
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Filter Chip Component

struct ReportFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HealthTypography.captionMedium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, HealthSpacing.md)
                .padding(.vertical, HealthSpacing.sm)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Reports View") {
    ReportsView()
        .environmentObject(AppState())
}

#Preview("Empty State") {
    ReportsView()
        .environmentObject(AppState())
}