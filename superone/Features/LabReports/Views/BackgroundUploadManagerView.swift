//
//  BackgroundUploadManagerView.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI

/// View for managing background upload tasks and monitoring their progress
struct BackgroundUploadManagerView: View {
    
    @StateObject private var backgroundUploadService = BackgroundUploadService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPriority: BackgroundUploadPriority = .normal
    @State private var showingUploadOptions = false
    @State private var documentToUpload: LabReportDocument?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Upload queue summary
                uploadQueueSummary
                
                // Active uploads section
                activeUploadsSection
                
                // Upload queue list
                uploadQueueList
            }
            .navigationTitle("Background Uploads")
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
                            Task {
                                await backgroundUploadService.resumePendingUploads()
                            }
                        } label: {
                            Label("Resume All", systemImage: "play.fill")
                        }
                        
                        Button {
                            showingUploadOptions = true
                        } label: {
                            Label("Schedule Upload", systemImage: "plus.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            cancelAllUploads()
                        } label: {
                            Label("Cancel All", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                // Refresh upload statuses
            }
            .sheet(isPresented: $showingUploadOptions) {
                DocumentPickerView { document in
                    documentToUpload = document
                    Task {
                        await scheduleUpload(document)
                    }
                }
            }
        }
        .onAppear {
            setupNotificationObservers()
        }
    }
    
    // MARK: - Upload Queue Summary
    
    private var uploadQueueSummary: some View {
        let statuses = backgroundUploadService.getAllBackgroundUploadStatuses()
        let pendingCount = statuses.filter { $0.status == .pending }.count
        let uploadingCount = statuses.filter { $0.status == .uploading }.count
        let completedCount = statuses.filter { $0.status == .completed }.count
        let failedCount = statuses.filter { $0.status == .failed }.count
        
        return VStack(spacing: HealthSpacing.lg) {
            HStack(spacing: HealthSpacing.lg) {
                QueueSummaryCard(
                    icon: "clock.fill",
                    title: "Pending",
                    count: pendingCount,
                    color: HealthColors.secondary
                )
                
                QueueSummaryCard(
                    icon: "arrow.up.circle.fill",
                    title: "Uploading",
                    count: uploadingCount,
                    color: HealthColors.primary
                )
                
                QueueSummaryCard(
                    icon: "checkmark.circle.fill",
                    title: "Completed",
                    count: completedCount,
                    color: HealthColors.healthGood
                )
                
                QueueSummaryCard(
                    icon: "exclamationmark.circle.fill",
                    title: "Failed",
                    count: failedCount,
                    color: HealthColors.healthCritical
                )
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
    }
    
    // MARK: - Active Uploads Section
    
    private var activeUploadsSection: some View {
        let activeStatuses = backgroundUploadService.getAllBackgroundUploadStatuses()
            .filter { $0.status == .uploading }
        
        return Group {
            if !activeStatuses.isEmpty {
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    HStack {
                        Text("Active Uploads")
                            .font(HealthTypography.headingSmall)
                            .foregroundColor(HealthColors.primaryText)
                        
                        Spacer()
                        
                        Button("Pause All") {
                            pauseAllActiveUploads()
                        }
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                    }
                    
                    ForEach(activeStatuses, id: \.taskId) { status in
                        ActiveUploadCard(
                            status: status,
                            onCancel: {
                                backgroundUploadService.cancelBackgroundUpload(taskId: status.taskId)
                            }
                        )
                    }
                }
                .padding(HealthSpacing.lg)
                .background(HealthColors.primaryBackground)
            }
        }
    }
    
    // MARK: - Upload Queue List
    
    private var uploadQueueList: some View {
        let allStatuses = backgroundUploadService.getAllBackgroundUploadStatuses()
            .filter { $0.status != .uploading }
            .sorted { status1, status2 in
                // Sort by priority, then by scheduled date
                if status1.status.rawValue == status2.status.rawValue {
                    return status1.scheduledAt > status2.scheduledAt
                }
                return status1.status.rawValue < status2.status.rawValue
            }
        
        return Group {
            if allStatuses.isEmpty {
                emptyQueueView
            } else {
                ScrollView {
                    LazyVStack(spacing: HealthSpacing.md) {
                        ForEach(allStatuses, id: \.taskId) { status in
                            UploadQueueCard(
                                status: status,
                                onCancel: {
                                    backgroundUploadService.cancelBackgroundUpload(taskId: status.taskId)
                                },
                                onRetry: {
                                    retryUpload(taskId: status.taskId)
                                }
                            )
                        }
                    }
                    .padding(HealthSpacing.lg)
                }
            }
        }
    }
    
    // MARK: - Empty Queue View
    
    private var emptyQueueView: some View {
        VStack(spacing: HealthSpacing.xl) {
            Image(systemName: "tray.fill")
                .font(.system(size: 48))
                .foregroundColor(HealthColors.secondaryText)
            
            VStack(spacing: HealthSpacing.md) {
                Text("No Background Uploads")
                    .font(HealthTypography.headingMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("Schedule uploads to continue processing when the app is in the background")
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button("Schedule Upload") {
                showingUploadOptions = true
            }
            .buttonStyle(HealthPrimaryButtonStyle())
        }
        .padding(HealthSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func scheduleUpload(_ document: LabReportDocument) async {
        do {
            let taskId = try await backgroundUploadService.scheduleBackgroundUpload(
                document,
                userPreferences: nil,
                priority: selectedPriority
            )
        } catch {
        }
    }
    
    private func cancelAllUploads() {
        let allStatuses = backgroundUploadService.getAllBackgroundUploadStatuses()
        for status in allStatuses {
            backgroundUploadService.cancelBackgroundUpload(taskId: status.taskId)
        }
    }
    
    private func pauseAllActiveUploads() {
        let activeStatuses = backgroundUploadService.getAllBackgroundUploadStatuses()
            .filter { $0.status == .uploading }
        
        for status in activeStatuses {
            backgroundUploadService.cancelBackgroundUpload(taskId: status.taskId)
        }
    }
    
    private func retryUpload(taskId: String) {
        // This would restart a failed upload
        // Implementation would depend on the specific retry mechanism
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .backgroundUploadCompleted,
            object: nil,
            queue: .main
        ) { _ in
            // Update UI when uploads complete
        }
        
        NotificationCenter.default.addObserver(
            forName: .backgroundUploadFailed,
            object: nil,
            queue: .main
        ) { _ in
            // Update UI when uploads fail
        }
    }
}

// MARK: - Supporting Views

struct QueueSummaryCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: HealthSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text("\(count)")
                .font(HealthTypography.headingMedium)
                .foregroundColor(HealthColors.primaryText)
                .fontWeight(.bold)
            
            Text(title)
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(HealthSpacing.md)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
}

struct ActiveUploadCard: View {
    let status: BackgroundUploadStatus
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.fileName)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(1)
                    
                    Text("Uploading...")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.primary)
                }
                
                Spacer()
                
                Button("Cancel") {
                    onCancel()
                }
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.healthCritical)
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(status.progressPercentage)%")
                        .font(HealthTypography.captionSmall)
                        .foregroundColor(HealthColors.secondaryText)
                    
                    Spacer()
                    
                    if let duration = status.duration {
                        Text(formatDuration(duration))
                            .font(HealthTypography.captionSmall)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
                
                ProgressView(value: status.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: HealthColors.primary))
                    .scaleEffect(y: 0.8)
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct UploadQueueCard: View {
    let status: BackgroundUploadStatus
    let onCancel: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.fileName)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(1)
                    
                    Text(formatScheduledTime(status.scheduledAt))
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: status.status.toProcessingStatus())
                    
                    if status.status == .completed, let duration = status.duration {
                        Text(formatDuration(duration))
                            .font(HealthTypography.captionSmall)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
            }
            
            // Error message for failed uploads
            if status.status == .failed, let error = status.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(HealthColors.healthCritical)
                        .font(.caption)
                    
                    Text(error.localizedDescription)
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
                if status.status == .failed {
                    Button("Retry") {
                        onRetry()
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                }
                
                Spacer()
                
                Button("Remove") {
                    onCancel()
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
    
    private func formatScheduledTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "Scheduled \(formatter.string(from: date))"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.0fs", duration)
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%dm %02ds", minutes, seconds)
        }
    }
}

// MARK: - Document Picker View (Simplified)

struct DocumentPickerView: View {
    let onDocumentSelected: (LabReportDocument) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Document Picker")
                    .font(HealthTypography.headingMedium)
                
                Text("This would integrate with document picker")
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                
                Button("Select Mock Document") {
                    let mockDocument = LabReportDocument(
                        id: UUID().uuidString,
                        fileName: "blood_test_\(Date().timeIntervalSince1970).pdf",
                        fileSize: 2048000,
                        mimeType: "application/pdf",
                        processingStatus: .pending,
                        data: Data()
                    )
                    onDocumentSelected(mockDocument)
                    dismiss()
                }
                .buttonStyle(HealthPrimaryButtonStyle())
            }
            .navigationTitle("Select Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions

extension BackgroundUploadTaskStatus {
    func toProcessingStatus() -> ProcessingStatus {
        switch self {
        case .pending: return .pending
        case .uploading: return .uploading
        case .retrying: return .retrying
        case .completed: return .completed
        case .failed: return .failed
        case .cancelled: return .cancelled
        }
    }
}

// MARK: - Preview

#Preview {
    BackgroundUploadManagerView()
}