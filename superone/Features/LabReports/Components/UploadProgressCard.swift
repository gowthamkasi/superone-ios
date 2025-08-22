//
//  UploadProgressCard.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI

/// Card component showing upload progress with detailed metrics
struct UploadProgressCard: View {
    let fileName: String
    let progress: Double
    let currentOperation: String
    let uploadSpeed: String
    let estimatedTimeRemaining: String
    
    var body: some View {
        VStack(spacing: HealthSpacing.lg) {
            // File info header
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(HealthColors.primary)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileName)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(1)
                    
                    Text(currentOperation)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primary)
            }
            
            // Progress bar
            VStack(spacing: HealthSpacing.sm) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(HealthColors.secondaryBackground)
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        // Progress fill
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [HealthColors.primary, HealthColors.healthGood],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                            .cornerRadius(4)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 8)
                
                // Progress metrics
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                            .foregroundColor(HealthColors.primary)
                            .font(.system(size: 12))
                        Text(uploadSpeed)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(HealthColors.primary)
                            .font(.system(size: 12))
                        Text(estimatedTimeRemaining)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.primaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                .stroke(HealthColors.border, lineWidth: 1)
        )
        .cornerRadius(HealthCornerRadius.lg)
    }
}

// MARK: - Processing Stage Card

struct ProcessingStageCard: View {
    let stage: ProcessingWorkflowStep
    let isActive: Bool
    let description: String
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            // Stage icon
            ZStack {
                Circle()
                    .fill(isActive ? HealthColors.primary : HealthColors.secondaryBackground)
                    .frame(width: 48, height: 48)
                
                Image(systemName: stage.icon)
                    .foregroundColor(isActive ? .white : HealthColors.secondaryText)
                    .font(.system(size: 20))
            }
            
            // Stage info
            VStack(alignment: .leading, spacing: 4) {
                Text(stage.displayName)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(description)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.primaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                .stroke(isActive ? HealthColors.primary : HealthColors.border, lineWidth: isActive ? 2 : 1)
        )
        .cornerRadius(HealthCornerRadius.lg)
    }
}

// MARK: - Animated Processing Indicator

struct AnimatedProcessingIndicator: View {
    let title: String
    let subtitle: String
    let progress: Double
    
    @State private var animationRotation: Double = 0
    @State private var pulseScale: Double = 1.0
    
    var body: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Animated processing icon
            ZStack {
                // Outer pulse ring
                Circle()
                    .stroke(HealthColors.primary.opacity(0.3), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - pulseScale)
                
                // Inner rotating ring
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        AngularGradient(
                            colors: [HealthColors.primary, HealthColors.primary.opacity(0.3)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(animationRotation))
                
                // Center icon
                Image(systemName: "brain.head.profile")
                    .foregroundColor(HealthColors.primary)
                    .font(.system(size: 24))
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    animationRotation = 360
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.2
                }
            }
            
            // Text content
            VStack(spacing: HealthSpacing.sm) {
                Text(title)
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(subtitle)
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                
                if progress > 0 {
                    Text("\(Int(progress * 100))% complete")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Upload Progress") {
    VStack(spacing: 20) {
        UploadProgressCard(
            fileName: "lab_results_2024.pdf",
            progress: 0.65,
            currentOperation: "Uploading to secure cloud servers",
            uploadSpeed: "2.1 MB/s",
            estimatedTimeRemaining: "15s remaining"
        )
        
        ProcessingStageCard(
            stage: .ocrProcessing,
            isActive: true,
            description: "Extracting text and data from your lab report using advanced AI"
        )
        
        AnimatedProcessingIndicator(
            title: "AI Analysis",
            subtitle: "Generating health insights",
            progress: 0.75
        )
    }
    .padding()
    .background(HealthColors.secondaryBackground)
}