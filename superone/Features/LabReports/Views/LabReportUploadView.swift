//
//  LabReportUploadView.swift
//  SuperOne
//
//  Created by Claude Code on 7/27/25.
//

import SwiftUI
import PhotosUI
import VisionKit

/// Main interface for lab report upload and processing workflow
struct LabReportUploadView: View {
    
    // MARK: - Properties
    
    @State private var viewModel = LabReportViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Processing preferences
    @State private var showProcessingOptions = false
    @State private var preferCloudProcessing = true
    @State private var allowLocalFallback = true
    @State private var showUploadHistory = false
    
    // MARK: - Body
    
    var body: some View {
        if AppConfiguration.current.isFeatureEnabled(.ocrUpload) {
            NavigationView {
                GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Progress indicator at top
                    if viewModel.currentStep != .selectDocument {
                        progressHeader
                    }
                    
                    // Main content area
                    ScrollView {
                        VStack(spacing: HealthSpacing.xl) {
                            // Current step content
                            currentStepContent
                                .frame(minHeight: geometry.size.height * 0.7)
                        }
                        .padding(.horizontal, HealthSpacing.screenPadding)
                        .padding(.vertical, HealthSpacing.xl)
                    }
                    
                    // Bottom navigation bar
                    if viewModel.currentStep != .selectDocument {
                        bottomNavigationBar
                    }
                }
            }
            .navigationTitle("Lab Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.currentStep == .selectDocument {
                        Menu {
                            Button(action: { showProcessingOptions = true }) {
                                Label("Processing Options", systemImage: "gear")
                            }
                            
                            Button(action: { showUploadHistory = true }) {
                                Label("Upload History", systemImage: "clock")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentStep == .selectDocument {
                        Button("Close") {
                            dismiss()
                        }
                    } else {
                        Button("Cancel") {
                            viewModel.cancelProcessing()
                        }
                        .foregroundColor(HealthColors.healthCritical)
                    }
                }
            }
            .fileImporter(
                isPresented: $viewModel.showFilePicker,
                allowedContentTypes: [.pdf, .jpeg, .png, .heic],
                allowsMultipleSelection: true
            ) { result in
                viewModel.handleFileSelection(result)
            }
            .photosPicker(
                isPresented: $viewModel.showPhotoLibrarySheet,
                selection: $viewModel.photoPickerItems,
                maxSelectionCount: 5,
                matching: .images
            )
            .onChange(of: viewModel.photoPickerItems) { _, _ in
                viewModel.handlePhotoSelection()
            }
            .sheet(isPresented: $viewModel.showDocumentScanner) {
                DocumentScannerSheetView { images in
                    viewModel.processSelectedImages(images)
                }
            }
            .alert("Processing Error", isPresented: $viewModel.showErrorAlert) {
                if let error = viewModel.processingError, error.isRecoverable {
                    Button("Retry") {
                        if let document = viewModel.selectedDocument {
                            viewModel.retryProcessing(document)
                        }
                    }
                }
                Button("OK") {
                    viewModel.processingError = nil
                }
            } message: {
                if let error = viewModel.processingError {
                    Text(error.message)
                }
            }
            .sheet(isPresented: $viewModel.showSuccessSheet) {
                ProcessingSuccessView(
                    summary: viewModel.processingSummary,
                    biomarkers: viewModel.extractedBiomarkers
                ) {
                    viewModel.resetForNewDocument()
                }
            }
            .sheet(isPresented: $showProcessingOptions) {
                ProcessingOptionsView(
                    preferCloudProcessing: $preferCloudProcessing,
                    allowLocalFallback: $allowLocalFallback
                ) {
                    viewModel.configureOCRPreferences(
                        preferCloud: preferCloudProcessing,
                        allowLocalFallback: allowLocalFallback
                    )
                }
            }
            .sheet(isPresented: $showUploadHistory) {
                SimpleUploadHistoryView()
            }
            } // End NavigationView
        } else {
            // Feature disabled - auto-dismiss modal
            Color.clear
                .onAppear {
                    dismiss()
                }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: HealthSpacing.sm) {
            // Step progress indicator
            HStack {
                ForEach(1...6, id: \.self) { step in
                    stepProgressIndicator(step: step, current: viewModel.currentStep.stepNumber)
                    
                    if step < 6 {
                        progressLine(isCompleted: step < viewModel.currentStep.stepNumber)
                    }
                }
            }
            .padding(.horizontal, HealthSpacing.xl)
            
            // Current step info
            HStack {
                Text(viewModel.currentStep.displayName)
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
            }
            .padding(.horizontal, HealthSpacing.xl)
        }
        .padding(.vertical, HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
    }
    
