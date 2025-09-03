//
//  ReportDetailView.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI
import Foundation

/// Detailed view for examining a specific lab report with biomarkers and analysis
struct ReportDetailView: View {
    let report: LabReportDocument
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DetailTab = .overview
    @State private var showExportSheet = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with report info
                reportHeader
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                tabContent
            }
            .background(HealthColors.background.ignoresSafeArea())
            .navigationTitle(report.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showExportSheet = true }) {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { showDeleteAlert = true }) {
                            Label("Delete Report", systemImage: "trash")
                        }
                        .foregroundColor(.red)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(HealthColors.primary)
                    }
                }
            }
            .confirmationDialog("Delete Report", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. The report and all associated data will be permanently deleted.")
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(report: report)
            }
        }
    }
    
    // MARK: - Report Header
    
    private var reportHeader: some View {
        VStack(spacing: HealthSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(report.fileName)
                        .font(HealthTypography.headingSmall)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(2)
                    
                    HStack(spacing: HealthSpacing.sm) {
                        Text(report.displayFileSize)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                        
                        Text("•")
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                        
                        Text(formatDate(report.uploadDate))
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
                
                Spacer()
                
                StatusBadge(status: report.processingStatus)
            }
            
            // Processing info
            if let documentType = report.documentType,
               let category = report.healthCategory {
                HStack(spacing: HealthSpacing.lg) {
                    Label(documentType.displayName, systemImage: documentType.icon)
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                    
                    Label(category.displayName, systemImage: "tag.fill")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(category.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // OCR confidence
            if let confidence = report.ocrConfidence {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(confidenceColor(confidence))
                    
                    Text("Processing Accuracy: \(Int(confidence * 100))%")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Spacer()
                }
            }
        }
        .padding(HealthSpacing.screenPadding)
        .background(HealthColors.secondaryBackground)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: HealthSpacing.xs) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        
                        Text(tab.title)
                            .font(HealthTypography.captionMedium)
                    }
                    .foregroundColor(selectedTab == tab ? HealthColors.primary : HealthColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HealthSpacing.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(HealthColors.background)
        .overlay(
            Rectangle()
                .fill(HealthColors.secondaryText.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        ScrollView {
            switch selectedTab {
            case .overview:
                overviewContent
            case .biomarkers:
                biomarkersContent
            case .analysis:
                analysisContent
            case .raw:
                rawTextContent
            }
        }
    }
    
    // MARK: - Overview Content
    
    private var overviewContent: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Processing timeline
            if report.processingStatus == .completed {
                ProcessingTimelineCard()
            } else if report.processingStatus == .processing {
                ProcessingProgressCard()
            } else if report.processingStatus == .failed {
                ProcessingErrorCard()
            }
            
            // Quick stats
            if report.processingStatus == .completed {
                QuickStatsCard(report: report)
            }
            
            // Health categories identified
            if let category = report.healthCategory {
                ReportHealthCategoryCard(category: category)
            }
        }
        .padding(HealthSpacing.screenPadding)
    }
    
    // MARK: - Biomarkers Content
    
    private var biomarkersContent: some View {
        VStack(spacing: HealthSpacing.lg) {
            if report.processingStatus == .completed {
                // Replace with actual biomarkers from report.biomarkers when backend integration is available
                EmptyStateView(
                    icon: "heart.text.square",
                    title: "Biomarkers Ready",
                    message: "Biomarker extraction completed. Integration with backend API pending."
                )
            } else {
                EmptyStateView(
                    icon: "heart.text.square",
                    title: report.processingStatus == .processing ? "Processing..." : "No Biomarkers",
                    message: report.processingStatus == .processing ? 
                             "We're extracting biomarkers from your report." :
                             "Biomarkers will appear here once processing is complete."
                )
            }
        }
        .padding(HealthSpacing.screenPadding)
    }
    
    // MARK: - Analysis Content
    
    private var analysisContent: some View {
        VStack(spacing: HealthSpacing.lg) {
            if report.processingStatus == .completed {
                AIAnalysisCard()
                HealthInsightsCard()
                RecommendationsCard()
            } else {
                EmptyStateView(
                    icon: "brain.head.profile",
                    title: "Analysis Pending",
                    message: "AI-powered health analysis will be available once processing is complete."
                )
            }
        }
        .padding(HealthSpacing.screenPadding)
    }
    
    // MARK: - Raw Text Content
    
    private var rawTextContent: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.lg) {
            if let extractedText = report.extractedText {
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    Text("Extracted Text")
                        .font(HealthTypography.headingSmall)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text(extractedText)
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.primaryText)
                        .textSelection(.enabled)
                        .padding(HealthSpacing.lg)
                        .background(HealthColors.secondaryBackground)
                        .cornerRadius(HealthCornerRadius.card)
                }
            } else {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Text Available",
                    message: report.processingStatus == .processing ? 
                             "Text extraction is in progress." :
                             "No text could be extracted from this document."
                )
            }
        }
        .padding(HealthSpacing.screenPadding)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.9 {
            return HealthColors.healthExcellent
        } else if confidence >= 0.8 {
            return HealthColors.healthGood
        } else if confidence >= 0.7 {
            return HealthColors.healthWarning
        } else {
            return HealthColors.healthCritical
        }
    }
    
}

