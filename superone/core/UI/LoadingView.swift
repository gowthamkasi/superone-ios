//
//  LoadingView.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Comprehensive loading state components for different scenarios
struct LoadingView: View {
    let message: String
    let showProgress: Bool
    let progress: Double?
    
    init(
        message: String = "Loading...",
        showProgress: Bool = false,
        progress: Double? = nil
    ) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Loading Animation
            if showProgress, let progress = progress {
                CircularProgressView(progress: progress)
            } else {
                SpinningLoaderView()
            }
            
            // Loading Message
            VStack(spacing: HealthSpacing.sm) {
                Text(message)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                
                if showProgress, let progress = progress {
                    Text("\(Int(progress * 100))% Complete")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HealthColors.background)
    }
}

// MARK: - Spinning Loader

struct SpinningLoaderView: View {
    @State private var isRotating = false
    
    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 40, weight: .medium))
            .foregroundColor(HealthColors.primary)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isRotating)
            .onAppear {
                isRotating = true
            }
            .onDisappear {
                isRotating = false
            }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(HealthColors.secondaryBackground, lineWidth: 8)
                .frame(width: 80, height: 80)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [HealthColors.primary, HealthColors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: animatedProgress)
            
            // Progress Text
            Text("\(Int(animatedProgress * 100))%")
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primaryText)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Inline Loading View

struct InlineLoadingView: View {
    let message: String
    let size: LoadingSize
    
    enum LoadingSize {
        case small, medium, large
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }
        
        var font: Font {
            switch self {
            case .small: return HealthTypography.captionRegular
            case .medium: return HealthTypography.body
            case .large: return HealthTypography.bodyMedium
            }
        }
    }
    
    init(message: String = "Loading...", size: LoadingSize = .medium) {
        self.message = message
        self.size = size
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: HealthSpacing.sm) {
            ProgressView()
                .scaleEffect(size == .small ? 0.8 : size == .medium ? 1.0 : 1.2)
                .tint(HealthColors.primary)
            
            Text(message)
                .font(size.font)
                .foregroundColor(HealthColors.secondaryText)
        }
        .opacity(isAnimating ? 1 : 0)
        .scaleEffect(isAnimating ? 1 : 0.8)
        .animation(.easeInOut(duration: 0.3), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Skeleton Loading View

struct SkeletonLoadingView: View {
    let rows: Int
    let showAvatar: Bool
    
    init(rows: Int = 3, showAvatar: Bool = false) {
        self.rows = rows
        self.showAvatar = showAvatar
    }
    
    var body: some View {
        VStack(spacing: HealthSpacing.md) {
            ForEach(0..<rows, id: \.self) { index in
                HStack(spacing: HealthSpacing.md) {
                    if showAvatar && index == 0 {
                        SkeletonShape()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                        SkeletonShape()
                            .frame(height: 16)
                            .frame(maxWidth: index == 0 ? .infinity : .infinity * 0.7)
                        
                        if index < 2 {
                            SkeletonShape()
                                .frame(height: 14)
                                .frame(maxWidth: .infinity * 0.5)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(HealthSpacing.md)
    }
}

struct SkeletonShape: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(HealthColors.secondaryBackground)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                HealthColors.background.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
                    .animation(
                        Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .cornerRadius(8)
            .onAppear {
                isAnimating = true
            }
            .clipped()
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String
    let isVisible: Bool
    
    var body: some View {
        ZStack {
            if isVisible {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: HealthSpacing.lg) {
                    SpinningLoaderView()
                    
                    Text(message)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(HealthSpacing.xl)
                .background(HealthColors.background)
                .cornerRadius(HealthCornerRadius.sheet)
                .healthCardShadow()
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
}

// MARK: - Pull to Refresh Loading

struct PullToRefreshLoadingView: View {
    let isRefreshing: Bool
    
    var body: some View {
        HStack(spacing: HealthSpacing.sm) {
            if isRefreshing {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(HealthColors.primary)
                
                Text("Refreshing...")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.secondaryText)
            }
        }
        .frame(height: isRefreshing ? 40 : 0)
        .opacity(isRefreshing ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
    }
}

// MARK: - Step Progress Loading

struct StepProgressLoadingView: View {
    let steps: [String]
    let currentStep: Int
    
    var body: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Progress Indicator
            HStack(spacing: HealthSpacing.sm) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? HealthColors.primary : HealthColors.secondaryBackground)
                        .frame(width: 12, height: 12)
                        .scaleEffect(index == currentStep ? 1.2 : 1.0)
                        .animation(.spring(duration: 0.3, bounce: 0.4), value: currentStep)
                    
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? HealthColors.primary : HealthColors.secondaryBackground)
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
            }
            
            // Current Step Text
            if currentStep < steps.count {
                Text(steps[currentStep])
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .id("step-\(currentStep)")
            }
        }
        .padding(HealthSpacing.lg)
    }
}

// MARK: - View Extensions

extension View {
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        self.overlay(
            LoadingOverlay(message: message, isVisible: isLoading)
        )
    }
}

// MARK: - Preview

#Preview("Loading View") {
    LoadingView(message: "Processing your health data...")
}

#Preview("Progress Loading") {
    LoadingView(
        message: "Analyzing lab report...",
        showProgress: true,
        progress: 0.65
    )
}

#Preview("Inline Loading") {
    VStack(spacing: HealthSpacing.lg) {
        InlineLoadingView(message: "Syncing data...", size: .small)
        InlineLoadingView(message: "Loading appointments...", size: .medium)
        InlineLoadingView(message: "Processing upload...", size: .large)
    }
    .padding()
}

#Preview("Skeleton Loading") {
    SkeletonLoadingView(rows: 4, showAvatar: true)
}

#Preview("Step Progress") {
    StepProgressLoadingView(
        steps: ["Upload", "OCR", "Extract", "Analyze", "Complete"],
        currentStep: 2
    )
}