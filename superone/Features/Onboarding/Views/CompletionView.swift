import SwiftUI

/// Onboarding completion view with celebration and next steps
/// Simplified for better user experience and scrollability
struct CompletionView: View {
    @Environment(OnboardingViewModel.self) private var _viewModel
    @EnvironmentObject var appState: AppState
    @Environment(AuthenticationManager.self) private var authManager
    @State private var showCelebration = false
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var pulseAnimation = false
    
    private var viewModel: OnboardingViewModel {
        _viewModel
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    HealthColors.accent.opacity(0.1),
                    HealthColors.background,
                    HealthColors.primary.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main scrollable content
            ScrollView {
                VStack(spacing: HealthSpacing.formGroupSpacing) {
                    Spacer(minLength: HealthSpacing.xl)
                    
                    // Celebration Section
                    celebrationSection
                    
                    // Profile Summary
                    profileSummarySection
                    
                    // Next Steps
                    nextStepsSection
                    
                    // Quick Tips
                    quickTipsSection
                    
                    // Bottom spacing for content separation
                    Spacer(minLength: HealthSpacing.xxl)
                    
                    // Update hint text
                    Text("You can always update your profile in Settings")
                        .healthTextStyle(.footnote, color: HealthColors.tertiaryText, alignment: .center)
                        .opacity(showContent ? 1.0 : 0.0)
                        .padding(.bottom, HealthSpacing.md)
                }
            }
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.5).delay(0.8), value: showContent)
            
            // Confetti Effect
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Bottom button
            OnboardingBottomButtonBar(
                configuration: .single(
                    title: "Start Your Health Journey",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.isLoading
                ) {
                    Task.detached(priority: .userInitiated) {
                        await MainActor.run {
                            guard !viewModel.isLoading else { return }
                        }
                        
                        // Complete onboarding data persistence
                        await viewModel.completeOnboarding()
                        
                        // Direct navigation to dashboard - no complex listeners needed!
                        await MainActor.run {
                            appState.isOnboardingComplete = true
                            
                            // SECURITY: Only bypass authentication in DEBUG builds
                            #if DEBUG
                            if ProcessInfo.processInfo.arguments.contains("--demo-mode") {
                                authManager.isAuthenticated = true
                            } else {
                            }
                            #else
                            // In production, never bypass authentication
                            #endif
                            
                        }
                    }
                }
            )
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 50)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(1.0), value: showContent)
        }
        .onAppear {
            startSimpleAnimation()
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Onboarding Error", isPresented: Binding(
            get: { viewModel.showError },
            set: { viewModel.showError = $0 }
        )) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "Unable to complete onboarding. Please try again.")
        }
    }
    
    // MARK: - Celebration Section
    
    private var celebrationSection: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Animated Success Icon
            ZStack {
                // Simplified pulse rings
                ForEach(0..<2) { index in
                    Circle()
                        .strokeBorder(HealthColors.primary.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: 120 + CGFloat(index * 15), height: 120 + CGFloat(index * 15))
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 0.8)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.2),
                            value: pulseAnimation
                        )
                }
                
                // Main success circle
                Circle()
                    .fill(HealthColors.primary)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(showCelebration ? 1.0 : 0.6)
                    )
                    .scaleEffect(showCelebration ? 1.0 : 0.3)
                    .opacity(showCelebration ? 1.0 : 0.0)
                    .animation(.spring(duration: 0.6, bounce: 0.3), value: showCelebration)
            }
            
            // Success Message
            VStack(spacing: HealthSpacing.md) {
                Text("You're All Set!")
                    .healthTextStyle(.largeTitle, color: HealthColors.primary, alignment: .center)
                    .scaleEffect(showCelebration ? 1.0 : 0.8)
                    .opacity(showCelebration ? 1.0 : 0.0)
                    .offset(y: showCelebration ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showCelebration)
                
                Text("Welcome to your personalized health journey")
                    .healthTextStyle(.title3, color: HealthColors.secondaryText, alignment: .center)
                    .opacity(showCelebration ? 1.0 : 0.0)
                    .offset(y: showCelebration ? 0 : 15)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: showCelebration)
                
                Text("Let's start analyzing your health data")
                    .healthTextStyle(.body, color: HealthColors.tertiaryText, alignment: .center)
                    .opacity(showCelebration ? 1.0 : 0.0)
                    .offset(y: showCelebration ? 0 : 10)
                    .animation(.easeOut(duration: 0.5).delay(0.6), value: showCelebration)
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Profile Summary Section
    
    private var profileSummarySection: some View {
        VStack(spacing: HealthSpacing.lg) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.primary)
                
                Text("Your Profile")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            VStack(spacing: HealthSpacing.md) {
                ProfileSummaryRow(
                    icon: "person.fill",
                    title: "Name",
                    value: viewModel.userProfile.fullName.isEmpty ? "Not provided" : viewModel.userProfile.fullName
                )
                
                if let age = viewModel.userProfile.age {
                    ProfileSummaryRow(
                        icon: "calendar",
                        title: "Age",
                        value: "\(age) years old"
                    )
                }
                
                ProfileSummaryRow(
                    icon: "person.2",
                    title: "Biological Sex",
                    value: viewModel.userProfile.biologicalSex.displayName
                )
                
                if let height = viewModel.userProfile.heightDisplayText {
                    ProfileSummaryRow(
                        icon: "ruler.fill",
                        title: "Height",
                        value: height
                    )
                }
                
                if let weight = viewModel.userProfile.weightDisplayText {
                    ProfileSummaryRow(
                        icon: "scalemass.fill",
                        title: "Weight",
                        value: weight
                    )
                }
                
                ProfileSummaryRow(
                    icon: "target",
                    title: "Health Goals",
                    value: "\(viewModel.userProfile.selectedGoals.count) selected"
                )
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
    }
    
    // MARK: - Next Steps Section
    
    private var nextStepsSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            HStack {
                Image(systemName: "list.number")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.primary)
                
                Text("What's Next?")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            VStack(spacing: HealthSpacing.md) {
                NextStepRow(
                    number: 1,
                    title: "Upload Your First Lab Report",
                    description: "Take a photo or upload a PDF of your latest lab results",
                    icon: "doc.text.viewfinder"
                )
                
                NextStepRow(
                    number: 2,
                    title: "Get AI-Powered Analysis",
                    description: "Receive comprehensive insights about your health metrics",
                    icon: "brain.head.profile"
                )
                
                NextStepRow(
                    number: 3,
                    title: "Track Your Progress",
                    description: "Monitor trends and improvements over time",
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                NextStepRow(
                    number: 4,
                    title: "Book Follow-up Tests",
                    description: "Schedule appointments based on recommendations",
                    icon: "calendar.badge.plus"
                )
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
    }
    
    // MARK: - Quick Tips Section
    
    private var quickTipsSection: some View {
        VStack(spacing: HealthSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.accent)
                
                Text("Quick Tips")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                TipRow(text: "Upload lab reports immediately after receiving them for the most accurate timeline")
                TipRow(text: "Check the app regularly for new insights and health trend updates")
                TipRow(text: "Use the comparison feature to track improvements between tests")
                TipRow(text: "Share reports with your healthcare provider for better consultations")
            }
        }
        .padding(HealthSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                .fill(HealthColors.accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                        .strokeBorder(HealthColors.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    
    // MARK: - Private Methods
    
    private func startSimpleAnimation() {
        // Start celebration animation immediately
        withAnimation(.easeOut(duration: 0.3)) {
            showCelebration = true
            showConfetti = true
            pulseAnimation = true
        }
        
        // Show content after brief celebration
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            
            // Stop confetti after 1.5 seconds
            try? await Task.sleep(for: .seconds(0.7))
            withAnimation(.easeOut(duration: 0.3)) {
                showConfetti = false
            }
        }
    }
}

// MARK: - Supporting Components

struct ProfileSummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(HealthColors.secondary)
                .frame(width: 24)
            
            Text(title)
                .healthTextStyle(.body, color: HealthColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
        }
        .padding(HealthSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                .fill(HealthColors.secondaryBackground)
        )
    }
}