    // MARK: - Current Step Content
    
    @ViewBuilder
    private var currentStepContent: some View {
        switch viewModel.currentStep {
        case .selectDocument:
            documentSelectionView
            
        case .uploadDocument:
            uploadProgressView
            
        case .processing:
            processingView
            
        case .ocrProcessing:
            processingView
            
        case .classifyDocument:
            classificationView
            
        case .extractBiomarkers:
            extractionView
            
        case .analyzeData:
            analysisView
            
        case .error:
            errorView
            
        case .reviewResults:
            resultsReviewView
            
        case .validateBiomarkers:
            biomarkerValidationView
            
        case .complete:
            completionView
        }
    }
    
    // MARK: - Document Selection View
    
    private var documentSelectionView: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Header
            VStack(spacing: HealthSpacing.md) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(HealthColors.primary)
                    .font(.system(size: 48))
                
                Text("Upload Lab Report")
                    .font(HealthTypography.headingLarge)
                    .foregroundColor(HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("Take a photo or scan your lab results to get AI-powered health insights")
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Upload zone
            UploadDropZone(
                onFileUpload: viewModel.uploadFromFiles,
                onPhotoLibrarySelect: viewModel.selectFromPhotoLibrary,
                onDocumentScan: viewModel.scanDocument
            )
            
            // Recent documents if any
            if !viewModel.documents.isEmpty {
                recentDocumentsSection
            }
        }
    }
    
    // MARK: - Processing View
    
    private var processingView: some View {
        VStack(spacing: HealthSpacing.xl) {
            if let document = viewModel.selectedDocument {
                DocumentPreviewCard(
                    document: document,
                    showActions: false
                )
            }
            
            ProcessingProgressView(
                progress: viewModel.processingProgress,
                currentOperation: viewModel.currentOperation,
                currentStep: viewModel.currentStep,
                isProcessing: viewModel.isProcessing,
                onCancel: viewModel.cancelProcessing
            )
        }
    }
    
    // MARK: - Results Review View
    
    private var resultsReviewView: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Header
            VStack(spacing: HealthSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(HealthColors.healthGood)
                    .font(.system(size: 48))
                
                Text("Processing Complete")
                    .font(HealthTypography.headingLarge)
                    .foregroundColor(HealthColors.primaryText)
                
                if let summary = viewModel.processingSummary {
                    Text("Extracted \(summary.totalBiomarkersExtracted) biomarkers with \(Int(summary.overallConfidence * 100))% confidence")
                        .font(HealthTypography.bodyRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Biomarkers summary
            biomarkersSummarySection
            
            // Processing summary
            if let summary = viewModel.processingSummary {
                ProcessingSummaryCard(summary: summary)
            }
        }
    }
    
    // MARK: - Biomarker Validation View
    
    private var biomarkerValidationView: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Header
            VStack(spacing: HealthSpacing.sm) {
                Image(systemName: "checkmark.seal")
                    .foregroundColor(HealthColors.primary)
                    .font(.system(size: 48))
                
                Text("Validate Data")
                    .font(HealthTypography.headingLarge)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("Review and correct any extracted biomarker values before saving")
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Biomarkers list for validation
            biomarkerValidationList
        }
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Success animation would go here
            VStack(spacing: HealthSpacing.lg) {
                Image(systemName: "heart.circle.fill")
                    .foregroundColor(HealthColors.healthExcellent)
                    .font(.system(size: 64))
                
                Text("Lab Report Processed!")
                    .font(HealthTypography.headingLarge)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("Your health data has been analyzed and is ready for review in your dashboard.")
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Action buttons
            VStack(spacing: HealthSpacing.md) {
                Button(action: {
                    // Navigate to dashboard/results
                    viewModel.resetForNewDocument()
                    dismiss()
                }) {
                    Text("View Health Insights")
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(HealthColors.primary)
                        .cornerRadius(HealthCornerRadius.button)
                }
                
                Button(action: {
                    viewModel.resetForNewDocument()
                }) {
                    Text("Process Another Report")
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(HealthColors.primary.opacity(0.1))
                        .cornerRadius(HealthCornerRadius.button)
                }
            }
        }
    }
    
    // MARK: - Supporting Views
    
    private var recentDocumentsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Recent Documents")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HealthSpacing.md) {
                    ForEach(viewModel.documents.prefix(3)) { document in
                        DocumentPreviewCard(
                            document: document,
                            showActions: true,
                            onTap: {
                                viewModel.processDocument(document)
                            },
                            onRetry: {
                                viewModel.retryProcessing(document)
                            },
                            onDelete: {
                                // Document deletion will be implemented
                            }
                        )
                        .frame(width: 280)
                    }
                }
                .padding(.horizontal, HealthSpacing.lg)
            }
        }
    }
    
    private var biomarkersSummarySection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Extracted Biomarkers")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: HealthSpacing.md) {
                ForEach(viewModel.extractedBiomarkers.prefix(6)) { biomarker in
                    BiomarkerSummaryCard(biomarker: biomarker)
                }
            }
            
            if viewModel.extractedBiomarkers.count > 6 {
                Text("And \(viewModel.extractedBiomarkers.count - 6) more...")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .padding(.top, HealthSpacing.sm)
            }
        }
    }
    
    private var biomarkerValidationList: some View {
        VStack(spacing: HealthSpacing.md) {
            ForEach(viewModel.biomarkersNeedingValidation()) { biomarker in
                BiomarkerValidationRow(
                    biomarker: biomarker,
                    onUpdate: { value, unit in
                        viewModel.updateBiomarker(biomarker, value: value, unit: unit)
                    },
                    onRemove: {
                        viewModel.removeBiomarker(biomarker)
                    }
                )
            }
            
            // Add manual biomarker button
            Button(action: {
                // Add biomarker sheet will be implemented
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Biomarker Manually")
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primary)
            }
        }
    }
    
    // MARK: - Bottom Navigation Bar
    
    private var bottomNavigationBar: some View {
        HStack {
            if viewModel.canGoBack {
                Button(action: viewModel.goToPreviousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primary)
                }
            }
            
            Spacer()
            
            if viewModel.canProceed {
                Button(action: viewModel.proceedToNextStep) {
                    HStack {
                        Text(nextButtonTitle)
                        Image(systemName: "chevron.right")
                    }
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, HealthSpacing.xl)
                    .padding(.vertical, HealthSpacing.lg)
                    .background(HealthColors.primary)
                    .cornerRadius(HealthCornerRadius.button)
                }
                .disabled(!viewModel.canProceed)
            }
        }
        .padding(.horizontal, HealthSpacing.xl)
        .padding(.vertical, HealthSpacing.lg)
        .background(HealthColors.background)
        .shadow(
            color: HealthShadows.lightShadow.color,
            radius: HealthShadows.lightShadow.radius,
            x: HealthShadows.lightShadow.x,
            y: -HealthShadows.lightShadow.y
        )
    }
    
    // MARK: - Helper Methods
    
    private func stepProgressIndicator(step: Int, current: Int) -> some View {
        ZStack {
            Circle()
                .fill(step <= current ? HealthColors.primary : HealthColors.secondaryBackground)
                .frame(width: 32, height: 32)
            
            if step < current {
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.caption)
                    .bold()
            } else {
                Text("\(step)")
                    .foregroundColor(step == current ? .white : HealthColors.secondaryText)
                    .font(.caption)
                    .bold()
            }
        }
    }
    
    private func progressLine(isCompleted: Bool) -> some View {
        Rectangle()
            .fill(isCompleted ? HealthColors.primary : HealthColors.secondaryBackground)
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }
    
    private var nextButtonTitle: String {
        switch viewModel.currentStep {
        case .selectDocument:
            return "Process"
        case .uploadDocument:
            return "Uploading..."
        case .processing:
            return "Continue"
        case .ocrProcessing:
            return "Continue"
        case .classifyDocument:
            return "Classifying..."
        case .extractBiomarkers:
            return "Extracting..."
        case .analyzeData:
            return "Analyzing..."
        case .error:
            return "Retry"
        case .reviewResults:
            return "Validate"
        case .validateBiomarkers:
            return "Save Results"
        case .complete:
            return "Done"
        }
    }
    
    // MARK: - Backend Processing Views
    
    private var uploadProgressView: some View {
        VStack(spacing: HealthSpacing.xl) {
            if let document = viewModel.selectedDocument {
                DocumentPreviewCard(
                    document: document,
                    showActions: false
                )
            }
            
            UploadProgressCard(
                fileName: viewModel.selectedDocument?.fileName ?? "Unknown",
                progress: viewModel.processingProgress,
                currentOperation: viewModel.currentOperation,
                uploadSpeed: viewModel.uploadSpeed,
                estimatedTimeRemaining: viewModel.estimatedTimeRemaining
            )
            
            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundColor(HealthColors.primary)
                Text("Uploading to secure cloud for AI processing")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            .padding()
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.sm)
        }
    }
    
    private var classificationView: some View {
        VStack(spacing: HealthSpacing.xl) {
            ProcessingStageCard(
                stage: .classifyDocument,
                isActive: true,
                description: "AI is analyzing your document to identify the type of lab report and optimize processing"
            )
            
            AnimatedProcessingIndicator(
                title: "Document Classification",
                subtitle: "Identifying lab report type",
                progress: viewModel.processingProgress
            )
        }
    }
    
    private var extractionView: some View {
        VStack(spacing: HealthSpacing.xl) {
            ProcessingStageCard(
                stage: .extractBiomarkers,
                isActive: true,
                description: "Extracting biomarker values, reference ranges, and test results from your document"
            )
            
            AnimatedProcessingIndicator(
                title: "Biomarker Extraction",
                subtitle: "Finding test values and ranges",
                progress: viewModel.processingProgress
            )
            
            if !viewModel.extractedBiomarkers.isEmpty {
                biomarkerExtractionProgress
            }
        }
    }
    
    private var analysisView: some View {
        VStack(spacing: HealthSpacing.xl) {
            ProcessingStageCard(
                stage: .analyzeData,
                isActive: true,
                description: "AI is generating comprehensive health insights and personalized recommendations"
            )
            
            AnimatedProcessingIndicator(
                title: "Health Analysis",
                subtitle: "Generating AI insights",
                progress: viewModel.processingProgress
            )
            
            if !viewModel.extractedBiomarkers.isEmpty {
                analysisCategoriesProgress
            }
        }
    }
    
    private var errorView: some View {
        VStack(spacing: HealthSpacing.xl) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(HealthColors.healthCritical)
                .font(.system(size: 48))
            
            Text("Processing Error")
                .font(HealthTypography.headingMedium)
                .foregroundColor(HealthColors.primaryText)
            
            if let error = viewModel.processingError {
                Text(error.message)
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                
                if error.isRecoverable {
                    VStack(spacing: HealthSpacing.md) {
                        Button("Try Again") {
                            if let document = viewModel.selectedDocument {
                                viewModel.retryProcessing(document)
                            }
                        }
                        .buttonStyle(HealthPrimaryButtonStyle())
                        
                        Button("Use Local Processing") {
                            if let document = viewModel.selectedDocument {
                                viewModel.processDocumentLocally(document)
                            }
                        }
                        .buttonStyle(HealthSecondaryButtonStyle())
                    }
                }
            }
        }
    }
    
    private var biomarkerExtractionProgress: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Found \(viewModel.extractedBiomarkers.count) biomarkers")
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: HealthSpacing.sm) {
                ForEach(viewModel.extractedBiomarkers.prefix(4)) { biomarker in
                    HStack {
                        Circle()
                            .fill(HealthColors.healthGood)
                            .frame(width: 8, height: 8)
                        Text(biomarker.name)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
    
    private var analysisCategoriesProgress: some View {
        let categories = Array(Set(viewModel.extractedBiomarkers.compactMap { $0.category }))
        
        return VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Analyzing \(categories.count) health categories")
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: HealthSpacing.sm) {
                ForEach(Array(categories.prefix(4)), id: \.self) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(HealthColors.primary)
                            .frame(width: 16)
                        Text(category.displayName)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
    
}

// MARK: - Supporting Views


/// Document scanner sheet wrapper
struct DocumentScannerSheetView: View {
    let onImagesSelected: ([UIImage]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Document scanner integration using VNDocumentCameraViewController will be implemented
        VStack {
            Text("Document scanner not yet implemented")
                .font(HealthTypography.bodyRegular)
                .foregroundColor(HealthColors.secondaryText)
            
            Button("Cancel") {
                dismiss()
            }
            .padding()
        }
    }
}

/// Processing success sheet
struct ProcessingSuccessView: View {
    let summary: LabReportProcessingSummary?
    let biomarkers: [ExtractedBiomarker]
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: HealthSpacing.xl) {
                // Success header
                VStack(spacing: HealthSpacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(HealthColors.healthExcellent)
                        .font(.system(size: 64))
                    
                    Text("Success!")
                        .font(HealthTypography.headingLarge)
                        .foregroundColor(HealthColors.primaryText)
                    
                    if let summary = summary {
                        Text("Processed \(summary.totalBiomarkersExtracted) biomarkers")
                            .font(HealthTypography.bodyRegular)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Action button
                Button(action: onComplete) {
                    Text("Continue")
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(HealthColors.primary)
                        .cornerRadius(HealthCornerRadius.button)
                }
            }
            .padding(HealthSpacing.xl)
            .navigationTitle("Processing Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Processing summary card
struct ProcessingSummaryCard: View {
    let summary: LabReportProcessingSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Processing Summary")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                summaryRow(icon: "timer", title: "Processing Time", value: formatDuration(summary.processingDuration))
                summaryRow(icon: "target", title: "Confidence", value: "\(Int(summary.overallConfidence * 100))%")
                summaryRow(icon: "list.bullet", title: "Biomarkers Found", value: "\(summary.totalBiomarkersExtracted)")
                summaryRow(icon: "checkmark.shield", title: "High Confidence", value: "\(summary.highConfidenceBiomarkers)")
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
    }
    
    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(HealthColors.primary)
                .frame(width: 20)
            
            Text(title)
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.secondaryText)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "N/A" }
        return String(format: "%.1fs", duration)
    }
}

/// Biomarker summary card for grid display
struct BiomarkerSummaryCard: View {
    let biomarker: ExtractedBiomarker
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            HStack {
                Text(biomarker.displayName)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: biomarker.status.icon)
                    .foregroundColor(biomarker.status.color)
                    .font(.caption2)
            }
            
            Text(biomarker.formattedValue)
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primaryText)
            
            if let range = biomarker.referenceRange {
                Text("Ref: \(range)")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
}

/// Biomarker validation row for editing
struct BiomarkerValidationRow: View {
    let biomarker: ExtractedBiomarker
    let onUpdate: (String, String?) -> Void
    let onRemove: () -> Void
    
    @State private var value: String
    @State private var unit: String
    
    init(biomarker: ExtractedBiomarker, onUpdate: @escaping (String, String?) -> Void, onRemove: @escaping () -> Void) {
        self.biomarker = biomarker
        self.onUpdate = onUpdate
        self.onRemove = onRemove
        self._value = State(initialValue: biomarker.value)
        self._unit = State(initialValue: biomarker.unit ?? "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            HStack {
                Text(biomarker.displayName)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                Text("Confidence: \(Int(biomarker.confidence * 100))%")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(biomarker.confidence >= 0.8 ? HealthColors.healthGood : biomarker.confidence >= 0.6 ? HealthColors.healthWarning : HealthColors.healthCritical)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(HealthColors.healthCritical)
                        .font(.caption)
                }
            }
            
            HStack {
                TextField("Value", text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: value) { _, newValue in
                        onUpdate(newValue, unit.isEmpty ? nil : unit)
                    }
                
                TextField("Unit", text: $unit)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 80)
                    .onChange(of: unit) { _, newValue in
                        onUpdate(value, newValue.isEmpty ? nil : newValue)
                    }
            }
            
            if let range = biomarker.referenceRange {
                Text("Reference Range: \(range)")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
    
}
// MARK: - Processing Options View

struct ProcessingOptionsView: View {
    @Binding var preferCloudProcessing: Bool
    @Binding var allowLocalFallback: Bool
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Prefer Cloud Processing", isOn: $preferCloudProcessing)
                    Toggle("Allow Local Fallback", isOn: $allowLocalFallback)
                } header: {
                    Text("OCR Processing")
                } footer: {
                    Text("Cloud processing provides higher accuracy with AI-powered analysis. Local fallback uses on-device Vision framework when cloud is unavailable.")
                }
                
                Section {
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(HealthColors.primary)
                        VStack(alignment: .leading) {
                            Text("Cloud Processing")
                                .font(HealthTypography.bodyMedium)
                            Text("AWS Textract + AI Analysis")
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(HealthColors.secondaryText)
                        }
                        Spacer()
                        Text("95% accuracy")
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.healthGood)
                    }
                    
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(HealthColors.primary)
                        VStack(alignment: .leading) {
                            Text("Local Processing")
                                .font(HealthTypography.bodyMedium)
                            Text("Vision Framework")
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(HealthColors.secondaryText)
                        }
                        Spacer()
                        Text("85% accuracy")
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.healthWarning)
                    }
                } header: {
                    Text("Processing Methods")
                }
            }
            .navigationTitle("Processing Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Upload History View

struct SimpleUploadHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var uploadHistory: [LabReportUploadResult] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading upload history...")
                } else if uploadHistory.isEmpty {
                    ContentUnavailableView(
                        "No Upload History",
                        systemImage: "clock",
                        description: Text("Your uploaded lab reports will appear here")
                    )
                } else {
                    List(uploadHistory) { upload in
                        UploadHistoryRow(upload: upload)
                    }
                }
            }
            .navigationTitle("Upload History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadUploadHistory()
            }
        }
    }
    
    private func loadUploadHistory() async {
        // Load actual upload history from LabReportAPIService when available
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        isLoading = false
    }
}

struct UploadHistoryRow: View {
    let upload: LabReportUploadResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(upload.fileName)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(upload.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: upload.uploadStatus.icon)
                    .foregroundColor(Color(upload.uploadStatus.color))
                
                Text(upload.uploadStatus.displayName)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Document Selection") {
    LabReportUploadView()
}

#Preview("Processing") {
    let viewModel = LabReportViewModel()
    // Configure for processing state
    return LabReportUploadView()
}
