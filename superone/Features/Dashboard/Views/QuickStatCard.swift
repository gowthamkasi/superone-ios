import SwiftUI

/// Dynamic quick stat card with real-time data binding and interactive animations
struct QuickStatCard: View {
    let quickStat: QuickStat
    let onTap: () -> Void
    
    @State private var isVisible: Bool = false
    @State private var pulseAnimation: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HealthSpacing.sm) {
                // Icon and badge row
                HStack {
                    ZStack {
                        // Icon with themed background
                        Circle()
                            .fill(iconBackgroundColor.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .scaleEffect(isVisible ? 1.0 : 0.8)
                            .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.2), value: isVisible)
                        
                        Image(systemName: quickStat.icon)
                            .font(.system(size: HealthSpacing.iconSize))
                            .foregroundColor(iconColor)
                            .scaleEffect(isVisible ? 1.0 : 0.8)
                            .animation(.spring(duration: 0.6, bounce: 0.4).delay(0.3), value: isVisible)
                    }
                    
                    Spacer()
                    
                    // Animated badge
                    if let badge = quickStat.badge {
                        BadgeView(count: badge, shouldPulse: shouldPulseBadge)
                            .opacity(isVisible ? 1 : 0)
                            .scaleEffect(isVisible ? 1.0 : 0.5)
                            .animation(.spring(duration: 0.4, bounce: 0.5).delay(0.4), value: isVisible)
                    }
                }
                
                // Value with animated counting
                AnimatedValueText(
                    value: quickStat.value,
                    isVisible: isVisible
                )
                .padding(.vertical, HealthSpacing.xs)
                
                // Title
                Text(quickStat.title)
                    .font(HealthTypography.caption1)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 10)
                    .animation(.easeInOut(duration: 0.4).delay(0.5), value: isVisible)
            }
            .padding(HealthSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                    .fill(cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .healthCardShadow()
            )
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .animation(.spring(duration: 0.6, bounce: 0.2).delay(cardAnimationDelay), value: isVisible)
        }
        .buttonStyle(QuickStatCardButtonStyle())
        .simultaneousGesture(
            // iOS 18+ Long Press Gesture for additional actions
            LongPressGesture(minimumDuration: 0.8)
                .onEnded { _ in
                    HapticFeedback.heavy()
                    // Could trigger context menu or additional actions
                }
        )
        .onAppear {
            withAnimation {
                isVisible = true
            }
            
            // Start badge pulse animation for alerts
            if shouldPulseBadge {
                startPulseAnimation()
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var iconColor: Color {
        switch quickStat.type {
        case .reports:
            return HealthColors.primary
        case .recommendations:
            return HealthColors.healthGood
        case .alerts:
            return quickStat.badge != nil && quickStat.badge! > 0 ? HealthColors.healthWarning : HealthColors.primary
        case .appointments:
            return HealthColors.secondary
        }
    }
    
    private var iconBackgroundColor: Color {
        return iconColor
    }
    
    private var cardBackgroundColor: Color {
        switch quickStat.type {
        case .alerts where quickStat.badge != nil && quickStat.badge! > 0:
            return HealthColors.healthWarning.opacity(0.05)
        case .recommendations where quickStat.badge != nil && quickStat.badge! > 0:
            return HealthColors.healthGood.opacity(0.05)
        default:
            return Color(.secondarySystemBackground)
        }
    }
    
    private var borderColor: Color {
        switch quickStat.type {
        case .alerts where quickStat.badge != nil && quickStat.badge! > 0:
            return HealthColors.healthWarning.opacity(0.2)
        case .recommendations where quickStat.badge != nil && quickStat.badge! > 0:
            return HealthColors.healthGood.opacity(0.2)
        default:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        return (quickStat.badge != nil && quickStat.badge! > 0) ? 1 : 0
    }
    
    private var shouldPulseBadge: Bool {
        return quickStat.type == .alerts && quickStat.badge != nil && quickStat.badge! > 0
    }
    
    private var cardAnimationDelay: Double {
        // Stagger card animations based on type
        switch quickStat.type {
        case .reports: return 0.1
        case .recommendations: return 0.2
        case .alerts: return 0.3
        case .appointments: return 0.4
        }
    }
    
    // MARK: - Private Methods
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            pulseAnimation = true
        }
    }
}

