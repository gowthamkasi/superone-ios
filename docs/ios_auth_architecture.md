# Complete iOS Authentication Architecture: Email + Biometric Login with Secure Token Management

## Overview

This guide provides a comprehensive authentication system for iOS health tech apps that supports:
- Email/password login with JWT tokens
- Biometric authentication (Face ID/Touch ID) as secondary auth
- Secure token storage and management
- Automatic token refresh
- Health data protection compliance

## 1. Authentication Architecture Pattern

### Core Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SwiftUI Views │◄──►│ AuthManager     │◄──►│ Backend API     │
│                 │    │ (ObservableObj) │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ TokenManager    │
                       │ (Keychain)      │
                       └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ BiometricAuth   │
                       │ (LocalAuth)     │
                       └─────────────────┘
```

### Complete Authentication Flow Diagram

```
┌─────────────────┐
│   App Launch    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐    No Token    ┌─────────────────┐
│ Check Keychain  │───────────────►│  Show Login     │
│ for Access Token│                │  Screen         │
└─────────┬───────┘                └─────────┬───────┘
          │                                  │
      Has Token                              │
          │                                  ▼
          ▼                        ┌─────────────────┐
┌─────────────────┐                │ Email/Password  │
│ Token Valid?    │                │ Authentication  │
└─────────┬───────┘                └─────────┬───────┘
          │                                  │
      Invalid/Expired                    Success
          │                                  │
          ▼                                  ▼
┌─────────────────┐                ┌─────────────────┐
│ Biometric       │                │ Store Tokens    │
│ Enabled?        │                │ in Keychain     │
└─────────┬───────┘                └─────────┬───────┘
          │                                  │
        Yes │                                │
          ▼                                  ▼
┌─────────────────┐                ┌─────────────────┐
│ Biometric Auth  │                │ Show Biometric  │
│ Required        │                │ Setup (Optional)│
└─────────┬───────┘                └─────────┬───────┘
          │                                  │
      Success                              Enable
          │                                  │
          ▼                                  ▼
┌─────────────────┐                ┌─────────────────┐
│ Access Refresh  │                │ Move Refresh    │
│ Token (Keychain)│                │ Token to        │
└─────────┬───────┘                │ Biometric Store │
          │                        └─────────────────┘
          ▼
┌─────────────────┐
│ Call Backend    │
│ /auth/refresh   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Store New       │
│ Tokens          │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Access App      │
│ Content         │
└─────────────────┘
```

## 2. Token Management Strategy (Approach 1 - Recommended)

### Why This Approach is Superior

1. **Security**: Biometric data never leaves the device (Secure Enclave)
2. **Privacy**: Backend doesn't need to handle biometric data
3. **Compatibility**: Works with any JWT-based backend without changes
4. **Offline**: Biometric check works even without network connection
5. **Apple Guidelines**: Follows Apple's recommended security patterns
6. **Simplicity**: No complex cryptographic challenge/response needed

### JWT Token Structure
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

### Token Lifecycle Management
1. **Email Login**: User provides credentials → Backend returns JWT tokens
2. **Token Storage**: Store access token normally, refresh token optionally with biometric protection
3. **Token Usage**: Use access token for API calls
4. **Token Refresh**: When access token expires, biometric auth (if enabled) → access refresh token → call backend
5. **Biometric Flow**: Biometric authentication **protects access to refresh token**, doesn't generate new tokens

### Critical Point: Backend Perspective
The backend **never knows** if biometric authentication was used. It only sees:
```bash
# Initial login (same as always)
POST /auth/login { email, password } → { access_token, refresh_token }

# Token refresh (identical whether biometric was used or not)
POST /auth/refresh { refresh_token } → { access_token, refresh_token }
```

### User Experience Flow
```swift
// Complete user journey example:

// 1. First time login
await authManager.signIn(email: "user@example.com", password: "password123")
// → Backend returns tokens → Stored in Keychain

// 2. User enables biometric (optional)
await authManager.enableBiometricAuth()
// → Refresh token moved to biometric-protected Keychain storage

