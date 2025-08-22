//
//  DataExportSheet.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Sheet for exporting user data
struct DataExportSheet: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormats: Set<ExportFormat> = [.json]
    @State private var includeImages: Bool = true
    @State private var includeAnalysis: Bool = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: HealthSpacing.xl) {
                // Header
                VStack(spacing: HealthSpacing.md) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(HealthColors.primary)
                    
                    Text("Export Your Health Data")
                        .font(HealthTypography.headingMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Download a copy of all your health reports, analysis, and data")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                
                if viewModel.isExporting {
                    // Export progress
                    exportProgressView
                } else {
                    // Export options
                    exportOptionsView
                }
                
                Spacer()
                
                // Action buttons
                if !viewModel.isExporting {
                    actionButtons
                }
            }
            .padding(.vertical, HealthSpacing.screenPadding)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isExporting)
                }
            }
        }
    }
    
    private var exportProgressView: some View {
        VStack(spacing: HealthSpacing.lg) {
            ProgressView(value: viewModel.exportProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: HealthColors.primary))
                .scaleEffect(1.2)
            
            Text("Preparing your data export...")
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primaryText)
            
            Text("\(Int(viewModel.exportProgress * 100))% complete")
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.secondaryText)
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    private var exportOptionsView: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Format selection
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                Text("Export Formats")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                VStack(spacing: HealthSpacing.sm) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        ExportFormatRow(
                            format: format,
                            isSelected: selectedFormats.contains(format),
                            onToggle: { isSelected in
                                if isSelected {
                                    selectedFormats.insert(format)
                                } else {
                                    selectedFormats.remove(format)
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            // Include options
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                Text("Include in Export")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                VStack(spacing: HealthSpacing.md) {
                    ExportOptionRow(
                        icon: "photo.fill",
                        title: "Original Images",
                        subtitle: "Include scanned document images",
                        isSelected: $includeImages
                    )
                    
                    ExportOptionRow(
                        icon: "brain.head.profile",
                        title: "AI Analysis",
                        subtitle: "Include health insights and recommendations",
                        isSelected: $includeAnalysis
                    )
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: HealthSpacing.md) {
            Button(action: {
                viewModel.exportData()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Start Export")
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.md)
                .background(HealthColors.primary)
                .cornerRadius(HealthCornerRadius.button)
            }
            .disabled(selectedFormats.isEmpty)
            
            Button("Cancel") {
                dismiss()
            }
            .font(HealthTypography.body)
            .foregroundColor(HealthColors.secondaryText)
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
}

// MARK: - Supporting Views

struct ExportFormatRow: View {
    let format: ExportFormat
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: { onToggle(!isSelected) }) {
            HStack {
                Image(systemName: format.icon)
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(format.displayName)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text(format.formatDescription)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
            }
            .padding(.vertical, HealthSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExportOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(HealthColors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(subtitle)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isSelected)
                .tint(HealthColors.primary)
        }
        .padding(.vertical, HealthSpacing.sm)
    }
}

// MARK: - Supporting Types

enum ExportFormat: String, CaseIterable {
    case json = "json"
    case csv = "csv"
    case pdf = "pdf"
    case excel = "excel"
    
    var displayName: String {
        switch self {
        case .json: return "JSON"
        case .csv: return "CSV"
        case .pdf: return "PDF Report"
        case .excel: return "Excel"
        }
    }
    
    var formatDescription: String {
        switch self {
        case .json: return "Machine-readable data format"
        case .csv: return "Spreadsheet-compatible format"
        case .pdf: return "Human-readable document"
        case .excel: return "Excel spreadsheet format"
        }
    }
    
    var icon: String {
        switch self {
        case .json: return "doc.text"
        case .csv: return "tablecells"
        case .pdf: return "doc.richtext"
        case .excel: return "tablecells.fill"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .pdf: return "pdf"
        case .excel: return "xlsx"
        }
    }
}

#Preview {
    DataExportSheet(viewModel: ProfileViewModel())
}