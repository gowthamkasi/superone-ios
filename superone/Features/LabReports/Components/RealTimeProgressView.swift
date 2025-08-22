//
//  RealTimeProgressView.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI
import Combine

/// Enhanced progress view with real-time backend status updates
struct RealTimeProgressView: View {
    
    // MARK: - Properties
    
    let labReportId: String
    let initialProgress: Double
    let onCancel: (() -> Void)?
    let onComplete: ((LabReportProcessingStatus) -> Void)?
    
    @State private var currentStatus: LabReportProcessingStatus?
    @State private var uploadProgress: Double = 0.0
    @State private var isMonitoring = false
    @State private var statusError: Error?
    @State private var animationAmount: Double = 1.0
    @State private var pulseScale: Double = 1.0
    
    @StateObject private var uploadStatusService = UploadStatusService.shared
    
    // Real-time status monitoring
    
    private var statusColor: Color {
        guard let status = currentStatus?.status else { return Color.gray }
        switch status {
        case .uploading, .processing, .analyzing: return HealthColors.primary
        case .completed: return HealthColors.healthGood
        case .failed: return HealthColors.healthCritical
        case .cancelled: return HealthColors.secondaryText
        }
    }
    @State private var statusCancellable: AnyCancellable?
    
    // MARK: - Initialization
    
