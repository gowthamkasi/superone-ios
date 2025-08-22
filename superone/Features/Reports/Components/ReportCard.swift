//
//  ReportCard.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Card component for displaying lab report information in list view
struct ReportCard: View {
    let report: LabReportDocument
    let onTap: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    @State private var showActionSheet = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                // Header with file info and status
                HStack {
                    VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                        Text(report.fileName)
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(HealthColors.primaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: HealthSpacing.sm) {
                            // File size
                            Text(report.displayFileSize)
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(HealthColors.secondaryText)
                            
                            Text("•")
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(HealthColors.secondaryText)
                            
                            // Upload date
                            Text(formatDate(report.uploadDate))
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(HealthColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: HealthSpacing.xs) {
                        // Status badge
                        ReportStatusBadge(status: report.processingStatus)
                        
                        // Actions button
                        Button(action: { showActionSheet = true }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(HealthColors.secondaryText)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Document type and category info
                HStack(spacing: HealthSpacing.md) {
                    // Document type
                    if let documentType = report.documentType {
                        Label(documentType.displayName, systemImage: documentType.icon)
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primary)
                    }
                    
                    // Health category
                    if let category = report.healthCategory {
                        Label(category.displayName, systemImage: "tag.fill")
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(category.color)
                    }
                }
                
                // OCR confidence (if available)
                if let confidence = report.ocrConfidence {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(confidenceColor(confidence))
                        
                        Text("Accuracy: \(Int(confidence * 100))%")
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                        
                        Spacer()
                    }
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
        }
        .buttonStyle(PlainButtonStyle())
        .healthCardShadow()
        .confirmationDialog("Report Actions", isPresented: $showActionSheet) {
            Button("Share") {
                onShare()
            }
            
            if report.processingStatus == .completed {
                Button("Export PDF") {
                    // Export functionality will be implemented
                }
            }
            
            Button("Delete", role: .destructive) {
                onDelete()
            }
            
            Button("Cancel", role: .cancel) { }
        }
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

// MARK: - Status Badge Component

struct ReportStatusBadge: View {
    let status: ProcessingStatus
    
    var body: some View {
        HStack(spacing: HealthSpacing.xs) {
            Image(systemName: status.icon)
                .font(.system(size: 10, weight: .medium))
            
            Text(status.displayName)
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, HealthSpacing.sm)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .foregroundColor(status.color)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview("Report Card - Completed") {
    VStack(spacing: HealthSpacing.md) {
        ReportCard(
            report: LabReportDocument(
                fileName: "Blood Work - Complete Panel.pdf",
                fileSize: 2_400_000,
                mimeType: "application/pdf",
                processingStatus: .completed,
                documentType: .bloodWork,
                healthCategory: .hematology,
                extractedText: "Complete Blood Count results...",
                ocrConfidence: 0.95
            ),
            onTap: {  },
            onShare: {  },
            onDelete: {  }
        )
        
        ReportCard(
            report: LabReportDocument(
                fileName: "Thyroid Function Tests - Very Long File Name That Should Wrap.pdf",
                fileSize: 1_200_000,
                mimeType: "application/pdf",
                processingStatus: .processing,
                documentType: .thyroidFunction,
                healthCategory: .endocrine,
                extractedText: nil,
                ocrConfidence: nil
            ),
            onTap: {  },
            onShare: {  },
            onDelete: {  }
        )
        
        ReportCard(
            report: LabReportDocument(
                fileName: "Failed Processing Report.pdf",
                fileSize: 1_800_000,
                mimeType: "application/pdf",
                processingStatus: .failed,
                documentType: .metabolicPanel,
                healthCategory: .metabolic,
                extractedText: nil,
                ocrConfidence: nil
            ),
            onTap: {  },
            onShare: {  },
            onDelete: {  }
        )
    }
    .padding()
    .background(HealthColors.background)
}