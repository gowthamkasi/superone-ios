import Foundation
import Combine

// MARK: - API Response Wrapper

/// Generic wrapper for all API responses
struct APIResponse<T: Codable>: Codable, Sendable where T: Sendable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
    let timestamp: Date?
    let requestId: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
        case error
        case timestamp
        case requestId = "request_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        data = try container.decodeIfPresent(T.self, forKey: .data)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        requestId = try container.decodeIfPresent(String.self, forKey: .requestId)
        
        // Handle timestamp as both ISO string and Unix timestamp
        if let timestampString = try? container.decodeIfPresent(String.self, forKey: .timestamp) {
            let formatter = ISO8601DateFormatter()
            timestamp = formatter.date(from: timestampString)
        } else if let timestampDouble = try? container.decodeIfPresent(Double.self, forKey: .timestamp) {
            timestamp = Date(timeIntervalSince1970: timestampDouble)
        } else {
            timestamp = nil
        }
    }
}

// MARK: - Authentication Models

/// Login request model - Removed: Using version from BackendModels.swift to avoid duplication

/// Registration request model
struct RegistrationRequest: Codable, Sendable {
    let email: String
    let password: String
    let name: String
    let dateOfBirth: Date?
    let phoneNumber: String?
    let deviceId: String?
    let acceptedTerms: Bool
    let acceptedPrivacy: Bool
    
    nonisolated enum CodingKeys: String, CodingKey {
        case email
        case password
        case name
        case dateOfBirth = "date_of_birth"
        case phoneNumber = "phone_number"
        case deviceId = "device_id"
        case acceptedTerms = "accepted_terms"
        case acceptedPrivacy = "accepted_privacy"
    }
    
    init(email: String, password: String, name: String, dateOfBirth: Date? = nil, phoneNumber: String? = nil, deviceId: String? = nil, acceptedTerms: Bool = true, acceptedPrivacy: Bool = true) {
        self.email = email
        self.password = password
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.phoneNumber = phoneNumber
        self.deviceId = deviceId
        self.acceptedTerms = acceptedTerms
        self.acceptedPrivacy = acceptedPrivacy
    }
}

/// Authentication response model - Removed: Using version from BackendModels.swift to avoid duplication

/// Token refresh request model
struct TokenRefreshRequest: Codable, Sendable {
    let refreshToken: String
    let deviceId: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
        case deviceId = "device_id"
    }
}

/// Password reset request model
struct PasswordResetRequest: Codable, Sendable {
    let email: String
}

/// Password change request model
struct PasswordChangeRequest: Codable, Sendable {
    let currentPassword: String
    let newPassword: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
    }
}

// MARK: - User Models

/// User model - Removed: Using consolidated version from BackendModels.swift to avoid duplication

/// User profile update request
struct UserProfileUpdateRequest: Codable, Sendable {
    let name: String?
    let phoneNumber: String?
    let dateOfBirth: Date?
    let profileImageURL: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case name
        case phoneNumber = "phone_number"
        case dateOfBirth = "date_of_birth"
        case profileImageURL = "profile_image_url"
    }
}

// MARK: - Health Models

/// Health profile model
struct HealthProfile: Codable, Sendable, Equatable {
    let id: String
    let userId: String
    let age: Int?
    let gender: Gender?
    let height: Double? // in cm
    let weight: Double? // in kg
    let bloodType: BloodType?
    let goals: [HealthGoal]
    let medicalConditions: [String]
    let medications: [String]
    let allergies: [String]
    let emergencyContact: EmergencyContact?
    let lastUpdated: Date
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case age
        case gender
        case height
        case weight
        case bloodType = "blood_type"
        case goals
        case medicalConditions = "medical_conditions"
        case medications
        case allergies
        case emergencyContact = "emergency_contact"
        case lastUpdated = "last_updated"
    }
}

// Gender enum moved to HealthKitModels.swift to avoid duplication

/// Blood type enumeration
enum BloodType: String, Codable, CaseIterable, Sendable {
    case aPositive = "A+"
    case aNegative = "A-"
    case bPositive = "B+"
    case bNegative = "B-"
    case abPositive = "AB+"
    case abNegative = "AB-"
    case oPositive = "O+"
    case oNegative = "O-"
    case unknown = "unknown"
}

// HealthGoal struct moved to HealthKitModels.swift to avoid duplication

// HealthCategory enum is now defined in BackendModels.swift to avoid duplication  
// Use the consolidated version with proper Sendable conformance

/// Emergency contact model
// EmergencyContact struct moved to HealthKitModels.swift to avoid duplication

/// Health metric model
struct HealthMetric: Codable, Identifiable, Sendable {
    let id: String
    let type: HealthMetricType
    let value: Double
    let unit: String
    let date: Date
    let source: String? // HealthKit, manual entry, lab report, etc.
    let notes: String?
    let isVerified: Bool
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case type
        case value
        case unit
        case date
        case source
        case notes
        case isVerified = "is_verified"
    }
}


// MARK: - File Upload Models

/// File upload request
struct FileUploadRequest: Codable, Sendable {
    let fileName: String
    let fileType: String
    let fileSize: Int64
    let category: String?
    let description: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
        case fileType = "file_type"
        case fileSize = "file_size"
        case category
        case description
    }
}

/// File upload response
struct FileUploadResponse: Codable, Sendable {
    let uploadId: String
    let uploadURL: String
    let expiresAt: Date
    let maxFileSize: Int64
    
    nonisolated enum CodingKeys: String, CodingKey {
        case uploadId = "upload_id"
        case uploadURL = "upload_url"
        case expiresAt = "expires_at"
        case maxFileSize = "max_file_size"
    }
}

// MARK: - Error Response Models

/// Standard error response format
struct ErrorResponse: Codable, Error, Sendable, @preconcurrency LocalizedError {
    let error: String
    let message: String
    let code: String?
    let details: String? // Changed from [String: Any]? to String? for Codable compliance
    let timestamp: Date?
    let requestId: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case error
        case message
        case code
        case details
        case timestamp
        case requestId = "request_id"
    }
    
    init(error: String, message: String, code: String? = nil, details: String? = nil, timestamp: Date? = nil, requestId: String? = nil) {
        self.error = error
        self.message = message
        self.code = code
        self.details = details
        self.timestamp = timestamp
        self.requestId = requestId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        error = try container.decode(String.self, forKey: .error)
        message = try container.decode(String.self, forKey: .message)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        details = try container.decodeIfPresent(String.self, forKey: .details)
        requestId = try container.decodeIfPresent(String.self, forKey: .requestId)
        
        // Handle timestamp
        if let timestampString = try? container.decodeIfPresent(String.self, forKey: .timestamp) {
            let formatter = ISO8601DateFormatter()
            timestamp = formatter.date(from: timestampString)
        } else {
            timestamp = nil
        }
    }
    
    // MARK: - LocalizedError Implementation
    
    var errorDescription: String? {
        return error
    }
    
    var failureReason: String? {
        return details
    }
    
    var recoverySuggestion: String? {
        switch code {
        case "AUTHENTICATION_REQUIRED":
            return "Please log in again"
        case "VALIDATION_ERROR":
            return "Please check your input and try again"
        case "NETWORK_ERROR":
            return "Please check your internet connection"
        default:
            return "Please try again later"
        }
    }
}

// MARK: - Pagination Models

/// Generic pagination wrapper
struct PaginatedResponse<T: Codable>: Codable, Sendable where T: Sendable {
    let data: [T]
    let pagination: PaginationInfo
}

// PaginationInfo is now defined in HealthAnalysisAPIService.swift