    init(
        labReportId: String,
        initialProgress: Double = 0.0,
        onCancel: (() -> Void)? = nil,
        onComplete: ((LabReportProcessingStatus) -> Void)? = nil
    ) {
        self.labReportId = labReportId
        self.initialProgress = initialProgress
        self.onCancel = onCancel
        self.onComplete = onComplete
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Current status header
            statusHeader
            
            // Main progress visualization
            progressVisualization
            
            // Processing stages timeline
            processingTimeline
            
            // Status details
            statusDetails
            
            // Actions
            actionButtons
        }
        .padding(HealthSpacing.xl)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.lg)
        .healthCardShadow()
        .onAppear {
            startStatusMonitoring()
            startAnimations()
        }
        .onDisappear {
            stopStatusMonitoring()
        }
    }
    
    // MARK: - Status Header
    
    private var statusHeader: some View {
        VStack(spacing: HealthSpacing.sm) {
            HStack {
                // Status icon with animation
                ZStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 40, height: 40)
                        .scaleEffect(pulseScale)
                        .opacity(isMonitoring ? 1.0 : 0.7)
                    
                    Image(systemName: currentStatus?.currentStage.icon ?? "hourglass")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                        .scaleEffect(animationAmount)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentStatus?.currentStage.displayName ?? "Initializing")
                        .font(HealthTypography.headingMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text(currentStatus?.status.description ?? "Preparing for processing")
                        .font(HealthTypography.bodyRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                Spacer()
                
                // Real-time indicator
                if isMonitoring {
                    LiveIndicator()
                }
            }
            
            // Error message if any
            if let error = statusError {
                ErrorBanner(error: error) {
                    retryStatusMonitoring()
                }
            }
        }
    }
    
    // MARK: - Progress Visualization
    
    private var progressVisualization: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Circular progress with real-time updates
            ZStack {
                // Background circle
                Circle()
                    .stroke(HealthColors.secondaryBackground, lineWidth: 10)
                    .frame(width: 140, height: 140)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: currentProgress)
                    .stroke(
                        AngularGradient(
                            colors: progressGradientColors,
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 140, height: 140)
                    .animation(.easeInOut(duration: 0.8), value: currentProgress)
                
                // Center content
                VStack(spacing: 4) {
                    Text("\(Int(currentProgress * 100))%")
                        .font(HealthTypography.headingLarge)
                        .foregroundColor(HealthColors.primaryText)
                        .bold()
                    
                    Text("Complete")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            // Linear progress with stage breakdown
            progressBreakdown
        }
    }
    
    private var progressBreakdown: some View {
        VStack(spacing: HealthSpacing.sm) {
            HStack {
                Text("Overall Progress")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.secondaryText)
                
                Spacer()
                
                if let timeRemaining = currentStatus?.estimatedTimeRemaining {
                    Text(formatTimeRemaining(timeRemaining))
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                }
            }
            
            // Multi-segment progress bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(ProcessingStage.allCases, id: \.self) { stage in
                        Rectangle()
                            .fill(stageProgressColor(stage))
                            .frame(height: 6)
                            .cornerRadius(3)
                    }
                }
            }
            .frame(height: 6)
        }
    }
    
    // MARK: - Processing Timeline
    
    private var processingTimeline: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Processing Timeline")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HealthSpacing.lg) {
                    ForEach(ProcessingStage.allCases, id: \.self) { stage in
                        TimelineStageCard(
                            stage: stage,
                            currentStage: currentStatus?.currentStage ?? .uploaded,
                            isActive: stage == currentStatus?.currentStage,
                            isCompleted: stage.progressPercentage <= (currentStatus?.progress ?? 0.0)
                        )
                    }
                }
                .padding(.horizontal, HealthSpacing.sm)
            }
        }
    }
    
    // MARK: - Status Details
    
    private var statusDetails: some View {
        VStack(spacing: HealthSpacing.md) {
            if let status = currentStatus {
                ProgressDetailRow(
                    icon: "doc.text",
                    title: "Document",
                    value: status.fileName
                )
                
                ProgressDetailRow(
                    icon: "clock",
                    title: "Started",
                    value: formatTimestamp(status.createdAt)
                )
                
                if let ocrResult = status.ocrResult {
                    ProgressDetailRow(
                        icon: "textformat",
                        title: "OCR Method",
                        value: ocrResult.method.displayName
                    )
                    
                    ProgressDetailRow(
                        icon: "checkmark.seal",
                        title: "OCR Confidence",
                        value: "\(Int(ocrResult.confidence * 100))%"
                    )
                }
                
                if let analysisResult = status.analysisResult {
                    ProgressDetailRow(
                        icon: "brain.head.profile",
                        title: "Health Score",
                        value: "\(analysisResult.overallHealthScore)/100"
                    )
                }
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: HealthSpacing.md) {
            if let onCancel = onCancel, isMonitoring {
                Button("Cancel") {
                    stopStatusMonitoring()
                    onCancel()
                }
                .buttonStyle(HealthSecondaryButtonStyle())
                .disabled(!isMonitoring)
            }
            
            if currentStatus?.status == .failed {
                Button("Retry") {
                    retryStatusMonitoring()
                }
                .buttonStyle(HealthPrimaryButtonStyle())
            }
            
            if currentStatus?.status == .completed {
                Button("View Results") {
                    if let status = currentStatus {
                        onComplete?(status)
                    }
                }
                .buttonStyle(HealthPrimaryButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var currentProgress: Double {
        return currentStatus?.progress ?? initialProgress
    }
    
    private var progressGradientColors: [Color] {
        guard let status = currentStatus?.status else {
            return [HealthColors.primary, HealthColors.secondary]
        }
        
        switch status {
        case .uploading, .processing:
            return [HealthColors.primary, HealthColors.secondary]
        case .analyzing:
            return [HealthColors.healthGood, HealthColors.primary]
        case .completed:
            return [HealthColors.healthGood, HealthColors.healthExcellent]
        case .failed:
            return [HealthColors.healthCritical, HealthColors.healthWarning]
        case .cancelled:
            return [HealthColors.healthNeutral, HealthColors.secondaryText]
        }
    }
    
    private func stageProgressColor(_ stage: ProcessingStage) -> Color {
        guard let currentStage = currentStatus?.currentStage,
              let progress = currentStatus?.progress else {
            return HealthColors.secondaryBackground
        }
        
        if stage.progressPercentage <= progress {
            return HealthColors.healthGood
        } else if stage == currentStage {
            return HealthColors.primary
        } else {
            return HealthColors.secondaryBackground
        }
    }
    
    // MARK: - Status Monitoring
    
    private func startStatusMonitoring() {
        isMonitoring = true
        
        let statusStream = uploadStatusService.startMonitoring(labReportId)
        
        statusCancellable = AsyncPublisher(statusStream)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isMonitoring = false
                    if case .failure(let error) = completion {
                        statusError = error
                    }
                },
                receiveValue: { status in
                    currentStatus = status
                    
                    if status.status == .completed || status.status == .failed {
                        isMonitoring = false
                        onComplete?(status)
                    }
                }
            )
    }
    
    private func stopStatusMonitoring() {
        isMonitoring = false
        statusCancellable?.cancel()
        uploadStatusService.stopMonitoring(labReportId)
    }
    
    private func retryStatusMonitoring() {
        statusError = nil
        startStatusMonitoring()
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            animationAmount = 1.2
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func formatTimeRemaining(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s remaining"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s remaining"
        }
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        guard let date = timestamp.iso8601Date else {
            return timestamp
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct LiveIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("LIVE")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.red)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct ErrorBanner: View {
    let error: Error
    let onRetry: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(HealthColors.healthCritical)
            
            Text(error.localizedDescription)
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
            
            Button("Retry") {
                onRetry()
            }
            .font(HealthTypography.captionMedium)
            .foregroundColor(HealthColors.primary)
        }
        .padding(HealthSpacing.sm)
        .background(HealthColors.healthCritical.opacity(0.1))
        .cornerRadius(HealthCornerRadius.sm)
    }
}

struct TimelineStageCard: View {
    let stage: ProcessingStage
    let currentStage: ProcessingStage
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: HealthSpacing.sm) {
            // Stage indicator
            ZStack {
                Circle()
                    .fill(stageColor)
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                } else {
                    Image(systemName: stage.icon)
                        .foregroundColor(isActive ? .white : HealthColors.secondaryText)
                        .font(.system(size: 16))
                }
            }
            
            // Stage name
            Text(stage.displayName)
                .font(HealthTypography.captionMedium)
                .foregroundColor(isActive ? HealthColors.primary : HealthColors.secondaryText)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
    
    private var stageColor: Color {
        if isCompleted {
            return HealthColors.healthGood
        } else if isActive {
            return HealthColors.primary
        } else {
            return HealthColors.secondaryBackground
        }
    }
}

struct ProgressDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(HealthColors.primary)
                .frame(width: 20)
            
            Text(title)
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.primaryText)
        }
    }
}

