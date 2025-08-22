import Foundation
import SwiftUI

// MARK: - Authentication View Models

/// Login form data model with validation
struct LoginFormData: Sendable {
    var email: String = ""
    var password: String = ""
    var rememberMe: Bool = false
    
    var isEmailValid: Bool {
        ValidationHelper.isValidEmail(email)
    }
    
    var isPasswordValid: Bool {
        !password.isEmpty && password.count >= 6
    }
    
    var isFormValid: Bool {
        isEmailValid && isPasswordValid
    }
    
    var toNetworkModel: LoginRequest {
        LoginRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            password: password,
            deviceId: UIDevice.current.identifierForVendor?.uuidString,
            rememberMe: rememberMe
        )
    }
}

/// Registration form data model with comprehensive validation
struct RegistrationFormData: Sendable {
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var name: String = ""
    var dateOfBirth: Date?
    var phoneNumber: String = ""
    var acceptedTerms: Bool = false
    var acceptedPrivacy: Bool = false
    
    // MARK: - Validation Properties
    
    var isEmailValid: Bool {
        ValidationHelper.isValidEmail(email)
    }
    
    var isPasswordValid: Bool {
        ValidationHelper.isValidPassword(password)
    }
    
    var isConfirmPasswordValid: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }
    
    var isNameValid: Bool {
        ValidationHelper.isValidName(name)
    }
    
    var isPhoneNumberValid: Bool {
        phoneNumber.isEmpty || ValidationHelper.isValidPhoneNumber(phoneNumber)
    }
    
    var isDateOfBirthValid: Bool {
        guard let dateOfBirth = dateOfBirth else { return true } // Optional field
        return ValidationHelper.isValidDateOfBirth(dateOfBirth)
    }
    
    var areTermsAccepted: Bool {
        acceptedTerms && acceptedPrivacy
    }
    
    var isFormValid: Bool {
        isEmailValid && 
        isPasswordValid && 
        isConfirmPasswordValid && 
        isNameValid && 
        isPhoneNumberValid && 
        isDateOfBirthValid && 
        areTermsAccepted
    }
    
    var toNetworkModel: RegistrationRequest {
        RegistrationRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            password: password,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            dateOfBirth: dateOfBirth,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            deviceId: UIDevice.current.identifierForVendor?.uuidString,
            acceptedTerms: acceptedTerms,
            acceptedPrivacy: acceptedPrivacy
        )
    }
}

// MARK: - Authentication State Models

/// Authentication state enum
enum AuthenticationState: Equatable, Sendable {
    case idle
    case loading
    case success(User)
    case error(AuthenticationError)
    case biometricPrompt
    case requiresTwoFactor
}

/// Authentication flow type
enum AuthenticationFlow: Sendable {
    case login
    case registration
    case passwordReset
    case biometricLogin
}

/// Biometric authentication state
enum BiometricAuthState: Equatable, Sendable {
    case unavailable
    case available
    case authenticating
    case success
    case failed(String)
    case cancelled
    case fallback
}

// MARK: - Authentication Errors

/// Authentication-specific errors for UI display
enum AuthenticationError: @preconcurrency LocalizedError, Equatable {
    case invalidCredentials
    case accountLocked
    case emailNotVerified
    case twoFactorRequired
    case networkError(String)
    case serverError(String)
    case validationError(String)
    case biometricError(String)
    case tokenExpired
    case unknownError
    case registrationFailed
    case sessionExpired
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please check your credentials and try again."
        case .accountLocked:
            return "Your account has been temporarily locked. Please try again later or contact support."
        case .emailNotVerified:
            return "Please verify your email address before signing in."
        case .twoFactorRequired:
            return "Two-factor authentication is required. Please check your authenticator app."
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .validationError(let message):
            return message
        case .biometricError(let message):
            return "Biometric authentication failed: \(message)"
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        case .registrationFailed:
            return "Registration failed. Please check your information and try again."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Double-check your email and password, or use 'Forgot Password' if needed."
        case .accountLocked:
            return "Wait a few minutes before trying again, or contact customer support."
        case .emailNotVerified:
            return "Check your email for a verification link, or request a new one."
        case .twoFactorRequired:
            return "Enter the code from your authenticator app to continue."
        case .networkError:
            return "Check your internet connection and try again."
        case .serverError:
            return "Our servers are experiencing issues. Please try again in a few minutes."
        case .validationError:
            return "Please correct the highlighted fields and try again."
        case .biometricError:
            return "Use your passcode instead, or try biometric authentication again."
        case .tokenExpired:
            return "Please sign in with your email and password."
        case .unknownError:
            return "If the problem persists, please contact support."
        case .registrationFailed:
            return "Please verify your information and try again."
        case .sessionExpired:
            return "Please sign in with your email and password."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidCredentials:
            return "Email and password combination does not match any registered account"
        case .accountLocked:
            return "Account access has been restricted due to security policy"
        case .emailNotVerified:
            return "Account email address verification is pending"
        case .twoFactorRequired:
            return "Additional authentication factor is required for this account"
        case .networkError(let message):
            return "Network connectivity issue: \(message)"
        case .serverError(let message):
            return "Server processing error: \(message)"
        case .validationError(let message):
            return "Input validation failed: \(message)"
        case .biometricError(let message):
            return "Biometric authentication error: \(message)"
        case .tokenExpired:
            return "Authentication session has exceeded maximum lifetime"
        case .unknownError:
            return "An unexpected authentication error occurred"
        case .registrationFailed:
            return "User account creation process failed"
        case .sessionExpired:
            return "Authentication session has exceeded maximum lifetime"
        }
    }
    
    var helpAnchor: String? {
        switch self {
        case .invalidCredentials:
            return "invalid-login-help"
        case .accountLocked:
            return "locked-account-help"
        case .emailNotVerified:
            return "email-verification-help"
        case .twoFactorRequired:
            return "two-factor-auth-help"
        case .networkError:
            return "network-troubleshooting-help"
        case .serverError:
            return "server-error-help"
        case .validationError:
            return "input-validation-help"
        case .biometricError:
            return "biometric-troubleshooting-help"
        case .tokenExpired:
            return "session-expired-help"
        case .unknownError:
            return "general-auth-help"
        case .registrationFailed:
            return "registration-help"
        case .sessionExpired:
            return "session-expired-help"
        }
    }
    
    static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials),
             (.accountLocked, .accountLocked),
             (.emailNotVerified, .emailNotVerified),
             (.twoFactorRequired, .twoFactorRequired),
             (.tokenExpired, .tokenExpired),
             (.unknownError, .unknownError):
            return true
        case (.networkError(let lhsMessage), .networkError(let rhsMessage)),
             (.serverError(let lhsMessage), .serverError(let rhsMessage)),
             (.validationError(let lhsMessage), .validationError(let rhsMessage)),
             (.biometricError(let lhsMessage), .biometricError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Field Validation States

/// Individual field validation state
enum FieldValidationState: Equatable, Sendable {
    case idle
    case valid
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .idle, .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .invalid(let message):
            return message
        case .idle, .valid:
            return nil
        }
    }
}

