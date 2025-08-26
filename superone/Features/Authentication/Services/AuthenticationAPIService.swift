//
//  AuthenticationAPIService.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//

@preconcurrency import Foundation
import UIKit
import Combine
import os.log
@preconcurrency import Alamofire

// Define UserResponse type for getCurrentUser

// MARK: - Authentication Request Models (moved outside of class to avoid main actor isolation)

struct APIRegisterRequest: @preconcurrency Codable, Sendable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let dateOfBirth: String
    let gender: String
    let diagnosisDate: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case email
        case password
        case firstName
        case lastName
        case dateOfBirth
        case gender
        case diagnosisDate
    }
}

struct APIUserProfileRequest: @preconcurrency Codable, Sendable {
    let dateOfBirth: Date?
    let gender: String?
    let height: Double?
    let weight: Double?
    let activityLevel: String?
    let healthGoals: [String]?
    let medicalConditions: [String]?
    let medications: [String]?
    let allergies: [String]?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case dateOfBirth
        case gender
        case height
        case weight
        case activityLevel
        case healthGoals
        case medicalConditions
        case medications
        case allergies
    }
}

struct APILoginRequest: @preconcurrency Codable, Sendable {
    let email: String
    let password: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case email
        case password
    }
}


struct APIForgotPasswordRequest: @preconcurrency Codable, Sendable {
    let email: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case email
    }
}


// MARK: - Authentication Error Types

enum AuthenticationAPIError: @preconcurrency LocalizedError {
    case invalidCredentials
    case tokenStorageError(Error)
    case noRefreshToken
    case tokenExpired
    case unauthorized
    case networkError(Error)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .tokenStorageError(let error):
            return "Failed to store authentication token: \(error.localizedDescription)"
        case .noRefreshToken:
            return "No refresh token available"
        case .tokenExpired:
            return "Authentication token has expired"
        case .unauthorized:
            return "Authentication required - please log in again"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown authentication error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Please check your email and password and try again"
        case .tokenStorageError:
            return "Please try logging in again"
        case .noRefreshToken, .tokenExpired, .unauthorized:
            return "Please log in again"
        case .networkError:
            return "Please check your internet connection and try again"
        case .unknownError:
            return "Please try again or contact support if the problem persists"
        }
    }
}

/// Authentication API service for Super One backend integration
class AuthenticationAPIService: ObservableObject {
    
    // MARK: - Properties
    
    private let networkService: NetworkService
    private let keychainHelper: KeychainHelper
    private let logger = Logger(subsystem: "com.superone.health", category: "Authentication")
    private let tokenManager = TokenManager.shared
    
    // MARK: - Initialization
    
    init(
        networkService: NetworkService = NetworkService.shared,
        keychainHelper: KeychainHelper = KeychainHelper.shared
    ) {
        self.networkService = networkService
        self.keychainHelper = keychainHelper
        
        // Validate production security on initialization
        _ = isProductionSecure
    }
    
    // MARK: - Public API Methods
    
    /// Register a new user
    func register(
        email: String,
        password: String,
        name: String,
        profile: UserProfile
    ) async throws -> AuthResponse {
        
        // Split name into firstName and lastName
        let nameParts = name.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        
        // Format date of birth for backend - use a default date if profile.dateOfBirth is nil
        let dateOfBirthString: String
        if let dateOfBirth = profile.dateOfBirth {
            dateOfBirthString = dateOfBirth.dateOnlyString  // Backend expects YYYY-MM-DD format
        } else {
            // Use a placeholder date for registration (can be updated in profile later)
            let calendar = Calendar.current
            let defaultDate = calendar.date(byAdding: .year, value: -25, to: Date()) ?? Date()
            dateOfBirthString = defaultDate.dateOnlyString  // Backend expects YYYY-MM-DD format
        }
        
        // Debug gender value transformation
        let genderRawValue = profile.gender?.rawValue ?? "not_specified"
        
        let request = APIRegisterRequest(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirthString,
            gender: genderRawValue,
            diagnosisDate: nil // Optional field
        )
        
        
        // Debug JSON serialization to verify exact payload
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(request)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "Could not convert to string"
        } catch {
        }
        
