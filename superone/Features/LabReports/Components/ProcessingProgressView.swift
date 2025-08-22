//
//  ProcessingProgressView.swift
//  SuperOne
//
//  Created by Claude Code on 7/27/25.
//

import SwiftUI

/// Reusable component for displaying OCR and biomarker extraction progress
struct ProcessingProgressView: View {
    
    // MARK: - Properties
    
    let progress: Double
    let currentOperation: String
    let currentStep: ProcessingWorkflowStep
    let isProcessing: Bool
    let onCancel: (() -> Void)?
    
    @State private var animationAmount: Double = 1.0
    
    // MARK: - Initialization
    
    init(
        progress: Double,
        currentOperation: String,
        currentStep: ProcessingWorkflowStep,
        isProcessing: Bool = true,
        onCancel: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.currentOperation = currentOperation
        self.currentStep = currentStep
        self.isProcessing = isProcessing
        self.onCancel = onCancel
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Header with step information
            stepHeader
            
            // Main progress section
            progressSection
            
            // Current operation details
            operationDetails
            
            // Processing steps overview
            stepsOverview
            
            // Cancel button
            if let onCancel = onCancel, isProcessing {
                cancelButton(action: onCancel)
            }
        }
        .padding(HealthSpacing.xl)
        .background(HealthColors.background)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
        .onAppear {
            startPulseAnimation()
        }
    }
    
    // MARK: - Step Header
    
    private var stepHeader: some View {
        VStack(spacing: HealthSpacing.sm) {
            HStack {
                Image(systemName: currentStep.icon)
                    .foregroundColor(HealthColors.primary)
                    .font(.title2)
                    .scaleEffect(animationAmount)
                
                Text(currentStep.displayName)
                    .font(HealthTypography.headingMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                Text("Step \(currentStep.stepNumber) of 5")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .padding(.horizontal, HealthSpacing.sm)
                    .padding(.vertical, 4)
                    .background(HealthColors.secondaryBackground)
                    .cornerRadius(HealthCornerRadius.md)
            }
            
            if isProcessing {
                Text("Processing your lab report...")
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: HealthSpacing.md) {
            // Circular progress indicator
            ZStack {
                // Background circle
                Circle()
                    .stroke(HealthColors.secondaryBackground, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                HealthColors.primary,
                                HealthColors.secondary
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                // Progress percentage
                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(HealthTypography.headingLarge)
                        .foregroundColor(HealthColors.primaryText)
                        .bold()
                    
                    if isProcessing {
                        Text("Complete")
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
            }
            
            // Linear progress bar for detailed progress
            VStack(spacing: HealthSpacing.sm) {
                HStack {
                    Text("Overall Progress")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: HealthColors.primary))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
    }
    
    // MARK: - Operation Details
    
    private var operationDetails: some View {
        VStack(spacing: HealthSpacing.sm) {
            if !currentOperation.isEmpty {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: HealthColors.primary))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(HealthColors.healthGood)
                    }
                    
                    Text(currentOperation)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, HealthSpacing.lg)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.secondaryBackground)
                .cornerRadius(HealthCornerRadius.md)
            }
        }
    }
    
    // MARK: - Steps Overview
    
    private var stepsOverview: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            Text("Processing Steps")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                ForEach(ProcessingWorkflowStep.allCases, id: \.self) { step in
                    stepRow(for: step)
                }
            }
        }
    }
    
    private func stepRow(for step: ProcessingWorkflowStep) -> some View {
        HStack(spacing: HealthSpacing.sm) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(stepBackgroundColor(for: step))
                    .frame(width: 24, height: 24)
                
                if step.stepNumber < currentStep.stepNumber {
                    // Completed step
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.caption)
                        .bold()
                } else if step == currentStep {
                    // Current step
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.6)
                    } else {
                        Text("\(step.stepNumber)")
                            .foregroundColor(.white)
                            .font(.caption)
                            .bold()
                    }
                } else {
                    // Future step
                    Text("\(step.stepNumber)")
                        .foregroundColor(HealthColors.secondaryText)
                        .font(.caption)
                }
            }
            
            // Step name
            Text(step.displayName)
                .font(HealthTypography.captionMedium)
                .foregroundColor(stepTextColor(for: step))
            
            Spacer()
            
            // Step icon
            Image(systemName: step.icon)
                .foregroundColor(stepIconColor(for: step))
                .font(.caption)
        }
    }
    
    // MARK: - Cancel Button
    
    private func cancelButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "xmark.circle")
                Text("Cancel Processing")
            }
            .font(HealthTypography.bodyMedium)
            .foregroundColor(HealthColors.healthCritical)
            .padding(.horizontal, HealthSpacing.lg)
            .padding(.vertical, HealthSpacing.sm)
            .background(HealthColors.healthCritical.opacity(0.1))
            .cornerRadius(HealthCornerRadius.md)
        }
    }
    
    // MARK: - Helper Methods
    
    private func stepBackgroundColor(for step: ProcessingWorkflowStep) -> Color {
        if step.stepNumber < currentStep.stepNumber {
            return HealthColors.healthGood
        } else if step == currentStep {
            return HealthColors.primary
        } else {
            return HealthColors.secondaryBackground
        }
    }
    
    private func stepTextColor(for step: ProcessingWorkflowStep) -> Color {
        if step.stepNumber <= currentStep.stepNumber {
            return HealthColors.primaryText
        } else {
            return HealthColors.secondaryText
        }
    }
    
    private func stepIconColor(for step: ProcessingWorkflowStep) -> Color {
        if step.stepNumber < currentStep.stepNumber {
            return HealthColors.healthGood
        } else if step == currentStep {
            return HealthColors.primary
        } else {
            return HealthColors.secondaryText
        }
    }
    
    private func startPulseAnimation() {
        guard isProcessing else { return }
        
        withAnimation(
            Animation
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
        ) {
            animationAmount = 1.2
        }
    }
}

