//
//  ProfileAPIService.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

@preconcurrency import Foundation
import UIKit
import Combine
import os.log
@preconcurrency import Alamofire

/// Profile API service for managing user profile updates
@MainActor
class ProfileAPIService: ObservableObject {
    
    // MARK: - Properties
    
    private let networkService: NetworkService
    private let tokenManager = TokenManager.shared
    private let logger = Logger(subsystem: "com.superone.health", category: "ProfileAPI")
    
    // MARK: - Initialization
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
    }
    
    // MARK: - Profile Update API
    
    /// Update user profile with mobile number and other fields
    /// - Parameter request: Profile update request with optional fields
    /// - Returns: Updated user profile response
    /// - Throws: ProfileAPIError for various error conditions
    nonisolated func updateProfile(_ request: UpdateProfileRequest) async throws -> UpdateProfileResponse {
        
        // Validate that at least one field is provided
        let hasValidField = request.firstName != nil ||
                           request.lastName != nil ||
                           request.email != nil ||
                           request.mobileNumber != nil ||
                           request.profilePicture != nil ||
                           request.dob != nil ||
                           request.gender != nil ||
                           request.height != nil ||
                           request.weight != nil
        
        guard hasValidField else {
            throw ProfileAPIError.validationFailed("At least one field must be provided for profile update")
        }
        
        // Validate email format if provided
        if let email = request.email, !email.isEmpty {
            guard isValidEmail(email) else {
                throw ProfileAPIError.validationFailed("Invalid email format")
            }
        }
        
        // Validate mobile number format if provided
        if let mobileNumber = request.mobileNumber, !mobileNumber.isEmpty {
            guard isValidMobileNumber(mobileNumber) else {
                throw ProfileAPIError.validationFailed("Invalid mobile number format")
            }
        }
        
        // Ensure we have a valid authentication token
        guard let token = await tokenManager.getValidToken() else {
            throw ProfileAPIError.unauthorized("Authentication token required")
        }
        
        do {
            let response: UpdateProfileResponse = try await networkService.put(
                APIConfiguration.Endpoints.Mobile.profile,
                body: request,
                responseType: UpdateProfileResponse.self
            )
            
            // Validate response structure
            guard response.success else {
                let errorMessage = response.message.isEmpty ? "Profile update failed" : response.message
                throw ProfileAPIError.updateFailed(errorMessage)
            }
            
            guard response.data?.user != nil else {
                throw ProfileAPIError.invalidResponse("No user data received in response")
            }
            
            return response
            
        } catch {
            // Handle specific network errors
            if let afError = error.asAFError {
                switch afError {
                case .sessionTaskFailed(let sessionError):
                    if let urlError = sessionError as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet:
                            throw ProfileAPIError.networkError("No internet connection available")
                        case .timedOut:
                            throw ProfileAPIError.networkError("Request timed out")
                        default:
                            throw ProfileAPIError.networkError("Network error: \(urlError.localizedDescription)")
                        }
                    }
                case .responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)):
                    switch statusCode {
                    case 400:
                        throw ProfileAPIError.validationFailed("Invalid profile data provided")
                    case 401:
                        await tokenManager.clearTokens()
                        throw ProfileAPIError.unauthorized("Authentication required")
                    case 403:
                        throw ProfileAPIError.forbidden("Profile update not permitted")
                    case 409:
                        throw ProfileAPIError.conflictError("Email or mobile number already in use")
                    case 422:
                        throw ProfileAPIError.validationFailed("Profile validation failed")
                    case 500...599:
                        throw ProfileAPIError.serverError("Server error occurred")
                    default:
                        throw ProfileAPIError.unknownError("HTTP \(statusCode): Profile update failed")
                    }
                default:
                    throw ProfileAPIError.networkError("Network error: \(afError.localizedDescription)")
                }
            }
            
            // Re-throw ProfileAPIError as-is
            if error is ProfileAPIError {
                throw error
            }
            
            // Handle unknown errors
            throw ProfileAPIError.unknownError("Profile update failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Validation Helpers
    
    /// Validate email format using comprehensive regex
    private nonisolated func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validate mobile number format (supports international formats)
    private nonisolated func isValidMobileNumber(_ mobileNumber: String) -> Bool {
        // Remove all non-digit characters for validation
        let digitsOnly = mobileNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Mobile number should be 10-15 digits
        guard digitsOnly.count >= 10 && digitsOnly.count <= 15 else {
            return false
        }
        
        // Basic pattern matching for common formats
        let patterns = [
            #"^\+?1?[2-9]\d{2}[2-9]\d{2}\d{4}$"#,     // US/Canada format
            #"^\+?[1-9]\d{1,14}$"#,                     // International format
            #"^[0-9]{10}$"#,                            // Simple 10-digit
            #"^\+[0-9]{1,3}[0-9]{4,14}$"#               // International with country code
        ]
        
        return patterns.contains { pattern in
            let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
            return predicate.evaluate(with: mobileNumber)
        }
    }
}

