//
//  HistoryExportView.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI
import UniformTypeIdentifiers

/// View for exporting upload history data in various formats
struct HistoryExportView: View {
    
    let history: [HistoryItem]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormat: ExportFormat = .csv
    @State private var includeStatistics = true
    @State private var includeFailedUploads = true
    @State private var selectedDateRange: HistoryTimeRange = .lastMonth
    @State private var isExporting = false
    @State private var exportError: ExportError?
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                    // Header
                    exportHeader
                    
                    // Format selection
                    formatSelectionSection
                    
                    // Options
                    exportOptionsSection
                    
                    // Preview
                    exportPreviewSection
                    
                    // Export button
                    exportButtonSection
                }
                .padding(HealthSpacing.lg)
            }
            .navigationTitle("Export History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Export Error", isPresented: .constant(exportError != nil)) {
                Button("OK") {
                    exportError = nil
                }
            } message: {
                if let error = exportError {
                    Text(error.localizedDescription)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    // MARK: - Export Header
    
    private var exportHeader: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Image(systemName: "square.and.arrow.up.fill")
                    .foregroundColor(HealthColors.primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export Upload History")
                        .font(HealthTypography.headingMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text("Export your upload history and statistics")
                        .font(HealthTypography.bodyRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                Spacer()
            }
            
            // Summary stats
            HStack(spacing: HealthSpacing.lg) {
                StatSummaryItem(
                    title: "Total Items",
                    value: "\(filteredHistory.count)",
                    icon: "doc.text.fill"
                )
                
                StatSummaryItem(
                    title: "Data Size",
                    value: totalDataSizeFormatted,
                    icon: "externaldrive.fill"
                )
                
                StatSummaryItem(
                    title: "Date Range",
                    value: selectedDateRange.displayName,
                    icon: "calendar.circle.fill"
                )
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.lg)
    }
    
    // MARK: - Format Selection
    
    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Export Format")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: HealthSpacing.md) {
                ForEach(ExportFormat.allCases.filter { $0 != .pdf && $0 != .excel }, id: \.self) { format in
                    FormatSelectionCard(
                        format: format,
                        isSelected: selectedFormat == format,
                        onSelect: {
                            selectedFormat = format
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Export Options
    
    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Export Options")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                OptionToggle(
                    title: "Include Statistics",
                    subtitle: "Export overall upload statistics",
                    isOn: $includeStatistics
                )
                
                OptionToggle(
                    title: "Include Failed Uploads",
                    subtitle: "Include uploads that failed processing",
                    isOn: $includeFailedUploads
                )
            }
        }
    }
    
    // MARK: - Export Preview
    
    private var exportPreviewSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Preview")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            ScrollView {
                VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                    if selectedFormat == .csv {
                        csvPreview
                    } else {
                        jsonPreview
                    }
                }
                .padding(HealthSpacing.md)
                .background(HealthColors.primaryBackground)
                .cornerRadius(HealthCornerRadius.md)
                .frame(maxHeight: 200)
            }
        }
    }
    
    // MARK: - Export Button
    
    private var exportButtonSection: some View {
        VStack(spacing: HealthSpacing.md) {
            Button {
                Task {
                    await performExport()
                }
            } label: {
                HStack {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up.fill")
                    }
                    
                    Text(isExporting ? "Exporting..." : "Export \(selectedFormat.displayName)")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.lg)
                .background(HealthColors.primary)
                .cornerRadius(HealthCornerRadius.lg)
            }
            .disabled(isExporting || filteredHistory.isEmpty)
            
            Text("File will be saved to your device and can be shared")
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Preview Content
    
    private var csvPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("File Name,Upload Date,Status,File Size,Processing Time")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(HealthColors.primaryText)
                .fontWeight(.semibold)
            
            ForEach(Array(filteredHistory.prefix(3).enumerated()), id: \.offset) { index, item in
                Text("\"\(item.fileName)\",\(formatDate(item.uploadDate)),\(item.status.rawValue),\(item.fileSize),\(item.processingTime ?? 0)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(HealthColors.secondaryText)
                    .lineLimit(1)
            }
            
            if filteredHistory.count > 3 {
                Text("... and \(filteredHistory.count - 3) more items")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(HealthColors.secondaryText)
                    .italic()
            }
        }
    }
    
    private var jsonPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("{\n  \"exportDate\": \"\(formatDate(Date()))\",")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(HealthColors.primaryText)
            
            if includeStatistics {
                Text("  \"statistics\": { ... },")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Text("  \"history\": [")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(HealthColors.primaryText)
            
            ForEach(Array(filteredHistory.prefix(2).enumerated()), id: \.offset) { index, item in
                Text("    { \"fileName\": \"\(item.fileName)\", ... }")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            if filteredHistory.count > 2 {
                Text("    ... \(filteredHistory.count - 2) more items")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(HealthColors.secondaryText)
                    .italic()
            }
            
            Text("  ]\n}")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(HealthColors.primaryText)
        }
    }
    
    // MARK: - Helper Properties
    
    private var filteredHistory: [HistoryItem] {
        var filtered = history
        
        if !includeFailedUploads {
            filtered = filtered.filter { $0.status != .failed }
        }
        
        return filtered
    }
    
    private var totalDataSizeFormatted: String {
        let totalSize = filteredHistory.reduce(0) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func performExport() async {
        isExporting = true
        exportError = nil
        
        do {
            let exportData = generateExportData()
            let fileName = generateFileName()
            let fileURL = try await saveToFile(data: exportData, fileName: fileName)
            
            await MainActor.run {
                exportedFileURL = fileURL
                showingShareSheet = true
            }
            
        } catch {
            exportError = ExportError.exportFailed(error.localizedDescription)
        }
        
        isExporting = false
    }
    
    private func generateExportData() -> Data {
        switch selectedFormat {
        case .csv:
            return generateCSVData()
        case .json:
            return generateJSONData()
        default:
            return Data()
        }
    }
    
    private func generateCSVData() -> Data {
        var csvString = "File Name,Upload Date,Status,File Size,Processing Time,Biomarkers,Document Type\n"
        
        for item in filteredHistory {
            let processingTime = item.processingTime.map { "\($0)" } ?? ""
            let biomarkers = item.biomarkerCount.map { "\($0)" } ?? ""
            let docType = item.documentType ?? ""
            
            csvString += "\"\(item.fileName)\",\(formatDate(item.uploadDate)),\(item.status.rawValue),\(item.fileSize),\(processingTime),\(biomarkers),\"\(docType)\"\n"
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
    
    private func generateJSONData() -> Data {
        let exportData = ExportData(
            exportDate: Date(),
            format: selectedFormat.rawValue,
            includeStatistics: includeStatistics,
            totalItems: filteredHistory.count,
            history: filteredHistory
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return (try? encoder.encode(exportData)) ?? Data()
    }
    
    private func generateFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = formatter.string(from: Date())
        
        return "upload_history_\(timestamp).\(selectedFormat.fileExtension)"
    }
    
    private func saveToFile(data: Data, fileName: String) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Supporting Views

struct StatSummaryItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: HealthSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(HealthColors.primary)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(HealthTypography.captionSmall)
                    .foregroundColor(HealthColors.secondaryText)
            }
        }
    }
}

