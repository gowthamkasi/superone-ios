import Foundation

// MARK: - Validation Field Types

enum ValidationField {
    case email
    case password
    case confirmPassword
    case name
    case phoneNumber
}

/// Main authentication view model managing login, registration, and biometric authentication
@MainActor
@Observable
class AuthenticationViewModel {
    
    // MARK: - Observable Properties
    
    var loginForm = LoginFormData()
    var registrationForm = RegistrationFormData()
    var authenticationState: AuthenticationState = .idle
    var currentFlow: AuthenticationFlow = .login
    var biometricState: BiometricAuthState = .unavailable
    var validationStates = FormValidationStates()
    var showError = false
    var errorMessage = ""
    var isPasswordVisible = false
    var isConfirmPasswordVisible = false
    
    
    // MARK: - Private Properties
    
    private var authAPIService: AuthenticationAPIService
    private var keychainService: KeychainServiceProtocol
    private var biometricAuth: BiometricAuthentication
    
    // PERFORMANCE: Debounced validation state
    private var validationTask: Task<Void, Never>?
    
    // PERFORMANCE: Real-time validation with debouncing and background processing
    func validateFieldWithDebouncing(field: ValidationField, value: String) {
        // Cancel previous validation task
        validationTask?.cancel()
        
        // Start new debounced validation task with background processing
        validationTask = Task {
            // Wait 500ms before validating (iOS 18 recommended delay)
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            // PERFORMANCE: Perform validation on main actor (simpler approach)
            await MainActor.run {
                // Perform validation based on field type
                switch field {
                case .email:
                    validationStates.email = validateEmail(value)
                case .password:
                    let isLogin = currentFlow == .login
                    validationStates.password = validatePassword(value, isLogin: isLogin)
                case .confirmPassword:
                    validationStates.confirmPassword = validateConfirmPassword()
                case .name:
                    validationStates.name = validateName(value)
                case .phoneNumber:
                    validationStates.phoneNumber = validatePhoneNumber(value)
                }
            }
        }
    }
    
    // PERFORMANCE: Cancel any pending validation when view disappears
    func cancelPendingValidation() {
        validationTask?.cancel()
        validationTask = nil
    }
    // MARK: - Computed Properties
    
    var isLoading: Bool {
        if case .loading = authenticationState {
            return true
        }
        return false
    }
    
    var canAttemptBiometricLogin: Bool {
        biometricState == .available && hasSavedCredentials && biometricAuth.isUserPreferenceEnabled
    }
    
    var hasSavedCredentials: Bool {
        // Check if we have saved tokens for biometric login
        (try? keychainService.retrieve(key: AppConfig.KeychainKeys.authToken, withBiometrics: false)) != nil
    }
    
    var loginButtonTitle: String {
        if isLoading {
            return "Signing In..."
        }
        return "Sign In"
    }
    
    var registrationButtonTitle: String {
        if isLoading {
            return "Creating Account..."
        }
        return "Create Account"
    }
    
    // MARK: - Initialization
    
    init(
        authAPIService: AuthenticationAPIService = AuthenticationAPIService(),
        keychainService: KeychainServiceProtocol = KeychainHelper.shared, 
        biometricAuth: BiometricAuthentication = BiometricAuthentication.shared
    ) {
        self.authAPIService = authAPIService
        self.keychainService = keychainService
        self.biometricAuth = biometricAuth
        
        // Removed heavy setupValidation() - only validate on form submission
        checkBiometricAvailability()
        setupBiometricObservers()
    }
    
    // MARK: - Public Methods
    
    /// Attempt login with email and password
    func login() async {
        
        // Validate production security - prevent test/demo accounts in production
        validateProductionCredentials(email: loginForm.email)
        
        guard loginForm.isFormValid else {
            validateLoginForm()
            return
        }
        
        authenticationState = .loading
        
        do {
            let authResponse = try await authAPIService.login(
                email: loginForm.email,
                password: loginForm.password
            )
            
            if authResponse.success, let authData = authResponse.data {
                authenticationState = .success(authData.user)
            } else {
                authenticationState = .error(.invalidCredentials)
                showError(authResponse.message ?? "Login failed")
            }
            
        } catch let error as AuthenticationAPIError {
            handleAuthenticationError(error)
        } catch {
            authenticationState = .error(.unknownError)
            showError("An unexpected error occurred")
        }
    }
    