        // Test JSON encoding before sending to NetworkService
        do {
            let testData = try JSONEncoder().encode(request)
            let testString = String(data: testData, encoding: .utf8) ?? "Could not convert to string"
        } catch {
            throw error
        }
        
        let response: AuthResponse = try await networkService.post(
            APIConfiguration.Endpoints.Auth.register,
            body: request,
            responseType: AuthResponse.self,
            timeout: 20.0  // Explicit 20 second timeout for registration
        )
        
        // Store tokens if registration successful
        if response.success, let authData = response.data {
            try await storeAuthTokens(authData.tokens)
        } else {
        }
        
        return response
    }
    
    /// Login user
    func login(email: String, password: String) async throws -> AuthResponse {
        
        let request = APILoginRequest(email: email, password: password)
        
        let response: AuthResponse = try await networkService.post(
            APIConfiguration.Endpoints.Auth.login,
            body: request,
            responseType: AuthResponse.self,
            timeout: 15.0  // Explicit 15 second timeout for login
        )
        
        // Store tokens if login successful
        if response.success, let authData = response.data {
            try await storeAuthTokens(authData.tokens)
        } else {
        }
        
        return response
    }
    
    /// Refresh authentication token
    func refreshToken() async throws -> TokenResponse {
        guard let refreshToken = await keychainHelper.getRefreshToken() else {
            throw AuthenticationAPIError.noRefreshToken
        }
        
        // Get device ID for the header
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        
        // Create custom headers with refresh token and device ID
        let headers: HTTPHeaders = [
            "x-refresh-token": refreshToken,
            "x-device-id": deviceId
        ]
        
        let response: TokenResponse = try await networkService.get(
            APIConfiguration.Endpoints.Auth.refresh,
            responseType: TokenResponse.self,
            headers: headers
        )
        
        // Store new tokens if refresh successful
        if response.success, let tokens = response.data {
            try await storeAuthTokens(tokens)
        }
        
        return response
    }
    
    /// Logout user from current device
    func logout(fromCurrentDeviceOnly: Bool = true) async throws -> LogoutResponse {
        // Get device ID from the header system (matches x-device-id header)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        
        // Create logout request matching backend API contract
        let request = LogoutRequest(
            deviceId: fromCurrentDeviceOnly ? deviceId : nil,
            allDevices: fromCurrentDeviceOnly ? nil : true
        )
        
        logger.info("Initiating logout: device=\(deviceId), currentDeviceOnly=\(fromCurrentDeviceOnly)")
        
        do {
            // Make logout API call to backend
            let response: LogoutResponse = try await networkService.post(
                APIConfiguration.Endpoints.Auth.logout,
                body: request,
                responseType: LogoutResponse.self,
                timeout: 10.0  // Quick timeout for logout
            )
            
            logger.info("Backend logout response: success=\(response.success), message=\(response.message ?? "none")")
            
            // Clear stored tokens after successful API call
            if response.success {
                await clearAuthTokens()
                logger.info("Local authentication tokens cleared successfully")
            } else {
                // Even if backend logout fails, clear local tokens for security
                await clearAuthTokens()
                logger.warning("Backend logout failed, but cleared local tokens for security: \(response.error ?? response.message ?? "unknown error")")
            }
            
            return response
            
        } catch {
            logger.error("Logout API call failed: \(error.localizedDescription)")
            
            // Always clear local tokens for security, even if API call fails
            await clearAuthTokens()
            logger.warning("Cleared local tokens despite logout API failure for security")
            
            // Re-throw the original error
            throw error
        }
    }
    
    /// Logout from all devices
    func logoutFromAllDevices() async throws -> LogoutResponse {
        return try await logout(fromCurrentDeviceOnly: false)
    }
    
    /// Request password reset
    func forgotPassword(email: String) async throws -> PasswordResetResponse {
        let request = APIForgotPasswordRequest(email: email)
        
        let response: PasswordResetResponse = try await networkService.post(
            APIConfiguration.Endpoints.Auth.forgotPassword,
            body: request,
            responseType: PasswordResetResponse.self
        )
        
        return response
    }
    
    // MARK: - Token Management
    
    /// Store authentication tokens securely
    private func storeAuthTokens(_ tokens: AuthTokens) async throws {
        await keychainHelper.storeAuthToken(tokens.accessToken)
        await keychainHelper.storeRefreshToken(tokens.refreshToken)
        
        // Note: Token expiration tracking removed - using reactive JWT approach
        
    }
    
    /// Clear all stored authentication tokens
    private func clearAuthTokens() async {
        await keychainHelper.clearAuthToken()
        await keychainHelper.clearRefreshToken()
        
    }
    
    /// Check if current token exists (server validates expiry)
    func isTokenValid() async -> Bool {
        guard let token = await keychainHelper.getAuthToken(),
              !token.isEmpty else {
            return false
        }
        
        // Simplified: Let server handle token validation via JWT expiry
        return true
    }
    
    /// Get current authentication token
    func getCurrentToken() async -> String? {
        return await keychainHelper.getAuthToken()
    }
    
    // REMOVED: refreshTokenIfNeeded() - using reactive approach in TokenManager instead
    
    // MARK: - User Session Management
    
    /// Check if user is currently authenticated
    func isAuthenticated() async -> Bool {
        return await isTokenValid()
    }
    
    /// Get current user from stored token
    nonisolated func getCurrentUser() async throws -> User? {
        guard await isAuthenticated() else {
            logger.info("User not authenticated, cannot fetch current user")
            return nil
        }
        
        guard let token = await tokenManager.getValidToken() else {
            logger.warning("No valid token available for getCurrentUser")
            return nil
        }
        
        do {
            logger.info("Fetching current user from backend API")
            
            let response: User = try await networkService.get(
                APIConfiguration.Endpoints.Mobile.currentUser,
                responseType: User.self
            )
            
            logger.info("Successfully fetched current user: \(response.email)")
            return response
            
        } catch {
            logger.error("Failed to fetch current user: \(error.localizedDescription)")
            
            // If it's an authentication error, user might need to re-login
            if let apiError = error as? AuthenticationAPIError, case .unauthorized = apiError {
                await tokenManager.clearTokens()
            }
            
            throw error
        }
    }
    
}

