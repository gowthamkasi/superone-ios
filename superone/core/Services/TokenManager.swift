//
//  TokenManager.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Simplified JWT token management with reactive refresh strategy
//

import Foundation
import LocalAuthentication
import UIKit

/// Simple, reactive JWT token manager following standard practices
/// No complex expiration tracking - let server handle token validity
@preconcurrency final class TokenManager: @unchecked Sendable {
    
    // MARK: - Singleton
    static let shared = TokenManager()
    
    // MARK: - Private Properties
    nonisolated private let keychain: KeychainServiceProtocol = KeychainHelper.shared
    
    // NetworkService access helper - use the service layer NetworkService, not the model
    @MainActor private var apiService: superone.NetworkService {
        return superone.NetworkService.shared
    }
    
    // Keychain keys
    nonisolated private struct Keys {
        nonisolated static let accessToken = "access_token"
        nonisolated static let refreshToken = "refresh_token"
    }
    
    private init() {}
    
    // MARK: - Token Storage
    
    /// Store tokens after successful login - simple storage without biometric protection
    func storeTokens(accessToken: String, refreshToken: String) async throws {        
        // Validate JWT format before storing
        try validateJWTFormat(accessToken, tokenType: "access")
        try validateJWTFormat(refreshToken, tokenType: "refresh")
        
        // Store both tokens normally in keychain
        try keychain.store(token: accessToken, for: Keys.accessToken)
        try keychain.store(token: refreshToken, for: Keys.refreshToken)
    }
    
    
    // MARK: - Token Retrieval
    
    /// Get current access token (may be expired - server will validate)
    nonisolated func getAccessToken() -> String? {
        return try? keychain.retrieve(key: Keys.accessToken, withBiometrics: false)
    }
    
    /// Get valid access token - alias for getAccessToken for backward compatibility
    nonisolated func getValidToken() async -> String? {
        return getAccessToken()
    }
    
    /// Get refresh token - simple retrieval without biometric protection
    func getRefreshToken() async throws -> String? {
        guard let refreshToken = try? keychain.retrieve(key: Keys.refreshToken, withBiometrics: false) else {
            throw TokenError.refreshTokenNotFound
        }
        
        // JWT FORMAT VALIDATION with recovery logic
        do {
            try validateJWTFormat(refreshToken, tokenType: "refresh")
            return refreshToken
        } catch TokenError.invalidTokenResponse {
            // Recovery logic for JSON-wrapped tokens (from previous biometric storage)
            if refreshToken.hasPrefix("{") && refreshToken.contains("\"token\"") {
                do {
                    guard let data = refreshToken.data(using: .utf8) else {
                        throw TokenError.invalidTokenResponse
                    }
                    
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let unwrappedToken = json?["token"] as? String {
                        // Validate the unwrapped token
                        try validateJWTFormat(unwrappedToken, tokenType: "refresh")
                        
                        // Re-store the unwrapped token as raw JWT (no more JSON wrapping)
                        try keychain.store(token: unwrappedToken, for: Keys.refreshToken)
                        
                        return unwrappedToken
                    }
                } catch {
                    // Essential error logging for token recovery failure
                }
            }
            
            // If recovery fails, clear the corrupted token
            try? keychain.delete(key: Keys.refreshToken)
            throw TokenError.refreshTokenNotFound
        }
    }
    
    // MARK: - Reactive Token Refresh
    
    /// Reactive token refresh - call this when API returns 401/403
    func refreshTokensIfNeeded() async throws -> (accessToken: String, refreshToken: String) {
        
        // Get refresh token (handles biometric auth if enabled)
        guard let refreshToken = try await getRefreshToken() else {
            throw TokenError.refreshTokenNotFound
        }
        
        
        // Call refresh API using non-isolated helper
        let response = try await performTokenRefresh(refreshToken)
        
        
        guard response.success, let tokenData = response.data else {
            throw TokenError.refreshFailed
        }
        
        
        // Store new tokens without biometric protection (consistent with initial login)
        try await storeTokens(
            accessToken: tokenData.accessToken,
            refreshToken: tokenData.refreshToken
        )
        
        return (tokenData.accessToken, tokenData.refreshToken)
    }
    
    
    // MARK: - Token Management
    
    /// Check if we have valid tokens stored (doesn't validate expiration - server does that)
    nonisolated func hasStoredTokens() -> Bool {
        let hasAccessToken = (try? keychain.retrieve(key: Keys.accessToken, withBiometrics: false)) != nil
        let hasRefreshToken = (try? keychain.retrieve(key: Keys.refreshToken, withBiometrics: false)) != nil
        return hasAccessToken && hasRefreshToken
    }
    
