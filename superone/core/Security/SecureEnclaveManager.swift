//
//  SecureEnclaveManager.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Enhanced biometric security with Secure Enclave integration
//

import Foundation
import CryptoKit
import LocalAuthentication
import Security
import Combine
import UIKit

/// Secure Enclave manager for hardware-backed cryptographic operations
/// Implements healthcare-grade security for biometric authentication
@available(iOS 13.0, *)
class SecureEnclaveManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = SecureEnclaveManager()
    
    // MARK: - Constants
    private struct Constants {
        static let keyTag = "com.superone.healthcare.biometric.key"
        static let encryptionKeyTag = "com.superone.healthcare.encryption.key"
        static let authenticationReason = "Authenticate to access your secure health data"
        static let keySize = 256 // P-256 curve for Secure Enclave
    }
    
    // MARK: - Properties
    @Published var isSecureEnclaveAvailable: Bool = false
    @Published var lastSecurityCheck: Date?
    
    private let queue = DispatchQueue(label: "secure.enclave.queue", qos: .userInitiated)
    
    // MARK: - Initialization
    private init() {
        checkSecureEnclaveAvailability()
    }
    
    // MARK: - Public Methods
    
    /// Check if Secure Enclave is available on the device
    func checkSecureEnclaveAvailability() {
        queue.async { [weak self] in
            let isAvailable = SecureEnclave.isAvailable
            
            Task { @MainActor [weak self] in
                self?.isSecureEnclaveAvailable = isAvailable
                self?.lastSecurityCheck = Date()
            }
        }
    }
    
    /// Generate a new P-256 private key in the Secure Enclave with biometric protection
    func generateBiometricProtectedKey() async throws -> SecureEnclave.P256.Signing.PrivateKey {
        guard SecureEnclave.isAvailable else {
            throw SecureEnclaveError.secureEnclaveNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    // Create access control with biometric protection
                    var error: Unmanaged<CFError>?
                    let accessControl = SecAccessControlCreateWithFlags(
                        kCFAllocatorDefault,
                        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                        [.biometryCurrentSet, .privateKeyUsage],
                        &error
                    )
                    
                    guard let accessControl = accessControl else {
                        continuation.resume(throwing: SecureEnclaveError.accessControlCreationFailed)
                        return
                    }
                    
                    // Generate key in Secure Enclave
                    let context = LAContext()
                    context.localizedFallbackTitle = "Use Passcode"
                    
                    let privateKey = try SecureEnclave.P256.Signing.PrivateKey(
                        accessControl: accessControl,
                        authenticationContext: context
                    )
                    
                    continuation.resume(returning: privateKey)
                } catch {
                    continuation.resume(throwing: SecureEnclaveError.keyGenerationFailed(error))
                }
            }
        }
    }
    
    /// Store biometric-protected data in Keychain with Secure Enclave encryption
    func storeBiometricProtectedData(_ data: Data, identifier: String) async throws {
        guard SecureEnclave.isAvailable else {
            throw SecureEnclaveError.secureEnclaveNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    // Create access control with biometric protection
                    var error: Unmanaged<CFError>?
                    guard let accessControl = SecAccessControlCreateWithFlags(
                        kCFAllocatorDefault,
                        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                        [.biometryCurrentSet, .privateKeyUsage],
                        &error
                    ) else {
                        if let error = error?.takeRetainedValue() {
                            continuation.resume(throwing: SecureEnclaveError.accessControlCreationFailed)
                        } else {
                            continuation.resume(throwing: SecureEnclaveError.accessControlCreationFailed)
                        }
                        return
                    }
                    
                    // Prepare keychain query
                    let query: [String: Any] = [
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.superone.healthcare",
                        kSecAttrAccount as String: identifier,
                        kSecValueData as String: data,
                        kSecAttrAccessControl as String: accessControl
                    ]
                    
                    // Delete existing item first
                    let deleteQuery: [String: Any] = [
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.superone.healthcare",
                        kSecAttrAccount as String: identifier
                    ]
                    SecItemDelete(deleteQuery as CFDictionary)
                    
                    // Add new item
                    let status = SecItemAdd(query as CFDictionary, nil)
                    
                    switch status {
                    case errSecSuccess:
                        continuation.resume()
                    case errSecDuplicateItem:
                        continuation.resume(throwing: SecureEnclaveError.duplicateItem)
                    case -128: // errSecUserCancel
                        continuation.resume(throwing: SecureEnclaveError.userCancelled)
                    case errSecAuthFailed:
                        continuation.resume(throwing: SecureEnclaveError.authenticationFailed)
                    default:
                        continuation.resume(throwing: SecureEnclaveError.keychainError(status))
                    }
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Retrieve biometric-protected data from Keychain (triggers biometric prompt)
    func retrieveBiometricProtectedData(identifier: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.superone.healthcare",
                    kSecAttrAccount as String: identifier,
                    kSecReturnData as String: true
                ]
                
                var result: AnyObject?
                let status = SecItemCopyMatching(query as CFDictionary, &result)
                
                switch status {
                case errSecSuccess:
                    if let data = result as? Data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: SecureEnclaveError.dataCorruption)
                    }
                case errSecItemNotFound:
                    continuation.resume(throwing: SecureEnclaveError.itemNotFound)
                case -128: // errSecUserCancel
                    continuation.resume(throwing: SecureEnclaveError.userCancelled)
                case errSecAuthFailed:
                    continuation.resume(throwing: SecureEnclaveError.authenticationFailed)
                default:
                    continuation.resume(throwing: SecureEnclaveError.keychainError(status))
                }
            }
        }
    }
    
    /// Create cryptographically-bound authentication token
    func createBiometricAuthenticationToken(userId: String) async throws -> BiometricAuthToken {
        guard SecureEnclave.isAvailable else {
            throw SecureEnclaveError.secureEnclaveNotAvailable
        }
        
        // Generate timestamp and nonce for token uniqueness
        let timestamp = Date()
        let nonce = UUID().uuidString
        
        // Create token data
        let tokenData = BiometricTokenData(
            userId: userId,
            timestamp: timestamp,
            nonce: nonce,
            deviceId: await getDeviceIdentifier()
        )
        
        // Serialize token data
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let tokenDataBytes = try encoder.encode(tokenData)
        
        // Generate signing key in Secure Enclave
        let signingKey = try await generateBiometricProtectedKey()
        
        // Sign the token data
        let signature = try signingKey.signature(for: tokenDataBytes)
        
        // Create final token
        let token = BiometricAuthToken(
            data: tokenData,
            signature: signature.rawRepresentation,
            publicKey: signingKey.publicKey.rawRepresentation
        )
        
        // Store token in secure keychain for validation
        let tokenBytes = try encoder.encode(token)
        try await storeBiometricProtectedData(tokenBytes, identifier: "biometric_auth_token_\(userId)")
        
        return token
    }
    
    /// Validate biometric authentication token
    func validateBiometricAuthenticationToken(userId: String) async throws -> BiometricAuthToken {
        // Retrieve token from secure storage (triggers biometric prompt)
        let tokenData = try await retrieveBiometricProtectedData(identifier: "biometric_auth_token_\(userId)")
        
        // Deserialize token
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let token = try decoder.decode(BiometricAuthToken.self, from: tokenData)
        
        // Validate token timestamp (15-minute expiration)
        let tokenAge = Date().timeIntervalSince(token.data.timestamp)
        if tokenAge > 900 { // 15 minutes
            throw SecureEnclaveError.tokenExpired
        }
        
        // Validate device ID
        let currentDeviceId = await getDeviceIdentifier()
        if token.data.deviceId != currentDeviceId {
            throw SecureEnclaveError.deviceMismatch
        }
        
        // Verify signature using stored public key
        let publicKey = try P256.Signing.PublicKey(rawRepresentation: token.publicKey)
        let tokenDataBytes = try JSONEncoder().encode(token.data)
        let signature = try P256.Signing.ECDSASignature(rawRepresentation: token.signature)
        
        if !publicKey.isValidSignature(signature, for: tokenDataBytes) {
            throw SecureEnclaveError.signatureValidationFailed
        }
        
        return token
    }
    
    /// Delete biometric-protected data
    func deleteBiometricProtectedData(identifier: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.superone.healthcare",
                    kSecAttrAccount as String: identifier
                ]
                
                let status = SecItemDelete(query as CFDictionary)
                
                switch status {
                case errSecSuccess, errSecItemNotFound:
                    continuation.resume()
                default:
                    continuation.resume(throwing: SecureEnclaveError.keychainError(status))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func getDeviceIdentifier() async -> String {
        return await MainActor.run {
            return UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
        }
    }
}

