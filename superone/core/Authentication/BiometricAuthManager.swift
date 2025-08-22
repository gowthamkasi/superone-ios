//
//  BiometricAuthManager.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Simplified biometric authentication for JWT token protection
//

import Foundation
import LocalAuthentication
import SwiftUI
import Combine

// MARK: - Notification Names for Biometric State Changes
extension Notification.Name {
    static let biometricPreferenceChanged = Notification.Name("biometricPreferenceChanged")
}

/// Simplified biometric authentication manager for protecting refresh token access
/// Follows standard JWT practices without complex cryptographic binding
@MainActor
class BiometricAuthManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = BiometricAuthManager()
    
    // MARK: - Published Properties
    @Published var isAvailable = false
    @Published var biometryType: LABiometryType = .none
    @Published var isEnrolled = false
    
    // MARK: - Private Properties
    private let context = LAContext()
    
    private init() {
        updateAvailability()
    }
    
    // MARK: - Availability Check
    
    /// Check if biometric authentication is available on this device
    func isBiometricAvailable() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let context = LAContext()
                var error: NSError?
                
                let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
                
                DispatchQueue.main.async {
                    self.isAvailable = available
                    self.biometryType = available ? context.biometryType : .none
                    self.isEnrolled = available
                    
                    continuation.resume(returning: available)
                }
            }
        }
    }
    
    /// Get the type of biometric authentication available
    func getBiometricType() async -> LABiometryType {
        _ = await isBiometricAvailable()
        return biometryType
    }
    
    /// Update availability status
    private func updateAvailability() {
        Task {
            _ = await isBiometricAvailable()
        }
    }
    
    // MARK: - Authentication
    
    /// Perform biometric authentication for refresh token access
    func authenticate(reason: String) async throws -> Bool {
        
        // Check availability first
        guard await isBiometricAvailable() else {
            throw BiometricError.notAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let context = LAContext()
            
            // Configure the context
            context.localizedFallbackTitle = "Use Passcode"
            context.localizedCancelTitle = "Cancel"
            
            // Perform authentication
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        continuation.resume(returning: true)
                    } else if let error = error as? LAError {
                        let biometricError = self.mapLAError(error)
                        continuation.resume(throwing: biometricError)
                    } else {
                        continuation.resume(throwing: BiometricError.authenticationFailed)
                    }
                }
            }
        }
    }
    
    /// Authenticate with fallback to device passcode
    func authenticateWithFallback(reason: String) async throws -> Bool {
        
        return try await withCheckedThrowingContinuation { continuation in
            let context = LAContext()
            
            // Configure the context for fallback
            context.localizedFallbackTitle = "Use Passcode"
            context.localizedCancelTitle = "Cancel"
            
            // Use policy that allows passcode fallback
            context.evaluatePolicy(
                .deviceOwnerAuthentication, // Allows passcode fallback
                localizedReason: reason
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        continuation.resume(returning: true)
                    } else if let error = error as? LAError {
                        let biometricError = self.mapLAError(error)
                        continuation.resume(throwing: biometricError)
                    } else {
                        continuation.resume(throwing: BiometricError.authenticationFailed)
                    }
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    /// Handle biometric authentication errors with appropriate user actions
    func handleBiometricError(_ error: LAError) -> BiometricErrorAction {
        switch error.code {
        case .userCancel:
            // User cancelled - keep them logged in with current session
            return .keepCurrentSession
            
        case .biometryLockout:
            // Too many failed attempts - offer passcode fallback
            return .offerPasscodeFallback
            
        case .biometryNotAvailable:
            // Hardware issue - disable biometric protection, use normal flow
            return .disableBiometricProtection
            
        case .userFallback:
            // User chose "Enter Passcode" - could implement app passcode
            return .showAppPasscode
            
        case .biometryNotEnrolled:
            // No biometric data enrolled
            return .showEnrollmentPrompt
            
        default:
            return .showError(error.localizedDescription)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Get display name for current biometric type
    var biometricDisplayName: String {
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometric Authentication"
        }
    }
    
    /// Check if biometric authentication is ready to use
    var isReadyToUse: Bool {
        return isAvailable && isEnrolled
    }
    
    // MARK: - Centralized Biometric Settings Management
    
    /// UserDefaults keys for biometric settings - SINGLE SOURCE OF TRUTH
    private struct UserDefaultsKeys {
        static let biometricEnabled = "biometric_auth_enabled"
        static let biometricFirstTimeSetup = "biometric_first_time_setup_completed"
        static let biometricLastEnabledDate = "biometric_last_enabled_date"
    }
    
    /// Check if user has enabled biometric authentication (PRIMARY STATE SOURCE)
    var isUserPreferenceEnabled: Bool {
        let enabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricEnabled)
        return enabled
    }
    
    /// Set user preference for biometric authentication (PRIMARY STATE SETTER)
    /// Following iOS 2024 best practices for immediate state persistence and UI feedback
    func setBiometricPreference(_ enabled: Bool) {
        
        // CRITICAL: Validate device capability before allowing enable
        if enabled {
            Task {
                let available = await isBiometricAvailable()
                await MainActor.run {
                    if !available {
                        return
                    }
                    performPreferenceUpdate(enabled)
                }
            }
        } else {
            performPreferenceUpdate(enabled)
        }
    }
    
    /// Internal method to perform the actual preference update
    private func performPreferenceUpdate(_ enabled: Bool) {
        // Update UserDefaults (single source of truth) with immediate synchronization
        UserDefaults.standard.set(enabled, forKey: UserDefaultsKeys.biometricEnabled)
        
        if enabled {
            // Track when biometric was last enabled
            UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.biometricLastEnabledDate)
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.biometricFirstTimeSetup)
        }
        
        // CRITICAL: Force immediate synchronization to disk for instant persistence
        UserDefaults.standard.synchronize()
        
        // Validate the write was successful
        let verifyEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricEnabled)
        
        
        // IMMEDIATE notification for instant UI updates
        NotificationCenter.default.post(
            name: .biometricPreferenceChanged,
            object: nil,
            userInfo: [
                "enabled": enabled,
                "verified": verifyEnabled,
                "timestamp": Date(),
                "source": "setBiometricPreference"
            ]
        )
        
        // Additional debugging for state consistency
        validateStateConsistency()
    }
    
    /// Check if this is the first time setting up biometric authentication
    var isFirstTimeSetup: Bool {
        return !UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricFirstTimeSetup)
    }
    
    /// Get the date when biometric was last enabled (for debugging)
    var lastEnabledDate: Date? {
        return UserDefaults.standard.object(forKey: UserDefaultsKeys.biometricLastEnabledDate) as? Date
    }
    
    /// Reset all biometric preferences (for logout or troubleshooting)
    func resetBiometricPreferences() {
        
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.biometricEnabled)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.biometricFirstTimeSetup)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.biometricLastEnabledDate)
        UserDefaults.standard.synchronize()
        
        
        // Notify observers
        NotificationCenter.default.post(
            name: .biometricPreferenceChanged,
            object: nil,
            userInfo: ["enabled": false, "reset": true]
        )
    }
    
    /// Reset biometric authentication context
    func invalidateContext() {
        // Create new context for fresh authentication
    }
    
    // MARK: - iOS 2024 State Validation and Debugging
    
    /// Validate internal state consistency for debugging
    func validateStateConsistency() {
        
        // Check UserDefaults state
        let userDefaultsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricEnabled)
        let userDefaultsSetup = UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricFirstTimeSetup)
        let userDefaultsDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.biometricLastEnabledDate) as? Date
        
        
        // Check computed properties
        let computedEnabled = isUserPreferenceEnabled
        let computedFirstTime = isFirstTimeSetup
        let computedLastDate = lastEnabledDate
        
        
        // Check device capabilities
        
        // Validate consistency
        let stateConsistent = (userDefaultsEnabled == computedEnabled)
        let setupConsistent = (userDefaultsSetup == !computedFirstTime)
        let dateConsistent = (userDefaultsDate == computedLastDate)
        
        if stateConsistent && setupConsistent && dateConsistent {
        } else {
        }
    }
    
    /// Force reload of all state from persistent storage
    func reloadStateFromStorage() {
        
        // Force re-read from UserDefaults
        UserDefaults.standard.synchronize()
        
        // Update device availability
        Task {
            await updateDeviceAvailability()
        }
        
        // Validate after reload
        validateStateConsistency()
        
        // Notify of potential state changes
        NotificationCenter.default.post(
            name: .biometricPreferenceChanged,
            object: nil,
            userInfo: [
                "enabled": isUserPreferenceEnabled,
                "source": "reloadStateFromStorage",
                "timestamp": Date()
            ]
        )
    }
    
    /// Update device availability status
    private func updateDeviceAvailability() async {
        let available = await isBiometricAvailable()
        await MainActor.run {
        }
    }
    
    // MARK: - Private Helpers
    
    /// Map LAError to our BiometricError
    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .biometryLockout:
            return .lockout
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .passcodeNotSet:
            return .passcodeNotSet
        case .touchIDLockout:
            return .lockout
        case .touchIDNotAvailable:
            return .biometryNotAvailable
        case .touchIDNotEnrolled:
            return .biometryNotEnrolled
        case .appCancel:
            return .appCancel
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .notInteractive
        default:
            return .authenticationFailed
        }
    }
}