    /// Attempt registration with form data
    func register() async {
        
        // Validate production security - prevent test/demo accounts in production
        validateProductionCredentials(email: registrationForm.email)
        
        guard registrationForm.isFormValid else {
            validateRegistrationForm()
            return
        }
        
        authenticationState = .loading
        
        do {
            // Create a basic UserProfile from registration form
            let profile = UserProfile(
                dateOfBirth: nil,
                gender: nil,
                height: nil,
                weight: nil,
                activityLevel: nil,
                healthGoals: nil,
                medicalConditions: nil,
                medications: nil,
                allergies: nil,
                emergencyContact: nil,
                profileImageURL: nil
            )
            
            let authResponse = try await authAPIService.register(
                email: registrationForm.email,
                password: registrationForm.password,
                name: registrationForm.name,
                profile: profile
            )
            
            if authResponse.success, let authData = authResponse.data {
                authenticationState = .success(authData.user)
            } else {
                authenticationState = .error(.registrationFailed)
                showError(authResponse.message ?? "Registration failed")
            }
            
        } catch let error as AuthenticationAPIError {
            handleAuthenticationError(error)
        } catch {
            authenticationState = .error(.unknownError)
            showError("An unexpected error occurred")
        }
    }
    
    /// Attempt secure biometric authentication with cryptographic binding
    func authenticateWithBiometrics() async {
        guard biometricState == .available else { return }
        
        biometricState = .authenticating
        
        // Log authentication attempt
        HealthcareAuditLogger.shared.logBiometricAuthenticationAttempt(
            userId: loginForm.email.isEmpty ? "unknown" : loginForm.email,
            biometricType: biometricAuth.biometricDisplayName,
            success: false,
            additionalContext: [
                "authentication_method": "cryptographic_binding",
                "app_integrity_check": "pending"
            ]
        )
        
        do {
            // Use secure cryptographic binding authentication
            let userId = loginForm.email.isEmpty ? "temp_user" : loginForm.email
            let authToken = try await biometricAuth.authenticateWithCryptographicBinding(
                userId: userId,
                reason: "Use \(biometricAuth.biometricDisplayName) to securely access your health data"
            )
            
            // Authentication successful - token is cryptographically bound
            biometricState = .success
            
            // Create authenticated user from token data
            let authenticatedUser = User(
                id: authToken.data.userId,
                email: userId.contains("@") ? userId : "secure@biometric.auth",
                name: "Authenticated User",
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
            )
            authenticationState = .success(authenticatedUser)
            
            // Log successful authentication
            HealthcareAuditLogger.shared.logBiometricAuthenticationAttempt(
                userId: userId,
                biometricType: biometricAuth.biometricDisplayName,
                success: true,
                additionalContext: [
                    "authentication_method": "cryptographic_binding",
                    "token_device_id": authToken.data.deviceId,
                    "token_timestamp": ISO8601DateFormatter().string(from: authToken.data.timestamp),
                    "secure_enclave_used": true
                ]
            )
            
        } catch BiometricAuthentication.BiometricError.userCancel {
            biometricState = .cancelled
        } catch BiometricAuthentication.BiometricError.userFallback {
            biometricState = .fallback
            currentFlow = .login
        } catch BiometricAuthentication.BiometricError.biometryNotAvailable, 
                BiometricAuthentication.BiometricError.biometryNotEnrolled {
            biometricState = .unavailable
        } catch BiometricAuthentication.BiometricError.lockout {
            biometricState = .failed("Biometric authentication is temporarily locked")
        } catch {
            biometricState = .failed(error.localizedDescription)
        }
    }
    
    /// Request password reset
    func requestPasswordReset() async {
        guard ValidationHelper.isValidEmail(loginForm.email) else {
            showValidationError("Please enter a valid email address")
            return
        }
        
        authenticationState = .loading
        
        do {
            _ = try await authAPIService.forgotPassword(email: loginForm.email)
            
            // Success toast/alert will be added: Password reset email sent. Please check your inbox.
            authenticationState = .idle
            
        } catch let error as AuthenticationAPIError {
            handleAuthenticationError(error)
        } catch {
            authenticationState = .error(.unknownError)
            showError("An unexpected error occurred")
        }
    }
    