// 3. App launched later / token expired
// → Check if biometric enabled → Show Face ID prompt → 
// → Access refresh token → Call backend /auth/refresh → Get new tokens

// 4. User can disable biometric anytime
await authManager.disableBiometricAuth()
// → Refresh token moved back to standard Keychain storage
```

## 3. SwiftUI Authentication Manager

```swift
import SwiftUI
import LocalAuthentication
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var user: User?
    @Published var biometricAuthEnabled = false
    
    // MARK: - Private Properties
    private let tokenManager = TokenManager.shared
    private let biometricManager = BiometricAuthManager.shared
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        checkAuthenticationStatus()
        setupTokenRefreshTimer()
    }
    
    // MARK: - Email Authentication
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.login(email: email, password: password)
            
            // Store tokens securely
            try await tokenManager.storeTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                expiresIn: response.expiresIn
            )
            
            // Update user state
            self.user = response.user
            self.isAuthenticated = true
            
            // Check if biometric auth should be enabled
            await checkBiometricAvailability()
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Biometric Authentication
    func enableBiometricAuth() async {
        guard await biometricManager.isBiometricAvailable() else {
            errorMessage = "Biometric authentication not available"
            return
        }
        
        do {
            // Protect refresh token with biometrics
            try await tokenManager.enableBiometricProtection()
            biometricAuthEnabled = true
        } catch {
            errorMessage = "Failed to enable biometric authentication: \(error.localizedDescription)"
        }
    }
    
    func disableBiometricAuth() async {
        do {
            try await tokenManager.disableBiometricProtection()
            biometricAuthEnabled = false
        } catch {
            errorMessage = "Failed to disable biometric authentication: \(error.localizedDescription)"
        }
    }
    
    func authenticateWithBiometrics() async -> Bool {
        do {
            return try await biometricManager.authenticate(
                reason: "Access your health data securely"
            )
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Token Management
    private func checkAuthenticationStatus() {
        Task {
            if let accessToken = await tokenManager.getValidAccessToken() {
                // Verify token with backend
                if await apiClient.verifyToken(accessToken) {
                    self.isAuthenticated = true
                    // Load user data
                    await loadUserData()
                } else {
                    await handleTokenExpiration()
                }
            }
        }
    }
    
    private func handleTokenExpiration() async {
        do {
            // Try to refresh token
            if biometricAuthEnabled {
                // Use biometric-protected refresh flow
                try await tokenManager.refreshTokensWithBiometric()
            } else {
                // Use standard refresh flow
                try await tokenManager.refreshTokens()
            }
            
            await loadUserData()
            
        } catch {
            // If refresh fails, sign out user
            await signOut()
        }
    }
    
    private func setupTokenRefreshTimer() {
        Timer.publish(every: 300, on: .main, in: .common) // Check every 5 minutes
            .autoconnect()
            .sink { _ in
                Task {
                    await self.checkTokenExpiration()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkTokenExpiration() async {
        if await tokenManager.isAccessTokenExpiringSoon() {
            await handleTokenExpiration()
        }
    }
    
    // MARK: - Sign Out
    func signOut() async {
        await tokenManager.clearTokens()
        
        self.isAuthenticated = false
        self.user = nil
        self.biometricAuthEnabled = false
        self.errorMessage = nil
    }
    
    // MARK: - Private Helpers
    private func checkBiometricAvailability() async {
        biometricAuthEnabled = await biometricManager.isBiometricAvailable()
    }
    
    private func loadUserData() async {
        do {
            if let accessToken = await tokenManager.getValidAccessToken() {
                self.user = try await apiClient.getUserProfile(token: accessToken)
            }
        } catch {
            print("Failed to load user data: \(error)")
        }
    }
}
```

## 4. Secure Token Manager

```swift
import Foundation
import Security
import CryptoKit

class TokenManager {
    static let shared = TokenManager()
    
    private let keychain = KeychainManager.shared
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let tokenExpirationKey = "token_expiration"
    
    private init() {}
    
    // MARK: - Token Storage
    func storeTokens(accessToken: String, refreshToken: String, expiresIn: Int) async throws {
        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        
        // Store access token (no biometric protection needed as it's short-lived)
        try keychain.store(accessToken, forKey: accessTokenKey)
        
        // Store refresh token based on biometric protection status
        if biometricProtectionEnabled {
            // Store with biometric protection
            try keychain.storeWithBiometricProtection(refreshToken, forKey: refreshTokenKey)
        } else {
            // Store normally (still encrypted by Keychain)
            try keychain.store(refreshToken, forKey: refreshTokenKey)
        }
        
        // Store expiration date
        let expirationData = try JSONEncoder().encode(expirationDate)
        try keychain.store(String(data: expirationData, encoding: .utf8)!, forKey: tokenExpirationKey)
    }
    
    func enableBiometricProtection() async throws {
        guard let refreshToken = try? keychain.retrieve(forKey: refreshTokenKey) else {
            throw TokenError.refreshTokenNotFound
        }
        
        // Re-store refresh token with biometric protection
        try keychain.storeWithBiometricProtection(refreshToken, forKey: refreshTokenKey)
        biometricProtectionEnabled = true
        
        // Store biometric protection status
        try keychain.store("enabled", forKey: "biometric_protection_status")
    }
    
    func disableBiometricProtection() async throws {
        guard let refreshToken = try? keychain.retrieve(forKey: refreshTokenKey) else {
            throw TokenError.refreshTokenNotFound
        }
        
        // Re-store refresh token without biometric protection
        try keychain.store(refreshToken, forKey: refreshTokenKey)
        biometricProtectionEnabled = false
        
        // Remove biometric protection status
        try? keychain.delete(forKey: "biometric_protection_status")
    }
    
    // MARK: - Private Properties
    private var biometricProtectionEnabled: Bool {
        return (try? keychain.retrieve(forKey: "biometric_protection_status")) == "enabled"
    }
    
    // MARK: - Token Retrieval
    func getValidAccessToken() async -> String? {
        // Check if current access token is still valid
        if let accessToken = try? keychain.retrieve(forKey: accessTokenKey),
           !isAccessTokenExpired() {
            return accessToken
        }
        
        // Try to refresh token
        do {
            try await refreshTokens()
            return try? keychain.retrieve(forKey: accessTokenKey)
        } catch {
            return nil
        }
    }
    
    func getRefreshToken() async throws -> String {
        guard let refreshToken = try? keychain.retrieve(forKey: refreshTokenKey) else {
            throw TokenError.refreshTokenNotFound
        }
        return refreshToken
    }
    
    // MARK: - Token Refresh
    func refreshTokens() async throws {
        // This method will trigger biometric auth if protection is enabled
        // because getRefreshToken() accesses biometric-protected Keychain item
        let refreshToken = try await getRefreshToken()
        
        let response = try await APIClient.shared.refreshToken(refreshToken)
        
        try await storeTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn
        )
    }
    
    // MARK: - Biometric Authentication Flow
    func refreshTokensWithBiometric() async throws {
        // Step 1: Perform biometric authentication to access refresh token
        guard await BiometricAuthManager.shared.authenticate(
            reason: "Authenticate to refresh your session"
        ) else {
            throw TokenError.biometricAuthenticationFailed
        }
        
        // Step 2: Biometric success unlocks refresh token from Keychain
        let refreshToken = try await getRefreshToken()
        
        // Step 3: Use refresh token to get new tokens from backend
        let response = try await APIClient.shared.refreshToken(refreshToken)
        
        // Step 4: Store new tokens (maintaining biometric protection)
        try await storeTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn
        )
        
        // Re-enable biometric protection for new refresh token
        if biometricProtectionEnabled {
            try await enableBiometricProtection()
        }
    }
    
    // MARK: - Token Validation
    func isAccessTokenExpired() -> Bool {
        guard let expirationString = try? keychain.retrieve(forKey: tokenExpirationKey),
              let expirationData = expirationString.data(using: .utf8),
              let expirationDate = try? JSONDecoder().decode(Date.self, from: expirationData) else {
            return true
        }
        
        return Date() >= expirationDate
    }
    
    func isAccessTokenExpiringSoon(threshold: TimeInterval = 300) async -> Bool {
        guard let expirationString = try? keychain.retrieve(forKey: tokenExpirationKey),
              let expirationData = expirationString.data(using: .utf8),
              let expirationDate = try? JSONDecoder().decode(Date.self, from: expirationData) else {
            return true
        }
        
        return Date().addingTimeInterval(threshold) >= expirationDate
    }
    
    // MARK: - Clear Tokens
    func clearTokens() async {
        try? keychain.delete(forKey: accessTokenKey)
        try? keychain.delete(forKey: refreshTokenKey)
        try? keychain.delete(forKey: tokenExpirationKey)
    }
}

enum TokenError: LocalizedError {
    case refreshTokenNotFound
    case tokenRefreshFailed
    case biometricAuthenticationFailed
    case biometricNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .refreshTokenNotFound:
            return "Refresh token not found. Please log in again."
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token."
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed or was cancelled."
        case .biometricNotAvailable:
            return "Biometric authentication is not available."
        }
    }
}
```

## 5. Keychain Manager with Biometric Protection

```swift
import Foundation
import Security
import LocalAuthentication

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.yourapp.healthtech"
    
    private init() {}
    
    // MARK: - Standard Storage
    func store(_ value: String, forKey key: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    // MARK: - Biometric Protected Storage
    func storeWithBiometricProtection(_ value: String, forKey key: String) throws {
        let data = value.data(using: .utf8)!
        
        // Create access control for biometric authentication
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.biometryCurrentSet, .privateKeyUsage],
            &error
        ) else {
            throw KeychainError.accessControlCreationFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: accessControl
        ]
        
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    // MARK: - Retrieval
    func retrieve(forKey key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        
        return value
    }
    
    // MARK: - Deletion
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case accessControlCreationFailed
    case dataConversionFailed
    
    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store item in Keychain. Status: \(status)"
        case .retrieveFailed(let status):
            return "Failed to retrieve item from Keychain. Status: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete item from Keychain. Status: \(status)"
        case .accessControlCreationFailed:
            return "Failed to create access control for biometric authentication"
        case .dataConversionFailed:
            return "Failed to convert Keychain data"
        }
    }
}
```

## 6. Biometric Authentication Manager

```swift
import LocalAuthentication
import Foundation

