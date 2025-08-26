//
//  APITestConfiguration.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Models for API testing configuration and results
//

import Foundation
import SwiftUI
import Combine

// MARK: - API Endpoint Definition

struct APIEndpoint: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let displayName: String
    let method: APIHTTPMethod
    let path: String
    let category: APICategory
    let description: String
    let requiredParameters: [ParameterDefinition]
    let optionalParameters: [ParameterDefinition]
    let expectedResponseType: String
    let requiresAuthentication: Bool
    
    // MARK: - Computed Properties
    
    var fullDisplayName: String {
        return "\(method.rawValue.uppercased()) \(displayName)"
    }
    
    var parameterCount: Int {
        return requiredParameters.count + optionalParameters.count
    }
    
    // MARK: - Hash and Equality
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(category)
    }
    
    static func == (lhs: APIEndpoint, rhs: APIEndpoint) -> Bool {
        return lhs.name == rhs.name && lhs.category == rhs.category
    }
}

// MARK: - API Categories

enum APICategory: String, CaseIterable, Sendable {
    case authentication = "authentication"
    case labLoop = "labloop"
    case health = "health"
    case reports = "reports"
    case upload = "upload"
    
    var displayName: String {
        switch self {
        case .authentication:
            return "Authentication"
        case .labLoop:
            return "LabLoop Integration"
        case .health:
            return "Health Analysis"
        case .reports:
            return "Lab Reports"
        case .upload:
            return "File Upload"
        }
    }
    
    var icon: String {
        switch self {
        case .authentication:
            return "key.fill"
        case .labLoop:
            return "building.2.fill"
        case .health:
            return "heart.fill"
        case .reports:
            return "doc.text.fill"
        case .upload:
            return "arrow.up.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .authentication:
            return HealthColors.primary
        case .labLoop:
            return HealthColors.healthGood
        case .health:
            return HealthColors.healthExcellent
        case .reports:
            return HealthColors.healthWarning
        case .upload:
            return HealthColors.healthCritical
        }
    }
}

// MARK: - HTTP Method

enum APIHTTPMethod: String, CaseIterable, Sendable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    
    var color: Color {
        switch self {
        case .GET:
            return HealthColors.healthGood
        case .POST:
            return HealthColors.primary
        case .PUT:
            return HealthColors.healthWarning
        case .PATCH:
            return HealthColors.healthModerate
        case .DELETE:
            return HealthColors.healthCritical
        }
    }
}

// MARK: - Parameter Definition

struct ParameterDefinition: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let displayName: String
    let type: ParameterType
    let description: String
    let defaultValue: Any?
    let validationRules: [APIValidationRule]
    
    // Custom initializer to handle Any? type
    init(
        name: String,
        displayName: String? = nil,
        type: ParameterType,
        description: String,
        defaultValue: Any? = nil,
        validationRules: [APIValidationRule] = []
    ) {
        self.name = name
        self.displayName = displayName ?? name.capitalized
        self.type = type
        self.description = description
        self.defaultValue = defaultValue
        self.validationRules = validationRules
    }
}

// MARK: - Parameter Types

enum ParameterType: Sendable, Equatable {
    case string
    case integer
    case double
    case boolean
    case date
    case array([String])
    case object
    
    // Implement Equatable manually due to associated values
    static func == (lhs: ParameterType, rhs: ParameterType) -> Bool {
        switch (lhs, rhs) {
        case (.string, .string), (.integer, .integer), (.double, .double), (.boolean, .boolean), (.date, .date), (.file, .file), (.email, .email), (.password, .password), (.url, .url), (.object, .object):
            return true
        case (.array(let lhsArray), .array(let rhsArray)):
            return lhsArray == rhsArray
        default:
            return false
        }
    }
    case file
    case email
    case password
    case url
    
    var displayName: String {
        switch self {
        case .string:
            return "String"
        case .integer:
            return "Integer"
        case .double:
            return "Number"
        case .boolean:
            return "Boolean"
        case .date:
            return "Date"
        case .array:
            return "Array"
        case .object:
            return "Object"
        case .file:
            return "File"
        case .email:
            return "Email"
        case .password:
            return "Password"
        case .url:
            return "URL"
        }
    }
    
    var icon: String {
        switch self {
        case .string, .email, .password, .url:
            return "textformat"
        case .integer, .double:
            return "number"
        case .boolean:
            return "checkmark.square"
        case .date:
            return "calendar"
        case .array:
            return "list.bullet"
        case .object:
            return "curlybraces"
        case .file:
            return "doc"
        }
    }
}

// MARK: - Validation Rules

enum APIValidationRule {
    case required
    case minLength(Int)
    case maxLength(Int)
    case minValue(Double)
    case maxValue(Double)
    case regex(String)
    // Note: Removing custom case due to Sendable conformance issues
    // Will be handled separately for advanced validation scenarios
}

// MARK: - Test Configuration

