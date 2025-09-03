import SwiftUI

/// Loading states and error handling UI components for authentication
struct AuthenticationLoadingView: View {
    let state: AuthenticationState
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Content card
            VStack(spacing: HealthSpacing.xl) {
                switch state {
                case .loading:
                    loadingContent
                case .error(let error):
                    errorContent(error)
                case .success:
                    successContent
                case .biometricPrompt:
                    biometricPromptContent
                case .requiresTwoFactor:
                    twoFactorContent
                case .idle:
                    EmptyView()
                }
            }
            .padding(HealthSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                    .fill(HealthColors.background)
                    .healthCardShadow()
            )
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }
    
    // MARK: - Loading Content
    
    private var loadingContent: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(HealthColors.accent.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(HealthColors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: 360))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: true)
            }
            
            VStack(spacing: HealthSpacing.sm) {
                Text("Signing You In")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Text("Please wait while we verify your credentials")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Error Content
    
    private func errorContent(_ error: AuthenticationError) -> some View {
        VStack(spacing: HealthSpacing.lg) {
            // Error icon
            Image(systemName: errorIcon(for: error))
                .font(.system(size: 50, weight: .light))
                .foregroundColor(HealthColors.healthCritical)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("Sign In Failed")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Text(error.errorDescription ?? "An unknown error occurred")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                
                if let recovery = error.recoverySuggestion {
                    Text(recovery)
                        .healthTextStyle(.caption1, color: HealthColors.tertiaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, HealthSpacing.xs)
                }
            }
            
            // Action buttons
            VStack(spacing: HealthSpacing.md) {
                HealthPrimaryButton("Try Again") {
                    onRetry()
                }
                
                Button("Cancel") {
                    onDismiss()
                }
                .healthTextStyle(.body, color: HealthColors.secondaryText)
            }
        }
    }
    
    // MARK: - Success Content
    
    private var successContent: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Success animation
            ZStack {
                Circle()
                    .fill(HealthColors.healthGood.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(HealthColors.healthGood)
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3), value: state)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("Welcome!")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Text("Successfully signed in to your account")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Biometric Prompt Content
    
    private var biometricPromptContent: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Biometric icon
            Image(systemName: "faceid")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(HealthColors.primary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("Biometric Authentication")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Text("Use Face ID or Touch ID to sign in securely")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Action buttons
            VStack(spacing: HealthSpacing.md) {
                HealthPrimaryButton("Continue") {
                    onRetry()
                }
                
                Button("Use Password Instead") {
                    onDismiss()
                }
                .healthTextStyle(.body, color: HealthColors.secondaryText)
            }
        }
    }
    
    // MARK: - Two Factor Content
    
    private var twoFactorContent: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Security icon
            Image(systemName: "shield.checkered")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(HealthColors.primary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("Two-Factor Authentication")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Text("Please check your authenticator app for the verification code")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Action buttons
            VStack(spacing: HealthSpacing.md) {
                HealthPrimaryButton("Continue") {
                    onRetry()
                }
                
                Button("Cancel") {
                    onDismiss()
                }
                .healthTextStyle(.body, color: HealthColors.secondaryText)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func errorIcon(for error: AuthenticationError) -> String {
        switch error {
        case .invalidCredentials:
            return "key.slash"
        case .accountLocked:
            return "lock.fill"
        case .emailNotVerified:
            return "envelope.badge.shield.half.filled"
        case .networkError:
            return "wifi.slash"
        case .serverError:
            return "server.rack"
        case .biometricError:
            return "faceid"
        case .tokenExpired:
            return "clock.badge.exclamationmark"
        default:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Error Banner

struct AuthenticationErrorBanner: View {
    let error: AuthenticationError
    let onDismiss: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: HealthSpacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text("Error")
                        .font(HealthTypography.caption1)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    
                    Text(error.errorDescription ?? "An unknown error occurred")
                        .font(HealthTypography.caption2)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, HealthSpacing.lg)
            .padding(.vertical, HealthSpacing.md)
            .background(HealthColors.healthCritical)
            .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.md))
            .healthCardShadow()
            .offset(y: isVisible ? 0 : -100)
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3), value: isVisible)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
            
            // Auto dismiss after 5 seconds with Task-based delay
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await MainActor.run {
                    dismissBanner()
                }
            }
        }
    }
    
    private func dismissBanner() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = false
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                onDismiss()
            }
        }
    }
}

// MARK: - Loading Button

struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HealthSpacing.md) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                        .animation(.easeInOut, value: isLoading)
                }
                
                Text(isLoading ? "Loading..." : title)
                    .healthTextStyle(.buttonPrimary, color: .white)
                    .animation(.easeInOut, value: isLoading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: HealthSpacing.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .fill(buttonBackgroundColor)
            )
            .opacity(buttonOpacity)
            .scaleEffect(isEnabled && !isLoading ? 1.0 : 0.98)
            .animation(.easeInOut(duration: 0.1), value: isEnabled)
        }
        .disabled(!isEnabled || isLoading)
    }
    
    private var buttonBackgroundColor: Color {
        if isEnabled && !isLoading {
            return HealthColors.primary
        } else {
            return HealthColors.healthNeutral
        }
    }
    
    private var buttonOpacity: Double {
        if isEnabled && !isLoading {
            return 1.0
        } else {
            return 0.6
        }
    }
}

// MARK: - Inline Loading Indicator

struct InlineLoadingIndicator: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Circle()
                .fill(HealthColors.primary)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
            
            Circle()
                .fill(HealthColors.primary)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2), value: isAnimating)
            
            Circle()
                .fill(HealthColors.primary)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.4), value: isAnimating)
            
            Text(message)
                .healthTextStyle(.body, color: HealthColors.secondaryText)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#Preview("Loading State") {
    AuthenticationLoadingView(
        state: .loading,
        onRetry: {},
        onDismiss: {}
    )
}

#Preview("Error State") {
    AuthenticationLoadingView(
        state: .error(.invalidCredentials),
        onRetry: {},
        onDismiss: {}
    )
}

#Preview("Success State") {
    AuthenticationLoadingView(
        state: .success(User(
            id: "1",
            email: "test@test.local",
            name: "Test User",
            profileImageURL: nil,
            phoneNumber: nil,
            dateOfBirth: nil,
            gender: nil,
            createdAt: Date(),
            updatedAt: Date(),
            emailVerified: true,
            phoneVerified: false,
            twoFactorEnabled: false,
            profile: nil,
            preferences: nil
        )),
        onRetry: {},
        onDismiss: {}
    )
}

#Preview("Error Banner") {
    AuthenticationErrorBanner(
        error: .networkError("Unable to connect to server"),
        onDismiss: {}
    )
}
