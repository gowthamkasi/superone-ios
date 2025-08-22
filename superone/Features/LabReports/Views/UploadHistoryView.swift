//
//  UploadHistoryView.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI

/// View for managing upload history and displaying processing statistics
struct UploadHistoryView: View {
    
    @State private var viewModel = UploadHistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTimeRange: HistoryTimeRange = .lastMonth
    @State private var selectedStatus: UploadHistoryFilter = .all
    @State private var showingDeleteConfirmation = false
    @State private var documentToDelete: HistoryItem?
    @State private var showingExportOptions = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistics header
                statisticsHeader
                
                // Filter and search section
                filterSection
                
                // History list
                historyList
            }
            .navigationTitle("Upload History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingExportOptions = true
                        } label: {
                            Label("Export History", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            Task {
                                await viewModel.refreshHistory()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Clear All History", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshHistory()
            }
            .searchable(text: $searchText, prompt: "Search documents...")
            .onChange(of: searchText) { oldValue, newValue in
                viewModel.searchText = newValue
            }
            .onChange(of: selectedTimeRange) { oldValue, newValue in
                viewModel.selectedTimeRange = newValue
            }
            .onChange(of: selectedStatus) { oldValue, newValue in
                viewModel.selectedFilter = newValue
            }
            .alert("Delete History Item", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let document = documentToDelete {
                        Task {
                            await viewModel.deleteHistoryItem(document)
                        }
                        documentToDelete = nil
                    } else {
                        Task {
                            await viewModel.clearAllHistory()
                        }
                    }
                }
            } message: {
                if documentToDelete != nil {
                    Text("Are you sure you want to delete this upload record? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to clear all upload history? This action cannot be undone.")
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                HistoryExportView(history: viewModel.filteredHistory)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadHistory()
            }
        }
    }
    
    // MARK: - Statistics Header
    
    private var statisticsHeader: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Overall statistics
            HStack(spacing: HealthSpacing.lg) {
                StatisticCard(
                    icon: "doc.text.fill",
                    title: "Total Uploads",
                    value: "\(viewModel.statistics.totalUploads)",
                    subtitle: "All time",
                    color: HealthColors.primary
                )
                
                StatisticCard(
                    icon: "checkmark.circle.fill",
                    title: "Success Rate",
                    value: "\(Int(viewModel.statistics.successRate * 100))%",
                    subtitle: "Last 30 days",
                    color: HealthColors.healthGood
                )
                
                StatisticCard(
                    icon: "externaldrive.fill",
                    title: "Data Processed",
                    value: viewModel.statistics.totalDataProcessedFormatted,
                    subtitle: "Total size",
                    color: HealthColors.secondary
                )
            }
            
            // Processing time statistics
            HStack(spacing: HealthSpacing.lg) {
                StatisticCard(
                    icon: "clock.fill",
                    title: "Avg. Processing",
                    value: viewModel.statistics.averageProcessingTimeFormatted,
                    subtitle: "Per document",
                    color: HealthColors.healthWarning
                )
                
                StatisticCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "This Month",
                    value: "\(viewModel.statistics.uploadsThisMonth)",
                    subtitle: "Uploads",
                    color: HealthColors.healthExcellent
                )
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(spacing: HealthSpacing.md) {
            // Time range picker
            HStack {
                Text("Time Range")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.secondaryText)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(HistoryTimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Status filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HealthSpacing.sm) {
                    ForEach(UploadHistoryFilter.allCases, id: \.self) { filter in
                        HistoryFilterChip(
                            title: filter.displayName,
                            count: viewModel.getCount(for: filter),
                            isSelected: selectedStatus == filter,
                            onTap: {
                                selectedStatus = filter
                            }
                        )
                    }
                }
                .padding(.horizontal, HealthSpacing.lg)
            }
        }
        .padding(.vertical, HealthSpacing.md)
        .background(HealthColors.primaryBackground)
    }
    
    // MARK: - History List
    
    private var historyList: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredHistory.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: HealthSpacing.md) {
                        ForEach(viewModel.filteredHistory) { item in
                            HistoryItemCard(
                                item: item,
                                onDelete: {
                                    documentToDelete = item
                                    showingDeleteConfirmation = true
                                },
                                onReprocess: {
                                    Task {
                                        await viewModel.reprocessDocument(item)
                                    }
                                }
                            )
                        }
                    }
                    .padding(HealthSpacing.lg)
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: HealthSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: HealthColors.primary))
                .scaleEffect(1.2)
            
            Text("Loading upload history...")
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: HealthSpacing.xl) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(HealthColors.secondaryText)
            
            VStack(spacing: HealthSpacing.md) {
                Text("No Upload History")
                    .font(HealthTypography.headingMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(emptyStateMessage)
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button("Upload Your First Document") {
                dismiss()
            }
            .buttonStyle(HealthPrimaryButtonStyle())
        }
        .padding(HealthSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateMessage: String {
        switch selectedStatus {
        case .all:
            return "Start uploading lab reports to see your history here"
        case .completed:
            return "No completed uploads found for the selected time period"
        case .failed:
            return "No failed uploads found for the selected time period"
        case .processing:
            return "No documents are currently being processed"
        }
    }
}

// MARK: - Supporting Views

struct StatisticCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: HealthSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(HealthTypography.headingMedium)
                .foregroundColor(HealthColors.primaryText)
                .fontWeight(.bold)
            
            Text(title)
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primaryText)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(HealthTypography.captionSmall)
                .foregroundColor(HealthColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(HealthSpacing.md)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
}

struct HistoryFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(title)
                    .font(HealthTypography.captionMedium)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(HealthTypography.captionSmall)
                }
            }
            .foregroundColor(isSelected ? .white : HealthColors.primaryText)
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(isSelected ? HealthColors.primary : HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HistoryItemCard: View {
    let item: HistoryItem
    let onDelete: () -> Void
    let onReprocess: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Header with file info and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.fileName)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(1)
                    
                    Text(item.uploadDateFormatted)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: item.status.toProcessingStatus())
                    
                    Text(item.fileSizeFormatted)
                        .font(HealthTypography.captionSmall)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            // Processing details
            if let processingTime = item.processingTime {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(HealthColors.primary)
                        .font(.caption)
                    
                    Text("Processed in \(formatProcessingTime(processingTime))")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                    
                    Spacer()
                    
                    if let biomarkerCount = item.biomarkerCount {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(HealthColors.healthGood)
                                .font(.caption)
                            
                            Text("\(biomarkerCount) biomarkers")
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(HealthColors.secondaryText)
                        }
                    }
                }
            }
            
            // Error message for failed uploads
            if item.status == .failed, let errorMessage = item.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(HealthColors.healthCritical)
                        .font(.caption)
                    
                    Text(errorMessage)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.healthCritical)
                        .lineLimit(2)
                    
                    Spacer()
                }
                .padding(.horizontal, HealthSpacing.sm)
                .padding(.vertical, HealthSpacing.xs)
                .background(HealthColors.healthCritical.opacity(0.1))
                .cornerRadius(HealthCornerRadius.sm)
            }
            
            // Action buttons
            HStack(spacing: HealthSpacing.md) {
                if item.status == .failed {
                    Button("Retry") {
                        onReprocess()
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                }
                
                Spacer()
                
                Button("Delete") {
                    onDelete()
                }
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.healthCritical)
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.lg)
        .healthCardShadow()
    }
    
    private func formatProcessingTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        UploadHistoryView()
    }
}