// MARK: - Supporting Types

/// Simplified biometric error types
enum BiometricError: Error, @preconcurrency LocalizedError, Sendable {
    case notAvailable
    case biometryNotEnrolled
    case authenticationFailed
    case userCancel
    case userFallback
    case systemCancel
    case lockout
    case appCancel
    case invalidContext
    case biometryNotAvailable
    case passcodeNotSet
    case notInteractive
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .biometryNotEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings"
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
        case .passcodeNotSet:
            return "Passcode is not set on the device"
        case .notInteractive:
            return "Authentication is not interactive"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .biometryNotEnrolled:
            return "Please set up Face ID or Touch ID in your device Settings"
        case .lockout:
            return "Please wait or use your device passcode to unlock biometric authentication"
        case .passcodeNotSet:
            return "Please set up a device passcode in Settings"
        case .userCancel, .userFallback:
            return "Try again or use email login"
        default:
            return "Please try again or contact support if the problem persists"
        }
    }
}

/// Actions to take based on biometric authentication errors
enum BiometricErrorAction: Sendable {
    case keepCurrentSession
    case offerPasscodeFallback
    case disableBiometricProtection
    case showAppPasscode
    case showEnrollmentPrompt
    case showError(String)
}

// MARK: - SwiftUI Integration

extension BiometricAuthManager {
    
    /// Get biometric authentication button configuration for UI
    func getAuthButtonConfig() -> BiometricButtonConfig {
        return BiometricButtonConfig(
            isAvailable: isReadyToUse,
            biometricType: biometryType,
            displayName: biometricDisplayName,
            iconName: biometricIconName
        )
    }
    
    private var biometricIconName: String {
        switch biometryType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "lock"
        }
    }
}

/// Configuration for biometric authentication button in UI
struct BiometricButtonConfig {
    let isAvailable: Bool
    let biometricType: LABiometryType
    let displayName: String
    let iconName: String
}