// MARK: - Validation Helpers

extension AuthenticationAPIService {
    
    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validate password strength
    static func isValidPassword(_ password: String) -> Bool {
        // Minimum 8 characters, at least one uppercase, one lowercase, one number
        return password.count >= 8 &&
               password.rangeOfCharacter(from: .uppercaseLetters) != nil &&
               password.rangeOfCharacter(from: .lowercaseLetters) != nil &&
               password.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    /// Get password validation errors
    static func getPasswordValidationErrors(_ password: String) -> [String] {
        var errors: [String] = []
        
        if password.count < 8 {
            errors.append("Password must be at least 8 characters long")
        }
        
        if password.rangeOfCharacter(from: .uppercaseLetters) == nil {
            errors.append("Password must contain at least one uppercase letter")
        }
        
        if password.rangeOfCharacter(from: .lowercaseLetters) == nil {
            errors.append("Password must contain at least one lowercase letter")
        }
        
        if password.rangeOfCharacter(from: .decimalDigits) == nil {
            errors.append("Password must contain at least one number")
        }
        
        return errors
    }
}

// MARK: - Mock Mode Support (for development)

extension AuthenticationAPIService {
    
    // MARK: - Production Security Validation
    
    /// Validate that we're not in an insecure development mode in production
    private func validateProductionSecurity() {
        #if DEBUG
        // In debug builds, log security mode
        if ProcessInfo.processInfo.arguments.contains("--mock-auth") {
        }
        #else
        // In production, ensure no debug flags are present
        let debugArgs = ["--mock-auth", "--debug", "--test", "--dev", "--unsafe"]
        let currentArgs = ProcessInfo.processInfo.arguments
        
        for debugArg in debugArgs {
            if currentArgs.contains(debugArg) {
                fatalError("🚨 SECURITY ERROR: Debug argument '\(debugArg)' detected in production build. This is a critical security vulnerability.")
            }
        }
        
        // Validate we're using HTTPS endpoints in production
        if !APIConfiguration.baseURL.hasPrefix("https://") {
            fatalError("🚨 SECURITY ERROR: Non-HTTPS endpoint detected in production: \(APIConfiguration.baseURL)")
        }
        #endif
    }
    
    /// Check if app is running in a secure production environment
    private var isProductionSecure: Bool {
        validateProductionSecurity()
        return true
    }
}