// MARK: - Supporting Types

/// Biometric authentication token data structure
struct BiometricTokenData: Codable, Sendable {
    let userId: String
    let timestamp: Date
    let nonce: String
    let deviceId: String
}

/// Complete biometric authentication token with cryptographic binding
struct BiometricAuthToken: Codable, Sendable {
    let data: BiometricTokenData
    let signature: Data
    let publicKey: Data
}

/// Secure Enclave specific errors
enum SecureEnclaveError: @preconcurrency LocalizedError, Sendable {
    case secureEnclaveNotAvailable
    case keyGenerationFailed(Error)
    case accessControlCreationFailed
    case keychainError(OSStatus)
    case userCancelled
    case authenticationFailed
    case itemNotFound
    case duplicateItem
    case dataCorruption
    case tokenExpired
    case deviceMismatch
    case signatureValidationFailed
    
    var errorDescription: String? {
        switch self {
        case .secureEnclaveNotAvailable:
            return "Secure Enclave is not available on this device"
        case .keyGenerationFailed(let error):
            return "Failed to generate cryptographic key: \(error.localizedDescription)"
        case .accessControlCreationFailed:
            return "Failed to create biometric access control"
        case .keychainError(let status):
            return "Keychain operation failed with status: \(status)"
        case .userCancelled:
            return "Authentication was cancelled by user"
        case .authenticationFailed:
            return "Biometric authentication failed"
        case .itemNotFound:
            return "Secure data not found"
        case .duplicateItem:
            return "Secure data already exists"
        case .dataCorruption:
            return "Secure data is corrupted"
        case .tokenExpired:
            return "Authentication token has expired"
        case .deviceMismatch:
            return "Authentication token is not valid for this device"
        case .signatureValidationFailed:
            return "Cryptographic signature validation failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .secureEnclaveNotAvailable:
            return "Use an alternative authentication method"
        case .userCancelled:
            return "Please complete biometric authentication to continue"
        case .authenticationFailed:
            return "Please try biometric authentication again"
        case .tokenExpired:
            return "Please authenticate again to continue"
        default:
            return "Please contact support if this issue persists"
        }
    }
}

// MARK: - Convenience Extensions

extension SecureEnclaveManager {
    
    /// Quick check if biometric authentication with Secure Enclave is ready
    var isReadyForBiometricAuth: Bool {
        return isSecureEnclaveAvailable && SecureEnclave.isAvailable
    }
    
    /// Get security status summary
    func getSecurityStatus() -> SecurityStatus {
        return SecurityStatus(
            secureEnclaveAvailable: isSecureEnclaveAvailable,
            biometricCapable: LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil),
            lastSecurityCheck: lastSecurityCheck
        )
    }
}

/// Security status information
struct SecurityStatus: Sendable {
    let secureEnclaveAvailable: Bool
    let biometricCapable: Bool
    let lastSecurityCheck: Date?
    
    var isFullySecure: Bool {
        return secureEnclaveAvailable && biometricCapable
    }
}