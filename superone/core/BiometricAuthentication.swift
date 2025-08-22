import Foundation
import LocalAuthentication
import Combine
import UIKit
import CryptoKit

/// Enhanced biometric authentication manager with cryptographic security
/// Implements healthcare-grade security with Secure Enclave integration
class BiometricAuthentication: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAvailable = false
    @Published var biometryType: LABiometryType = .none
    @Published var isEnrolled = false
    @Published var lastAuthenticationDate: Date?
    @Published var authenticationState: AuthenticationState = .idle
    
    // MARK: - Authentication State
    enum AuthenticationState {
        case idle
        case authenticating
        case success
        case failed(Error)
        case cancelled
    }
    
    // MARK: - Error Types
    enum BiometricError: Error, @preconcurrency LocalizedError {
        case notAvailable
        case noFingerprintEnrolled
        case noFaceIDEnrolled
        case authenticationFailed
        case userCancel
        case userFallback
        case systemCancel
        case lockout
        case appCancel
        case invalidContext
        case biometryNotAvailable
        case biometryNotEnrolled
        case passcodeNotSet
        case touchIDNotAvailable
        case touchIDNotEnrolled
        case faceIDNotAvailable
        case faceIDNotEnrolled
        case biometryLockout
        case notInteractive
        case integrityCompromised
        case secureEnclaveError
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device"
            case .noFingerprintEnrolled:
                return "No fingerprints are enrolled. Please add a fingerprint in Settings"
            case .noFaceIDEnrolled:
                return "Face ID is not set up. Please set up Face ID in Settings"
            case .authenticationFailed:
                return "Biometric authentication failed"
            case .userCancel:
                return "Authentication was cancelled by user"
            case .userFallback:
                return "User selected fallback authentication method"
            case .systemCancel:
                return "Authentication was cancelled by system"
            case .lockout:
                return "Biometric authentication is locked out due to too many failed attempts"
            case .appCancel:
                return "Authentication was cancelled by the app"
            case .invalidContext:
                return "Authentication context is invalid"
            case .biometryNotAvailable:
                return "Biometric authentication is not available"
            case .biometryNotEnrolled:
                return "No biometric data is enrolled"
            case .passcodeNotSet:
                return "Passcode is not set on the device"
            case .touchIDNotAvailable:
                return "Touch ID is not available on this device"
            case .touchIDNotEnrolled:
                return "No fingerprints are enrolled for Touch ID"
            case .faceIDNotAvailable:
                return "Face ID is not available on this device"
            case .faceIDNotEnrolled:
                return "Face ID is not enrolled"
            case .biometryLockout:
                return "Biometric authentication is temporarily locked"
            case .notInteractive:
                return "Authentication is not interactive"
            case .integrityCompromised:
                return "App integrity has been compromised - authentication disabled for security"
            case .secureEnclaveError:
                return "Secure hardware authentication failed"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .noFingerprintEnrolled, .touchIDNotEnrolled:
                return "Add a fingerprint in Settings > Touch ID & Passcode"
            case .noFaceIDEnrolled, .faceIDNotEnrolled:
                return "Set up Face ID in Settings > Face ID & Passcode"
            case .passcodeNotSet:
                return "Set up a passcode in Settings > Face ID & Passcode"
            case .lockout, .biometryLockout:
                return "Try again later or use your passcode"
            case .integrityCompromised:
                return "Please restart the app and ensure your device hasn't been modified"
            case .secureEnclaveError:
                return "Please try again or contact support if this issue persists"
            default:
                return nil
            }
        }
    }
    
    // MARK: - Singleton
    static let shared = BiometricAuthentication()
    
    // MARK: - Private Properties
    private let context = LAContext()
    private var authenticationPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
    private let queue = DispatchQueue(label: "biometric.queue", qos: .userInitiated)
    private let secureEnclaveManager = SecureEnclaveManager.shared
    private let integrityValidator = AppIntegrityValidator.shared
    
    // MARK: - Configuration
    private var maxRetryAttempts = 3
    private var retryDelay: TimeInterval = 2.0
    private var currentRetryAttempt = 0
    
    // MARK: - Initialization
    private init() {
        updateBiometricInfo()
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Update biometric availability information
    func updateBiometricInfo() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let context = LAContext()
            var error: NSError?
            
            let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            let enrolled = available && error == nil
            
            // PERFORMANCE FIX: Use Task instead of DispatchQueue for better concurrency
            Task { @MainActor in
                self.isAvailable = available
                self.biometryType = context.biometryType
                self.isEnrolled = enrolled
            }
        }
    }
    
    /// Authenticate with biometrics using cryptographic binding (SECURE METHOD)
    /// This method replaces boolean authentication with cryptographically-bound tokens
    func authenticateWithCryptographicBinding(userId: String, reason: String = "Authenticate to access your secure health data") async throws -> BiometricAuthToken {
        await MainActor.run {
            authenticationState = .authenticating
        }
        
        // First perform app integrity validation
        do {
            let integrityResult = try await integrityValidator.validateAppIntegrity()
            if !integrityResult.overallIntegrity {
                await MainActor.run {
                    authenticationState = .failed(BiometricError.integrityCompromised)
                }
                throw BiometricError.integrityCompromised
            }
        } catch {
            await MainActor.run {
                authenticationState = .failed(error)
            }
            throw error
        }
        
        // Perform cryptographically-bound authentication
        do {
            let authToken = try await secureEnclaveManager.createBiometricAuthenticationToken(userId: userId)
            
            await MainActor.run {
                authenticationState = .success
                lastAuthenticationDate = Date()
            }
            
            return authToken
            
        } catch {
            let biometricError = mapSecureEnclaveError(error)
            await MainActor.run {
                authenticationState = .failed(biometricError)
            }
            throw biometricError
        }
    }
    
    /// Validate existing biometric authentication token (SECURE METHOD)
    func validateBiometricToken(userId: String) async throws -> BiometricAuthToken {
        await MainActor.run {
            authenticationState = .authenticating
        }
        
        do {
            let validToken = try await secureEnclaveManager.validateBiometricAuthenticationToken(userId: userId)
            
            await MainActor.run {
                authenticationState = .success
                lastAuthenticationDate = Date()
            }
            
            return validToken
            
        } catch {
            let biometricError = mapSecureEnclaveError(error)
            await MainActor.run {
                authenticationState = .failed(biometricError)
            }
            throw biometricError
        }
    }
    
    /// DEPRECATED: Boolean-based authentication (vulnerable to manipulation)
    /// Use authenticateWithCryptographicBinding instead
    @available(*, deprecated, message: "Use authenticateWithCryptographicBinding for secure authentication")
    func authenticate(reason: String, policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics) async throws -> Bool {
        await MainActor.run {
            authenticationState = .authenticating
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                self?.performAuthentication(reason: reason, policy: policy, continuation: continuation)
            }
        }
    }
    
    /// Authenticate with retry logic
    func authenticateWithRetry(reason: String, maxRetries: Int = 3) async throws -> Bool {
        currentRetryAttempt = 0
        
        while currentRetryAttempt < maxRetries {
            do {
                let result = try await authenticate(reason: reason)
                currentRetryAttempt = 0 // Reset on success
                return result
            } catch BiometricError.userCancel {
                throw BiometricError.userCancel
            } catch BiometricError.lockout {
                throw BiometricError.lockout
            } catch {
                currentRetryAttempt += 1
                
                if currentRetryAttempt >= maxRetries {
                    throw error
                }
                
                // Wait before retry
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            }
        }
        
        throw BiometricError.authenticationFailed
    }
    
    /// Check if biometric authentication is available and configured
    func checkAvailability() -> (available: Bool, error: BiometricError?) {
        let context = LAContext()
        var nsError: NSError?
        
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &nsError)
        
        if let error = nsError {
            let biometricError = mapLAError(error)
            return (false, biometricError)
        }
        
        return (canEvaluate, nil)
    }
    
    /// Get biometric type display name
    var biometricDisplayName: String {
        switch biometryType {
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
    
    /// Check if user has biometric preference enabled
    var isUserPreferenceEnabled: Bool {
        return KeychainHelper.getBiometricPreference()
    }
    
    /// Enable or disable biometric preference
    func setBiometricPreference(_ enabled: Bool) throws {
        try KeychainHelper.storeBiometricPreference(enabled)
    }
    
    /// Invalidate current authentication context
    func invalidateContext() {
        context.invalidate()
        
        // PERFORMANCE FIX: Use Task instead of DispatchQueue
        Task { @MainActor [weak self] in
            self?.authenticationState = .idle
        }
    }
    
    // MARK: - Private Methods
    
    nonisolated private func performAuthentication(
        reason: String,
        policy: LAPolicy,
        continuation: CheckedContinuation<Bool, Error>
    ) {
        let context = LAContext()
        
        // Configure context
        context.localizedFallbackTitle = "Use Passcode"
        context.localizedCancelTitle = "Cancel"
        
        // Check availability first
        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            let biometricError = error.map(mapLAError) ?? BiometricError.notAvailable
            
            // PERFORMANCE FIX: Use Task instead of DispatchQueue
            Task { @MainActor [weak self] in
                self?.authenticationState = .failed(biometricError)
            }
            
            continuation.resume(throwing: biometricError)
            return
        }
        
        // Perform authentication
        context.evaluatePolicy(policy, localizedReason: reason) { [weak self] success, error in
            // PERFORMANCE FIX: Use Task instead of DispatchQueue
            Task { @MainActor in
                if success {
                    self?.authenticationState = .success
                    self?.lastAuthenticationDate = Date()
                    continuation.resume(returning: true)
                } else if let error = error {
                    let biometricError = self?.mapLAError(error as NSError) ?? BiometricError.authenticationFailed
                    self?.authenticationState = .failed(biometricError)
                    continuation.resume(throwing: biometricError)
                } else {
                    let unknownError = BiometricError.authenticationFailed
                    self?.authenticationState = .failed(unknownError)
                    continuation.resume(throwing: unknownError)
                }
            }
        }
    }
    
    nonisolated private func mapLAError(_ error: NSError) -> BiometricError {
        guard let laError = LAError.Code(rawValue: error.code) else {
            return .authenticationFailed
        }
        
        switch laError {
        case .appCancel:
            return .appCancel
        case .authenticationFailed:
            return .authenticationFailed
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .notInteractive
        case .passcodeNotSet:
            return .passcodeNotSet
        case .systemCancel:
            return .systemCancel
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .biometryLockout:
            return .biometryLockout
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .touchIDLockout:
            return .lockout
        case .touchIDNotAvailable:
            return .touchIDNotAvailable
        case .touchIDNotEnrolled:
            return .touchIDNotEnrolled
        case .companionNotAvailable:
            return .biometryNotAvailable
        @unknown default:
            return .authenticationFailed
        }
    }
    
    /// Map Secure Enclave errors to biometric errors
    private func mapSecureEnclaveError(_ error: Error) -> BiometricError {
        if let secureEnclaveError = error as? SecureEnclaveError {
            switch secureEnclaveError {
            case .userCancelled:
                return .userCancel
            case .authenticationFailed:
                return .authenticationFailed
            case .secureEnclaveNotAvailable:
                return .secureEnclaveError
            case .tokenExpired:
                return .authenticationFailed
            case .deviceMismatch:
                return .secureEnclaveError
            default:
                return .secureEnclaveError
            }
        } else if let laError = error as? LAError {
            return mapLAError(laError as NSError)
        } else {
            return .authenticationFailed
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidBecomeActive() {
        updateBiometricInfo()
    }
    
    @objc private func applicationWillResignActive() {
        invalidateContext()
    }
}

// MARK: - Convenience Methods
extension BiometricAuthentication {
    
    /// Quick check if biometrics are ready to use with Secure Enclave
    var isReadyToUse: Bool {
        return isAvailable && isEnrolled && isUserPreferenceEnabled && secureEnclaveManager.isReadyForBiometricAuth
    }
    
    /// Check if secure biometric authentication is available
    var isSecureAuthenticationAvailable: Bool {
        return isReadyToUse && integrityValidator.isIntegrityValid
    }
    
    /// Get user-friendly error message
    func userFriendlyError(for error: Error) -> String {
        if let biometricError = error as? BiometricError {
            return biometricError.localizedDescription
        } else if let laError = error as? LAError {
            return mapLAError(laError as NSError).localizedDescription
        } else {
            return "An unknown error occurred during authentication"
        }
    }
    
    /// Get recovery suggestion for error
    func recoverySuggestion(for error: Error) -> String? {
        if let biometricError = error as? BiometricError {
            return biometricError.recoverySuggestion
        }
        return nil
    }
}

// MARK: - SwiftUI Integration
extension BiometricAuthentication {
    
    /// Create authentication flow for SwiftUI
    func createAuthenticationFlow(reason: String) -> AuthenticationFlow {
        return AuthenticationFlow(biometricAuth: self, reason: reason)
    }
    
    struct AuthenticationFlow {
        let biometricAuth: BiometricAuthentication
        let reason: String
        
        func start() async throws -> Bool {
            return try await biometricAuth.authenticate(reason: reason)
        }
        
        func startWithRetry(maxRetries: Int = 3) async throws -> Bool {
            return try await biometricAuth.authenticateWithRetry(reason: reason, maxRetries: maxRetries)
        }
    }
}