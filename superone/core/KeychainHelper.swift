import Foundation
import Security
import LocalAuthentication
import Combine
import CryptoKit
import UIKit

// MARK: - KeychainServiceProtocol

/// Protocol defining keychain service operations
protocol KeychainServiceProtocol {
    nonisolated func store(token: String, for key: String) throws
    nonisolated func retrieve(key: String, withBiometrics: Bool) throws -> String?
    nonisolated func delete(key: String) throws
    nonisolated func isBiometricAvailable() -> Bool
    
    // Enhanced methods
    nonisolated func storeWithExpiration(token: String, for key: String, expirationDate: Date) throws
    func retrieveWithBiometrics(key: String, reason: String) async throws -> String?
    func migrateIfNeeded() async throws
    nonisolated func deleteAllTokens() throws
    nonisolated func tokenExpirationDate(for key: String) throws -> Date?
    nonisolated func isTokenExpired(for key: String) throws -> Bool
}

/// Secure keychain storage for sensitive app data with enhanced capabilities
class KeychainHelper: KeychainServiceProtocol {
    
    // MARK: - Error Types
    enum KeychainError: Error, @preconcurrency LocalizedError {
        case noPassword
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
        case biometricNotAvailable
        case biometricNotEnrolled
        case authenticationFailed
        case tokenExpired
        case migrationFailed
        case invalidExpirationDate
        case secureEnclaveNotAvailable
        case itemAlreadyExists
        case invalidTokenFormat
        case biometricPromptCancelled
        case tooManyFailedAttempts
        
        var errorDescription: String? {
            switch self {
            case .noPassword:
                return "No password found in keychain"
            case .unexpectedPasswordData:
                return "Unexpected password data format"
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            case .biometricNotAvailable:
                return "Biometric authentication not available"
            case .biometricNotEnrolled:
                return "No biometric data enrolled"
            case .authenticationFailed:
                return "Biometric authentication failed"
            case .tokenExpired:
                return "Token has expired"
            case .migrationFailed:
                return "Failed to migrate keychain data"
            case .invalidExpirationDate:
                return "Invalid token expiration date"
            case .secureEnclaveNotAvailable:
                return "Secure Enclave not available on this device"
            case .itemAlreadyExists:
                return "Keychain item already exists"
            case .invalidTokenFormat:
                return "Invalid token format"
            case .biometricPromptCancelled:
                return "Biometric authentication was cancelled"
            case .tooManyFailedAttempts:
                return "Too many failed authentication attempts"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .biometricNotAvailable:
                return "Please enable Face ID or Touch ID in Settings"
            case .biometricNotEnrolled:
                return "Please set up Face ID or Touch ID in Settings"
            case .tokenExpired:
                return "Please log in again to refresh your session"
            case .secureEnclaveNotAvailable:
                return "This device doesn't support hardware-level security"
            default:
                return nil
            }
        }
        
        var failureReason: String? {
            switch self {
            case .noPassword:
                return "Requested password item not found in keychain"
            case .unexpectedPasswordData:
                return "Keychain returned data in unexpected format"
            case .unhandledError(let status):
                return "Keychain operation failed with status code \(status)"
            case .biometricNotAvailable:
                return "Device does not support biometric authentication"
            case .biometricNotEnrolled:
                return "No biometric data enrolled on device"
            case .authenticationFailed:
                return "User biometric authentication was unsuccessful"
            case .tokenExpired:
                return "Stored authentication token has passed expiration date"
            case .migrationFailed:
                return "Unable to migrate keychain data to current version"
            case .invalidExpirationDate:
                return "Token expiration date is not valid"
            case .secureEnclaveNotAvailable:
                return "Device hardware does not support Secure Enclave"
            case .itemAlreadyExists:
                return "Keychain item with same identifier already exists"
            case .invalidTokenFormat:
                return "Token data structure is not in expected format"
            case .biometricPromptCancelled:
                return "User cancelled biometric authentication prompt"
            case .tooManyFailedAttempts:
                return "Maximum number of authentication attempts exceeded"
            }
        }
        