// MARK: - Profile API Errors

/// Comprehensive error handling for profile API operations
enum ProfileAPIError: @preconcurrency LocalizedError, Equatable {
    case validationFailed(String)
    case unauthorized(String)
    case forbidden(String)
    case conflictError(String)
    case networkError(String)
    case serverError(String)
    case updateFailed(String)
    case invalidResponse(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return "Validation Error: \(message)"
        case .unauthorized(let message):
            return "Authentication Error: \(message)"
        case .forbidden(let message):
            return "Permission Error: \(message)"
        case .conflictError(let message):
            return "Conflict Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .updateFailed(let message):
            return "Update Failed: \(message)"
        case .invalidResponse(let message):
            return "Invalid Response: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .validationFailed:
            return "Please check your input and try again"
        case .unauthorized:
            return "Please log in again"
        case .forbidden:
            return "You don't have permission to perform this action"
        case .conflictError:
            return "Please use a different email or mobile number"
        case .networkError:
            return "Please check your internet connection and try again"
        case .serverError:
            return "Please try again later"
        case .updateFailed:
            return "Please verify your information and try again"
        case .invalidResponse:
            return "Please try again or contact support"
        case .unknownError:
            return "Please try again or contact support if the problem persists"
        }
    }
    
    /// User-friendly error message for UI display
    var userFriendlyMessage: String {
        switch self {
        case .validationFailed(let message):
            return message
        case .unauthorized:
            return "Please log in to update your profile"
        case .forbidden:
            return "You don't have permission to update this profile"
        case .conflictError(let message):
            return message
        case .networkError:
            return "Unable to connect. Please check your internet connection"
        case .serverError:
            return "Server is temporarily unavailable. Please try again later"
        case .updateFailed(let message):
            return message
        case .invalidResponse:
            return "Something went wrong. Please try again"
        case .unknownError:
            return "An unexpected error occurred. Please try again"
        }
    }
    
    /// Determine if the error is recoverable by retrying
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .unknownError:
            return true
        case .validationFailed, .unauthorized, .forbidden, .conflictError, .updateFailed, .invalidResponse:
            return false
        }
    }
}

// MARK: - ProfileAPIError CaseIterable Support

extension ProfileAPIError: CaseIterable {
    static var allCases: [ProfileAPIError] {
        return [
            .validationFailed(""),
            .unauthorized(""),
            .forbidden(""),
            .conflictError(""),
            .networkError(""),
            .serverError(""),
            .updateFailed(""),
            .invalidResponse(""),
            .unknownError("")
        ]
    }
}

// MARK: - Profile Update Helper Extensions

extension UpdateProfileRequest {
    
