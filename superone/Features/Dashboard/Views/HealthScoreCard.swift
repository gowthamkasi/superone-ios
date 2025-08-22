import SwiftUI

/// Animated health score card with smooth progress indicators and trend visualization
/// Uses simple state-based animations that play once on appearance
struct HealthScoreCard: View {
    let healthScore: HealthScore
    let onTap: () -> Void
    
    @State private var hasAppeared = false
    @State private var showCard = false
    @State private var showProgress = false
    @State private var showDetails = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HealthSpacing.lg) {
                // Header with simple animation
                HStack {
                    Text("Overall Health Score")
                        .font(HealthTypography.headline)
                        .foregroundColor(HealthColors.secondaryText)
                        .opacity(showCard ? 1 : 0)
                        .offset(y: showCard ? 0 : -10)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: showCard)
                    
                    Spacer()
                    
                    // Trend indicator
                    HStack(spacing: HealthSpacing.xs) {
                        Image(systemName: healthScore.trend.systemImage)
                            .font(.system(size: 12))
                            .foregroundColor(healthScore.trend.color)
                        
                        Text(healthScore.trend.displayText)
                            .font(HealthTypography.caption1)
                            .foregroundColor(healthScore.trend.color)
                    }
                    .opacity(showDetails ? 1 : 0)
                    .scaleEffect(showDetails ? 1.0 : 0.8)
                    .animation(.spring(duration: 0.5, bounce: 0.2).delay(1.0), value: showDetails)
                }
            
                // Animated circular progress indicator
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(HealthColors.accent.opacity(0.3), lineWidth: 8)
                        .frame(width: HealthSpacing.healthScoreSize, height: HealthSpacing.healthScoreSize)
                        .scaleEffect(showCard ? 1.0 : 0.8)
                        .opacity(showCard ? 1.0 : 0.0)
                        .animation(.spring(duration: 0.4, bounce: 0.2).delay(0.1), value: showCard)
                    
                    // Animated progress circle
                    Circle()
                        .trim(from: 0, to: showProgress ? healthScore.normalizedProgress : 0)
                        .stroke(
                            AngularGradient(
                                colors: gradientColors,
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: HealthSpacing.healthScoreSize, height: HealthSpacing.healthScoreSize)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.2).delay(0.3), value: showProgress)
                    
                    // Score value with animated counting
                    VStack(spacing: HealthSpacing.xs) {
                        SimpleAnimatedScoreText(
                            score: healthScore.value,
                            isVisible: showProgress
                        )
                        
                        Text("%")
                            .font(HealthTypography.headline)
                            .foregroundColor(HealthColors.secondaryText)
                            .opacity(showProgress ? 1 : 0)
                            .scaleEffect(showProgress ? 1.0 : 0.5)
                            .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.8), value: showProgress)
                    }
                }
            
                // Status text with simple animation
                VStack(spacing: HealthSpacing.xs) {
                    Text(healthScore.statusDisplayText)
                        .font(HealthTypography.subheadline)
                        .foregroundColor(HealthColors.statusColor(for: healthScore.status))
                        .multilineTextAlignment(.center)
                        .opacity(showDetails ? 1 : 0)
                        .offset(y: showDetails ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(1.0), value: showDetails)
                    
                    Text("Last updated: \(formattedUpdateTime)")
                        .font(HealthTypography.caption2)
                        .foregroundColor(HealthColors.tertiaryText)
                        .opacity(showDetails ? 0.8 : 0)
                        .scaleEffect(showDetails ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 0.3).delay(1.2), value: showDetails)
                }
            }
            .padding(HealthSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                    .fill(Color(.secondarySystemBackground))
                    .healthCardShadow()
            )
            .scaleEffect(showCard ? 1.0 : 0.95)
            .opacity(showCard ? 1.0 : 0.0)
            .animation(.spring(duration: 0.4, bounce: 0.2).delay(0.1), value: showCard)
        }
        .buttonStyle(HealthScoreCardButtonStyle())
        .onAppear {
            // Only animate once when the view first appears
            if !hasAppeared {
                hasAppeared = true
                startSimpleAnimation()
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var gradientColors: [Color] {
        switch healthScore.status {
        case .excellent:
            return [HealthColors.healthExcellent, HealthColors.healthGood]
        case .good:
            return [HealthColors.healthGood, HealthColors.healthNormal]
        case .normal:
            return [HealthColors.healthNormal, HealthColors.primary]
        case .monitor:
            return [HealthColors.healthWarning, HealthColors.healthNormal]
        case .needsAttention:
            return [HealthColors.healthCritical, HealthColors.healthWarning]
        @unknown default:
            return [HealthColors.primary, HealthColors.secondary]
        }
    }
    
    private var formattedUpdateTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: healthScore.lastUpdated, relativeTo: Date())
    }
    
    // MARK: - Private Methods
    
    private func startSimpleAnimation() {
        // Animate elements sequentially, only once
        showCard = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showProgress = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showDetails = true
        }
    }
}

// MARK: - Simple Animated Score Text (No Looping)
struct SimpleAnimatedScoreText: View {
    let score: Int
    let isVisible: Bool
    
    @State private var animatableScore: Double = 0
    
    var body: some View {
        Text("\(Int(animatableScore))")
            .font(HealthTypography.healthScoreDisplay)
            .fontWeight(.bold)
            .foregroundColor(HealthColors.primary)
            .monospacedDigit()
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1.0 : 0.5)
            .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.5), value: isVisible)
            .onChange(of: isVisible) { oldValue, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        animatableScore = Double(score)
                    }
                }
            }
    }
}


// MARK: - iOS 18+ Enhanced Health Score Button Style
struct HealthScoreCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(duration: 0.4, bounce: 0.3), value: configuration.isPressed)
            .background(
                // iOS 18+ enhanced interaction area
                RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                    .fill(Color.clear)
                    .contentShape(Rectangle())
            )
            .simultaneousGesture(
                // iOS 18+ advanced gesture with haptic feedback
                TapGesture()
                    .onEnded { _ in
                        HapticFeedback.success()
                    }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Tap to view detailed health analysis")
    }
}

// MARK: - Preview
#Preview("Default Score") {
    HealthScoreCard(healthScore: HealthScore(value: 78, trend: .stable)) {
    }
    .padding()
    .background(HealthColors.background)
}

#Preview("Excellent Score") {
    HealthScoreCard(healthScore: HealthScore(value: 92, trend: .improving)) {
    }
    .padding()
    .background(HealthColors.background)
}

#Preview("Warning Score") {
    HealthScoreCard(healthScore: HealthScore(value: 65, trend: .declining)) {
    }
    .padding()
    .background(HealthColors.background)
}