struct FormatSelectionCard: View {
    let format: ExportFormat
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: HealthSpacing.sm) {
                Image(systemName: format.iconName)
                    .foregroundColor(isSelected ? .white : HealthColors.primary)
                    .font(.title2)
                
                Text(format.displayName)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(isSelected ? .white : HealthColors.primaryText)
                    .fontWeight(.semibold)
                
                Text(format.description)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(HealthSpacing.lg)
            .background(isSelected ? HealthColors.primary : HealthColors.primaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                    .stroke(isSelected ? HealthColors.primary : HealthColors.border, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(HealthCornerRadius.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OptionToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(subtitle)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(HealthColors.primary)
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Supporting Types

struct ExportData: Codable {
    let exportDate: Date
    let format: String
    let includeStatistics: Bool
    let totalItems: Int
    let history: [HistoryItem]
}

extension ExportFormat {
    var iconName: String {
        switch self {
        case .csv: return "tablecells.fill"
        case .json: return "curlybraces"
        case .pdf: return "doc.fill"
        case .excel: return "tablecells.fill"
        }
    }
    
    var description: String {
        switch self {
        case .csv: return "Spreadsheet format"
        case .json: return "Structured data format"
        case .pdf: return "Document format"
        case .excel: return "Excel spreadsheet"
        }
    }
}

enum ExportError: Error, LocalizedError, Sendable {
    case exportFailed(String)
    case fileWriteFailed
    case invalidData
    
    nonisolated var errorDescription: String? {
        switch self {
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .fileWriteFailed:
            return "Failed to save file to device"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

// MARK: - Preview

#Preview {
    let mockHistory = [
        HistoryItem(
            id: "1",
            labReportId: "lr_1",
            fileName: "blood_test_2024.pdf",
            fileSize: 2048000,
            uploadDate: Date(),
            status: .completed,
            documentType: "Blood Test",
            processingTime: 45,
            biomarkerCount: 12,
            errorMessage: nil
        ),
        HistoryItem(
            id: "2",
            labReportId: "lr_2",
            fileName: "cholesterol_report.jpg",
            fileSize: 1024000,
            uploadDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            status: .failed,
            documentType: "Lipid Panel",
            processingTime: nil,
            biomarkerCount: nil,
            errorMessage: "OCR processing failed"
        )
    ]
    
    return HistoryExportView(history: mockHistory)
}