struct APITestConfiguration: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let endpoint: String
    let method: String
    let parameters: [String: TestParameterValue]
    let expectedResponse: TestResponseValue?
    let timeout: TimeInterval
    let retries: Int
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
    
    init(
        name: String,
        description: String = "",
        endpoint: String,
        method: String,
        parameters: [String: TestParameterValue] = [:],
        expectedResponse: TestResponseValue? = nil,
        timeout: TimeInterval = 30.0,
        retries: Int = 0,
        tags: [String] = []
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.endpoint = endpoint
        self.method = method
        self.parameters = parameters
        self.expectedResponse = expectedResponse
        self.timeout = timeout
        self.retries = retries
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Test Parameter Value

enum TestParameterValue: Codable, Sendable {
    case string(String)
    case integer(Int)
    case double(Double)
    case boolean(Bool)
    case date(Date)
    case array([String])
    case null
    
    var displayValue: String {
        switch self {
        case .string(let value):
            return value
        case .integer(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .boolean(let value):
            return value ? "true" : "false"
        case .date(let value):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            return formatter.string(from: value)
        case .array(let values):
            return "[\(values.joined(separator: ", "))]"
        case .null:
            return "null"
        }
    }
    
    var actualValue: Any? {
        switch self {
        case .string(let value):
            return value
        case .integer(let value):
            return value
        case .double(let value):
            return value
        case .boolean(let value):
            return value
        case .date(let value):
            return value
        case .array(let value):
            return value
        case .null:
            return nil
        }
    }
}

// MARK: - Test Response Value

enum TestResponseValue: Codable, Sendable {
    case string(String)
    case integer(Int)
    case double(Double)
    case boolean(Bool)
    case object([String: TestResponseValue])
    case array([TestResponseValue])
    case null
    
    var displayValue: String {
        switch self {
        case .string(let value):
            return "\"\(value)\""
        case .integer(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .boolean(let value):
            return value ? "true" : "false"
        case .object(let dict):
            return "{ \(dict.count) properties }"
        case .array(let arr):
            return "[ \(arr.count) items ]"
        case .null:
            return "null"
        }
    }
}

// MARK: - Test Result

struct APITestResult: Identifiable, Sendable {
    let id: String
    let endpoint: APIEndpoint
    let parameters: [String: Any]
    let response: Any?
    let responseTime: TimeInterval
    let timestamp: Date
    let status: APITestStatus
    let validationResult: APIValidationResult?
    let error: Error?
    
    // Custom initializer to handle Any types
    init(
        id: String = UUID().uuidString,
        endpoint: APIEndpoint,
        parameters: [String: Any] = [:],
        response: Any? = nil,
        responseTime: TimeInterval,
        timestamp: Date = Date(),
        status: APITestStatus,
        validationResult: APIValidationResult? = nil,
        error: Error? = nil
    ) {
        self.id = id
        self.endpoint = endpoint
        self.parameters = parameters
        self.response = response
        self.responseTime = responseTime
        self.timestamp = timestamp
        self.status = status
        self.validationResult = validationResult
        self.error = error
    }
    
    var formattedResponseTime: String {
        if responseTime < 1000 {
            return "\(Int(responseTime))ms"
        } else {
            return String(format: "%.2fs", responseTime / 1000)
        }
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

// MARK: - Test Status

enum APITestStatus: String, CaseIterable, Sendable {
    case running = "running"
    case success = "success"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .running:
            return "Running"
        case .success:
            return "Success"
        case .failed:
            return "Failed"
        }
    }
    
    var color: Color {
        switch self {
        case .running:
            return HealthColors.primary
        case .success:
            return HealthColors.healthGood
        case .failed:
            return HealthColors.healthCritical
        }
    }
    
    var icon: String {
        switch self {
        case .running:
            return "clock.fill"
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Validation Result

struct APIValidationResult: Sendable {
    let isValid: Bool
    let mismatches: [APIValidationMismatch]
    let errors: [String]
    let warnings: [String]
    
    init(
        isValid: Bool,
        mismatches: [APIValidationMismatch] = [],
        errors: [String] = [],
        warnings: [String] = []
    ) {
        self.isValid = isValid
        self.mismatches = mismatches
        self.errors = errors
        self.warnings = warnings
    }
    
    var hasIssues: Bool {
        return !mismatches.isEmpty || !errors.isEmpty
    }
    
    var issueCount: Int {
        return mismatches.count + errors.count
    }
}

// MARK: - Validation Mismatch

struct APIValidationMismatch: Identifiable, Sendable {
    let id = UUID()
    let path: String
    let expected: String
    let actual: String
    let severity: APIMismatchSeverity
    
    var description: String {
        return "At path '\(path)': expected \(expected), got \(actual)"
    }
}

enum APIMismatchSeverity: String, Sendable {
    case error = "error"
    case warning = "warning"
    case info = "info"
    
    var color: Color {
        switch self {
        case .error:
            return HealthColors.healthCritical
        case .warning:
            return HealthColors.healthWarning
        case .info:
            return HealthColors.primary
        }
    }
    
    var icon: String {
        switch self {
        case .error:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}