//
//  ReportsView.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Simplified reports screen with search and history view
struct ReportsView: View {
    
    @State private var viewModel = ReportsViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: HealthSpacing.lg) {
                    // Search bar
                    ReportsSearchBar(
                        searchText: $viewModel.searchText,
                        onFilterTap: { viewModel.showFilterSheet = true }
                    )
                    
                    // Chronological history
                    if viewModel.isLoadingHistory && viewModel.groupedReports.isEmpty {
                        SkeletonList(count: 6, staggerDelay: 0.12) { index in
                            ReportCardSkeleton()
                        }
                    } else if viewModel.groupedReports.isEmpty {
                        EmptyHistoryView()
                    } else {
                        ReportHistoryGroupsView(
                            groupedReports: viewModel.groupedReports,
                            onSelectReport: { report in
                                viewModel.selectReport(report)
                            },
                            onShare: { report in
                                viewModel.shareReport(report)
                            },
                            onDelete: { report in
                                viewModel.deleteReport(report)
                            }
                        )
                    }
                }
                .padding(.horizontal, HealthSpacing.lg)
            }
            .background(HealthColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    LocationSelectorButton(
                        currentLocation: viewModel.locationText ?? "Getting location...",
                        onLocationChange: {
                            // Refresh location when user taps
                            viewModel.refreshLocation()
                        }
                    )
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showUploadSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(HealthColors.primary)
                            .font(.system(size: 24))
                    }
                }
            }
            .refreshable {
                await viewModel.refreshReports()
            }
            .onAppear {
                // Load reports when view appears
                Task {
                    await viewModel.loadReports()
                }
            }
            .sheet(isPresented: $viewModel.showUploadSheet) {
                UploadReportSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showReportDetail) {
                if let report = viewModel.selectedReport {
                    ReportDetailSheet(report: report)
                }
            }
            .alert("Delete Report", isPresented: $viewModel.showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.confirmDelete()
                }
            } message: {
                Text("Are you sure you want to delete this report? This action cannot be undone.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .sheet(isPresented: $viewModel.showFilterSheet) {
                ReportsFilterSheet(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Component Views

// MARK: - Processing Reports Section

struct ProcessingReportsSection: View {
    let reports: [LabReportDocument]
    let onSelectReport: (LabReportDocument) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Processing Reports")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                ForEach(reports.prefix(3)) { report in
                    ProcessingReportCard(
                        report: report,
                        onTap: { onSelectReport(report) }
                    )
                }
                
                if reports.count > 3 {
                    Button("View All Processing (\(reports.count))") {
                        // Handle view all processing
                    }
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HealthSpacing.sm)
                }
            }
        }
    }
}

struct ProcessingReportCard: View {
    let report: LabReportDocument
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                        Text(report.fileName)
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(HealthColors.primaryText)
                            .lineLimit(2)
                        
                        Text("Uploaded \(report.uploadDate.formatted(.relative(presentation: .named)))")
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    ProcessingStatusBadge(status: report.processingStatus)
                }
                
                // Progress indicator
                ProcessingProgressView(
                    progress: report.processingProgress,
                    currentOperation: "Processing",
                    currentStep: .processing,
                    isProcessing: true
                ) {
                    // Handle cancel processing
                }
                
                // Action buttons
                HStack(spacing: HealthSpacing.sm) {
                    Button("View Progress") {
                        onTap()
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                    
                    Button("Cancel Processing") {
                        // Handle cancel
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.healthCritical)
                    
                    Spacer()
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ProcessingProgressView is already defined in Features/LabReports/Components/ProcessingProgressView.swift

struct ProcessingStatusBadge: View {
    let status: ProcessingStatus
    
    var body: some View {
        HStack(spacing: HealthSpacing.xs) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.displayName)
                .font(HealthTypography.captionMedium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, HealthSpacing.sm)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Recent Completed Reports Section

struct RecentCompletedReportsSection: View {
    let reports: [LabReportDocument]
    let onSelectReport: (LabReportDocument) -> Void
    let onShare: (LabReportDocument) -> Void
    let onDelete: (LabReportDocument) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Recent Reports")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                ForEach(reports.prefix(5)) { report in
                    EnhancedReportCard(
                        report: report,
                        onTap: { onSelectReport(report) },
                        onShare: { onShare(report) },
                        onDelete: { onDelete(report) }
                    )
                }
                
                if reports.count > 5 {
                    Button("View All Reports (\(reports.count))") {
                        // Handle view all
                    }
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HealthSpacing.sm)
                }
            }
        }
    }
}

