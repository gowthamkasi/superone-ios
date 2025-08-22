import Foundation

// MARK: - Network Error Types

/// Comprehensive error handling for network operations
enum NetworkError: Error, @preconcurrency LocalizedError, Equatable {
    // Connection errors
    case noInternetConnection
    case requestTimeout
    case serverUnreachable
    case connectionLost
    case networkFailure(String)
    
    // HTTP errors
    case unauthorized(message: String?)
    case forbidden(message: String?)
    case notFound(message: String?)
    case serverError(code: Int, message: String?)
    case badRequest(message: String?)
    case conflict(message: String?)
    case unprocessableEntity(message: String?)
    
    // Request/Response errors
    case invalidRequest
    case invalidResponse
    case decodingError(String)
    case encodingError(String)
    case missingData
    
    // Authentication specific errors
    case tokenExpired
    case tokenInvalid
    case refreshTokenExpired
    case authenticationRequired
    
    // Rate limiting
    case tooManyRequests(retryAfter: TimeInterval?)
    
    // Generic errors
    case unknown(String)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        // Connection errors
        case .noInternetConnection:
            return "No internet connection available. Please check your network settings."
        case .requestTimeout:
            return "The request timed out. Please try again."
        case .serverUnreachable:
            return "Unable to reach the server. Please try again later."
        case .connectionLost:
            return "Connection lost during request. Please try again."
        case .networkFailure(let message):
            return "Network failure: \(message)"
            
        // HTTP errors
        case .unauthorized(let message):
            return message ?? "You are not authorized to perform this action."
        case .forbidden(let message):
            return message ?? "Access to this resource is forbidden."
        case .notFound(let message):
            return message ?? "The requested resource was not found."
        case .serverError(_, let message):
            return message ?? "A server error occurred. Please try again later."
        case .badRequest(let message):
            return message ?? "Invalid request. Please check your input and try again."
        case .conflict(let message):
            return message ?? "A conflict occurred while processing your request."
        case .unprocessableEntity(let message):
            return message ?? "The request could not be processed. Please check your input."
            
        // Request/Response errors
        case .invalidRequest:
            return "Invalid request format."
        case .invalidResponse:
            return "Invalid response received from server."
        case .decodingError(let details):
            return "Failed to process server response: \(details)"
        case .encodingError(let details):
            return "Failed to prepare request: \(details)"
        case .missingData:
            return "No data received from server."
            
        // Authentication errors
        case .tokenExpired:
            return "Your session has expired. Please log in again."
        case .tokenInvalid:
            return "Invalid authentication token. Please log in again."
        case .refreshTokenExpired:
            return "Your session has expired. Please log in again."
        case .authenticationRequired:
            return "Authentication required to access this resource."
            
        // Rate limiting
        case .tooManyRequests(let retryAfter):
            if let retryAfter = retryAfter {
                return "Too many requests. Please try again in \(Int(retryAfter)) seconds."
            } else {
                return "Too many requests. Please try again later."
            }
            
