import SwiftUI
import LocalAuthentication

/// Modern login view with simplified authentication using consolidated AuthenticationManager
struct LoginView: View {
    
    // MARK: - Properties
    
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(AppFlowManager.self) private var flowManager
    @State private var showingPasswordReset = false
    @State private var isPasswordVisible = false
    
    // MARK: - Initialization
    
    init() {
        // No initialization needed - using environment AuthenticationManager
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                        .padding(.top, HealthSpacing.xxxl)
                    
                    // Form Section
                    formSection
                        .padding(.horizontal, HealthSpacing.screenPadding)
                        .padding(.top, HealthSpacing.xxxl)
                    
                    // Actions Section
                    actionsSection
                        .padding(.horizontal, HealthSpacing.screenPadding)
                        .padding(.top, HealthSpacing.xl)
                    
                    // Alternative Sign In
                    alternativeSignInSection
                        .padding(.horizontal, HealthSpacing.screenPadding)
                        .padding(.top, HealthSpacing.xxxl)
                    
                    // Footer
                    footerSection
                        .padding(.top, HealthSpacing.xxxl)
                        .padding(.bottom, HealthSpacing.xl)
                }
                .frame(minHeight: max(geometry.size.height * 0.9, 600))
            }
            .scrollDismissesKeyboard(.interactively)
            // iOS 18+ Enhanced keyboard handling with automatic dismissal
            .keyboardType(.default)
            .scrollContentBackground(.hidden)
        }
        .background(HealthColors.background)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Error", isPresented: Binding(
            get: { authManager.showError },
            set: { authManager.showError = $0 }
        )) {
            Button("OK") {
                authManager.showError = false
            }
        } message: {
            Text(authManager.errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetView(email: Binding(
                get: { authManager.loginForm.email },
                set: { authManager.loginForm.email = $0 }
            )) {
                // Password reset functionality can be added to AuthenticationManager later
                showingPasswordReset = false
            }
        }
        .onAppear {
            
            // Smart email pre-fill from flow manager
            if let lastKnownEmail = flowManager.lastKnownEmail, authManager.loginForm.email.isEmpty {
                authManager.loginForm.email = lastKnownEmail
            } else {
            }
            
            // Check authentication state for automatic login
            
            // Automatic token refresh disabled - will be handled by app flow
        }
        .onDisappear {
            // Clear any in-memory credentials for security
            authManager.loginForm.password = ""
            
            // PERFORMANCE FIX: Comprehensive input session cleanup
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        // Biometric onChange handlers removed for now
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            // App Logo or Icon
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(HealthColors.primary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("Welcome Back")
                    .healthTextStyle(.title1, color: HealthColors.primaryText)
                
                Text("Sign in to access your health insights")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Email Field
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(HealthColors.primary)
                        .frame(width: 20)
                    
                    TextField("Email Address", text: Binding(
                        get: { authManager.loginForm.email },
                        set: { authManager.loginForm.email = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(HealthColors.primary)
                        .frame(width: 20)
                    
                    Group {
                        if isPasswordVisible {
                            TextField("Password", text: Binding(
                                get: { authManager.loginForm.password },
                                set: { authManager.loginForm.password = $0 }
                            ))
                        } else {
                            SecureField("Password", text: Binding(
                                get: { authManager.loginForm.password },
                                set: { authManager.loginForm.password = $0 }
                            ))
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
            }
            
            // Remember Me & Forgot Password
            HStack {
                Button(action: {
                    authManager.loginForm.rememberMe.toggle()
                }) {
                    HStack(spacing: HealthSpacing.sm) {
                        Image(systemName: authManager.loginForm.rememberMe ? "checkmark.square.fill" : "square")
                            .foregroundColor(authManager.loginForm.rememberMe ? HealthColors.primary : HealthColors.secondaryText)
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Remember me")
                            .healthTextStyle(.body, color: HealthColors.secondaryText)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button("Forgot Password?") {
                    showingPasswordReset = true
                }
                .healthTextStyle(.body, color: HealthColors.primary)
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Sign In Button
            Button(action: {
                
                // Additional validation - only proceed if form is actually valid
                guard authManager.loginForm.isFormValid else {
                    return
                }
                
                
                // Dismiss keyboard before login
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                Task {
                    await authManager.signInWithEmail()
                }
            }) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    Text(authManager.isLoading ? "Signing In..." : "Sign In")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(HealthColors.primary)
                .foregroundColor(.white)
                .cornerRadius(HealthCornerRadius.button)
            }
            .disabled(!authManager.loginForm.isFormValid || authManager.isLoading)
            // DEBUG: Add visual debugging border for email button
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .stroke(Color.red, lineWidth: 2)
                    .opacity(0.5)
            )
            
            // Biometric authentication removed for now - will be added back later
        }
    }
    
    // MARK: - Alternative Sign In Section
    
    private var alternativeSignInSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Divider with Text
            HStack {
                VStack {
                    Divider()
                }
                
                Text("OR")
                    .healthTextStyle(.caption1, color: HealthColors.tertiaryText)
                    .padding(.horizontal, HealthSpacing.md)
                
                VStack {
                    Divider()
                }
            }
            
            // Start Fresh Option
            VStack(spacing: HealthSpacing.sm) {
                HStack(spacing: HealthSpacing.sm) {
                    Text("Need a new account?")
                        .healthTextStyle(.body, color: HealthColors.secondaryText)
                    
                    Button("Start Fresh") {
                        flowManager.resetToFreshState()
                    }
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primary)
                }
                
                if flowManager.isPossibleReinstall {
                    Text("This will guide you through creating a new account")
                        .healthTextStyle(.caption1, color: HealthColors.tertiaryText, alignment: .center)
                }
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: HealthSpacing.sm) {
            Text("By signing in, you agree to our")
                .healthTextStyle(.caption1, color: HealthColors.tertiaryText)
            
            HStack(spacing: HealthSpacing.xs) {
                Button("Terms of Service") {
                    // Handle terms tap
                }
                .healthTextStyle(.caption1, color: HealthColors.primary)
                
                Text("and")
                    .healthTextStyle(.caption1, color: HealthColors.tertiaryText)
                
                Button("Privacy Policy") {
                    // Handle privacy tap
                }
                .healthTextStyle(.caption1, color: HealthColors.primary)
            }
        }
        .multilineTextAlignment(.center)
    }
    
}

// MARK: - Login Field Enum (Removed)

// LoginField enum removed - no @FocusState for improved stability