struct EnhancedReportCard: View {
    let report: LabReportDocument
    let onTap: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                // Header
                HStack {
                    HStack(spacing: HealthSpacing.sm) {
                        Image(systemName: report.documentType?.icon ?? "doc.text.fill")
                            .foregroundColor(HealthColors.primary)
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                            Text(report.fileName)
                                .font(HealthTypography.bodyMedium)
                                .foregroundColor(HealthColors.primaryText)
                                .lineLimit(2)
                            
                            Text("Completed \(report.uploadDate.formatted(.relative(presentation: .named)))")
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(HealthColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: HealthSpacing.xs) {
                        ProcessingStatusBadge(status: report.processingStatus)
                        
                        if let category = report.healthCategory {
                            Text(category.displayName)
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(category.color)
                                .padding(.horizontal, HealthSpacing.sm)
                                .padding(.vertical, 2)
                                .background(category.color.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // AI Insights Preview
                if let insights = report.aiInsights, !insights.isEmpty {
                    AIInsightsPreview(insights: insights)
                }
                
                // Key metrics preview
                if let keyMetrics = report.keyBiomarkers, !keyMetrics.isEmpty {
                    KeyMetricsPreview(metrics: keyMetrics)
                }
                
                // Action buttons
                HStack(spacing: HealthSpacing.sm) {
                    Button("View Full Report") {
                        onTap()
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                    
                    Button("Share") {
                        onShare()
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                    
                    Button("Export PDF") {
                        // Handle export
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                    
                    Spacer()
                    
                    Menu {
                        Button("Delete Report", role: .destructive) {
                            onDelete()
                        }
                        Button("Archive") {
                            // Handle archive
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AIInsightsPreview: View {
    let insights: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(HealthColors.primary)
                    .font(.system(size: 14))
                
                Text("AI Health Insights")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                ForEach(insights.prefix(2), id: \.self) { insight in
                    HStack(spacing: HealthSpacing.xs) {
                        Circle()
                            .fill(HealthColors.primary)
                            .frame(width: 4, height: 4)
                        
                        Text(insight)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                            .lineLimit(2)
                    }
                }
                
                if insights.count > 2 {
                    Text("+ \(insights.count - 2) more insights")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.primary)
                }
            }
        }
        .padding(HealthSpacing.sm)
        .background(HealthColors.primary.opacity(0.05))
        .cornerRadius(HealthCornerRadius.sm)
    }
}

struct KeyMetricsPreview: View {
    let metrics: [BiomarkerResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            Text("Key Biomarkers")
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primaryText)
            
            HStack(spacing: HealthSpacing.md) {
                ForEach(metrics.prefix(3)) { metric in
                    VStack(spacing: HealthSpacing.xs) {
                        Text(metric.displayValue)
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(metric.status.color)
                        
                        Text(metric.name)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                if metrics.count > 3 {
                    Text("+\(metrics.count - 3)")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(HealthSpacing.sm)
        .background(HealthColors.secondaryText.opacity(0.05))
        .cornerRadius(HealthCornerRadius.sm)
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Quick Actions")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            HStack(spacing: HealthSpacing.md) {
                ReportsQuickActionCard(
                    icon: "camera.fill",
                    title: "Scan Report",
                    subtitle: "Camera capture",
                    color: HealthColors.primary
                ) {
                    // Handle camera scan
                }
                
                ReportsQuickActionCard(
                    icon: "doc.badge.plus",
                    title: "Upload File",
                    subtitle: "From gallery",
                    color: HealthColors.secondary
                ) {
                    // Handle file upload
                }
            }
            
            HStack(spacing: HealthSpacing.md) {
                ReportsQuickActionCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "View Trends",
                    subtitle: "Health analytics",
                    color: HealthColors.healthGood
                ) {
                    // Handle trends view
                }
                
                ReportsQuickActionCard(
                    icon: "square.and.arrow.up",
                    title: "Export Data",
                    subtitle: "PDF/Excel",
                    color: HealthColors.healthWarning
                ) {
                    // Handle export
                }
            }
        }
    }
}

struct ReportsQuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: HealthSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                VStack(spacing: HealthSpacing.xs) {
                    Text(title)
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text(subtitle)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(HealthSpacing.lg)
            .background(color.opacity(0.1))
            .cornerRadius(HealthCornerRadius.card)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - History and Trends Components

struct ReportsSearchBar: View {
    @Binding var searchText: String
    let onFilterTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(HealthColors.secondaryText)
            
            TextField("Search reports, insights, biomarkers...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(HealthTypography.body)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            Button(action: onFilterTap) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(HealthColors.primary)
            }
        }
        .padding(.horizontal, HealthSpacing.lg)
        .padding(.vertical, HealthSpacing.md)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.button)
    }
}

struct HealthTrendsSummarySection: View {
    let trends: [HealthTrendUI]
    let onViewDetailedAnalysis: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Health Trends")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                ForEach(trends.prefix(4)) { trend in
                    ReportsHealthTrendRow(trend: trend)
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
            
           
        }
    }
}

// HealthTrendRow is already defined in Features/Appointments/Views/AppointmentsView.swift - using custom implementation
struct ReportsHealthTrendRow: View {
    let trend: HealthTrendUI
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                HStack {
                    Text(trend.title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Image(systemName: trend.trendIcon)
                        .foregroundColor(trend.trendColor)
                        .font(.system(size: 16))
                }
                
                Text(trend.subtitle)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
            
            if let improvement = trend.improvement {
                Text(improvement)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(trend.trendColor)
                    .padding(.horizontal, HealthSpacing.sm)
                    .padding(.vertical, 4)
                    .background(trend.trendColor.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

struct ReportHistoryGroupsView: View {
    let groupedReports: [DateGroupedReports]
    let onSelectReport: (LabReportDocument) -> Void
    let onShare: (LabReportDocument) -> Void
    let onDelete: (LabReportDocument) -> Void
    
    var body: some View {
        VStack(spacing: HealthSpacing.lg) {
            ForEach(groupedReports) { group in
                ReportHistoryGroup(
                    group: group,
                    onSelectReport: onSelectReport,
                    onShare: onShare,
                    onDelete: onDelete
                )
            }
        }
    }
}

struct ReportHistoryGroup: View {
    let group: DateGroupedReports
    let onSelectReport: (LabReportDocument) -> Void
    let onShare: (LabReportDocument) -> Void
    let onDelete: (LabReportDocument) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text(group.title)
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
                .padding(.horizontal, HealthSpacing.lg)
            
            VStack(spacing: HealthSpacing.md) {
                ForEach(group.reports) { report in
                    CompactReportCard(
                        report: report,
                        onTap: { onSelectReport(report) },
                        onShare: { onShare(report) },
                        onDelete: { onDelete(report) }
                    )
                }
            }
        }
    }
}

struct CompactReportCard: View {
    let report: LabReportDocument
    let onTap: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: HealthSpacing.md) {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(report.fileName)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        if let category = report.healthCategory {
                            Text(category.displayName)
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(category.color)
                        }
                        
                        Text("• \(report.uploadDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: HealthSpacing.xs) {
                    ProcessingStatusBadge(status: report.processingStatus)
                    
                    HStack(spacing: HealthSpacing.sm) {
                        Button("Share") { onShare() }
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primary)
                        
                        Menu {
                            Button("Delete Report", role: .destructive) { onDelete() }
                            Button("Archive") { /* Handle archive */ }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(HealthColors.secondaryText)
                        }
                    }
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Categories and Insights Components

struct HealthCategoriesOverviewSection: View {
    let categories: [HealthCategoryData]
    let onSelectCategory: (HealthCategory) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Health Categories")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: HealthSpacing.md) {
                ForEach(categories) { categoryData in
                    HealthCategoryCard(
                        categoryData: categoryData,
                        onTap: { onSelectCategory(categoryData.category) }
                    )
                }
            }
        }
    }
}

struct HealthCategoryCard: View {
    let categoryData: HealthCategoryData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HealthSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                        Text(categoryData.category.displayName)
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(HealthColors.primaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text("\(categoryData.reportCount) reports")
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: categoryData.category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(categoryData.category.color)
                }
                
                if let latestTrend = categoryData.latestTrend {
                    HStack {
                        Text(latestTrend.title)
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: latestTrend.trendIcon)
                            .foregroundColor(latestTrend.trendColor)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, HealthSpacing.sm)
                    .padding(.vertical, 4)
                    .background(categoryData.category.color.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AIInsightsSummarySection: View {
    let insights: [AIInsight]
    let onViewAllInsights: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("AI Health Insights")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                ForEach(insights.prefix(3)) { insight in
                    AIInsightCard(insight: insight)
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
            
            Button("View All Insights (\(insights.count))") {
                onViewAllInsights()
            }
            .font(HealthTypography.bodyMedium)
            .foregroundColor(HealthColors.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct AIInsightCard: View {
    let insight: AIInsight
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Image(systemName: insight.icon)
                .font(.system(size: 20))
                .foregroundColor(insight.priority.color)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(insight.title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .lineLimit(2)
                
                Text(insight.summary)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .lineLimit(3)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: HealthSpacing.xs) {
                Text(insight.priority.displayName)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(insight.priority.color)
                    .padding(.horizontal, HealthSpacing.sm)
                    .padding(.vertical, 2)
                    .background(insight.priority.color.opacity(0.1))
                    .cornerRadius(8)
                
                Text(insight.date.formatted(.relative(presentation: .named)))
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
        }
    }
}

struct BiomarkerTrendsSection: View {
    let biomarkers: [BiomarkerTrend]
    let onViewBiomarker: (BiomarkerTrend) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Biomarker Trends")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HealthSpacing.md) {
                    ForEach(biomarkers) { biomarker in
                        BiomarkerTrendCard(
                            biomarker: biomarker,
                            onTap: { onViewBiomarker(biomarker) }
                        )
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
            }
        }
    }
}

struct BiomarkerTrendCard: View {
    let biomarker: BiomarkerTrend
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HealthSpacing.md) {
                VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                    Text(biomarker.name)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(biomarker.currentValue)
                            .font(HealthTypography.headingSmall)
                            .foregroundColor(biomarker.status.color)
                        
                        Spacer()
                        
                        Image(systemName: biomarker.trendIcon)
                            .foregroundColor(biomarker.trendColor)
                            .font(.system(size: 16))
                    }
                    
                    Text(biomarker.changeText)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                // Mini trend line would go here
                Rectangle()
                    .fill(biomarker.trendColor.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
            }
            .padding(HealthSpacing.lg)
            .frame(width: 180)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HealthRecommendationsSection: View {
    let recommendations: [HealthRecommendationUI]
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Health Recommendations")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                ForEach(recommendations.prefix(3)) { recommendation in
                    HealthRecommendationCard(recommendation: recommendation)
                }
            }
        }
    }
}

struct HealthRecommendationCard: View {
    let recommendation: HealthRecommendationUI
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Image(systemName: recommendation.icon)
                .font(.system(size: 20))
                .foregroundColor(recommendation.priority.color)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(recommendation.title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .lineLimit(2)
                
                Text(recommendation.description)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .lineLimit(3)
            }
            
            Spacer()
            
            Button("Act") {
                // Handle recommendation action
            }
            .font(HealthTypography.captionMedium)
            .foregroundColor(recommendation.priority.color)
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(recommendation.priority.color.opacity(0.1))
            .cornerRadius(HealthCornerRadius.button)
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

// MARK: - Empty State Views

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: HealthSpacing.lg) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(HealthColors.primary)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("No History Available")
                    .font(HealthTypography.headline)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("Your report history will appear here as you upload and process more lab reports")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HealthSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(HealthSpacing.xl)
    }
}