struct NextStepRow: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            // Step Number
            ZStack {
                Circle()
                    .fill(HealthColors.primary)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .healthTextStyle(.bodyEmphasized, color: .white)
            }
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(title)
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                
                Text(description)
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(HealthColors.accent)
        }
        .padding(HealthSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                .fill(HealthColors.secondaryBackground)
        )
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: HealthSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(HealthColors.healthGood)
                .padding(.top, 2)
            
            Text(text)
                .healthTextStyle(.body, color: HealthColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// MARK: - Confetti Effect

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Reduced from 50 to 20 particles for better performance
            ForEach(0..<20, id: \.self) { index in
                ConfettiPiece(delay: Double(index) * 0.08)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    let delay: Double
    @State private var animate = false
    
    // Pre-computed values for better performance
    private let color: Color = [
        HealthColors.primary,
        HealthColors.emerald,
        HealthColors.sage,
        HealthColors.accent
    ].randomElement() ?? HealthColors.primary
    
    private let startX = CGFloat.random(in: 50...300)
    private let endX = CGFloat.random(in: 50...300)
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 6, height: 6)
            .position(
                x: animate ? endX : startX,
                y: animate ? 600 : -50
            )
            .rotationEffect(.degrees(animate ? Double.random(in: 180...540) : 0))
            .opacity(animate ? 0.0 : 1.0)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0).delay(delay)) {
                    animate = true
                }
            }
    }
}

// MARK: - Preview

#Preview("Completion View") {
    CompletionView()
        .environment(OnboardingViewModel())
}

#Preview("Profile Summary Row") {
    ProfileSummaryRow(
        icon: "person.fill",
        title: "Name",
        value: "Sample User"
    )
    .padding()
}

#Preview("Next Step Row") {
    NextStepRow(
        number: 1,
        title: "Upload Your First Lab Report",
        description: "Take a photo or upload a PDF of your latest lab results",
        icon: "doc.text.viewfinder"
    )
    .padding()
}