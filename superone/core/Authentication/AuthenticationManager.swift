import SwiftUI
import Foundation
import LocalAuthentication
import Combine

/// Consolidated authentication manager following clean JWT practices
/// Handles email authentication with reactive token management
@MainActor
@Observable
class AuthenticationManager {
    
    // MARK: - Observable Properties
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var currentUser: User?
    var errorMessage: String?
    var showError: Bool = false
    
    // Form data
    var loginForm = LoginFormData()
    
    // MARK: - Private Properties
    private let tokenManager = TokenManager.shared
    private let authAPIService = AuthenticationAPIService()
    private var cancellables = Set<AnyCancellable>()
    
    // Flow manager integration
    private var flowManager: AppFlowManager? {
        return AppFlowManager.shared
    }
    
    // MARK: - Initialization
    init() {
        checkInitialAuthenticationStatus()
    }
    
    // MARK: - Email Authentication
    
    /// Sign in with email and password
    func signInWithEmail() async {
        guard loginForm.isFormValid else {
            validateLoginForm()
            return
        }
        
        // Validate production security
        validateProductionCredentials(email: loginForm.email)
        
        await Task.yield()
        isLoading = true
        clearError()
        
        do {
            // Call login API
            let authResponse = try await authAPIService.login(
                email: loginForm.email,
                password: loginForm.password
            )
            
            guard authResponse.success, let authData = authResponse.data else {
                // CRITICAL: Ensure authentication state is false before throwing
                isAuthenticated = false
                currentUser = nil
                
                throw AuthenticationError.invalidCredentials
            }
            
            // Store tokens using TokenManager (no biometric protection)
            try await tokenManager.storeTokens(
                accessToken: authData.tokens.accessToken,
                refreshToken: authData.tokens.refreshToken
            )
            
            // Update authentication state
            await Task.yield()
            currentUser = authData.user
            isAuthenticated = true
            
            // Notify other components about successful sign in
            NotificationCenter.default.post(name: .userDidSignIn, object: authData.user)
            
            
            // CRITICAL FIX: Explicitly trigger navigation flow update
            flowManager?.completeAuthentication(email: authData.user.email)
            
        } catch {
            
            // CRITICAL: Explicitly set authentication state to false on ANY error
            isAuthenticated = false
            currentUser = nil
            
            handleAuthenticationError(error)
        }
        
        // CRITICAL: Always reset loading state last
        await Task.yield()
        isLoading = false
    }
    