class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    
    private init() {}
    
    func isBiometricAvailable() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func getBiometricType() async -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        return context.biometryType
    }
    
    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        
        // Configure the context
        context.localizedFallbackTitle = "Use Passcode"
        context.localizedCancelTitle = "Cancel"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            throw BiometricError.authenticationFailed(error)
        }
    }
    
    func authenticateWithFallback(reason: String) async throws -> Bool {
        let context = LAContext()
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication, // Allows passcode fallback
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            throw BiometricError.authenticationFailed(error)
        }
    }
    
    // MARK: - Error Handling for Different Scenarios
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
            
        default:
            return .showError(error.localizedDescription)
        }
    }
}

enum BiometricErrorAction {
    case keepCurrentSession
    case offerPasscodeFallback
    case disableBiometricProtection
    case showAppPasscode
    case showError(String)
}
}

enum BiometricError: LocalizedError {
    case notAvailable
    case authenticationFailed(LAError)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .authenticationFailed(let laError):
            switch laError.code {
            case .userCancel:
                return "Authentication was cancelled"
            case .userFallback:
                return "User chose to use passcode"
            case .biometryNotAvailable:
                return "Biometric authentication is not available"
            case .biometryNotEnrolled:
                return "No biometric data is enrolled"
            case .biometryLockout:
                return "Biometric authentication is locked due to too many failed attempts"
            default:
                return "Authentication failed: \(laError.localizedDescription)"
            }
        }
    }
}
```

## 7. API Client with Token Management

```swift
import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = URL(string: "https://your-api-domain.com")!
    private let tokenManager = TokenManager.shared
    
    private init() {}
    
    // MARK: - Authentication Endpoints
    func login(email: String, password: String) async throws -> LoginResponse {
        let endpoint = baseURL.appendingPathComponent("/auth/login")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginRequest = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(loginRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
    
    func refreshToken(_ refreshToken: String) async throws -> TokenRefreshResponse {
        let endpoint = baseURL.appendingPathComponent("/auth/refresh")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let refreshRequest = TokenRefreshRequest(refreshToken: refreshToken)
        request.httpBody = try JSONEncoder().encode(refreshRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.tokenRefreshFailed
        }
        
        return try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
    }
    
    func verifyToken(_ token: String) async -> Bool {
        let endpoint = baseURL.appendingPathComponent("/auth/verify")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
    
    // MARK: - Protected Endpoints
    func getUserProfile(token: String) async throws -> User {
        let endpoint = baseURL.appendingPathComponent("/user/profile")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    // MARK: - Authenticated Request Helper
    func authenticatedRequest(to endpoint: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        guard let accessToken = await tokenManager.getValidAccessToken() else {
            throw APIError.noValidToken
        }
        
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode < 400 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return data
    }
}

// MARK: - API Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

struct TokenRefreshRequest: Codable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct TokenRefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

struct User: Codable {
    let id: String
    let email: String
    let name: String
    let role: String
}

enum APIError: LocalizedError {
    case invalidResponse
    case serverError(Int)
    case tokenRefreshFailed
    case noValidToken
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .noValidToken:
            return "No valid authentication token available"
        }
    }
}
```

## 8. SwiftUI Views Implementation

### Login Screen
```swift
import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var email = ""
    @State private var password = ""
    @State private var showBiometricSetup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("HealthApp")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Secure access to your health data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: signIn) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Sign In")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                }
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Welcome")
            .sheet(isPresented: $showBiometricSetup) {
                BiometricSetupView()
                    .environmentObject(authManager)
            }
            .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    // Show biometric setup if available and not already enabled
                    Task {
                        if await BiometricAuthManager.shared.isBiometricAvailable() && !authManager.biometricAuthEnabled {
                            showBiometricSetup = true
                        }
                    }
                }
            }
        }
    }
    
    private func signIn() {
        Task {
            await authManager.signIn(email: email, password: password)
        }
    }
}
```

### Biometric Setup View
```swift
import SwiftUI
import LocalAuthentication