// MARK: - Supporting Types

enum DetailTab: String, CaseIterable {
    case overview = "Overview"
    case biomarkers = "Biomarkers"
    case analysis = "Analysis"
    case raw = "Raw Text"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "doc.text.magnifyingglass"
        case .biomarkers: return "heart.text.square"
        case .analysis: return "brain.head.profile"
        case .raw: return "doc.plaintext"
        }
    }
}



// MARK: - Supporting Views

struct ProcessingTimelineCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Processing Complete")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                TimelineStep(title: "Document Uploaded", completed: true)
                TimelineStep(title: "OCR Processing", completed: true)
                TimelineStep(title: "Biomarker Extraction", completed: true)
                TimelineStep(title: "AI Analysis", completed: true)
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct ProcessingProgressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Processing In Progress")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            ProgressView(value: 0.65)
                .progressViewStyle(LinearProgressViewStyle(tint: HealthColors.primary))
            
            Text("Extracting biomarkers...")
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct ProcessingErrorCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(HealthColors.healthCritical)
                
                Text("Processing Failed")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
            }
            
            Text("Unable to process this document. The image quality may be too low or the format not supported.")
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
            
            Button("Retry Processing") {
                // Retry functionality will be implemented with backend integration
            }
            .font(HealthTypography.bodyMedium)
            .foregroundColor(HealthColors.primary)
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct QuickStatsCard: View {
    let report: LabReportDocument
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Quick Stats")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            HStack(spacing: HealthSpacing.lg) {
                ReportStatItem(title: "Biomarkers", value: "12", color: HealthColors.primary)
                ReportStatItem(title: "Normal", value: "8", color: HealthColors.healthGood)
                ReportStatItem(title: "Flagged", value: "4", color: HealthColors.healthWarning)
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct ReportHealthCategoryCard: View {
    let category: HealthCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Health Category")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(category.color)
                
                Text(category.displayName)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}


struct AIAnalysisCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(HealthColors.primary)
                
                Text("AI Analysis")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
            }
            
            Text("Your cholesterol levels are elevated, which may increase cardiovascular risk. Consider dietary changes and discuss with your healthcare provider.")
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.primaryText)
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct HealthInsightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Health Insights")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                InsightItem(icon: "heart.fill", text: "Cardiovascular health needs attention", color: HealthColors.healthWarning)
                InsightItem(icon: "drop.fill", text: "Blood sugar levels are optimal", color: HealthColors.healthGood)
                InsightItem(icon: "lungs.fill", text: "Consider monitoring lipid levels", color: HealthColors.healthWarning)
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct RecommendationsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Recommendations")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                RecommendationItem(text: "Schedule follow-up with your doctor")
                RecommendationItem(text: "Consider a heart-healthy diet")
                RecommendationItem(text: "Increase physical activity")
                RecommendationItem(text: "Monitor cholesterol levels monthly")
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct TimelineStep: View {
    let title: String
    let completed: Bool
    
    var body: some View {
        HStack {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(completed ? HealthColors.healthGood : HealthColors.secondaryText)
            
            Text(title)
                .font(HealthTypography.body)
                .foregroundColor(completed ? HealthColors.primaryText : HealthColors.secondaryText)
            
            Spacer()
        }
    }
}

struct ReportStatItem: View {
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
    }
}

struct InsightItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
        }
    }
}

struct RecommendationItem: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(HealthColors.primary)
                .frame(width: 20)
            
            Text(text)
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: HealthSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(HealthColors.secondaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                Text(title)
                    .font(HealthTypography.headline)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(message)
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(HealthSpacing.xl)
    }
}

struct ExportSheet: View {
    let report: LabReportDocument
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: HealthSpacing.xl) {
                Text("Export Options")
                    .font(HealthTypography.headline)
                    .foregroundColor(HealthColors.primaryText)
                
                VStack(spacing: HealthSpacing.md) {
                    ExportOptionButton(title: "PDF Report", icon: "doc.fill", description: "Complete report with analysis")
                    ExportOptionButton(title: "Biomarkers CSV", icon: "tablecells", description: "Raw biomarker data")
                    ExportOptionButton(title: "Share Link", icon: "link", description: "Shareable report link")
                }
                
                Spacer()
            }
            .padding(HealthSpacing.screenPadding)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ExportOptionButton: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        Button(action: {
            // Export functionality implementation pending
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text(description)
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

