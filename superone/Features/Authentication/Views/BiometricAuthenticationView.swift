import SwiftUI
import LocalAuthentication

/// Biometric authentication UI components with Face ID/Touch ID support
struct BiometricAuthenticationView: View {
    @State private var viewModel: AuthenticationViewModel
    @State private var showingBiometricPrompt = false
    @State private var biometricType: LABiometryType = .none
    
    init(viewModel: AuthenticationViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Header
            headerSection
            
            // Biometric Option
            biometricSection
            
            // Alternative Options
            alternativeSection
            
            Spacer()
        }
        .padding(HealthSpacing.screenPadding)
        .background(HealthColors.background)
        .onAppear {
            checkBiometricType()
        }
        .sheet(isPresented: $showingBiometricPrompt) {
            BiometricSetupSheet(
                biometricType: biometricType,
                onEnable: { enabled in
                    if enabled {
                        Task { @MainActor in
                            guard viewModel.biometricState != .authenticating else { return }
                            await viewModel.authenticateWithBiometrics()
                        }
                    }
                    showingBiometricPrompt = false
                }
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Biometric icon
            Image(systemName: biometricIconName)
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(HealthColors.primary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("Secure Sign In")
                    .healthTextStyle(.title1, color: HealthColors.primaryText)
                
                Text("Use \(biometricDisplayName) for quick and secure access to your health data")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Biometric Section
    
    private var biometricSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Main biometric button
            BiometricActionButton(
                biometricType: biometricType,
                state: viewModel.biometricState,
                isEnabled: viewModel.canAttemptBiometricLogin
            ) {
                Task { @MainActor in
                    guard viewModel.biometricState != .authenticating else { return }
                    await viewModel.authenticateWithBiometrics()
                }
            }
            
            // Status message
            if let statusMessage = biometricStatusMessage {
                HStack(spacing: HealthSpacing.sm) {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(statusMessage)
                        .healthTextStyle(.caption1, color: statusColor)
                        .multilineTextAlignment(.center)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Alternative Section
    
    private var alternativeSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Divider
            HStack {
                VStack { Divider() }
                Text("OR")
                    .healthTextStyle(.caption1, color: HealthColors.tertiaryText)
                    .padding(.horizontal, HealthSpacing.md)
                VStack { Divider() }
            }
            
            // Alternative options
            VStack(spacing: HealthSpacing.md) {
                // Use Password Button
                Button(action: {
                    viewModel.switchToFlow(.login)
                }) {
                    HStack(spacing: HealthSpacing.md) {
                        Image(systemName: "key")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(HealthColors.primary)
                        
                        Text("Sign in with Password")
                            .healthTextStyle(.body, color: HealthColors.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(HealthColors.tertiaryText)
                    }
                    .padding(.horizontal, HealthSpacing.lg)
                    .frame(height: HealthSpacing.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .fill(HealthColors.secondaryBackground)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Setup Biometrics Button (if not available)
                if !viewModel.canAttemptBiometricLogin && biometricType != .none {
                    Button(action: {
                        showingBiometricPrompt = true
                    }) {
                        HStack(spacing: HealthSpacing.md) {
                            Image(systemName: "gear")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(HealthColors.secondary)
                            
                            Text("Enable \(biometricDisplayName)")
                                .healthTextStyle(.body, color: HealthColors.secondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(HealthColors.tertiaryText)
                        }
                        .padding(.horizontal, HealthSpacing.lg)
                        .frame(height: HealthSpacing.buttonHeight)
                        .background(
                            RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                                .fill(HealthColors.accent.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var biometricIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield"
        }
    }
    
    private var biometricDisplayName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometric Authentication"
        }
    }
    
    private var biometricStatusMessage: String? {
        switch viewModel.biometricState {
        case .unavailable:
            return "Biometric authentication is not available on this device"
        case .authenticating:
            return "Authenticating with \(biometricDisplayName)..."
        case .failed(let message):
            return message
        case .cancelled:
            return "Authentication was cancelled"
        case .fallback:
            return "Please use your device passcode"
        default:
            return nil
        }
    }
    
    private var statusIcon: String {
        switch viewModel.biometricState {
        case .unavailable:
            return "exclamationmark.triangle"
        case .authenticating:
            return "hourglass"
        case .failed:
            return "xmark.circle"
        case .cancelled:
            return "xmark.circle"
        case .fallback:
            return "key"
        default:
            return "checkmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch viewModel.biometricState {
        case .unavailable, .failed, .cancelled:
            return HealthColors.healthCritical
        case .authenticating:
            return HealthColors.healthWarning
        case .fallback:
            return HealthColors.secondary
        default:
            return HealthColors.healthGood
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }
}

// MARK: - Biometric Action Button

struct BiometricActionButton: View {
    let biometricType: LABiometryType
    let state: BiometricAuthState
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var animationScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: HealthSpacing.lg) {
                // Biometric icon with animation
                ZStack {
                    Circle()
                        .fill(backgroundGradient)
                        .frame(width: 120, height: 120)
                        .scaleEffect(animationScale)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animationScale)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 50, weight: .ultraLight))
                        .foregroundColor(.white)
                        .symbolRenderingMode(.hierarchical)
                }
                
                // Button text
                Text(buttonTitle)
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                    .multilineTextAlignment(.center)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        .onTapGesture {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        .onAppear {
            if state == .authenticating {
                startAnimation()
            }
        }
        .onChange(of: state) { newState in
            if newState == .authenticating {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private var iconName: String {
        switch state {
        case .authenticating:
            return biometricType == .faceID ? "faceid" : "touchid"
        case .success:
            return "checkmark"
        case .failed, .cancelled:
            return "xmark"
        default:
            return biometricType == .faceID ? "faceid" : "touchid"
        }
    }
    
    private var backgroundGradient: LinearGradient {
        switch state {
        case .authenticating:
            return LinearGradient(
                colors: [HealthColors.primary, HealthColors.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .success:
            return LinearGradient(
                colors: [HealthColors.healthGood, HealthColors.healthExcellent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .failed, .cancelled:
            return LinearGradient(
                colors: [HealthColors.healthCritical, HealthColors.healthWarning],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [HealthColors.primary, HealthColors.forest],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var buttonTitle: String {
        switch state {
        case .available:
            return "Touch to authenticate with \(biometricType == .faceID ? "Face ID" : "Touch ID")"
        case .authenticating:
            return "Authenticating..."
        case .success:
            return "Authentication successful!"
        case .failed:
            return "Authentication failed. Try again?"
        case .cancelled:
            return "Authentication cancelled"
        case .fallback:
            return "Use device passcode"
        case .unavailable:
            return "Biometric authentication unavailable"
        }
    }
    
    private func startAnimation() {
        withAnimation {
            animationScale = 1.1
        }
    }
    
    private func stopAnimation() {
        withAnimation {
            animationScale = 1.0
        }
    }
}

// MARK: - Biometric Setup Sheet

struct BiometricSetupSheet: View {
    let biometricType: LABiometryType
    let onEnable: (Bool) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            VStack(spacing: HealthSpacing.xl) {
                // Header
                VStack(spacing: HealthSpacing.lg) {
                    Image(systemName: biometricType == .faceID ? "faceid" : "touchid")
                        .font(.system(size: 80, weight: .ultraLight))
                        .foregroundColor(HealthColors.primary)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: HealthSpacing.sm) {
                        Text("Enable \(biometricDisplayName)")
                            .healthTextStyle(.title2, color: HealthColors.primaryText)
                        
                        Text("Use \(biometricDisplayName) for quick and secure access to your health data.")
                            .healthTextStyle(.body, color: HealthColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Benefits
                VStack(spacing: HealthSpacing.lg) {
                    BiometricBenefitRow(
                        icon: "bolt.fill",
                        title: "Lightning Fast",
                        description: "Sign in instantly with just a glance or touch"
                    )
                    
                    BiometricBenefitRow(
                        icon: "shield.fill",
                        title: "Extra Secure",
                        description: "Your biometric data never leaves your device"
                    )
                    
                    BiometricBenefitRow(
                        icon: "heart.fill",
                        title: "Health Focused",
                        description: "Quick access to your health insights when you need them"
                    )
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: HealthSpacing.md) {
                    HealthPrimaryButton("Enable \(biometricDisplayName)") {
                        onEnable(true)
                    }
                    
                    Button("Not Now") {
                        onEnable(false)
                    }
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                }
            }
            .padding(HealthSpacing.screenPadding)
            .navigationTitle("Biometric Security")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var biometricDisplayName: String {
        biometricType == .faceID ? "Face ID" : "Touch ID"
    }
}

// MARK: - Biometric Benefit Row

private struct BiometricBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: HealthSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(HealthColors.primary)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(title)
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Text(description)
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Biometric Permission Status

struct BiometricPermissionStatus: View {
    let biometricType: LABiometryType
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: HealthSpacing.lg) {
            Image(systemName: biometricType == .faceID ? "faceid" : "touchid")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(HealthColors.primary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text("\(biometricType == .faceID ? "Face ID" : "Touch ID") Authentication")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Text(isEnabled ? "Enabled for quick sign in" : "Disabled")
                    .healthTextStyle(.body, color: isEnabled ? HealthColors.healthGood : HealthColors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    onToggle(newValue)
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: HealthColors.primary))
        }
        .padding(HealthSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                .fill(HealthColors.secondaryBackground)
        )
    }
}

// MARK: - Preview

#Preview("Biometric Authentication") {
    BiometricAuthenticationView(viewModel: AuthenticationViewModel())
}

#Preview("Biometric Action Button") {
    VStack(spacing: HealthSpacing.xl) {
        BiometricActionButton(
            biometricType: .faceID,
            state: .available,
            isEnabled: true
        ) {}
        
        BiometricActionButton(
            biometricType: .touchID,
            state: .authenticating,
            isEnabled: true
        ) {}
        
        BiometricActionButton(
            biometricType: .faceID,
            state: .success,
            isEnabled: true
        ) {}
    }
    .padding()
}

#Preview("Biometric Setup Sheet") {
    BiometricSetupSheet(biometricType: .faceID) { _ in }
}