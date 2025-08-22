import SwiftUI

/// Main onboarding coordinator view that manages the entire onboarding flow
struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(AppFlowManager.self) private var flowManager
    
    var body: some View {
        // Remove NavigationView nesting to prevent gesture conflicts
        ZStack {
            // Background
            HealthColors.background.ignoresSafeArea()
            
            // Current Step Content
            Group {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeView()
                
                case .profileSetup:
                    ProfileSetupView()
                
                case .healthGoals:
                    HealthGoalsView()
                
                case .healthKitPermissions:
                    HealthKitPermissionsView()
                
                case .biometricSetup:
                    BiometricSetupView()
                
                case .accountSetup:
                    AccountSetupView()
                
                case .completion:
                    CompletionView()
                }
            }
            .transition(.identity)  // CRITICAL: Remove opacity transition to prevent rendering delays
            
            // "Already Have Account?" floating button - shown on all steps except account setup and completion
            if shouldShowAlreadyHaveAccountButton {
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            flowManager.startAuthentication()
                        }) {
                            HStack(spacing: HealthSpacing.xs) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text("I have an account")
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                            }
                            .foregroundColor(HealthColors.primary)
                            .padding(.horizontal, HealthSpacing.sm)
                            .padding(.vertical, HealthSpacing.xs)
                            .background(
                                Capsule()
                                    .fill(HealthColors.background)
                                    .shadow(color: HealthColors.primary.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(HealthColors.primary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.trailing, HealthSpacing.md)
                    }
                    .padding(.top, HealthSpacing.sm)
                    
                    Spacer()
                }
            }
        }
        .environment(viewModel)  // CRITICAL: Inject viewModel into environment for all child views
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: viewModel.userProfile.hasCompletedOnboarding) { oldValue, hasCompleted in
            // Navigate to main app when onboarding is completed
            if hasCompleted && viewModel.currentStep == .completion {
                // Don't show the placeholder - let the main ContentView handle the navigation
                // The app state will be updated and ContentView will show the appropriate screen
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Determines whether to show the "Already Have Account?" button
    private var shouldShowAlreadyHaveAccountButton: Bool {
        // Don't show on account setup or completion steps
        return viewModel.currentStep != .accountSetup && viewModel.currentStep != .completion
    }
}

// MARK: - Main App Placeholder

struct MainAppPlaceholderView: View {
    var body: some View {
        ZStack {
            HealthColors.background.ignoresSafeArea()
            
            VStack(spacing: HealthSpacing.xl) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80, weight: .medium))
                    .foregroundColor(HealthColors.primary)
                
                VStack(spacing: HealthSpacing.md) {
                    Text("Welcome to Super One")
                        .healthTextStyle(.largeTitle, color: HealthColors.primaryText, alignment: .center)
                    
                    Text("Onboarding completed successfully!")
                        .healthTextStyle(.title3, color: HealthColors.secondaryText, alignment: .center)
                    
                    Text("Main app interface will be implemented in the next phase")
                        .healthTextStyle(.body, color: HealthColors.tertiaryText, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HealthSpacing.screenPadding)
                }
            }
        }
    }
}



// MARK: - Preview

#Preview("Onboarding View") {
    OnboardingView()
}

#Preview("Main App Placeholder") {
    MainAppPlaceholderView()
}