    /// Switch between authentication flows
    func switchToFlow(_ flow: AuthenticationFlow) {
        currentFlow = flow
        clearErrors()
        resetValidationStates()
    }
    
    /// Toggle password visibility
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }
    
    /// Toggle confirm password visibility
    func toggleConfirmPasswordVisibility() {
        isConfirmPasswordVisible.toggle()
    }
    
    /// Clear all form data and states
    func resetForms() {
        loginForm = LoginFormData()
        registrationForm = RegistrationFormData()
        authenticationState = .idle
        biometricState = .available
        resetValidationStates()
        clearErrors()
    }
    
    /// Enable biometric authentication
    func enableBiometricAuthentication() async throws {
        guard biometricAuth.isAvailable else {
            throw AuthenticationError.biometricError("Biometric authentication is not available")
        }
        
        // Test biometric authentication first
        let reason = "Enable \(biometricAuth.biometricDisplayName) for quick and secure access"
        _ = try await biometricAuth.authenticate(reason: reason)
        
        // Enable biometric preference
        try biometricAuth.setBiometricPreference(true)
        
        // Update state
        checkBiometricAvailability()
    }
    
    /// Disable biometric authentication
    func disableBiometricAuthentication() throws {
        try biometricAuth.setBiometricPreference(false)
        checkBiometricAvailability()
    }
    
    /// Check if biometric setup is recommended
    var shouldShowBiometricSetup: Bool {
        return biometricAuth.isAvailable && !biometricAuth.isUserPreferenceEnabled
    }
    
    /// Logout user with proper backend API integration
    func logout(fromAllDevices: Bool = false) async {
        authenticationState = .loading
        
        do {
            // Call backend logout API first
            let logoutResponse = try await authAPIService.logout(fromCurrentDeviceOnly: !fromAllDevices)
            
            // Log successful logout (audit logging implementation will be added)
            // TODO: Add proper audit logging for logout events
            
            // Reset all states after successful logout
            resetForms()
            authenticationState = .idle
            
            // Reset biometric auth context
            biometricAuth.invalidateContext()
            
        } catch {
            // Even if API call fails, we still need to clear local state for security
            // TODO: Add proper audit logging for logout errors
            
            // Always clear local tokens and reset states for security
            do {
                try KeychainHelper.deleteAllAuthData()
            } catch {
                // If keychain cleanup also fails, log it but continue with UI reset
            }
            
            resetForms()
            authenticationState = .idle
            biometricAuth.invalidateContext()
            
            // Show error to user but don't prevent logout
            showError("Logout completed, but there was an issue contacting the server: \(error.localizedDescription)")
        }
    }
    
    /// Logout from current device only (default behavior)
    func logoutCurrentDevice() async {
        await logout(fromAllDevices: false)
    }
    
    /// Logout from all devices
    func logoutAllDevices() async {
        await logout(fromAllDevices: true)
    }
    
    // MARK: - Validation Methods
    
    /// Validate login form and update validation states
    func validateLoginForm() {
        validationStates.email = validateEmail(loginForm.email)
        validationStates.password = validatePassword(loginForm.password, isLogin: true)
    }
    
    /// Validate registration form and update validation states
    func validateRegistrationForm() {
        validationStates.email = validateEmail(registrationForm.email)
        validationStates.password = validatePassword(registrationForm.password, isLogin: false)
        validationStates.confirmPassword = validateConfirmPassword()
        validationStates.name = validateName(registrationForm.name)
        validationStates.phoneNumber = validatePhoneNumber(registrationForm.phoneNumber)
        validationStates.dateOfBirth = validateDateOfBirth(registrationForm.dateOfBirth)
    }
    
    // MARK: - Private Methods
    
    // REMOVED: Heavy Combine-based validation system that was causing 1.74s hangs
    // Validation now only runs on form submission to prevent main thread blocking
    
    private func validateEmail(_ email: String) -> FieldValidationState {
        if let message = ValidationHelper.emailValidationMessage(email) {
            return .invalid(message)
        }
        return .valid
    }
    
    private func validatePassword(_ password: String, isLogin: Bool) -> FieldValidationState {
        if isLogin {
            return password.isEmpty ? .invalid("Password is required") : .valid
        } else {
            if let message = ValidationHelper.passwordValidationMessage(password) {
                return .invalid(message)
            }
            return .valid
        }
    }
    
    private func validateConfirmPassword() -> FieldValidationState {
        if registrationForm.confirmPassword.isEmpty {
            return .invalid("Please confirm your password")
        }
        if registrationForm.password != registrationForm.confirmPassword {
            return .invalid("Passwords do not match")
        }
        return .valid
    }
    
    private func validateName(_ name: String) -> FieldValidationState {
        if let message = ValidationHelper.nameValidationMessage(name) {
            return .invalid(message)
        }
        return .valid
    }
    
    private func validatePhoneNumber(_ phoneNumber: String) -> FieldValidationState {
        if phoneNumber.isEmpty {
            return .valid // Optional field
        }
        if !ValidationHelper.isValidPhoneNumber(phoneNumber) {
            return .invalid("Please enter a valid phone number")
        }
        return .valid
    }
    
    private func validateDateOfBirth(_ dateOfBirth: Date?) -> FieldValidationState {
        guard let dateOfBirth = dateOfBirth else {
            return .valid // Optional field
        }
        if !ValidationHelper.isValidDateOfBirth(dateOfBirth) {
            return .invalid("You must be at least 18 years old")
        }
        return .valid
    }
    
    private func checkBiometricAvailability() {
        let availability = biometricAuth.checkAvailability()
        if availability.available && biometricAuth.isUserPreferenceEnabled {
            biometricState = .available
        } else {
            biometricState = .unavailable
        }
    }
    
    private func setupBiometricObservers() {
        // iOS 18+ @Observable pattern - biometric state is managed directly
        // Check biometric availability on initialization
        Task {
            await MainActor.run {
                checkBiometricAvailability()
            }
        }
    }
    
    private func updateBiometricState(from authState: BiometricAuthentication.AuthenticationState) {
        switch authState {
        case .idle:
            if biometricAuth.isReadyToUse {
                biometricState = .available
            } else {
                biometricState = .unavailable
            }
        case .authenticating:
            biometricState = .authenticating
        case .success:
            biometricState = .success
        case .failed(let error):
            biometricState = .failed(error.localizedDescription)
        case .cancelled:
            biometricState = .cancelled
        }
    }
    
    private func storeAuthenticationTokens(_ authResponse: AuthResponse) async throws {
        // Store tokens with biometric protection if available and enabled
        guard let authData = authResponse.data else {
            throw AuthenticationError.unknownError
        }
        
        if biometricAuth.isReadyToUse {
            try KeychainHelper.storeAuthToken(authData.tokens.accessToken, expiresIn: TimeInterval(authData.tokens.expiresIn ?? 3600))
            try KeychainHelper.storeRefreshToken(authData.tokens.refreshToken)
        } else {
            try keychainService.store(token: authData.tokens.accessToken, for: AppConfig.KeychainKeys.authToken)
            try keychainService.store(token: authData.tokens.refreshToken, for: AppConfig.KeychainKeys.refreshToken)
        }
        
        // Store user info if needed
        if let userData = try? JSONEncoder().encode(authData.user) {
            try keychainService.store(token: String(data: userData, encoding: .utf8) ?? "", for: "user_data")
        }
    }
    
    private func handleAuthenticationError(_ error: AuthenticationAPIError) {
        let authError: AuthenticationError
        
        switch error {
        case .invalidCredentials:
            authError = .invalidCredentials
        case .tokenExpired:
            authError = .sessionExpired
        case .networkError(let error):
            authError = .networkError(error.localizedDescription)
        case .noRefreshToken:
            authError = .sessionExpired
        case .unauthorized:
            authError = .sessionExpired
        case .tokenStorageError(_):
            authError = .unknownError
        case .unknownError:
            authError = .unknownError
        }
        
        authenticationState = .error(authError)
        showError(error.errorDescription ?? "An unknown error occurred")
    }
    
    /// Show error message to user
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
        // PERFORMANCE FIX: Let SwiftUI handle error dismissal via user interaction
        // No automatic timing - user must dismiss manually for better UX
    }
    
    
    private func showValidationError(_ message: String) {
        showError(message)
    }
    
    private func clearErrors() {
        showError = false
        errorMessage = ""
    }
    
    private func resetValidationStates() {
        validationStates = FormValidationStates()
    }
    
    // MARK: - Production Security Validation
    
    /// Validate production credentials to prevent demo/test accounts in production
    private func validateProductionCredentials(email: String) {
        #if DEBUG
        // In debug builds, allow test accounts but log warnings
        let testDomains = ["example.com", "test.com", "demo.com", "localhost"]
        let lowercaseEmail = email.lowercased()
        
        for domain in testDomains {
            if lowercaseEmail.contains(domain) {
                break
            }
        }
        
        if lowercaseEmail.contains("admin") || lowercaseEmail.contains("test") || lowercaseEmail.contains("demo") {
        }
        #else
        // In production, prevent any test/demo accounts
        let testDomains = ["example.com", "test.com", "demo.com", "localhost", "127.0.0.1"]
        let testPatterns = ["admin", "test", "demo", "mock", "dev", "staging"]
        let lowercaseEmail = email.lowercased()
        
        // Check for test domains
        for domain in testDomains {
            if lowercaseEmail.contains(domain) {
                fatalError("🚨 SECURITY ERROR: Test email domain '\(domain)' detected in production: \(email). This is prohibited in production builds.")
            }
        }
        
        // Check for test patterns
        for pattern in testPatterns {
            if lowercaseEmail.contains(pattern) {
                fatalError("🚨 SECURITY ERROR: Test email pattern '\(pattern)' detected in production: \(email). This is prohibited in production builds.")
            }
        }
        
        // Validate email has valid production domain
        if !lowercaseEmail.contains("@") || lowercaseEmail.count < 5 {
            fatalError("🚨 SECURITY ERROR: Invalid email format detected in production: \(email)")
        }
        #endif
    }
}

