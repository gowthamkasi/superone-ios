import SwiftUI

/// Welcome screen that introduces the app and its key features
@MainActor
struct WelcomeView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @State private var animateContent = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        HealthColors.accent.opacity(0.1),
                        HealthColors.background
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: HealthSpacing.onboardingSpacing) {
                        // Logo and Title Section
                        VStack(spacing: HealthSpacing.lg) {
                            // App Icon/Logo
                            ZStack {
                                Circle()
                                    .fill(HealthColors.primary)
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 50, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(animateContent ? 1.0 : 0.8)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                            
                            VStack(spacing: HealthSpacing.sm) {
                                Text("Welcome to")
                                    .healthTextStyle(.title2, color: HealthColors.secondaryText)
                                
                                Text("Super One Health")
                                    .healthTextStyle(.largeTitle, color: HealthColors.primary)
                                    .multilineTextAlignment(.center)
                                
                                Text("Your personal health analysis companion")
                                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, HealthSpacing.xl)
                            }
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                        }
                        .padding(.top, HealthSpacing.xxl)
                        
                        // Features Carousel
                        VStack(spacing: HealthSpacing.xl) {
                            Text("Powerful Features")
                                .healthTextStyle(.title2, color: HealthColors.primaryText)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
                            
                            // Manual horizontal scrolling to avoid TabView gesture conflicts
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(Array(WelcomeFeature.features.enumerated()), id: \.element.id) { index, feature in
                                        FeatureCard(feature: feature)
                                            .frame(width: 280) // Fixed width for consistent sizing
                                            .id(index)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .frame(height: 300)
                            .scrollTargetBehavior(.paging)
                            
                            // Static page indicator (no timer needed)
                            HStack(spacing: 8) {
                                ForEach(0..<WelcomeFeature.features.count, id: \.self) { index in
                                    Circle()
                                        .fill(HealthColors.primary)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.top, 10)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(0.8), value: animateContent)
                        }
                        
                        // Benefits Section
                        VStack(spacing: HealthSpacing.lg) {
                            Text("Why Choose Super One?")
                                .healthTextStyle(.title2, color: HealthColors.primaryText)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: HealthSpacing.md) {
                                BenefitItem(
                                    icon: "brain.head.profile",
                                    title: "AI-Powered",
                                    description: "Advanced AI analyzes your health data"
                                )
                                
                                BenefitItem(
                                    icon: "shield.checkered",
                                    title: "Secure",
                                    description: "Bank-level encryption for your data"
                                )
                                
                                BenefitItem(
                                    icon: "person.crop.circle.badge.checkmark",
                                    title: "Personalized",
                                    description: "Tailored insights just for you"
                                )
                                
                                BenefitItem(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Real-time",
                                    description: "Instant analysis and updates"
                                )
                            }
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6).delay(1.0), value: animateContent)
                        
                        // Bottom spacing for content separation
                        Spacer(minLength: HealthSpacing.xxl)
                        
                        // Setup hint text
                        Text("Takes less than 2 minutes to set up")
                            .healthTextStyle(.footnote, color: HealthColors.tertiaryText, alignment: .center)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(1.4), value: animateContent)
                            .padding(.bottom, HealthSpacing.md)
                    }
                    .screenPadding()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            OnboardingBottomButtonBar(
                configuration: .single(
                    title: "Get Started",
                    isLoading: false,
                    isDisabled: false
                ) {
                    viewModel.nextStep()
                }
            )
            .opacity(animateContent ? 1.0 : 0.0)
        }
        .onAppear {
            animateContent = true
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Feature Card Component

@MainActor
struct FeatureCard: View {
    let feature: WelcomeFeature
    
    var body: some View {
        VStack(spacing: HealthSpacing.lg) {
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(feature.color)
            }
            
            VStack(spacing: HealthSpacing.sm) {
                Text(feature.title)
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(HealthSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                .fill(HealthColors.background)
                .healthCardShadow()
        )
        .padding(.horizontal, HealthSpacing.md)
    }
}

// MARK: - Benefit Item Component

@MainActor
struct BenefitItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: HealthSpacing.sm) {
            ZStack {
                Circle()
                    .fill(HealthColors.accent.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(HealthColors.primary)
            }
            
            VStack(spacing: HealthSpacing.xs) {
                Text(title)
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(HealthSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                .fill(HealthColors.secondaryBackground)
        )
    }
}

// MARK: - Haptic Feedback Helper (using shared implementation from QuickStatCard)

// MARK: - Preview

#Preview("Welcome View") {
    WelcomeView()
}

#Preview("Feature Card") {
    FeatureCard(feature: WelcomeFeature.features[0])
        .padding()
}

#Preview("Benefit Item") {
    BenefitItem(
        icon: "brain.head.profile",
        title: "AI-Powered",
        description: "Advanced AI analyzes your health data"
    )
    .padding()
}