struct BiometricSetupView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var biometricType: LABiometryType = .none
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Icon
                Image(systemName: biometricIcon)
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                // Title and Description
                VStack(spacing: 16) {
                    Text("Enable \(biometricTitle)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Use \(biometricTitle.lowercased()) to quickly and securely access your health data without entering your password each time.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 12) {
                    BenefitRow(icon: "lock.shield", text: "Enhanced security")
                    BenefitRow(icon: "bolt.fill", text: "Quick access")
                    BenefitRow(icon: "hand.raised.fill", text: "No passwords to remember")
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button("Enable \(biometricTitle)") {
                        enableBiometric()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding()
            .navigationTitle("Security Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            biometricType = await BiometricAuthManager.shared.getBiometricType()
        }
    }
    
    private var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock"
        }
    }
    
    private var biometricTitle: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometric Authentication"
        }
    }
    
    private func enableBiometric() {
        Task {
            await authManager.enableBiometricAuth()
            dismiss()
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}
```

### Main App View with Authentication State
```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            // Check if biometric authentication is required
            checkBiometricAuth()
        }
    }
    
    private func checkBiometricAuth() {
        // If user has biometric auth enabled and app is launching
        if authManager.biometricAuthEnabled && authManager.isAuthenticated {
            Task {
                let success = await authManager.authenticateWithBiometrics()
                if !success {
                    await authManager.signOut()
                }
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            HealthDataView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Health")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
    }
}
```

## 9. Security Best Practices Implementation

### Scene Phase Management
```swift
struct AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}