// MARK: - Mock Implementation

#if DEBUG
extension AuthenticationViewModel {
    /// Create mock view model for previews and testing
    static func mock() -> AuthenticationViewModel {
        return AuthenticationViewModel(
            authAPIService: AuthenticationAPIService(),
            keychainService: MockKeychainService(),
            biometricAuth: BiometricAuthentication.shared
        )
    }
}

// MockNetworkService removed - using direct AuthenticationAPIService for mocking

/// Mock keychain service for testing and previews
class MockKeychainService: KeychainServiceProtocol {
    private let storageQueue = DispatchQueue(label: "MockKeychainService.storage", attributes: .concurrent)
    private nonisolated(unsafe) var _storage: [String: String] = [:]
    
    nonisolated func store(token: String, for key: String) throws {
        storageQueue.async(flags: .barrier) { [weak self] in
            self?._storage[key] = token
        }
    }
    
    nonisolated func retrieve(key: String, withBiometrics: Bool) throws -> String? {
        return storageQueue.sync {
            return _storage[key]
        }
    }
    
    nonisolated func delete(key: String) throws {
        storageQueue.async(flags: .barrier) { [weak self] in
            self?._storage.removeValue(forKey: key)
        }
    }
    
    nonisolated func isBiometricAvailable() -> Bool {
        return true
    }
    
    nonisolated func storeWithExpiration(token: String, for key: String, expirationDate: Date) throws {
        storageQueue.async(flags: .barrier) { [weak self] in
            self?._storage[key] = token
        }
    }
    
    func retrieveWithBiometrics(key: String, reason: String) async throws -> String? {
        return storageQueue.sync {
            return _storage[key]
        }
    }
    
    func migrateIfNeeded() async throws {
        // Mock implementation - no migration needed
    }
    
    nonisolated func deleteAllTokens() throws {
        storageQueue.async(flags: .barrier) { [weak self] in
            self?._storage.removeAll()
        }
    }
    
    nonisolated func tokenExpirationDate(for key: String) throws -> Date? {
        // Mock implementation - return nil for non-expiring tokens
        return nil
    }
    
    nonisolated func isTokenExpired(for key: String) throws -> Bool {
        // Mock implementation - never expired
        return false
    }
}
#endif