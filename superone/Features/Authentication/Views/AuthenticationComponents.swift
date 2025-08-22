import SwiftUI

// MARK: - iOS 18 Performance-Optimized Authentication Text Field

struct AuthenticationTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: UITextAutocapitalizationType = .sentences
    let validationState: FieldValidationState
    let validationField: ValidationField?
    let viewModel: AuthenticationViewModel?
    let onEditingChanged: (Bool) -> Void
    
    // PERFORMANCE: Pre-computed static properties to avoid body reevaluation
    private static let titleFont = Font.system(size: 16, weight: .medium)
    private static let iconFrameSize: CGFloat = 20
    private static let containerPadding: CGFloat = 12
    private static let containerCornerRadius: CGFloat = 8
    private static let containerSpacing: CGFloat = 12
    private static let vStackSpacing: CGFloat = 8
    
    // PERFORMANCE: Computed properties for conditional styling
    private var hasError: Bool { validationState.errorMessage != nil }
    
    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        
        VStack(alignment: .leading, spacing: Self.vStackSpacing) {
            // PERFORMANCE: Static title styling
            Text(title)
                .font(Self.titleFont)
                .foregroundColor(.primary)
            
            // PERFORMANCE: Optimized TextField container
            HStack(spacing: Self.containerSpacing) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: Self.iconFrameSize)
                
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .onChange(of: text) { _, newValue in
                        // PERFORMANCE: Debounced validation to prevent main thread blocking
                        if let field = validationField, let vm = viewModel {
                            vm.validateFieldWithDebouncing(field: field, value: newValue)
                        }
                    }
            }
            .padding(Self.containerPadding)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Self.containerCornerRadius)
            
            // PERFORMANCE: Conditional error display with minimal overhead
            if hasError {
                Text(validationState.errorMessage!)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - iOS 18 Performance-Optimized Authentication Secure Field

struct AuthenticationSecureField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let isSecure: Bool
    let validationState: FieldValidationState
    let validationField: ValidationField?
    let viewModel: AuthenticationViewModel?
    let showVisibilityToggle: Bool
    let onVisibilityToggle: () -> Void
    let onEditingChanged: (Bool) -> Void
    
    // PERFORMANCE: Pre-computed static properties to avoid body reevaluation
    private static let titleFont = Font.system(size: 16, weight: .medium)
    private static let iconFrameSize: CGFloat = 20
    private static let containerPadding: CGFloat = 12
    private static let containerCornerRadius: CGFloat = 8
    private static let containerSpacing: CGFloat = 12
    private static let vStackSpacing: CGFloat = 8
    
    // PERFORMANCE: Computed properties for conditional styling and icons
    private var hasError: Bool { validationState.errorMessage != nil }
    private var visibilityIcon: String { isSecure ? "eye" : "eye.slash" }
    
    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        
        VStack(alignment: .leading, spacing: Self.vStackSpacing) {
            // PERFORMANCE: Static title styling
            Text(title)
                .font(Self.titleFont)
                .foregroundColor(.primary)
            
            // PERFORMANCE: Optimized SecureField/TextField container
            HStack(spacing: Self.containerSpacing) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: Self.iconFrameSize)
                
                Group {
                    if isSecure {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .textFieldStyle(.plain)
                .textContentType(.password)
                .autocapitalization(.none)
                .onChange(of: text) { _, newValue in
                    // PERFORMANCE: Debounced validation to prevent main thread blocking
                    if let field = validationField, let vm = viewModel {
                        vm.validateFieldWithDebouncing(field: field, value: newValue)
                    }
                }
                
                if showVisibilityToggle {
                    Button(action: onVisibilityToggle) {
                        Image(systemName: visibilityIcon)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(Self.containerPadding)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Self.containerCornerRadius)
            
            // PERFORMANCE: Conditional error display with minimal overhead
            if hasError {
                Text(validationState.errorMessage!)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Biometric Login Button

struct BiometricLoginButton: View {
    let biometricState: BiometricAuthState
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HealthSpacing.md) {
                Image(systemName: biometricIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(buttonColor)
                
                Text(buttonTitle)
                    .healthTextStyle(.bodyEmphasized, color: buttonColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: HealthSpacing.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .strokeBorder(borderColor, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(biometricState == .authenticating)
    }
    
    private var biometricIcon: String {
        return "faceid"
    }
    
    private var buttonTitle: String {
        switch biometricState {
        case .authenticating:
            return "Authenticating..."
        case .available:
            return "Sign in with Face ID"
        default:
            return "Use Biometric Login"
        }
    }
    
    private var buttonColor: Color {
        switch biometricState {
        case .authenticating:
            return HealthColors.secondaryText
        default:
            return HealthColors.primary
        }
    }
    
    private var backgroundColor: Color {
        return HealthColors.secondaryBackground
    }
    
    private var borderColor: Color {
        return HealthColors.primary.opacity(0.3)
    }
}

// MARK: - Password Reset View

struct PasswordResetView: View {
    @Binding var email: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: HealthSpacing.xl) {
                VStack(spacing: HealthSpacing.lg) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(HealthColors.primary)
                    
                    VStack(spacing: HealthSpacing.sm) {
                        Text("Reset Password")
                            .healthTextStyle(.title1, color: HealthColors.primaryText)
                        
                        Text("Enter your email address and we will send you instructions to reset your password")
                            .healthTextStyle(.body, color: HealthColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                
                AuthenticationTextField(
                    title: "Email Address",
                    text: $email,
                    icon: "envelope",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .none,
                    validationState: .idle,
                    validationField: nil,
                    viewModel: nil,
                    onEditingChanged: { _ in }
                )
                
                VStack(spacing: HealthSpacing.md) {
                    HealthPrimaryButton("Send Reset Instructions") {
                        onSubmit()
                    }
                    .disabled(email.isEmpty)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                }
                
                Spacer()
            }
            .screenPadding()
            .navigationTitle("Password Reset")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .healthTextStyle(.body, color: HealthColors.primary)
                }
            }
        }
    }
}