@main
struct HealthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.scenePhase) var scenePhase
    @State private var blurView: UIVisualEffectView?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onChange(of: scenePhase) { phase in
                    handleScenePhase(phase)
                }
        }
    }
    
    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            // Hide sensitive content when app goes to background
            addBlurEffect()
            
        case .active:
            // Remove blur and check for biometric auth if needed
            removeBlurEffect()
            
            if authManager.biometricAuthEnabled && authManager.isAuthenticated {
                Task {
                    let success = await authManager.authenticateWithBiometrics()
                    if !success {
                        await authManager.signOut()
                    }
                }
            }
            
        @unknown default:
            break
        }
    }
    
    private func addBlurEffect() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = window.bounds
        blurView.tag = 999
        
        window.addSubview(blurView)
        self.blurView = blurView
    }
    
    private func removeBlurEffect() {
        blurView?.removeFromSuperview()
        blurView = nil
    }
}
```

## 10. Testing Strategy

### Unit Tests for Authentication
```swift
import XCTest
@testable import HealthApp

class AuthenticationManagerTests: XCTestCase {
    var authManager: AuthenticationManager!
    var mockTokenManager: MockTokenManager!
    var mockAPIClient: MockAPIClient!
    
    override func setUp() {
        super.setUp()
        mockTokenManager = MockTokenManager()
        mockAPIClient = MockAPIClient()
        authManager = AuthenticationManager(
            tokenManager: mockTokenManager,
            apiClient: mockAPIClient
        )
    }
    
