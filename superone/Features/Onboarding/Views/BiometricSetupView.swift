import SwiftUI
import LocalAuthentication

/// Biometric authentication setup view with optional configuration
struct BiometricSetupView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @State private var animateContent = false
    @State private var biometricType: LABiometryType = .none
    @State private var isAvailable = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                HealthColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: HealthSpacing.formGroupSpacing) {
                        // Header Section
                        headerSection
                        
                        // Progress Indicator
                        ProgressView(value: viewModel.progressValue)
                            .progressViewStyle(HealthProgressViewStyle())
                            .padding(.horizontal, HealthSpacing.screenPadding)
                        
                        // Biometric Illustration
                        biometricIllustration
                        
                        // Features Section
                        featuresSection
                        
                        // Security Info
                        securitySection
                        
                        // Bottom spacing for content separation
                        Spacer(minLength: HealthSpacing.xxl)
                    }
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: animateContent)
            }
        }
        .safeAreaInset(edge: .bottom) {
            OnboardingBottomButtonBar(
                configuration: .triple(
                    leftTitle: "Back",
                    leftHandler: {
                        viewModel.previousStep()
                    },
                    centerTitle: "Set Up Later",
                    centerHandler: {
                        viewModel.skipBiometricSetup()
                    },
                    rightTitle: "Enable \(biometricDisplayName)",
                    rightIsLoading: viewModel.isLoading,
                    rightHandler: {
                        Task.detached(priority: .userInitiated) {
                            await MainActor.run {
                                guard !viewModel.isLoading else { return }
                            }
                            await viewModel.setupBiometricAuthentication()
                        }
                    }
                )
            )
        }
        .onAppear {
            detectBiometricType()
            animateContent = true
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: HealthSpacing.md) {
            Image(systemName: biometricIconName)
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(HealthColors.primary)
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("Secure Your Data")
                    .healthTextStyle(.title1, color: HealthColors.primaryText, alignment: .center)
                
                Text("Keep your health data private with \(biometricDisplayName)")
                    .healthTextStyle(.body, color: HealthColors.secondaryText, alignment: .center)
            }
        }
        .padding(.top, HealthSpacing.xxl)
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Biometric Illustration
    
    private var biometricIllustration: some View {
        ZStack {
            // Background Circle
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            HealthColors.accent.opacity(0.1),
                            HealthColors.primary.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 160)
            
            // Biometric Icon
            Image(systemName: largeIconName)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(HealthColors.primary)
                .scaleEffect(animateContent ? 1.0 : 0.6)
                .animation(.easeOut(duration: 0.8).delay(0.4), value: animateContent)
            
            // Animated Ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            HealthColors.primary.opacity(0.3),
                            HealthColors.primary,
                            HealthColors.primary.opacity(0.3)
                        ]),
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(animateContent ? 360 : 0))
                .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: animateContent)
        }
        .padding(.vertical, HealthSpacing.xl)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            HStack {
                Text("Why Enable \(biometricDisplayName)?")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            VStack(spacing: HealthSpacing.md) {
                BiometricFeatureRow(
                    icon: "bolt.fill",
                    title: "Quick Access",
                    description: "Unlock the app instantly with just a glance or touch"
                )
                
                BiometricFeatureRow(
                    icon: "shield.fill",
                    title: "Enhanced Security",
                    description: "Your biometric data never leaves your device"
                )
                
                BiometricFeatureRow(
                    icon: "key.fill",
                    title: "No More Passwords",
                    description: "Forget about remembering complex passwords"
                )
                
                BiometricFeatureRow(
                    icon: "heart.fill",
                    title: "Protected Health Data",
                    description: "Additional layer of protection for sensitive information"
                )
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        VStack(spacing: HealthSpacing.md) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.primary)
                
                Text("Security Information")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                SecurityInfoRow(text: "Your biometric data is stored securely in the Secure Enclave")
                SecurityInfoRow(text: "We never have access to your biometric information")
                SecurityInfoRow(text: "You can disable this feature at any time in Settings")
                SecurityInfoRow(text: "Standard passcode authentication is still available as backup")
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
    
    
    // MARK: - Computed Properties
    
    private var biometricDisplayName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometric Authentication"
        @unknown default:
            return "Biometric Authentication"
        }
    }
    
    private var biometricIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        @unknown default:
            return "lock.fill"
        }
    }
    
    private var largeIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.circle.fill"
        @unknown default:
            return "lock.circle.fill"
        }
    }
    
    // MARK: - Private Methods
    
    private func detectBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            isAvailable = false
            return
        }
        
        biometricType = context.biometryType
        isAvailable = true
    }
}

// MARK: - Supporting Components

struct BiometricFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            ZStack {
                Circle()
                    .fill(HealthColors.accent.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.primary)
            }
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(title)
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                
                Text(description)
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct SecurityInfoRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: HealthSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(HealthColors.healthGood)
                .padding(.top, 2)
            
            Text(text)
                .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}


// MARK: - Preview

#Preview("Biometric Setup View - Face ID") {
    BiometricSetupView()
        .environment(OnboardingViewModel())
}

#Preview("Biometric Feature Row") {
    BiometricFeatureRow(
        icon: "bolt.fill",
        title: "Quick Access",
        description: "Unlock the app instantly with just a glance or touch"
    )
    .padding()
}