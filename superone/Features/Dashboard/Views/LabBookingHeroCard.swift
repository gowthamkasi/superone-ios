import SwiftUI

/// Lab booking hero card with medical-focused design and booking call-to-action
/// Uses smooth animations and integrates with the existing design system
struct LabBookingHeroCard: View {
    let onBookNow: () -> Void
    
    @State private var hasAppeared = false
    @State private var showCard = false
    @State private var showContent = false
    @State private var showButton = false
    @State private var animateIcons = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            onBookNow()
        }) {
            VStack(spacing: HealthSpacing.xl) {
                // Header Section with Icons
                VStack(spacing: HealthSpacing.md) {
                    // Medical Icons Row
                    HStack(spacing: HealthSpacing.lg) {
                        ForEach(medicalIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(HealthColors.primary.opacity(0.7))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(HealthColors.accent.opacity(0.2))
                                )
                                .scaleEffect(animateIcons ? 1.0 : 0.8)
                                .opacity(animateIcons ? 1.0 : 0.3)
                                .animation(
                                    .spring(duration: 0.6, bounce: 0.3)
                                    .delay(Double(medicalIcons.firstIndex(of: icon) ?? 0) * 0.1 + 0.5),
                                    value: animateIcons
                                )
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)
                    
                    // Main Heading
                    Text("Book Lab Test")
                        .font(HealthTypography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: showContent)
                    
                    // Subtitle
                    Text("Find labs near you and schedule tests")
                        .font(HealthTypography.bodyRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 15)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: showContent)
                }
                
                // Location-based messaging
                HStack(spacing: HealthSpacing.sm) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(HealthColors.primary)
                    
                    Text("Available labs in your area")
                        .font(HealthTypography.footnote)
                        .foregroundColor(HealthColors.tertiaryText)
                }
                .padding(.horizontal, HealthSpacing.lg)
                .padding(.vertical, HealthSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                        .fill(HealthColors.accent.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                                .stroke(HealthColors.accent.opacity(0.3), lineWidth: 1)
                        )
                )
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1.0 : 0.9)
                .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.7), value: showContent)
                
                // Book Now Button
                VStack(spacing: HealthSpacing.sm) {
                    HStack(spacing: HealthSpacing.sm) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Book Now")
                            .font(HealthTypography.buttonPrimary)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: HealthSpacing.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .fill(
                                LinearGradient(
                                    colors: [HealthColors.primary, HealthColors.forest],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .stroke(
                                LinearGradient(
                                    colors: [HealthColors.primary.opacity(0.6), HealthColors.forest.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: HealthColors.primary.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                    .scaleEffect(showButton ? 1.0 : 0.9)
                    .opacity(showButton ? 1.0 : 0)
                    .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.9), value: showButton)
                    
                    // Small help text
                    Text("Quick and easy appointment booking")
                        .font(HealthTypography.caption1)
                        .foregroundColor(HealthColors.tertiaryText)
                        .opacity(showButton ? 0.8 : 0)
                        .animation(.easeOut(duration: 0.4).delay(1.1), value: showButton)
                }
            }
            .padding(HealthSpacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.secondarySystemBackground),
                                HealthColors.accent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                            .stroke(HealthColors.accent.opacity(0.2), lineWidth: 1)
                    )
                    .healthCardShadow()
            )
            .scaleEffect(showCard ? 1.0 : 0.95)
            .opacity(showCard ? 1.0 : 0.0)
            .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.1), value: showCard)
        }
        .buttonStyle(LabBookingCardButtonStyle())
        .onAppear {
            // Only animate once when the view first appears
            if !hasAppeared {
                hasAppeared = true
                startAnimation()
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let medicalIcons = [
        "stethoscope",
        "cross.vial",
        "medical.thermometer"
    ]
    
    // MARK: - Private Methods
    
    private func startAnimation() {
        // Animate elements sequentially
        showCard = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showContent = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            animateIcons = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showButton = true
        }
    }
}

// MARK: - Lab Booking Card Button Style
struct LabBookingCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.2), value: configuration.isPressed)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                    .fill(Color.clear)
                    .contentShape(Rectangle())
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        HapticFeedback.light()
                    }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Book lab test")
            .accessibilityHint("Tap to find and schedule lab tests in your area")
    }
}


// MARK: - Preview
#Preview("Default Lab Booking Card") {
    LabBookingHeroCard {
        print("Book now tapped")
    }
    .padding()
    .background(HealthColors.background)
}

#Preview("Dark Mode") {
    LabBookingHeroCard {
        print("Book now tapped")
    }
    .padding()
    .background(HealthColors.background)
    .preferredColorScheme(.dark)
}

#Preview("Compact Size") {
    LabBookingHeroCard {
        print("Book now tapped")
    }
    .padding(.horizontal, HealthSpacing.md)
    .background(HealthColors.background)
}