// MARK: - Specialized Progress Views

/// Processing progress view for OCR operations
struct OCRProgressView: View {
    let progress: Double
    let currentOperation: String
    let onCancel: (() -> Void)?
    
    var body: some View {
        ProcessingProgressView(
            progress: progress,
            currentOperation: currentOperation,
            currentStep: ProcessingWorkflowStep.ocrProcessing,
            isProcessing: progress < 1.0,
            onCancel: onCancel
        )
    }
}

/// Processing progress view for biomarker extraction
struct BiomarkerExtractionProgressView: View {
    let progress: Double
    let extractedCount: Int
    let totalExpected: Int?
    let onCancel: (() -> Void)?
    
    private var operationText: String {
        if let total = totalExpected {
            return "Extracted \(extractedCount) of \(total) biomarkers"
        } else {
            return "Extracted \(extractedCount) biomarkers"
        }
    }
    
    var body: some View {
        ProcessingProgressView(
            progress: progress,
            currentOperation: operationText,
            currentStep: ProcessingWorkflowStep.reviewResults,
            isProcessing: progress < 1.0,
            onCancel: onCancel
        )
    }
}

// MARK: - Preview

#Preview("OCR Processing") {
    OCRProgressView(
        progress: 0.65,
        currentOperation: "Extracting text from document",
        onCancel: {}
    )
    .padding()
}

#Preview("Biomarker Extraction") {
    BiomarkerExtractionProgressView(
        progress: 0.8,
        extractedCount: 12,
        totalExpected: 15,
        onCancel: {}
    )
    .padding()
}

#Preview("Complete Processing") {
    ProcessingProgressView(
        progress: 1.0,
        currentOperation: "Processing complete",
        currentStep: ProcessingWorkflowStep.complete,
        isProcessing: false
    )
    .padding()
}