// MARK: - AsyncPublisher Helper

struct AsyncPublisher<T>: Publisher {
    typealias Output = T
    typealias Failure = Error
    
    private let stream: AsyncThrowingStream<T, Error>
    
    init(_ stream: AsyncThrowingStream<T, Error>) {
        self.stream = stream
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, T == S.Input {
        let subscription = AsyncSubscription(stream: stream, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

private class AsyncSubscription<T, S: Subscriber>: Subscription where S.Input == T, S.Failure == Error {
    private let stream: AsyncThrowingStream<T, Error>
    private let subscriber: S
    private var task: Task<Void, Never>?
    
    init(stream: AsyncThrowingStream<T, Error>, subscriber: S) {
        self.stream = stream
        self.subscriber = subscriber
    }
    
    func request(_ demand: Subscribers.Demand) {
        task = Task {
            do {
                for try await value in stream {
                    _ = subscriber.receive(value)
                }
                subscriber.receive(completion: .finished)
            } catch {
                subscriber.receive(completion: .failure(error))
            }
        }
    }
    
    func cancel() {
        task?.cancel()
    }
}

// MARK: - Preview

#Preview {
    RealTimeProgressView(
        labReportId: "sample-id",
        initialProgress: 0.4
    ) {
    } onComplete: { status in
    }
    .padding()
    .background(HealthColors.secondaryBackground)
}

// MARK: - String Extensions