/// Form validation states for UI feedback
struct FormValidationStates: Sendable {
    var email: FieldValidationState = .idle
    var password: FieldValidationState = .idle
    var confirmPassword: FieldValidationState = .idle
    var name: FieldValidationState = .idle
    var phoneNumber: FieldValidationState = .idle
    var dateOfBirth: FieldValidationState = .idle
}

// MARK: - Validation Helper

/// Centralized validation logic for authentication forms
struct ValidationHelper: Sendable {
    
    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validate password strength
    static func isValidPassword(_ password: String) -> Bool {
        // Minimum 8 characters, at least one letter and one number
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d@$!%*?&]{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }
    
    /// Validate name format
    static func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 50
    }
    
    /// Validate phone number format (US format for now)
    static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^\\+?1?[-.\\s]?\\(?[0-9]{3}\\)?[-.\\s]?[0-9]{3}[-.\\s]?[0-9]{4}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }
    
    /// Validate date of birth (must be at least 18 years old)
    static func isValidDateOfBirth(_ dateOfBirth: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
        guard let age = ageComponents.year else { return false }
        return age >= 18 && age <= 120
    }
    
    /// Get password strength description
    static func passwordStrength(_ password: String) -> (strength: PasswordStrength, description: String) {
        let length = password.count
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasDigits = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialChars = password.rangeOfCharacter(from: CharacterSet(charactersIn: "@$!%*?&")) != nil
        
        var score = 0
        if length >= 8 { score += 1 }
        if length >= 12 { score += 1 }
        if hasLowercase { score += 1 }
        if hasUppercase { score += 1 }
        if hasDigits { score += 1 }
        if hasSpecialChars { score += 1 }
        
        switch score {
        case 0...2:
            return (.weak, "Weak - Add more characters and variety")
        case 3...4:
            return (.medium, "Medium - Consider adding special characters")
        case 5...6:
            return (.strong, "Strong password")
        default:
            return (.strong, "Strong password")
        }
    }
    
    /// Get detailed validation message for email
    static func emailValidationMessage(_ email: String) -> String? {
        if email.isEmpty {
            return "Email address is required"
        }
        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }
        return nil
    }
    
    /// Get detailed validation message for password
    static func passwordValidationMessage(_ password: String) -> String? {
        if password.isEmpty {
            return "Password is required"
        }
        if password.count < 8 {
            return "Password must be at least 8 characters"
        }
        if !isValidPassword(password) {
            return "Password must contain at least one letter and one number"
        }
        return nil
    }
    
    /// Get detailed validation message for name
    static func nameValidationMessage(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Name is required"
        }
        if trimmed.count < 2 {
            return "Name must be at least 2 characters"
        }
        if trimmed.count > 50 {
            return "Name cannot exceed 50 characters"
        }
        return nil
    }
}

// MARK: - Password Strength Enum

enum PasswordStrength: CaseIterable, Sendable {
    case weak
    case medium
    case strong
    
    var color: Color {
        switch self {
        case .weak:
            return HealthColors.healthCritical
        case .medium:
            return HealthColors.healthWarning
        case .strong:
            return HealthColors.healthGood
        }
    }
    
    var description: String {
        switch self {
        case .weak:
            return "Weak"
        case .medium:
            return "Medium"
        case .strong:
            return "Strong"
        }
    }
}

// MARK: - UI Configuration Models

/// Configuration for authentication UI appearance
struct AuthenticationUIConfig: Sendable {
    static let animationDuration: Double = 0.3
    static let errorDisplayDuration: Double = 5.0
    static let biometricPromptDelay: Double = 0.5
    static let maxLoginAttempts: Int = 5
    static let passwordMinLength: Int = 8
    static let nameMaxLength: Int = 50
    static let debounceDelay: Double = 0.5
}

/// Biometric configuration
struct BiometricConfig: Sendable {
    static let promptReason = "Use Face ID or Touch ID to sign in to your health account"
    static let fallbackTitle = "Use Passcode"
    static let cancelTitle = "Cancel"
    static let lockoutDuration: TimeInterval = 300 // 5 minutes
}