    func testSuccessfulLogin() async {
        // Given
        let expectedResponse = LoginResponse(
            accessToken: "access123",
            refreshToken: "refresh123",
            expiresIn: 3600,
            user: User(id: "1", email: "test@example.com", name: "Test User", role: "patient")
        )
        mockAPIClient.loginResponse = expectedResponse
        
        // When
        await authManager.signIn(email: "test@example.com", password: "password")
        
        // Then
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertEqual(authManager.user?.email, "test@example.com")
        XCTAssertFalse(authManager.isLoading)
        XCTAssertNil(authManager.errorMessage)
    }
    
    func testBiometricAuthenticationFlow() async {
        // Given
        authManager.isAuthenticated = true
        authManager.biometricAuthEnabled = true
        
        // When
        let success = await authManager.authenticateWithBiometrics()
        
        // Then
        XCTAssertTrue(success)
    }
}
```

## 11. Backend Integration Considerations

### JWT Token Structure (Backend)
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "user_id",
    "email": "user@example.com",
    "role": "patient",
    "iat": 1642680000,
    "exp": 1642683600,
    "iss": "healthapp-api",
    "aud": "healthapp-mobile"
  }
}
```

### API Endpoints Required (Backend Unchanged)
- `POST /auth/login` - Email/password authentication
- `POST /auth/refresh` - Token refresh (same whether biometric used or not)
- `GET /auth/verify` - Token verification
- `POST /auth/logout` - Token invalidation
- `GET /user/profile` - User profile data

**Critical Point**: The backend API remains completely unchanged. Biometric authentication is purely a client-side security enhancement that protects access to the refresh token.

## 13. Compliance and Security Notes

### HIPAA Compliance
- All tokens stored in iOS Keychain with proper access controls
- Biometric data never leaves the device (Secure Enclave)
- Comprehensive audit logging on backend
- Proper consent management for biometric enrollment
- Zero backend changes needed for compliance

### Security Measures
- Automatic token rotation prevents replay attacks
- Biometric protection for refresh tokens (local security layer)
- Certificate pinning for API communications
- App backgrounding protection with blur overlay
- Automatic logout on repeated biometric failures
- Backend agnostic - works with any JWT implementation

### Final Implementation Summary

This architecture provides a robust, secure, and user-friendly authentication system that:

1. **Maintains Backend Simplicity**: No changes needed to existing JWT refresh endpoints
2. **Enhances Client Security**: Biometric protection for sensitive token storage
3. **Follows Apple Guidelines**: Uses recommended Secure Enclave patterns
4. **Meets Healthcare Requirements**: HIPAA compliant with proper data protection
5. **Enables Gradual Rollout**: Can be enabled/disabled per user without backend coordination
6. **Provides Excellent UX**: Convenient biometric access while maintaining security

The key insight is that biometric authentication serves as a **local security gate** rather than a new authentication method - it protects access to existing credentials rather than replacing them.

### Error Handling Scenarios

```swift
// Handle different biometric failure scenarios
func handleBiometricFailure(_ error: BiometricError) async {
    switch error {
    case .authenticationFailed(let laError):
        let action = biometricManager.handleBiometricError(laError)
        
        switch action {
        case .keepCurrentSession:
            // User cancelled - keep them logged in with current session
            // Don't sign them out, just continue with existing access token
            break
            
        case .offerPasscodeFallback:
            // Too many failed attempts - offer device passcode
            let success = try? await biometricManager.authenticateWithFallback(
                reason: "Use your device passcode to access the app"
            )
            if success != true {
                await signOut()
            }
            
        case .disableBiometricProtection:
            // Hardware issue - disable biometric protection, use normal flow
            await disableBiometricAuth()
            try? await tokenManager.refreshTokens()
            
        case .showAppPasscode:
            // User chose "Enter Passcode" - implement app-specific passcode
            showAppPasscodeScreen()
            
        case .showError(let message):
            errorMessage = message
            await signOut()
        }
    }
}
```

### Testing Strategy

```swift
// Easy to test since backend behavior is unchanged
class AuthenticationManagerTests: XCTestCase {
    
    func testTokenRefreshWithBiometric() async {
        // Setup
        authManager.biometricAuthEnabled = true
        mockBiometric.shouldSucceed = true
        mockTokenManager.hasValidRefreshToken = true
        
        // Test
        await authManager.handleTokenExpiration()
        
        // Verify
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertEqual(mockAPI.refreshCallCount, 1)
        XCTAssertEqual(mockBiometric.authenticationCallCount, 1)
    }
    
    func testBiometricFailureFallback() async {
        // Setup
        authManager.biometricAuthEnabled = true
        mockBiometric.shouldSucceed = false
        mockBiometric.error = .biometryLockout
        
        // Test
        await authManager.handleTokenExpiration()
        
        // Verify fallback was offered
        XCTAssertTrue(mockBiometric.fallbackAuthenticationCalled)
    }
    
    func testBackendIntegrationUnchanged() async {
        // Test that backend sees identical requests regardless of biometric usage
        
        // Without biometric
        authManager.biometricAuthEnabled = false
        await authManager.handleTokenExpiration()
        let requestWithoutBiometric = mockAPI.lastRefreshRequest
        
        // With biometric
        authManager.biometricAuthEnabled = true
        mockBiometric.shouldSucceed = true
        await authManager.handleTokenExpiration()
        let requestWithBiometric = mockAPI.lastRefreshRequest
        
        // Verify requests are identical
        XCTAssertEqual(requestWithoutBiometric, requestWithBiometric)
    }
}
```

### Key Implementation Benefits

1. **Backend Doesn't Change**: Your existing JWT refresh endpoint stays exactly the same
2. **Gradual Rollout**: Can enable/disable biometric per user without backend changes
3. **Local Security Layer**: Biometric authentication only protects access to the refresh token
4. **User Experience**: Convenient biometric access while maintaining robust JWT flow
5. **Apple Security**: Uses Secure Enclave - biometric data never accessible to your app
6. **Network Independence**: Biometric check works offline, only token refresh needs network

### Security Benefits

- **Local Protection**: Even if device is compromised, refresh token needs biometric authentication
- **No Network Dependency**: Biometric check works offline
- **Apple Security**: Uses Secure Enclave - biometric data never leaves the device
- **Zero Backend Changes**: Maintains existing security model while adding client-side protection
- **Gradual Enhancement**: Can be enabled/disabled per user as needed