// MARK: - Animated Value Text
struct AnimatedValueText: View {
    let value: String
    let isVisible: Bool
    
    @State private var displayedValue: String = "0"
    @State private var animatableValue: Double = 0
    
    var body: some View {
        Text(displayedValue)
            .font(HealthTypography.title2)
            .fontWeight(.bold)
            .foregroundColor(HealthColors.primaryText)
            .monospacedDigit()
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.6), value: isVisible)
            .onChange(of: value) { oldValue, newValue in
                if let numericValue = Double(newValue) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        animatableValue = numericValue
                    }
                } else {
                    displayedValue = newValue
                }
            }
            .onChange(of: animatableValue) { _, newValue in
                displayedValue = "\(Int(newValue))"
            }
            .onAppear {
                if isVisible {
                    if let numericValue = Double(value) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            animatableValue = numericValue
                        }
                    } else {
                        displayedValue = value
                    }
                }
            }
    }
    
}

// MARK: - Badge View
struct BadgeView: View {
    let count: Int
    let shouldPulse: Bool
    
    @State private var pulsing: Bool = false
    
    var body: some View {
        Text("\(count)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(minWidth: 20, minHeight: 20)
            .background(
                Circle()
                    .fill(badgeColor)
                    .scaleEffect(shouldPulse && pulsing ? 1.1 : 1.0)
                    .animation(
                        shouldPulse ? 
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : 
                        .none,
                        value: pulsing
                    )
            )
            .onAppear {
                if shouldPulse {
                    pulsing = true
                }
            }
    }
    
    private var badgeColor: Color {
        switch count {
        case 0:
            return HealthColors.healthNeutral
        case 1:
            return HealthColors.healthWarning
        default:
            return HealthColors.healthCritical
        }
    }
}

// MARK: - iOS 18+ Enhanced Button Style with Advanced Gestures
struct QuickStatCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: configuration.isPressed)
            .background(
                // iOS 18+ enhanced tap area for better accessibility
                RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                    .fill(Color.clear)
                    .contentShape(Rectangle())
            )
            .onTapGesture {
                // iOS 18+ haptic feedback integration
                HapticFeedback.medium()
            }
            .accessibilityAddTraits(.isButton)
    }
}


// MARK: - Preview
#Preview("Default Stats") {
    let sampleStats = [
        QuickStat(icon: "doc.text", title: "Recent Tests", value: "5", badge: nil, type: .reports),
        QuickStat(icon: "lightbulb", title: "Recommendations", value: "3", badge: 1, type: .recommendations),
        QuickStat(icon: "exclamationmark.triangle", title: "Health Alerts", value: "2", badge: 2, type: .alerts),
        QuickStat(icon: "calendar", title: "Appointments", value: "1", badge: nil, type: .appointments)
    ]
    
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: HealthSpacing.md) {
        ForEach(sampleStats) { stat in
            QuickStatCard(quickStat: stat) {
            }
        }
    }
    .padding()
    .background(HealthColors.background)
}

#Preview("Alert Card") {
    QuickStatCard(
        quickStat: QuickStat(
            icon: "exclamationmark.triangle",
            title: "Health Alerts",
            value: "3",
            badge: 3,
            type: .alerts
        )
    ) {
    }
    .padding()
    .background(HealthColors.background)
}

#Preview("Recommendation Card") {
    QuickStatCard(
        quickStat: QuickStat(
            icon: "lightbulb",
            title: "New Recommendations",
            value: "2",
            badge: 2,
            type: .recommendations
        )
    ) {
    }
    .padding()
    .background(HealthColors.background)
}