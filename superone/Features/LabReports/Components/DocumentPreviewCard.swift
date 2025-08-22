//
//  DocumentPreviewCard.swift
//  SuperOne
//
//  Created by Claude Code on 7/27/25.
//

import SwiftUI

/// Reusable card component for displaying lab report document previews
struct DocumentPreviewCard: View {
    
    // MARK: - Properties
    
    let document: LabReportDocument
    let onTap: (() -> Void)?
    let onRetry: (() -> Void)?
    let onDelete: (() -> Void)?
    let showActions: Bool
    
    // MARK: - Initialization
    
    init(
        document: LabReportDocument,
        showActions: Bool = true,
        onTap: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.document = document
        self.showActions = showActions
        self.onTap = onTap
        self.onRetry = onRetry
        self.onDelete = onDelete
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with document info
            headerSection
            
            // Thumbnail or icon section
            thumbnailSection
            
            // Status and details section
            detailsSection
            
            // Actions section
            if showActions {
                actionsSection
            }
        }
        .background(HealthColors.background)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Document type icon and name
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: document.documentType?.icon ?? "doc")
                    .foregroundColor(statusColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.fileName)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(1)
                    
                    Text(document.displayFileSize)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            Spacer()
            
            // Status indicator
            statusIndicator
        }
        .padding(.horizontal, HealthSpacing.lg)
        .padding(.vertical, HealthSpacing.sm)
    }
    
    // MARK: - Thumbnail Section
    
    private var thumbnailSection: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                .fill(HealthColors.secondaryBackground)
                .frame(height: 120)
            
            if let thumbnailData = document.thumbnail,
               let image = UIImage(data: thumbnailData) {
                // Show actual thumbnail
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 100)
                    .cornerRadius(HealthCornerRadius.md)
            } else {
                // Show placeholder icon
                VStack(spacing: HealthSpacing.sm) {
                    Image(systemName: document.documentType?.icon ?? "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(HealthColors.primary)
                    
                    Text(document.documentType?.displayName ?? "Lab Report")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Processing overlay
            if document.processingStatus == .processing {
                processingOverlay
            }
        }
        .padding(.horizontal, HealthSpacing.lg)
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            // Upload date
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(HealthColors.secondaryText)
                    .font(.caption)
                
                Text("Uploaded \(RelativeDateTimeFormatter().localizedString(for: document.uploadDate, relativeTo: Date()))")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                
                Spacer()
            }
            
            // Document type and category
            if let documentType = document.documentType {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(HealthColors.secondaryText)
                        .font(.caption)
                    
                    Text(documentType.displayName)
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    if let category = document.healthCategory {
                        Spacer()
                        
                        Text(category.displayName)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(category.color)
                            .padding(.horizontal, HealthSpacing.sm)
                            .padding(.vertical, 2)
                            .background(category.color.opacity(0.1))
                            .cornerRadius(HealthCornerRadius.md)
                    }
                }
            }
            
            // OCR confidence if available
            if let confidence = document.ocrConfidence {
                HStack {
                    Image(systemName: "checkmark.shield")
                        .foregroundColor(confidenceColor(confidence))
                        .font(.caption)
                    
                    Text("Confidence: \(Int(confidence * 100))%")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(confidenceColor(confidence))
                    
                    Spacer()
                }
            }
            
            // Error message if failed
            if document.processingStatus == .failed {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(HealthColors.healthCritical)
                        .font(.caption)
                    
                    Text("Processing failed - tap to retry")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.healthCritical)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, HealthSpacing.lg)
        .padding(.bottom, HealthSpacing.sm)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        HStack(spacing: HealthSpacing.md) {
            if document.canRetryProcessing {
                Button(action: {
                    onRetry?()
                }) {
                    HStack(spacing: HealthSpacing.sm) {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                }
            }
            
            Spacer()
            
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    HStack(spacing: HealthSpacing.sm) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.healthCritical)
                }
            }
        }
        .padding(.horizontal, HealthSpacing.lg)
        .padding(.bottom, HealthSpacing.lg)
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(HealthTypography.captionMedium)
                .foregroundColor(statusColor)
        }
    }
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                .fill(Color.black.opacity(0.7))
            
            VStack(spacing: HealthSpacing.sm) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Processing...")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch document.processingStatus {
        case .pending:
            return HealthColors.healthNeutral
        case .uploading, .preprocessing, .processing, .analyzing, .extracting, .validating, .retrying:
            return HealthColors.primary
        case .completed:
            return HealthColors.healthGood
        case .failed:
            return HealthColors.healthCritical
        case .cancelled:
            return HealthColors.healthWarning
        case .paused:
            return HealthColors.healthWarning
        }
    }
    
    private var statusText: String {
        switch document.processingStatus {
        case .pending:
            return "Pending"
        case .uploading:
            return "Uploading"
        case .preprocessing:
            return "Preprocessing"
        case .processing:
            return "Processing"
        case .analyzing:
            return "Analyzing"
        case .extracting:
            return "Extracting"
        case .validating:
            return "Validating"
        case .completed:
            return "Complete"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        case .paused:
            return "Paused"
        case .retrying:
            return "Retrying"
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.9 {
            return HealthColors.healthExcellent
        } else if confidence >= 0.8 {
            return HealthColors.healthGood
        } else if confidence >= 0.6 {
            return HealthColors.healthWarning
        } else {
            return HealthColors.healthCritical
        }
    }
}

// MARK: - Preview

#Preview("Pending Document") {
    DocumentPreviewCard(
        document: LabReportDocument(
            fileName: "blood_work_results.pdf",
            fileSize: 2_456_789,
            mimeType: "application/pdf",
            processingStatus: .pending,
            documentType: .bloodWork
        )
    )
    .padding()
}

#Preview("Processing Document") {
    DocumentPreviewCard(
        document: LabReportDocument(
            fileName: "lipid_panel.jpg",
            fileSize: 1_234_567,
            mimeType: "image/jpeg",
            processingStatus: .processing,
            documentType: .lipidPanel,
            healthCategory: .cardiovascular
        )
    )
    .padding()
}

#Preview("Completed Document") {
    DocumentPreviewCard(
        document: LabReportDocument(
            fileName: "comprehensive_metabolic_panel.pdf",
            fileSize: 3_789_456,
            mimeType: "application/pdf",
            processingStatus: .completed,
            documentType: .metabolicPanel,
            healthCategory: .metabolic,
            ocrConfidence: 0.92
        )
    )
    .padding()
}

#Preview("Failed Document") {
    DocumentPreviewCard(
        document: LabReportDocument(
            fileName: "thyroid_function.jpg",
            fileSize: 987_654,
            mimeType: "image/jpeg",
            processingStatus: .failed,
            documentType: .thyroidFunction,
            healthCategory: .endocrine
        )
    )
    .padding()
}