        var helpAnchor: String? {
            switch self {
            case .biometricNotAvailable, .biometricNotEnrolled, .biometricPromptCancelled:
                return "biometric-setup-help"
            case .authenticationFailed, .tooManyFailedAttempts:
                return "authentication-troubleshooting-help"
            case .tokenExpired:
                return "token-refresh-help"
            case .secureEnclaveNotAvailable:
                return "device-security-help"
            case .migrationFailed:
                return "keychain-migration-help"
            default:
                return "keychain-general-help"
            }
        }
    }
    
    // MARK: - Configuration
    nonisolated private static let service = AppConfiguration.bundleIdentifier
    nonisolated private static let accessGroup = "\(AppConfiguration.bundleIdentifier).keychain"
    nonisolated private static let versionKey = "keychain_version"
    nonisolated static let keychainVersion = "2.0"
    nonisolated private static let maxRetryAttempts = 3
    nonisolated private static let retryDelay: TimeInterval = 1.0
    
    // MARK: - Singleton
    nonisolated static let shared = KeychainHelper()
    nonisolated private init() {}
    
    // MARK: - Private Properties  
    private let queue = DispatchQueue(label: "keychain.queue", qos: .userInitiated)
    private let maxFailedAttempts = 5
    
    // Use UserDefaults for simple failed attempts tracking (thread-safe)
    nonisolated private func getFailedAttempts(for key: String) -> Int {
        return UserDefaults.standard.integer(forKey: "keychain_failed_\(key)")
    }
    
    nonisolated private func setFailedAttempts(_ attempts: Int, for key: String) {
        UserDefaults.standard.set(attempts, forKey: "keychain_failed_\(key)")
    }
    
