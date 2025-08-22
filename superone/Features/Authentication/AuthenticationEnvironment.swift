import SwiftUI
import Foundation

// MARK: - Authentication Context

/// Comprehensive authentication context for iOS 18+ environment integration
/// Uses @Entry macro for clean environment access throughout the app
struct AuthenticationContext {
    let state: AuthenticationState
    let flow: AuthenticationFlow
    let biometricState: BiometricAuthState
    let currentUser: User?
    let isAuthenticated: Bool
    let biometricEnabled: Bool
    let sessionExpiryDate: Date?
    let loginAttempts: Int
    let isLocked: Bool
    
    /// Default authentication context for unauthenticated state
    static let `default` = AuthenticationContext(
        state: .idle,
        flow: .login,
        biometricState: .unavailable,
        currentUser: nil,
        isAuthenticated: false,
        biometricEnabled: false,
        sessionExpiryDate: nil,
        loginAttempts: 0,
        isLocked: false
    )
    
    /// Create authenticated context
    static func authenticated(
        user: User,
        sessionExpiryDate: Date? = nil,
        biometricEnabled: Bool = false
    ) -> AuthenticationContext {
        return AuthenticationContext(
            state: .success(user),
            flow: .login,
            biometricState: biometricEnabled ? .available : .unavailable,
            currentUser: user,
            isAuthenticated: true,
            biometricEnabled: biometricEnabled,
            sessionExpiryDate: sessionExpiryDate,
            loginAttempts: 0,
            isLocked: false
        )
    }
    
    /// Create error context
    static func error(
        _ error: AuthenticationError,
        flow: AuthenticationFlow = .login,
        attempts: Int = 0
    ) -> AuthenticationContext {
        AuthenticationContext(
            state: .error(error),
            flow: flow,
            biometricState: .unavailable,
            currentUser: nil,
            isAuthenticated: false,
            biometricEnabled: false,
            sessionExpiryDate: nil,
            loginAttempts: attempts,
            isLocked: attempts >= AuthenticationUIConfig.maxLoginAttempts
        )
    }
    
    /// Create loading context
    static func loading(
        flow: AuthenticationFlow = .login,
        biometricState: BiometricAuthState = .unavailable
    ) -> AuthenticationContext {
        AuthenticationContext(
            state: .loading,
            flow: flow,
            biometricState: biometricState,
            currentUser: nil,
            isAuthenticated: false,
            biometricEnabled: false,
            sessionExpiryDate: nil,
            loginAttempts: 0,
            isLocked: false
        )
    }
}

// MARK: - Authentication Actions

/// Authentication actions available through environment
struct AuthenticationActions {
    let login: (LoginFormData) async -> Void
    let register: (RegistrationFormData) async -> Void
    let logout: () async -> Void
    let biometricLogin: () async -> Void
    let resetPassword: (String) async -> Void
    let verifyEmail: (String) async -> Void
    let refreshToken: () async -> Void
    let updateProfile: (User) async -> Void
    let enableBiometric: () async -> Void
    let disableBiometric: () async -> Void
    
    /// Default actions (no-op implementations for initial state)
    static let `default` = AuthenticationActions(
        login: { _ in },
        register: { _ in },
        logout: { },
        biometricLogin: { },
        resetPassword: { _ in },
        verifyEmail: { _ in },
        refreshToken: { },
        updateProfile: { _ in },
        enableBiometric: { },
        disableBiometric: { }
    )
}

// MARK: - Authentication Configuration

/// Configuration for authentication behavior and UI
struct AuthenticationConfiguration {
    let biometricConfig: BiometricConfig
    let uiConfig: AuthenticationUIConfig
    let securitySettings: SecuritySettings
    let featureFlags: AuthenticationFeatureFlags
    
    /// Default authentication configuration
    static let `default` = AuthenticationConfiguration(
        biometricConfig: BiometricConfig(),
        uiConfig: AuthenticationUIConfig(),
        securitySettings: SecuritySettings(),
        featureFlags: AuthenticationFeatureFlags()
    )
}

// MARK: - Security Settings

struct SecuritySettings {
    let passwordPolicy: PasswordPolicy
    let sessionTimeout: TimeInterval
    let maxLoginAttempts: Int
    let lockoutDuration: TimeInterval
    let requireBiometricReauth: Bool
    let enableSecurityNotifications: Bool
    