    /// Clear all stored tokens
    nonisolated func clearTokens() async {
        try? keychain.delete(key: Keys.accessToken)
        try? keychain.delete(key: Keys.refreshToken)
    }
    
    
    // MARK: - Private Helpers
    
    /// Validate JWT format to ensure token is properly formatted
    private func validateJWTFormat(_ token: String, tokenType: String) throws {
        
        // Check for JSON wrapper (indicates corrupted storage)
        if token.hasPrefix("{") && token.contains("\"token\"") {
            throw TokenError.invalidTokenResponse
        }
        
        // Validate JWT structure (must have exactly 3 parts separated by dots)
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            throw TokenError.invalidTokenResponse
        }
        
        // Validate each part has reasonable length
        for (_, part) in parts.enumerated() {
            if part.isEmpty {
                throw TokenError.invalidTokenResponse
            }
            if part.count < 10 {
                // Parts shorter than 10 characters are likely invalid but we'll be lenient
            }
        }
        
    }
    
}

// MARK: - Token Errors

enum TokenError: @preconcurrency LocalizedError {
    case refreshTokenNotFound
    case refreshFailed
    case biometricNotAvailable
    case biometricNotEnabled
    case biometricAuthenticationFailed
    case accessTokenNotFound
    case invalidTokenResponse
    
    var errorDescription: String? {
        switch self {
        case .refreshTokenNotFound:
            return "Refresh token not found. Please log in again."
        case .refreshFailed:
            return "Failed to refresh authentication token. Please log in again."
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometricNotEnabled:
            return "Biometric authentication is not enabled for this account."
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed. Please try again or log in with email."
        case .accessTokenNotFound:
            return "Access token not found. Please log in again."
        case .invalidTokenResponse:
            return "Invalid response from authentication server."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .refreshTokenNotFound, .refreshFailed, .accessTokenNotFound:
            return "Please log in again with your email and password."
        case .biometricNotAvailable:
            return "Please enable Face ID or Touch ID in your device settings."
        case .biometricNotEnabled:
            return "Enable biometric authentication in app settings for quick access."
        case .biometricAuthenticationFailed:
            return "Try biometric authentication again or use email login."
        case .invalidTokenResponse:
            return "Check your internet connection and try again."
        }
    }
}

// MARK: - Network Service Extension

// MARK: - Non-isolated Helper Function

// RefreshTokenRequest model is no longer needed since we use headers only

nonisolated func performTokenRefresh(_ refreshToken: String) async throws -> TokenResponse {
    // Avoid the generic post method entirely - use a simpler approach
    return try await withCheckedThrowingContinuation { continuation in
        Task { @MainActor in
            do {
                // Create a simple refresh request directly in the MainActor context
                let endpoint = APIConfiguration.Endpoints.Auth.refresh
                
                // Use a basic HTTP request instead of the complex generic post method
                let response = try await superone.NetworkService.shared.performRefreshRequest(
                    endpoint: endpoint,
                    refreshToken: refreshToken
                )
                continuation.resume(returning: response)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

extension superone.NetworkService {
    /// Refresh tokens using refresh token  
    func refreshToken(_ refreshToken: String) async throws -> TokenResponse {
        return try await performTokenRefresh(refreshToken)
    }
    
    /// Direct refresh request method using GET with headers
    func performRefreshRequest(endpoint: String, refreshToken: String) async throws -> TokenResponse {
        
        // Create URL string and convert to URL
        let urlString = APIConfiguration.mobileURL(for: endpoint)
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var request = URLRequest(url: url)
            request.httpMethod = "GET"  // Changed from POST to GET
            // No request body needed for GET request
            
            // Add standard headers manually
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("SuperOne-iOS/1.0.0", forHTTPHeaderField: "User-Agent")
            request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
            
            // Add refresh token header
            request.setValue(refreshToken, forHTTPHeaderField: "x-refresh-token")
            
            // Add device ID header
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
            request.setValue(deviceId, forHTTPHeaderField: "x-device-id")
            
            // Use URLSession directly instead of Alamofire session
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: NetworkError.unknownError(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: NetworkError.invalidResponse)
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        continuation.resume(throwing: NetworkError.authenticationRequired)
                    } else {
                        continuation.resume(throwing: NetworkError.serverError(httpResponse.statusCode))
                    }
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: NetworkError.invalidResponse)
                    return
                }
                
                do {
                    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                    continuation.resume(returning: tokenResponse)
                } catch {
                    continuation.resume(throwing: NetworkError.decodingError(error))
                }
            }.resume()
        }
    }
}

// MARK: - Request/Response Models

// Note: RefreshTokenRequest model removed - using headers only for GET requests
// Note: TokenResponse and AuthTokens are defined in APIResponseModels.swift