    /// Register new user account
    func registerUser(name: String, email: String, password: String, dateOfBirth: Date?, profile: UserProfile? = nil) async {
        
        isLoading = true
        clearError()
        
        do {
            // Use provided profile or create default profile from registration data
            let userProfile = profile ?? UserProfile(
                dateOfBirth: dateOfBirth,
                gender: nil,
                height: nil,
                weight: nil,
                activityLevel: nil,
                healthGoals: nil,
                medicalConditions: nil,
                medications: nil,
                allergies: nil
            )
            
            
            // Call registration API
            let registrationResponse = try await authAPIService.register(
                email: email,
                password: password,
                name: name,
                profile: userProfile
            )
            
            guard registrationResponse.success, let authData = registrationResponse.data else {
                let errorMessage = registrationResponse.message ?? "Registration failed"
                throw AuthenticationError.registrationFailed
            }
            
            // Store tokens (no biometric protection for now)
            try await tokenManager.storeTokens(
                accessToken: authData.tokens.accessToken,
                refreshToken: authData.tokens.refreshToken
            )
            
            // Update authentication state
            currentUser = authData.user
            isAuthenticated = true
            
            
            // Trigger navigation flow update
            flowManager?.completeAuthentication(email: authData.user.email)
            
        } catch {
            isAuthenticated = false
            currentUser = nil
            handleAuthenticationError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    
    /// Sign out current user with backend API integration
    func signOut(fromAllDevices: Bool = false) async throws {
        
        isLoading = true
        
        var apiError: Error?
        
        do {
            // Call backend logout API first
            let logoutResponse = try await authAPIService.logout(fromCurrentDeviceOnly: !fromAllDevices)
            
            // Log successful logout
            
        } catch {
            // Store API error but don't fail the entire logout process
            apiError = error
        }
        
        // Always clear tokens and local state for security (regardless of API response)
        await tokenManager.clearTokens()
        
        // Clear authentication state
        isAuthenticated = false
        currentUser = nil
        
        // Clear form data for security
        loginForm.password = ""
        
        // Notify other components to clear their data
        await MainActor.run {
            NotificationCenter.default.post(name: .userDidSignOut, object: nil)
        }
        
        
        // Update flow manager
        flowManager?.signOut()
        
        isLoading = false
        
        // If there was an API error, throw it after clearing local state
        if let apiError = apiError {
            throw apiError
        }
    }
    
    /// Sign out from current device only (default behavior)
    func signOutCurrentDevice() async throws {
        try await signOut(fromAllDevices: false)
    }
    
    /// Sign out from all devices
    func signOutAllDevices() async throws {
        try await signOut(fromAllDevices: true)
    }
    
    // MARK: - Authentication Status
    
    func checkInitialAuthenticationStatus() {
        
        // Check if we have stored tokens
        if tokenManager.hasStoredTokens() {
            
            // Attempt automatic token refresh in background
            Task {
                await attemptAutomaticLogin()
            }
        } else {
            // No tokens, user needs to login manually
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    /// Attempt automatic login using stored refresh token
    private func attemptAutomaticLogin() async {
        
        do {
            // Try to refresh tokens
            let refreshedTokens = try await tokenManager.refreshTokensIfNeeded()
            
            // Load user data using available method
            if let currentUser = try? await authAPIService.getCurrentUser() {
                self.currentUser = currentUser
            }
            
            // Update authentication state
            await MainActor.run {
                isAuthenticated = true
                
                // CRITICAL: Trigger navigation to dashboard via flow manager
                flowManager?.completeAuthentication(email: currentUser?.email ?? "auto-login")
            }
            
        } catch {
            
            // CRITICAL FIX: Only clear tokens for authentication failures, not network/server errors
            let shouldClearTokens = isAuthenticationError(error)
            
            if shouldClearTokens {
                await tokenManager.clearTokens()
                
                await MainActor.run {
                    isAuthenticated = false
                    currentUser = nil
                }
            } else {
                
                await MainActor.run {
                    isAuthenticated = false
                    currentUser = nil
                }
            }
            
            // Flow manager will detect this and show appropriate screen (login or retry)
        }
    }
    
    private func loadCurrentUser() async {
        
        guard tokenManager.getAccessToken() != nil else {
            return
        }
        
        do {
            let userProfile = try await authAPIService.getCurrentUser()
            
            await MainActor.run {
                currentUser = userProfile
            }
            
        } catch {
            // Don't fail the entire login process if profile fetch fails
            // Create a minimal user object if needed
        }
    }
    
    // MARK: - Form Validation
    
    private func validateLoginForm() {
        if !loginForm.isEmailValid {
            showError("Please enter a valid email address")
        } else if !loginForm.isPasswordValid {
            showError("Password must be at least 6 characters")
        }
    }
    
    private func validateProductionCredentials(email: String) {
        // Prevent unauthorized access in production
        guard !email.lowercased().contains("test") || AppConfiguration.current.environment.isDevelopment else {
            showError("Test accounts are not allowed in production")
            return
        }
    }
    
    // MARK: - Error Handling
    
    private func handleAuthenticationError(_ error: Error) {
        if let authError = error as? AuthenticationError {
            switch authError {
            case .invalidCredentials:
                showError("Invalid email or password")
            case .accountLocked:
                showError("Account is locked. Please contact support.")
            case .emailNotVerified:
                showError("Please verify your email before signing in")
            case .registrationFailed:
                showError("Registration failed. Please try again.")
            case .twoFactorRequired:
                showError("Two-factor authentication required")
            case .networkError(let message):
                showError("Network error: \(message)")
            case .serverError(let message):
                showError("Server error: \(message)")
            case .validationError(let message):
                showError("Validation error: \(message)")
            case .biometricError(let message):
                showError("Biometric error: \(message)")
            case .tokenExpired:
                showError("Session expired. Please sign in again.")
            case .unknownError:
                showError("An unexpected error occurred")
            case .sessionExpired:
                showError("Session expired. Please sign in again.")
            }
        } else if error is TokenError {
            showError("Authentication token error. Please sign in again.")
        } else if let networkError = error as? NetworkService.NetworkError {
            switch networkError {
            case .noConnection:
                showError("No internet connection available")
            case .partialResponse(let received, let expected):
                let expectedText = expected > 0 ? "\(expected)" : "unknown"
                showError("Response transfer interrupted (\(received)/\(expectedText) bytes). Please try again.")
            case .requestTimeout:
                showError("Request timed out. Please check your connection and try again.")
            case .serverError(let code):
                showError("Server error (Code: \(code)). Please try again later.")
            default:
                showError("Network error: \(networkError.localizedDescription)")
            }
        } else {
            showError("An unexpected error occurred: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func clearError() {
        errorMessage = nil
        showError = false
    }
    
    /// Determine if an error is an authentication failure (requiring token clearing) vs network/server error (preserve tokens)
    private func isAuthenticationError(_ error: Error) -> Bool {
        // Check for explicit authentication errors that require token clearing
        if let authError = error as? AuthenticationError {
            switch authError {
            case .invalidCredentials, .tokenExpired, .sessionExpired, .accountLocked, .emailNotVerified:
                return true
            case .networkError, .serverError, .unknownError:
                return false // Network/server issues - preserve tokens
            default:
                return false
            }
        }
        
        // Check for token-specific errors
        if let tokenError = error as? TokenError {
            switch tokenError {
            case .refreshTokenNotFound, .invalidTokenResponse:
                return true // Token issues require clearing
            case .refreshFailed:
                return false // Could be temporary server issue - preserve tokens for retry
            default:
                return false
            }
        }
        
        // Check for network errors (preserve tokens)
        if let networkError = error as? NetworkService.NetworkError {
            switch networkError {
            case .authenticationRequired:
                return true // 401/403 requires token clearing
            case .noConnection, .requestTimeout, .serverError, .invalidResponse, .partialResponse, .unknownError:
                return false // Network/server issues - preserve tokens
            default:
                return false
            }
        }
        
        // Unknown error types - be conservative and preserve tokens
        return false
    }
}

// MARK: - Supporting Types
// Note: LoginFormData is defined in Features/Authentication/AuthenticationModels.swift

// MARK: - Authentication Errors
// Note: AuthenticationError is defined in Features/Authentication/AuthenticationModels.swift

// MARK: - Notification Names
extension Notification.Name {
    static let userDidSignOut = Notification.Name("userDidSignOut")
    static let userDidSignIn = Notification.Name("userDidSignIn")
}