    init(
        passwordPolicy: PasswordPolicy = .default,
        sessionTimeout: TimeInterval = 3600, // 1 hour
        maxLoginAttempts: Int = 5,
        lockoutDuration: TimeInterval = 300, // 5 minutes
        requireBiometricReauth: Bool = false,
        enableSecurityNotifications: Bool = true
    ) {
        self.passwordPolicy = passwordPolicy
        self.sessionTimeout = sessionTimeout
        self.maxLoginAttempts = maxLoginAttempts
        self.lockoutDuration = lockoutDuration
        self.requireBiometricReauth = requireBiometricReauth
        self.enableSecurityNotifications = enableSecurityNotifications
    }
}

// MARK: - Password Policy

struct PasswordPolicy {
    let minLength: Int
    let requireUppercase: Bool
    let requireLowercase: Bool
    let requireNumbers: Bool
    let requireSpecialCharacters: Bool
    let preventCommonPasswords: Bool
    
    static let `default` = PasswordPolicy(
        minLength: 8,
        requireUppercase: true,
        requireLowercase: true,
        requireNumbers: true,
        requireSpecialCharacters: false,
        preventCommonPasswords: true
    )
    
    static let strict = PasswordPolicy(
        minLength: 12,
        requireUppercase: true,
        requireLowercase: true,
        requireNumbers: true,
        requireSpecialCharacters: true,
        preventCommonPasswords: true
    )
}

// MARK: - Authentication Feature Flags

struct AuthenticationFeatureFlags {
    let enableBiometricAuth: Bool
    let enableSocialLogin: Bool
    let enableTwoFactorAuth: Bool
    let enablePasswordStrengthMeter: Bool
    let enableSecurityQuestions: Bool
    let enableAccountRecovery: Bool
    let enableSessionManagement: Bool
    
    init(
        enableBiometricAuth: Bool = true,
        enableSocialLogin: Bool = false,
        enableTwoFactorAuth: Bool = false,
        enablePasswordStrengthMeter: Bool = true,
        enableSecurityQuestions: Bool = false,
        enableAccountRecovery: Bool = true,
        enableSessionManagement: Bool = true
    ) {
        self.enableBiometricAuth = enableBiometricAuth
        self.enableSocialLogin = enableSocialLogin
        self.enableTwoFactorAuth = enableTwoFactorAuth
        self.enablePasswordStrengthMeter = enablePasswordStrengthMeter
        self.enableSecurityQuestions = enableSecurityQuestions
        self.enableAccountRecovery = enableAccountRecovery
        self.enableSessionManagement = enableSessionManagement
    }
}

// MARK: - Authentication Session

/// Session information for authenticated users
struct AuthenticationSession {
    let user: User
    let token: String
    let refreshToken: String
    let expiresAt: Date
    let biometricEnabled: Bool
    let deviceId: String
    let lastActivity: Date
    let ipAddress: String?
    let userAgent: String?
    
    /// Check if session is expired
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    /// Check if session needs refresh (expires within 5 minutes)
    var needsRefresh: Bool {
        Date().addingTimeInterval(300) > expiresAt
    }
    
    /// Time until session expires
    var timeUntilExpiry: TimeInterval {
        expiresAt.timeIntervalSince(Date())
    }
}

// MARK: - iOS 18+ Environment Integration with @Entry Macro

extension EnvironmentValues {
    /// Authentication context environment value using iOS 18+ @Entry macro
    @Entry var authenticationContext: AuthenticationContext = .default
    
    /// Authentication actions environment value
    @Entry var authenticationActions: AuthenticationActions = .default
    
    /// Authentication configuration environment value
    @Entry var authenticationConfiguration: AuthenticationConfiguration = .default
}

// MARK: - Authentication Environment Modifiers

extension View {
    /// Apply authentication environment with context
    func authenticationEnvironment(
        context: AuthenticationContext = .default,
        actions: AuthenticationActions = .default,
        configuration: AuthenticationConfiguration = .default
    ) -> some View {
        self
            .environment(\.authenticationContext, context)
            .environment(\.authenticationActions, actions)
            .environment(\.authenticationConfiguration, configuration)
    }
    
