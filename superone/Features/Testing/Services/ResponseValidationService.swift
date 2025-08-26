//
//  ResponseValidationService.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Service for validating API responses against expected schemas and values
//

import Foundation
import os.log

/// Service for validating API responses and detecting mismatches
class ResponseValidationService: Sendable {
    
    private let logger = Logger(subsystem: "com.superone.health", category: "ResponseValidation")
    
    // MARK: - Public Interface
    
    /// Validate an API response against expected schema and values
    func validateResponse(
        actual: Any?,
        expected: Any?,
        endpoint: APIEndpoint
    ) async -> APIValidationResult {
        
        logger.info("Starting response validation for endpoint: \(endpoint.name)")
        
        var mismatches: [APIValidationMismatch] = []
        var errors: [String] = []
        var warnings: [String] = []
        
        // Check if we have an actual response
        guard let actualResponse = actual else {
            errors.append("No response received from endpoint")
            return APIValidationResult(isValid: false, mismatches: mismatches, errors: errors, warnings: warnings)
        }
        
        // If no expected response provided, validate against known response schemas
        if expected == nil {
            return await validateAgainstKnownSchema(actualResponse, endpoint: endpoint)
        }
        
        // Validate against expected response
        let comparisonResult = await compareResponses(actual: actualResponse, expected: expected!, path: "root")
        mismatches.append(contentsOf: comparisonResult.mismatches)
        errors.append(contentsOf: comparisonResult.errors)
        warnings.append(contentsOf: comparisonResult.warnings)
        
        let isValid = errors.isEmpty && mismatches.allSatisfy { $0.severity != .error }
        
        logger.info("Response validation completed. Valid: \(isValid), Issues: \(mismatches.count + errors.count)")
        
        return APIValidationResult(
            isValid: isValid,
            mismatches: mismatches,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Schema Validation
    
    private func validateAgainstKnownSchema(_ response: Any, endpoint: APIEndpoint) async -> APIValidationResult {
        switch endpoint.category {
        case .authentication:
            return await validateAuthenticationResponse(response, endpoint: endpoint)
        case .labLoop:
            return await validateLabLoopResponse(response, endpoint: endpoint)
        case .health:
            return await validateHealthResponse(response, endpoint: endpoint)
        case .reports:
            return await validateReportsResponse(response, endpoint: endpoint)
        case .upload:
            return await validateUploadResponse(response, endpoint: endpoint)
        }
    }
    
    // MARK: - Authentication Response Validation
    
    private func validateAuthenticationResponse(_ response: Any, endpoint: APIEndpoint) async -> APIValidationResult {
        var mismatches: [APIValidationMismatch] = []
        var errors: [String] = []
        var warnings: [String] = []
        
        switch endpoint.name {
        case "register", "login":
            // Expect AuthResponse with tokens
            if let authResponse = response as? AuthResponse {
                if !authResponse.success {
                    errors.append("Authentication response indicates failure: \(authResponse.message ?? "Unknown error")")
                }
                
                if authResponse.data?.tokens == nil {
                    errors.append("Missing authentication tokens in successful response")
                }
                
                if authResponse.data?.user == nil {
                    warnings.append("Missing user information in authentication response")
                }
            } else {
                errors.append("Response is not of type AuthResponse")
            }
            
        case "logout":
            // Expect LogoutResponse
            if let logoutResponse = response as? LogoutResponse {
                if !logoutResponse.success {
                    warnings.append("Logout response indicates failure: \(logoutResponse.message ?? "Unknown error")")
                }
            } else {
                errors.append("Response is not of type LogoutResponse")
            }
            
        case "refreshToken":
            // Expect TokenResponse
            if let tokenResponse = response as? TokenResponse {
                if !tokenResponse.success {
                    errors.append("Token refresh response indicates failure")
                }
                
                if tokenResponse.data == nil {
                    errors.append("Missing tokens in refresh response")
                }
            } else {
                errors.append("Response is not of type TokenResponse")
            }
            
        case "forgotPassword":
            // Expect PasswordResetResponse
            if let passwordResponse = response as? PasswordResetResponse {
                if !passwordResponse.success {
                    warnings.append("Password reset response indicates failure")
                }
            } else {
                errors.append("Response is not of type PasswordResetResponse")
            }
            
        case "getCurrentUser":
            // Expect User object
            if let user = response as? User {
                if user.email.isEmpty {
                    errors.append("User email is empty")
                }
                
                if user.id.isEmpty {
                    errors.append("User ID is empty")
                }
            } else {
                errors.append("Response is not of type User")
            }
            
        case "validateToken":
            // Expect Boolean
            if !(response is Bool) {
                errors.append("Token validation should return a Boolean value")
            }
            
        default:
            warnings.append("Unknown authentication endpoint: \(endpoint.name)")
        }
        
        let isValid = errors.isEmpty
        return APIValidationResult(isValid: isValid, mismatches: mismatches, errors: errors, warnings: warnings)
    }
    
    // MARK: - Other Category Validations (Placeholders)
    
    private func validateLabLoopResponse(_ response: Any, endpoint: APIEndpoint) async -> APIValidationResult {
        // TODO: Implement LabLoop response validation
        return APIValidationResult(isValid: true, warnings: ["LabLoop validation not yet implemented"])
    }
    
    private func validateHealthResponse(_ response: Any, endpoint: APIEndpoint) async -> APIValidationResult {
        // TODO: Implement Health response validation
        return APIValidationResult(isValid: true, warnings: ["Health validation not yet implemented"])
    }
    
    private func validateReportsResponse(_ response: Any, endpoint: APIEndpoint) async -> APIValidationResult {
        // TODO: Implement Reports response validation
        return APIValidationResult(isValid: true, warnings: ["Reports validation not yet implemented"])
    }
    
    private func validateUploadResponse(_ response: Any, endpoint: APIEndpoint) async -> APIValidationResult {
        // TODO: Implement Upload response validation
        return APIValidationResult(isValid: true, warnings: ["Upload validation not yet implemented"])
    }
    
    // MARK: - Response Comparison
    
    private func compareResponses(actual: Any, expected: Any, path: String) async -> APIValidationResult {
        var mismatches: [APIValidationMismatch] = []
        var errors: [String] = []
        var warnings: [String] = []
        
        // Handle different types of comparison
        if let actualDict = actual as? [String: Any], let expectedDict = expected as? [String: Any] {
            // Compare dictionaries
            let dictResult = await compareDictionaries(actual: actualDict, expected: expectedDict, path: path)
            mismatches.append(contentsOf: dictResult.mismatches)
            errors.append(contentsOf: dictResult.errors)
            warnings.append(contentsOf: dictResult.warnings)
            
        } else if let actualArray = actual as? [Any], let expectedArray = expected as? [Any] {
            // Compare arrays
            let arrayResult = await compareArrays(actual: actualArray, expected: expectedArray, path: path)
            mismatches.append(contentsOf: arrayResult.mismatches)
            errors.append(contentsOf: arrayResult.errors)
            warnings.append(contentsOf: arrayResult.warnings)
            
        } else {
            // Compare primitive values
            if !areValuesEqual(actual, expected) {
                mismatches.append(APIValidationMismatch(
                    path: path,
                    expected: String(describing: expected),
                    actual: String(describing: actual),
                    severity: .error
                ))
            }
        }
        
        let isValid = errors.isEmpty && mismatches.allSatisfy { $0.severity != .error }
        return APIValidationResult(isValid: isValid, mismatches: mismatches, errors: errors, warnings: warnings)
    }
    
    private func compareDictionaries(actual: [String: Any], expected: [String: Any], path: String) async -> APIValidationResult {
        var mismatches: [APIValidationMismatch] = []
        var errors: [String] = []
        var warnings: [String] = []
        
        // Check for missing keys in actual
        for (key, expectedValue) in expected {
            let keyPath = path.isEmpty ? key : "\(path).\(key)"
            
            if let actualValue = actual[key] {
                let result = await compareResponses(actual: actualValue, expected: expectedValue, path: keyPath)
                mismatches.append(contentsOf: result.mismatches)
                errors.append(contentsOf: result.errors)
                warnings.append(contentsOf: result.warnings)
            } else {
                mismatches.append(APIValidationMismatch(
                    path: keyPath,
                    expected: String(describing: expectedValue),
                    actual: "missing",
                    severity: .error
                ))
            }
        }
        
        // Check for extra keys in actual
        for key in actual.keys {
            if expected[key] == nil {
                let keyPath = path.isEmpty ? key : "\(path).\(key)"
                warnings.append("Unexpected key found: \(keyPath)")
            }
        }
        
        let isValid = errors.isEmpty && mismatches.allSatisfy { $0.severity != .error }
        return APIValidationResult(isValid: isValid, mismatches: mismatches, errors: errors, warnings: warnings)
    }
    
    private func compareArrays(actual: [Any], expected: [Any], path: String) async -> APIValidationResult {
        var mismatches: [APIValidationMismatch] = []
        var errors: [String] = []
        var warnings: [String] = []
        
        if actual.count != expected.count {
            mismatches.append(APIValidationMismatch(
                path: "\(path).length",
                expected: String(expected.count),
                actual: String(actual.count),
                severity: APIMismatchSeverity.warning
            ))
        }
        
        // Compare elements up to the minimum count
        let minCount = min(actual.count, expected.count)
        for i in 0..<minCount {
            let result = await compareResponses(
                actual: actual[i],
                expected: expected[i],
                path: "\(path)[\(i)]"
            )
            mismatches.append(contentsOf: result.mismatches)
            errors.append(contentsOf: result.errors)
            warnings.append(contentsOf: result.warnings)
        }
        
        let isValid = errors.isEmpty && mismatches.allSatisfy { $0.severity != .error }
        return APIValidationResult(isValid: isValid, mismatches: mismatches, errors: errors, warnings: warnings)
    }
    
    private func areValuesEqual(_ actual: Any, _ expected: Any) -> Bool {
        // Handle different types of equality comparison
        if let actualString = actual as? String, let expectedString = expected as? String {
            return actualString == expectedString
        }
        
        if let actualNumber = actual as? NSNumber, let expectedNumber = expected as? NSNumber {
            return actualNumber == expectedNumber
        }
        
        if let actualBool = actual as? Bool, let expectedBool = expected as? Bool {
            return actualBool == expectedBool
        }
        
        // For other types, use string representation as fallback
        return String(describing: actual) == String(describing: expected)
    }
    
    // MARK: - JSON Schema Validation (Future Enhancement)
    
    /// Validate response against a JSON schema (for future implementation)
    func validateAgainstJSONSchema(_ response: Any, schema: [String: Any]) async -> APIValidationResult {
        // TODO: Implement JSON schema validation
        return APIValidationResult(isValid: true, warnings: ["JSON schema validation not yet implemented"])
    }
}