        // Generic errors
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        case .cancelled:
            return "Request was cancelled."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection:
            return "Check your Wi-Fi or cellular connection and try again."
        case .requestTimeout, .serverUnreachable, .connectionLost, .networkFailure:
            return "Please try again in a few moments."
        case .unauthorized, .tokenExpired, .tokenInvalid, .refreshTokenExpired:
            return "Please log in again to continue."
        case .serverError:
            return "If this problem persists, please contact support."
        case .badRequest, .unprocessableEntity:
            return "Please verify your input and try again."
        case .tooManyRequests:
            return "Please wait a moment before trying again."
        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .noInternetConnection:
            return "Network connection is not available"
        case .requestTimeout:
            return "Request exceeded maximum time limit"
        case .serverUnreachable:
            return "Unable to establish connection to server"
        case .connectionLost:
            return "Network connection was interrupted"
        case .networkFailure(let message):
            return "Network layer failure: \(message)"
        case .unauthorized:
            return "Authentication credentials are invalid or expired"
        case .forbidden:
            return "Access to requested resource is denied"
        case .notFound:
            return "Requested resource does not exist"
        case .serverError(let code, _):
            return "Server returned error code \(code)"
        case .badRequest:
            return "Request format or parameters are invalid"
        case .conflict:
            return "Request conflicts with current resource state"
        case .unprocessableEntity:
            return "Request data failed validation"
        case .invalidRequest:
            return "Request structure is malformed"
        case .invalidResponse:
            return "Server response format is invalid"
        case .decodingError:
            return "Failed to parse server response"
        case .encodingError:
            return "Failed to serialize request data"
        case .missingData:
            return "Expected data was not received from server"
        case .tokenExpired:
            return "Authentication token has expired"
        case .tokenInvalid:
            return "Authentication token format is invalid"
        case .refreshTokenExpired:
            return "Refresh token has expired and cannot be used"
        case .authenticationRequired:
            return "Valid authentication is required to access resource"
        case .tooManyRequests:
            return "Request rate limit has been exceeded"
        case .unknown:
            return "An unexpected error occurred"
        case .cancelled:
            return "Request was cancelled by user or system"
        }
    }
    
    var helpAnchor: String? {
        switch self {
        case .noInternetConnection:
            return "network-connection-help"
        case .unauthorized, .tokenExpired, .tokenInvalid, .refreshTokenExpired, .authenticationRequired:
            return "authentication-help"
        case .serverError:
            return "server-error-help"
        case .badRequest, .unprocessableEntity:
            return "request-validation-help"
        case .tooManyRequests:
            return "rate-limiting-help"
        default:
            return "general-network-help"
        }
    }
    
    /// HTTP status code associated with the error (if applicable)
    var statusCode: Int? {
        switch self {
        case .badRequest:
            return 400
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .conflict:
            return 409
        case .unprocessableEntity:
            return 422
        case .tooManyRequests:
            return 429
        case .serverError(let code, _):
            return code
        default:
            return nil
        }
    }
    
    /// Whether this error should trigger an automatic retry
    var isRetryable: Bool {
        switch self {
        case .requestTimeout, .serverUnreachable, .connectionLost, .networkFailure, .serverError:
            return true
        case .tooManyRequests:
            return true
        case .noInternetConnection:
            return false // Should wait for connection to be restored
        default:
            return false
        }
    }
    
    /// Whether this error indicates authentication failure
    var isAuthenticationError: Bool {
        switch self {
        case .unauthorized, .tokenExpired, .tokenInvalid, .refreshTokenExpired, .authenticationRequired:
            return true
        default:
            return false
        }
    }
}

// MARK: - Authentication Error

/// Network-specific authentication errors
enum NetworkAuthenticationError: Error, @preconcurrency LocalizedError {
    case invalidCredentials
    case accountLocked
    case accountNotVerified
    case passwordExpired
    case biometricAuthenticationFailed
    case noStoredCredentials
    case tokenRefreshFailed
    case logoutFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .accountLocked:
            return "Your account has been locked due to multiple failed login attempts."
        case .accountNotVerified:
            return "Please verify your email address before logging in."
        case .passwordExpired:
            return "Your password has expired. Please reset your password."
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed. Please try again or use your password."
        case .noStoredCredentials:
            return "No stored credentials found. Please log in manually."
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token. Please log in again."
        case .logoutFailed:
            return "Failed to complete logout. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Double-check your email and password, or use 'Forgot Password' if needed."
        case .accountLocked:
            return "Please contact support or wait before trying again."
        case .accountNotVerified:
            return "Check your email for the verification link."
        case .passwordExpired:
            return "Use the 'Forgot Password' feature to reset your password."
        case .biometricAuthenticationFailed:
            return "Try using Face ID/Touch ID again or enter your password manually."
        case .noStoredCredentials, .tokenRefreshFailed:
            return "Please log in with your email and password."
        case .logoutFailed:
            return "Try logging out again, or restart the app if the problem persists."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidCredentials:
            return "Provided credentials do not match any registered account"
        case .accountLocked:
            return "Account has been temporarily locked due to security concerns"
        case .accountNotVerified:
            return "Account email address has not been verified"
        case .passwordExpired:
            return "Account password has exceeded maximum age limit"
        case .biometricAuthenticationFailed:
            return "Device biometric authentication did not succeed"
        case .noStoredCredentials:
            return "No authentication credentials found in secure storage"
        case .tokenRefreshFailed:
            return "Unable to refresh authentication token with server"
        case .logoutFailed:
            return "Server did not acknowledge logout request"
        }
    }
    
    var helpAnchor: String? {
        switch self {
        case .invalidCredentials:
            return "invalid-credentials-help"
        case .accountLocked:
            return "account-locked-help"
        case .accountNotVerified:
            return "email-verification-help"
        case .passwordExpired:
            return "password-reset-help"
        case .biometricAuthenticationFailed:
            return "biometric-auth-help"
        case .noStoredCredentials, .tokenRefreshFailed:
            return "manual-login-help"
        case .logoutFailed:
            return "logout-troubleshooting-help"
        }
    }
}

// MARK: - Validation Error