    /// Apply authenticated user environment
    func authenticatedEnvironment(
        user: User,
        actions: AuthenticationActions,
        biometricEnabled: Bool = false
    ) -> some View {
        let context = AuthenticationContext.authenticated(
            user: user,
            biometricEnabled: biometricEnabled
        )
        return self.authenticationEnvironment(
            context: context,
            actions: actions
        )
    }
    
    /// Apply authentication loading environment
    func authenticationLoadingEnvironment(
        flow: AuthenticationFlow = .login,
        biometricState: BiometricAuthState = .unavailable
    ) -> some View {
        let context = AuthenticationContext.loading(
            flow: flow,
            biometricState: biometricState
        )
        return self.authenticationEnvironment(context: context)
    }
    
    /// Apply authentication error environment
    func authenticationErrorEnvironment(
        error: AuthenticationError,
        flow: AuthenticationFlow = .login,
        attempts: Int = 0
    ) -> some View {
        let context = AuthenticationContext.error(
            error,
            flow: flow,
            attempts: attempts
        )
        return self.authenticationEnvironment(context: context)
    }
}

// MARK: - Authentication State Helpers

extension AuthenticationContext {
    /// Check if user can attempt login
    var canAttemptLogin: Bool {
        !isLocked && loginAttempts < AuthenticationUIConfig.maxLoginAttempts
    }
    
    /// Check if biometric authentication is available and enabled
    var canUseBiometric: Bool {
        biometricEnabled && (biometricState == .available || biometricState == .success)
    }
    
    /// Check if session is valid and not expired
    var hasValidSession: Bool {
        guard isAuthenticated, let expiryDate = sessionExpiryDate else {
            return false
        }
        return Date() < expiryDate
    }
    
    /// Get user display name or fallback
    var userDisplayName: String {
        currentUser?.name ?? currentUser?.email ?? "User"
    }
    
    /// Check if user needs to complete profile
    var needsProfileCompletion: Bool {
        guard let user = currentUser else { return false }
        return user.name.isEmpty || user.profile?.dateOfBirth == nil
    }
}

// MARK: - Authentication View Helpers

extension View {
    /// Show content only if authenticated
    @ViewBuilder
    func requiresAuthentication<Content: View>(
        @ViewBuilder fallback: @escaping () -> Content = { EmptyView() }
    ) -> some View {
        AuthenticationGatedView(
            content: { self },
            fallback: fallback
        )
    }
    
    /// Show content only if NOT authenticated
    @ViewBuilder
    func requiresUnauthenticated<Content: View>(
        @ViewBuilder fallback: @escaping () -> Content = { EmptyView() }
    ) -> some View {
        UnauthenticatedGatedView(
            content: { self },
            fallback: fallback
        )
    }
}

// MARK: - Authentication Gating Views

struct AuthenticationGatedView<Content: View, Fallback: View>: View {
    @Environment(\.authenticationContext) private var authContext
    let content: () -> Content
    let fallback: () -> Fallback
    
    var body: some View {
        if authContext.isAuthenticated && authContext.hasValidSession {
            content()
        } else {
            fallback()
        }
    }
}

struct UnauthenticatedGatedView<Content: View, Fallback: View>: View {
    @Environment(\.authenticationContext) private var authContext
    let content: () -> Content
    let fallback: () -> Fallback
    
    var body: some View {
        if !authContext.isAuthenticated {
            content()
        } else {
            fallback()
        }
    }
}

// MARK: - Extensions (BiometricConfig and AuthenticationUIConfig use synthesized initializers)

// MARK: - Preview Helpers

#if DEBUG
extension AuthenticationContext {
    /// Preview context for authenticated user
    static let authenticatedPreview = AuthenticationContext.authenticated(
        user: User(
            id: "preview_user",
            email: "user@example.com",
            name: "Preview User",
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
        ),
        biometricEnabled: true
    )
    
    /// Preview context for loading state
    static let loadingPreview = AuthenticationContext.loading(
        flow: .login,
        biometricState: .authenticating
    )
    
    /// Preview context for error state
    static let errorPreview = AuthenticationContext.error(
        .invalidCredentials,
        attempts: 2
    )
}
#endif