    /// Create a profile update request from a User model
    static func from(user: User, updatedFields: [String: Any]) -> UpdateProfileRequest {
        return UpdateProfileRequest(
            firstName: updatedFields["firstName"] as? String ?? user.firstName,
            lastName: updatedFields["lastName"] as? String ?? user.lastName,
            email: updatedFields["email"] as? String ?? user.email,
            mobileNumber: updatedFields["mobileNumber"] as? String ?? user.mobileNumber,
            profilePicture: updatedFields["profilePicture"] as? String ?? user.profileImageURL,
            dob: updatedFields["dob"] as? Date ?? user.dateOfBirth,
            gender: updatedFields["gender"] as? String ?? user.gender?.rawValue,
            height: updatedFields["height"] as? Double ?? user.height,
            weight: updatedFields["weight"] as? Double ?? user.weight
        )
    }
    
    /// Create a profile update request with only changed fields
    static func withChanges(
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        mobileNumber: String? = nil,
        profilePicture: String? = nil,
        dob: Date? = nil,
        gender: Gender? = nil,
        height: Double? = nil,
        weight: Double? = nil
    ) -> UpdateProfileRequest {
        return UpdateProfileRequest(
            firstName: firstName,
            lastName: lastName,
            email: email,
            mobileNumber: mobileNumber,
            profilePicture: profilePicture,
            dob: dob,
            gender: gender?.rawValue,
            height: height,
            weight: weight
        )
    }
    
    /// Check if the request has any non-nil, non-empty fields
    var hasChanges: Bool {
        // Helper function to check if a string field has meaningful content
        let hasValue: (String?) -> Bool = { string in
            guard let string = string else { return false }
            return !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        let changes = [
            ("firstName", hasValue(firstName)),
            ("lastName", hasValue(lastName)),
            ("email", hasValue(email)),
            ("mobileNumber", hasValue(mobileNumber)),
            ("profilePicture", hasValue(profilePicture)),
            ("dob", dob != nil),
            ("gender", hasValue(gender)),
            ("height", height != nil),
            ("weight", weight != nil)
        ]
        
        // Debug logging to help identify what changes were detected
        let detectedChanges = changes.filter { $0.1 }.map { $0.0 }
        print("🔍 UpdateProfileRequest.hasChanges - Detected changes: \(detectedChanges)")
        
        return detectedChanges.count > 0
    }
    
    /// Debug description showing which fields have changes
    var changesDescription: String {
        var changes: [String] = []
        
        if firstName != nil && !firstName!.isEmpty { changes.append("firstName: '\(firstName!)'") }
        if lastName != nil && !lastName!.isEmpty { changes.append("lastName: '\(lastName!)'") }
        if email != nil && !email!.isEmpty { changes.append("email: '\(email!)'") }
        if mobileNumber != nil && !mobileNumber!.isEmpty { changes.append("mobileNumber: '\(mobileNumber!)'") }
        if profilePicture != nil && !profilePicture!.isEmpty { changes.append("profilePicture: '\(profilePicture!)'") }
        if dob != nil { changes.append("dob: '\(dob!)'") }
        if gender != nil && !gender!.isEmpty { changes.append("gender: '\(gender!)'") }
        if height != nil { changes.append("height: '\(height!)'") }
        if weight != nil { changes.append("weight: '\(weight!)'") }
        
        return changes.isEmpty ? "No changes" : changes.joined(separator: ", ")
    }
}

extension UpdatedUserProfile {
    
    /// Convert API response user profile to main User model
    func toUser(withId id: String) -> User {
        // Convert zero values to nil for height and weight to make them truly optional
        let optionalHeight = (height == nil || height == 0) ? nil : height
        let optionalWeight = (weight == nil || weight == 0) ? nil : weight
        
        return User(
            id: id,
            email: self.email,
            name: "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces),
            firstName: firstName,
            lastName: lastName,
            profileImageURL: nil,
            phoneNumber: mobileNumber, // Map mobileNumber to phoneNumber for compatibility
            mobileNumber: mobileNumber,
            dateOfBirth: dob,
            gender: Gender(rawValue: gender ?? "not_specified"),
            height: optionalHeight, // Convert 0 to nil
            weight: optionalWeight, // Convert 0 to nil
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}