    nonisolated private func clearAllFailedAttempts() {
        let keys = ["auth_token", "refresh_token", "user_credentials", "biometric_data"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: "keychain_failed_\(key)")
        }
    }
    
    // MARK: - Token Storage Structure
    private struct TokenData: Sendable {
        let token: String
        let expirationDate: Date?
        let createdAt: Date
        let version: String
        
        nonisolated init(token: String, expirationDate: Date? = nil) {
            self.token = token
            self.expirationDate = expirationDate
            self.createdAt = Date()
            self.version = KeychainHelper.keychainVersion
        }
        
        nonisolated private init(token: String, expirationDate: Date?, createdAt: Date, version: String) {
            self.token = token
            self.expirationDate = expirationDate
            self.createdAt = createdAt
            self.version = version
        }
        
        // Manual JSON encoding/decoding to avoid Codable actor isolation issues
        nonisolated func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [
                "token": token,
                "createdAt": createdAt.timeIntervalSince1970,
                "version": version
            ]
            if let expirationDate = expirationDate {
                dict["expirationDate"] = expirationDate.timeIntervalSince1970
            }
            return dict
        }
        
        nonisolated static func fromDictionary(_ dict: [String: Any]) -> TokenData? {
            guard let token = dict["token"] as? String,
                  let createdAtTimestamp = dict["createdAt"] as? TimeInterval,
                  let version = dict["version"] as? String else {
                return nil
            }
            
            let createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
            let expirationDate: Date? = {
                if let timestamp = dict["expirationDate"] as? TimeInterval {
                    return Date(timeIntervalSince1970: timestamp)
                }
                return nil
            }()
            
            return TokenData(token: token, expirationDate: expirationDate, createdAt: createdAt, version: version)
        }
    }
    
    // MARK: - Store Methods
    
    /// Store a string value in keychain
    nonisolated static func store(key: String, value: String, requireBiometric: Bool = false) throws {
        let data = value.data(using: .utf8)!
        try store(key: key, data: data, requireBiometric: requireBiometric)
    }
    
    /// Store data in keychain with optional biometric protection
    nonisolated static func store(key: String, data: Data, requireBiometric: Bool = false) throws {
        // Delete any existing item
        try? delete(key: key)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Add biometric protection if required
        if requireBiometric {
            guard isBiometricAvailable() else {
                throw KeychainError.biometricNotAvailable
            }
            
            let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryAny,
                nil
            )
            
            if let access = access {
                query[kSecAttrAccessControl as String] = access
            }
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Retrieve Methods
    
    /// Retrieve a string value from keychain
    nonisolated static func retrieve(key: String, promptMessage: String? = nil) throws -> String? {
        guard let data: Data = try retrieve(key: key, promptMessage: promptMessage) else {
            return nil
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedPasswordData
        }
        
        return string
    }
    
    /// Retrieve data from keychain
    nonisolated static func retrieve(key: String, promptMessage: String? = nil) throws -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // Add biometric prompt if message provided
        if let promptMessage = promptMessage {
            let context = LAContext()
            context.localizedReason = promptMessage
            query[kSecUseAuthenticationContext as String] = context
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.unexpectedPasswordData
            }
            return data
            
        case errSecItemNotFound:
            return nil
            
        case -128: // errSecUserCancel
            throw KeychainError.authenticationFailed
            
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Update Methods
    
    /// Update an existing keychain item
    nonisolated static func update(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        try update(key: key, data: data)
    }
    
    /// Update an existing keychain item with data
    nonisolated static func update(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Delete Methods
    
    /// Delete a keychain item
    nonisolated static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Delete all keychain items for this app
    nonisolated static func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Check if a key exists in keychain
    nonisolated static func exists(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Check if biometric authentication is available
    nonisolated static func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Get the type of biometric authentication available
    nonisolated static func biometricType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        return context.biometryType
    }
    
    /// Get biometric authentication display name
    nonisolated static func biometricDisplayName() -> String {
        switch biometricType() {
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
    
    // MARK: - Enhanced Protocol Methods
    
    /// Store token for key (protocol method)
    nonisolated func store(token: String, for key: String) throws {
        try Self.store(key: key, value: token, requireBiometric: false)
    }
    
    /// Retrieve token with optional biometrics (protocol method)
    nonisolated func retrieve(key: String, withBiometrics: Bool) throws -> String? {
        let rawResult: String?
        
        if withBiometrics {
            let promptMessage = "Use \(Self.biometricDisplayName()) to access your secure data"
            rawResult = try Self.retrieve(key: key, promptMessage: promptMessage)
        } else {
            rawResult = try Self.retrieve(key: key)
        }
        
        // CRITICAL FIX: Check if the result is a TokenData JSON structure and unwrap it
        guard let rawData = rawResult else { return nil }
        
        
        // If the stored data is JSON (from storeWithExpiration), unwrap it
        if rawData.hasPrefix("{") && rawData.contains("\"token\"") {
            
            do {
                guard let data = rawData.data(using: .utf8) else {
                    throw KeychainError.invalidTokenFormat
                }
                
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let tokenData = TokenData.fromDictionary(json ?? [:]) {
                    
                    // Check if token is expired
                    if let expiration = tokenData.expirationDate, expiration < Date() {
                        throw KeychainError.tokenExpired
                    }
                    
                    return tokenData.token
                } else {
                    throw KeychainError.invalidTokenFormat
                }
            } catch {
                throw KeychainError.invalidTokenFormat
            }
        } else {
            return rawData
        }
    }
    
    /// Delete key (protocol method)
    nonisolated func delete(key: String) throws {
        try Self.delete(key: key)
    }
    
    /// Check biometric availability (protocol method)
    nonisolated func isBiometricAvailable() -> Bool {
        return Self.isBiometricAvailable()
    }
    
    /// Store token with expiration date
    nonisolated func storeWithExpiration(token: String, for key: String, expirationDate: Date) throws {
        guard expirationDate > Date() else {
            throw KeychainError.invalidExpirationDate
        }
        
        let tokenData = TokenData(token: token, expirationDate: expirationDate)
        let dict = tokenData.toDictionary()
        let data = try JSONSerialization.data(withJSONObject: dict)
        
        try Self.store(key: key, data: data, requireBiometric: false)
    }
    
    /// Retrieve token with biometric authentication (async)
    func retrieveWithBiometrics(key: String, reason: String) async throws -> String? {
        // Check failed attempts
        let attempts = getFailedAttempts(for: key)
        if attempts >= maxFailedAttempts {
            throw KeychainError.tooManyFailedAttempts
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let result: String? = try Self.retrieve(key: key, promptMessage: reason)
                    
                    // Reset failed attempts on success
                    self.setFailedAttempts(0, for: key)
                    
                    // CRITICAL FIX: Check if the result is a TokenData JSON structure and unwrap it
                    if let rawData = result {
                        
                        // If the stored data is JSON (from storeWithExpiration), unwrap it
                        if rawData.hasPrefix("{") && rawData.contains("\"token\"") {
                            
                            do {
                                guard let data = rawData.data(using: .utf8) else {
                                    throw KeychainError.invalidTokenFormat
                                }
                                
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                
                                if let tokenData = TokenData.fromDictionary(json ?? [:]) {
                                    
                                    // Check if token is expired
                                    if let expiration = tokenData.expirationDate, expiration < Date() {
                                        throw KeychainError.tokenExpired
                                    }
                                    
                                    continuation.resume(returning: tokenData.token)
                                    return
                                } else {
                                    throw KeychainError.invalidTokenFormat
                                }
                            } catch {
                                throw KeychainError.invalidTokenFormat
                            }
                        } else {
                            continuation.resume(returning: rawData)
                            return
                        }
                    }
                    
                    continuation.resume(returning: result)
                } catch {
                    // Increment failed attempts
                    let currentAttempts = self.getFailedAttempts(for: key)
                    self.setFailedAttempts(currentAttempts + 1, for: key)
                    
                    if let keychainError = error as? KeychainError,
                       case .unhandledError(let status) = keychainError,
                       status == -128 { // User cancelled
                        continuation.resume(throwing: KeychainError.biometricPromptCancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// Get token expiration date
    nonisolated func tokenExpirationDate(for key: String) throws -> Date? {
        guard let data: Data = try Self.retrieve(key: key) else {
            return nil
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            guard let dict = jsonObject as? [String: Any],
                  let tokenData = TokenData.fromDictionary(dict) else {
                // Fallback for plain string tokens
                return nil
            }
            return tokenData.expirationDate
        } catch {
            // Fallback for plain string tokens
            return nil
        }
    }
    
    /// Check if token is expired
    nonisolated func isTokenExpired(for key: String) throws -> Bool {
        guard let expirationDate = try tokenExpirationDate(for: key) else {
            return false // Non-expiring token
        }
        
        return Date() >= expirationDate
    }
    
    /// Delete all authentication tokens
    nonisolated func deleteAllTokens() throws {
        let tokenKeys = [
            AppConfig.KeychainKeys.authToken,
            AppConfig.KeychainKeys.refreshToken,
            AppConfig.KeychainKeys.userCredentials,
            AppConfig.KeychainKeys.biometricData
        ]
        
        for key in tokenKeys {
            try Self.delete(key: key)
        }
        
        // Reset failed attempts
        clearAllFailedAttempts()
    }
    
    /// Migrate keychain data if needed
    func migrateIfNeeded() async throws {
        do {
            let currentVersion = try Self.retrieve(key: Self.versionKey) ?? "1.0"
            
            if currentVersion != Self.keychainVersion {
                try await performMigration(from: currentVersion, to: Self.keychainVersion)
                try Self.store(key: Self.versionKey, value: Self.keychainVersion)
            }
        } catch {
            throw KeychainError.migrationFailed
        }
    }
    
    // MARK: - Enhanced Security Methods
    
    /// Check if Secure Enclave is available
    nonisolated static func isSecureEnclaveAvailable() -> Bool {
        var error: Unmanaged<CFError>?
        guard let _ = SecKeyCreateRandomKey([
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate
        ] as CFDictionary, &error) else {
            return false
        }
        return true
    }
    
    /// Store with Secure Enclave protection
    nonisolated static func storeWithSecureEnclave(key: String, value: String) throws {
        guard isSecureEnclaveAvailable() else {
            throw KeychainError.secureEnclaveNotAvailable
        }
        
        let data = value.data(using: .utf8)!
        
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.biometryAny, .privateKeyUsage],
            nil
        )
        
        guard let access = access else {
            throw KeychainError.unhandledError(status: errSecAllocate)
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: access,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Audit log for keychain operations
    nonisolated private static func auditLog(operation: String, key: String, success: Bool) {
        let logEntry = """
        Keychain Operation: \(operation)
        Key: \(key)
        Success: \(success)
        Timestamp: \(Date())
        App Version: \(AppConfiguration.appVersion)
        """
        
        if AppConfiguration.isDebug {
        }
        
        // In production, you might want to send this to your analytics service
    }
    
    // MARK: - Private Migration Methods
    
    private func performMigration(from oldVersion: String, to newVersion: String) async throws {
        // Migration logic based on version differences
        switch (oldVersion, newVersion) {
        case ("1.0", "2.0"):
            try await migrateFromV1ToV2()
        default:
            break
        }
    }
    
    private func migrateFromV1ToV2() async throws {
        // Migrate existing tokens to new TokenData structure
        let keysToMigrate = [
            AppConfig.KeychainKeys.authToken,
            AppConfig.KeychainKeys.refreshToken
        ]
        
        for key in keysToMigrate {
            if let existingToken: String = try Self.retrieve(key: key) {
                // Convert to new format with expiration
                let expirationDate = Calendar.current.date(
                    byAdding: .hour, 
                    value: 1, 
                    to: Date()
                )
                
                try Self.delete(key: key)
                try storeWithExpiration(
                    token: existingToken, 
                    for: key, 
                    expirationDate: expirationDate ?? Date().addingTimeInterval(3600)
                )
            }
        }
    }
}

// MARK: - TokenManager Integration Methods (removed duplicates)

// MARK: - Enhanced Convenience Methods for App-Specific Keys
extension KeychainHelper {
    
    /// Store authentication token with expiration
    nonisolated static func storeAuthToken(_ token: String, expiresIn: TimeInterval? = nil) throws {
        if let expiresIn = expiresIn {
            let expirationDate = Date().addingTimeInterval(expiresIn - AppConfig.Security.tokenExpirationBuffer)
            try shared.storeWithExpiration(token: token, for: AppConfig.KeychainKeys.authToken, expirationDate: expirationDate)
        } else {
            try store(key: AppConfig.KeychainKeys.authToken, value: token, requireBiometric: false)
        }
        
        auditLog(operation: "storeAuthToken", key: AppConfig.KeychainKeys.authToken, success: true)
    }
    
    // MARK: - Convenience Methods for API Service
    
    /// Store authentication token (instance method)
    func storeAuthToken(_ token: String) {
        do {
            try Self.storeAuthToken(token)
        } catch {
        }
    }
    
    /// Get authentication token (instance method)
    func getAuthToken() -> String? {
        do {
            return try Self.retrieveAuthToken()
        } catch {
            return nil
        }
    }
    
    /// Clear authentication token (instance method)
    func clearAuthToken() {
        do {
            try Self.delete(key: AppConfig.KeychainKeys.authToken)
        } catch {
        }
    }
    
    /// Store refresh token (instance method)
    func storeRefreshToken(_ token: String) {
        do {
            try Self.storeRefreshToken(token)
        } catch {
        }
    }
    
    /// Get refresh token (instance method)
    func getRefreshToken() -> String? {
        do {
            return try Self.retrieveRefreshToken()
        } catch {
            return nil
        }
    }
    
    /// Clear refresh token (instance method)
    func clearRefreshToken() {
        do {
            try Self.delete(key: AppConfig.KeychainKeys.refreshToken)
        } catch {
        }
    }
    
    // REMOVED: Token expiration tracking methods
    // These are no longer needed with our simplified JWT approach
    // The server handles all token validation via JWT expiry claims
    
    /// Retrieve authentication token with expiration check
    nonisolated static func retrieveAuthToken() throws -> String? {
        do {
            // Check if token is expired
            if try shared.isTokenExpired(for: AppConfig.KeychainKeys.authToken) {
                try delete(key: AppConfig.KeychainKeys.authToken)
                throw KeychainError.tokenExpired
            }
            
            let token: String? = try retrieve(key: AppConfig.KeychainKeys.authToken)
            auditLog(operation: "retrieveAuthToken", key: AppConfig.KeychainKeys.authToken, success: token != nil)
            return token
        } catch {
            auditLog(operation: "retrieveAuthToken", key: AppConfig.KeychainKeys.authToken, success: false)
            throw error
        }
    }
    
    /// Store refresh token with expiration
    nonisolated static func storeRefreshToken(_ token: String, expiresIn: TimeInterval? = nil) throws {
        if let expiresIn = expiresIn {
            let expirationDate = Date().addingTimeInterval(expiresIn - AppConfig.Security.tokenExpirationBuffer)
            try shared.storeWithExpiration(token: token, for: AppConfig.KeychainKeys.refreshToken, expirationDate: expirationDate)
        } else {
            try store(key: AppConfig.KeychainKeys.refreshToken, value: token, requireBiometric: false)
        }
        
        auditLog(operation: "storeRefreshToken", key: AppConfig.KeychainKeys.refreshToken, success: true)
    }
    
    /// Retrieve refresh token with expiration check
    nonisolated static func retrieveRefreshToken() throws -> String? {
        do {
            // Check if token is expired
            if try shared.isTokenExpired(for: AppConfig.KeychainKeys.refreshToken) {
                try delete(key: AppConfig.KeychainKeys.refreshToken)
                throw KeychainError.tokenExpired
            }
            
            let token: String? = try retrieve(key: AppConfig.KeychainKeys.refreshToken)
            auditLog(operation: "retrieveRefreshToken", key: AppConfig.KeychainKeys.refreshToken, success: token != nil)
            return token
        } catch {
            auditLog(operation: "retrieveRefreshToken", key: AppConfig.KeychainKeys.refreshToken, success: false)
            throw error
        }
    }
    
    /// Store user credentials with biometric protection
    nonisolated static func storeUserCredentials(email: String, password: String) throws {
        let credentials = "\(email):\(password)"
        try store(key: AppConfig.KeychainKeys.userCredentials, value: credentials, requireBiometric: true)
        auditLog(operation: "storeUserCredentials", key: AppConfig.KeychainKeys.userCredentials, success: true)
    }
    
    /// Retrieve user credentials with biometric authentication (async)
    nonisolated static func retrieveUserCredentialsAsync() async throws -> (email: String, password: String)? {
        let reason = "Use \(biometricDisplayName()) to access your stored credentials"
        
        guard let credentials = try await shared.retrieveWithBiometrics(
            key: AppConfig.KeychainKeys.userCredentials, 
            reason: reason
        ) else {
            return nil
        }
        
        let components = credentials.components(separatedBy: ":")
        guard components.count == 2 else {
            throw KeychainError.unexpectedPasswordData
        }
        
        auditLog(operation: "retrieveUserCredentials", key: AppConfig.KeychainKeys.userCredentials, success: true)
        return (email: components[0], password: components[1])
    }
    
    /// Retrieve user credentials synchronously
    nonisolated static func retrieveUserCredentials() throws -> (email: String, password: String)? {
        let promptMessage = "Use \(biometricDisplayName()) to access your stored credentials"
        
        guard let credentials: String = try retrieve(key: AppConfig.KeychainKeys.userCredentials, promptMessage: promptMessage) else {
            return nil
        }
        
        let components = credentials.components(separatedBy: ":")
        guard components.count == 2 else {
            throw KeychainError.unexpectedPasswordData
        }
        
        auditLog(operation: "retrieveUserCredentials", key: AppConfig.KeychainKeys.userCredentials, success: true)
        return (email: components[0], password: components[1])
    }
    
    /// Delete all authentication data
    nonisolated static func deleteAllAuthData() throws {
        try shared.deleteAllTokens()
        auditLog(operation: "deleteAllAuthData", key: "all", success: true)
    }
    
    /// Check if authentication tokens are valid and not expired
    nonisolated static func hasValidAuthToken() -> Bool {
        do {
            let hasToken = try retrieveAuthToken() != nil
            return hasToken
        } catch KeychainError.tokenExpired {
            return false
        } catch {
            return false
        }
    }
    
    /// Get token expiration info
    nonisolated static func getTokenExpirationInfo() -> (authTokenExpiry: Date?, refreshTokenExpiry: Date?) {
        let authExpiry = try? shared.tokenExpirationDate(for: AppConfig.KeychainKeys.authToken)
        let refreshExpiry = try? shared.tokenExpirationDate(for: AppConfig.KeychainKeys.refreshToken)
        
        return (authExpiry, refreshExpiry)
    }
    
    /// Store biometric preference
    nonisolated static func storeBiometricPreference(_ enabled: Bool) throws {
        let value = enabled ? "true" : "false"
        try store(key: "biometric_preference", value: value, requireBiometric: false)
    }
    
    /// Retrieve biometric preference
    nonisolated static func getBiometricPreference() -> Bool {
        guard let value: String = try? retrieve(key: "biometric_preference") else {
            return true // Default to true for biometric authentication
        }
        return value == "true"
    }
}

// MARK: - Healthcare Compliance Extensions

extension KeychainHelper {
    
    /// Store healthcare data with HIPAA-compliant encryption
    /// Uses kSecAttrAccessibleWhenUnlockedThisDeviceOnly to prevent iCloud sync
    static func storeHealthcareData(
        _ data: Data,
        identifier: String,
        requireBiometric: Bool = true
    ) async throws {
        var accessControl: SecAccessControl?
        
        if requireBiometric {
            // Create access control with biometric protection and device-only storage
            var error: Unmanaged<CFError>?
            accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [.biometryCurrentSet, .privateKeyUsage],
                &error
            )
            
            if accessControl == nil {
                throw KeychainError.secureEnclaveNotAvailable
            }
        }
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.superone.healthcare",
            kSecAttrAccount as String: "healthcare_\(identifier)",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        if let accessControl = accessControl {
            query[kSecAttrAccessControl as String] = accessControl
        }
        
        // Add audit metadata
        let deviceId = await MainActor.run { UIDevice.current.identifierForVendor?.uuidString ?? "unknown" }
        let auditData: [String: Any] = [
            "operation": "store_healthcare_data",
            "identifier": identifier,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "device_id": deviceId,
            "biometric_required": requireBiometric
        ]
        
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.superone.healthcare",
            kSecAttrAccount as String: "healthcare_\(identifier)"
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // Log audit event
        Task { @MainActor in
            HealthcareAuditLogger.shared.logDataAccess(
                userId: "system",
                dataType: "healthcare_keychain_data",
                operation: "store",
                success: status == errSecSuccess,
                additionalContext: auditData
            )
        }
        
        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            throw KeychainError.itemAlreadyExists
        case -128: // errSecUserCancel
            throw KeychainError.biometricPromptCancelled
        case errSecAuthFailed:
            throw KeychainError.authenticationFailed
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Retrieve healthcare data with biometric authentication
    static func retrieveHealthcareData(identifier: String) async throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.superone.healthcare",
            kSecAttrAccount as String: "healthcare_\(identifier)",
            kSecReturnData as String: true,
kSecUseOperationPrompt as String: "Access your secure health data"
        ]
        
        let deviceId = await MainActor.run { UIDevice.current.identifierForVendor?.uuidString ?? "unknown" }
        
        return try await withCheckedThrowingContinuation { continuation in
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            let auditData: [String: Any] = [
                "operation": "retrieve_healthcare_data",
                "identifier": identifier,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "device_id": deviceId,
                "status_code": status
            ]
            
            // Log audit event
            Task { @MainActor in
                HealthcareAuditLogger.shared.logDataAccess(
                    userId: "system",
                    dataType: "healthcare_keychain_data",
                    operation: "retrieve",
                    success: status == errSecSuccess,
                    additionalContext: auditData
                )
            }
            
            switch status {
            case errSecSuccess:
                if let data = result as? Data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: KeychainError.unexpectedPasswordData)
                }
            case errSecItemNotFound:
                continuation.resume(throwing: KeychainError.noPassword)
            case -128: // errSecUserCancel
                continuation.resume(throwing: KeychainError.biometricPromptCancelled)
            case errSecAuthFailed:
                continuation.resume(throwing: KeychainError.authenticationFailed)
            default:
                continuation.resume(throwing: KeychainError.unhandledError(status: status))
            }
        }
    }
    
    /// Store encrypted healthcare token with expiration
    static func storeHealthcareToken(
        _ token: String,
        identifier: String,
        expirationDate: Date
    ) async throws {
        // Create token metadata
        let deviceId = await MainActor.run { UIDevice.current.identifierForVendor?.uuidString ?? "unknown" }
        let tokenMetadata = HealthcareTokenMetadata(
            token: token,
            createdAt: Date(),
            expiresAt: expirationDate,
            deviceId: deviceId,
            encryptionMethod: "AES-256-GCM"
        )
        
        // Encode token metadata
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let tokenData = try encoder.encode(tokenMetadata)
        
        // Store with healthcare compliance
        try await storeHealthcareData(tokenData, identifier: identifier, requireBiometric: true)
        
        // Log token creation
        Task { @MainActor in
            HealthcareAuditLogger.shared.logTokenCreation(
                userId: "system",
                tokenType: "healthcare_access_token",
                encryptionMethod: "AES-256-GCM",
                expirationTime: expirationDate
            )
        }
    }
    
    /// Retrieve and validate healthcare token
    static func retrieveHealthcareToken(identifier: String) async throws -> String {
        let tokenData = try await retrieveHealthcareData(identifier: identifier)
        
        // Decode token metadata
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let tokenMetadata = try decoder.decode(HealthcareTokenMetadata.self, from: tokenData)
        
        // Check expiration
        if tokenMetadata.expiresAt < Date() {
            // Delete expired token
            try deleteHealthcareData(identifier: identifier)
            
            HealthcareAuditLogger.shared.logTokenValidation(
                userId: "system",
                tokenType: "healthcare_access_token",
                success: false,
                failureReason: "token_expired"
            )
            
            throw KeychainError.tokenExpired
        }
        
        // Log successful validation
        HealthcareAuditLogger.shared.logTokenValidation(
            userId: "system",
            tokenType: "healthcare_access_token",
            success: true
        )
        
        return tokenMetadata.token
    }
    
    /// Delete healthcare data with audit logging
    nonisolated static func deleteHealthcareData(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.superone.healthcare",
            kSecAttrAccount as String: "healthcare_\(identifier)"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Log audit event
        Task { @MainActor in
            HealthcareAuditLogger.shared.logDataAccess(
                userId: "system",
                dataType: "healthcare_keychain_data",
                operation: "delete",
                success: status == errSecSuccess || status == errSecItemNotFound,
                additionalContext: [
                    "identifier": identifier,
                    "timestamp": ISO8601DateFormatter().string(from: Date()),
                    "status_code": status
                ]
            )
        }
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            break // Success or item didn't exist
        default:
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Secure wipe of all healthcare data (for account deletion)
    nonisolated static func secureWipeHealthcareData() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.superone.healthcare"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Log secure wipe event
        Task { @MainActor in
            HealthcareAuditLogger.shared.logDataAccess(
                userId: "system",
                dataType: "all_healthcare_data",
                operation: "secure_wipe",
                success: status == errSecSuccess || status == errSecItemNotFound,
                additionalContext: [
                    "timestamp": ISO8601DateFormatter().string(from: Date()),
                    "device_id": UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                    "status_code": status,
                    "reason": "account_deletion_or_data_retention_policy"
                ]
            )
        }
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Generate and store certificate pinning data
    static func storeCertificatePinningData(_ pinnedCertificates: [String: Data]) async throws {
        let encoder = JSONEncoder()
        let certData = try encoder.encode(pinnedCertificates)
        
        try await storeHealthcareData(
            certData,
            identifier: "certificate_pins",
            requireBiometric: false
        )
    }
    
    /// Retrieve certificate pinning data
    static func retrieveCertificatePinningData() async throws -> [String: Data] {
        let certData = try await retrieveHealthcareData(identifier: "certificate_pins")
        
        let decoder = JSONDecoder()
        return try decoder.decode([String: Data].self, from: certData)
    }
}

// MARK: - Healthcare Token Metadata

/// Metadata structure for healthcare tokens
private struct HealthcareTokenMetadata: Codable {
    let token: String
    let createdAt: Date
    let expiresAt: Date
    let deviceId: String
    let encryptionMethod: String
}