/// Input validation errors
enum ValidationError: Error, @preconcurrency LocalizedError {
    case invalidEmail
    case weakPassword
    case passwordMismatch
    case requiredFieldMissing(String)
    case invalidPhoneNumber
    case invalidDateOfBirth
    case invalidFileFormat
    case fileTooLarge(maxSize: String)
    case fieldTooLong(field: String, maxLength: Int)
    case fieldTooShort(field: String, minLength: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 8 characters with letters and numbers."
        case .passwordMismatch:
            return "Passwords do not match. Please try again."
        case .requiredFieldMissing(let field):
            return "\(field) is required."
        case .invalidPhoneNumber:
            return "Please enter a valid phone number."
        case .invalidDateOfBirth:
            return "Please enter a valid date of birth."
        case .invalidFileFormat:
            return "File format not supported. Please use PDF, JPG, or PNG."
        case .fileTooLarge(let maxSize):
            return "File is too large. Maximum size is \(maxSize)."
        case .fieldTooLong(let field, let maxLength):
            return "\(field) cannot exceed \(maxLength) characters."
        case .fieldTooShort(let field, let minLength):
            return "\(field) must be at least \(minLength) characters."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Enter a valid email address in the format name@domain.com"
        case .weakPassword:
            return "Use a combination of uppercase, lowercase, numbers, and symbols"
        case .passwordMismatch:
            return "Make sure both password fields contain exactly the same text"
        case .requiredFieldMissing:
            return "This field is required and cannot be left empty"
        case .invalidPhoneNumber:
            return "Enter a phone number in the format (555) 123-4567"
        case .invalidDateOfBirth:
            return "Select a valid date from the date picker"
        case .invalidFileFormat:
            return "Convert your file to PDF, JPG, or PNG format before uploading"
        case .fileTooLarge:
            return "Reduce the file size or use a different file"
        case .fieldTooLong:
            return "Shorten the text to fit within the character limit"
        case .fieldTooShort:
            return "Add more characters to meet the minimum requirement"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidEmail:
            return "Email address format does not match required pattern"
        case .weakPassword:
            return "Password does not meet security requirements"
        case .passwordMismatch:
            return "Password confirmation does not match original password"
        case .requiredFieldMissing(let field):
            return "\(field) field was left empty but is required"
        case .invalidPhoneNumber:
            return "Phone number format is not recognized"
        case .invalidDateOfBirth:
            return "Date of birth is outside acceptable range"
        case .invalidFileFormat:
            return "File type is not supported by the system"
        case .fileTooLarge(let maxSize):
            return "File exceeds maximum allowed size of \(maxSize)"
        case .fieldTooLong(let field, let maxLength):
            return "\(field) contains more than \(maxLength) allowed characters"
        case .fieldTooShort(let field, let minLength):
            return "\(field) contains fewer than \(minLength) required characters"
        }
    }
    
    var helpAnchor: String? {
        switch self {
        case .invalidEmail:
            return "email-format-help"
        case .weakPassword:
            return "password-requirements-help"
        case .passwordMismatch:
            return "password-confirmation-help"
        case .requiredFieldMissing:
            return "required-fields-help"
        case .invalidPhoneNumber:
            return "phone-format-help"
        case .invalidDateOfBirth:
            return "date-selection-help"
        case .invalidFileFormat, .fileTooLarge:
            return "file-upload-help"
        case .fieldTooLong, .fieldTooShort:
            return "field-length-help"
        }
    }
}

// MARK: - Network Error Factory

extension NetworkError {
    /// Create a NetworkError from an HTTP status code and response data
    static func from(statusCode: Int, data: Data? = nil) async -> NetworkError {
        // Try to extract error message from response
        var message: String?
        if let data = data {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    message = json["message"] as? String ?? json["error"] as? String
                }
            } catch {
                // Ignore JSON parsing errors
            }
        }
        
        switch statusCode {
        case 400:
            return .badRequest(message: message)
        case 401:
            return .unauthorized(message: message)
        case 403:
            return .forbidden(message: message)
        case 404:
            return .notFound(message: message)
        case 409:
            return .conflict(message: message)
        case 422:
            return .unprocessableEntity(message: message)
        case 429:
            // Try to extract retry-after from headers if available
            return .tooManyRequests(retryAfter: nil)
        case 500...599:
            return .serverError(code: statusCode, message: message)
        default:
            return .serverError(code: statusCode, message: message)
        }
    }
    
    /// Create a NetworkError from a URLError
    static func from(urlError: URLError) async -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternetConnection
        case .timedOut:
            return .requestTimeout
        case .cannotConnectToHost, .cannotFindHost:
            return .serverUnreachable
        case .cancelled:
            return .cancelled
        default:
            return .unknown(urlError.localizedDescription)
        }
    }
}