// MARK: - Skeleton Views


// SkeletonRectangle is already defined in Features/Appointments/Views/AppointmentsView.swift

// MARK: - Sheet Components

struct UploadReportSheet: View {
    @Bindable var viewModel: ReportsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: HealthSpacing.xl) {
                Text("Upload Lab Report")
                    .font(HealthTypography.headingLarge)
                    .foregroundColor(HealthColors.primaryText)
                
                VStack(spacing: HealthSpacing.lg) {
                    UploadOptionCard(
                        icon: "camera.fill",
                        title: "Scan with Camera",
                        subtitle: "Take a photo of your report",
                        color: HealthColors.primary
                    ) {
                        // Handle camera scan
                        dismiss()
                    }
                    
                    UploadOptionCard(
                        icon: "photo.on.rectangle",
                        title: "Choose from Gallery",
                        subtitle: "Select from your photos",
                        color: HealthColors.secondary
                    ) {
                        // Handle gallery selection
                        dismiss()
                    }
                    
                    UploadOptionCard(
                        icon: "doc.badge.plus",
                        title: "Upload PDF File",
                        subtitle: "Choose PDF from files",
                        color: HealthColors.healthGood
                    ) {
                        // Handle PDF upload
                        dismiss()
                    }
                }
                
                Spacer()
            }
            .padding(HealthSpacing.screenPadding)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct UploadOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HealthSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text(subtitle)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(HealthColors.secondaryText)
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReportDetailSheet: View {
    let report: LabReportDocument
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HealthSpacing.xl) {
                    // Report header
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        Text(report.fileName)
                            .font(HealthTypography.headingMedium)
                            .foregroundColor(HealthColors.primaryText)
                        
                        HStack {
                            ProcessingStatusBadge(status: report.processingStatus)
                            
                            if let category = report.healthCategory {
                                Text(category.displayName)
                                    .font(HealthTypography.captionMedium)
                                    .foregroundColor(category.color)
                                    .padding(.horizontal, HealthSpacing.sm)
                                    .padding(.vertical, 4)
                                    .background(category.color.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Report content would go here
                    Text("Full report details will be displayed here")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(HealthSpacing.screenPadding)
            }
            .navigationTitle("Report Details")
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

struct ReportsFilterSheet: View {
    @Bindable var viewModel: ReportsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
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
                            
                            // Health categories would be added here
                        }
                        .padding(.horizontal, HealthSpacing.screenPadding)
                    }
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
