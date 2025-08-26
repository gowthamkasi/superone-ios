//
//  APITestingService.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Core service for managing API testing sessions and results
//

import Foundation
import SwiftUI
import Combine
import os.log

/// Core service for API testing functionality
@MainActor
class APITestingService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isConnected: Bool = true
    @Published var apiVersion: String = "1.0"
    @Published var totalTestsRun: Int = 0
    @Published var successfulTests: Int = 0
    @Published var failedTests: Int = 0
    @Published var averageResponseTime: Double = 0.0
    @Published var testResults: [APITestResult] = []
    @Published var activeTests: Set<String> = []
    @Published var testConfigurations: [String: APITestConfiguration] = [:]
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.superone.health", category: "APITesting")
    private var responseTimes: [Double] = []
    private let maxStoredResults = 100
    private let maxStoredResponseTimes = 50
    
    // MARK: - Services
    
    private let authService: AuthenticationAPIService
    private let networkService: NetworkService
    private let validationService: ResponseValidationService
    
    // MARK: - Initialization
    
    init() {
        self.authService = AuthenticationAPIService()
        self.networkService = NetworkService.shared
        self.validationService = ResponseValidationService()
        
        loadStoredResults()
        updateConnectionStatus()
    }
    
    // MARK: - Test Execution
    
    /// Execute a test for a specific API endpoint
    func executeTest(
        endpoint: APIEndpoint,
        parameters: [String: Any] = [:],
        expectedResponse: Any? = nil
    ) async throws -> APITestResult {
        
        let testId = UUID().uuidString
        let startTime = Date()
        
        // Track active test
        activeTests.insert(testId)
        
        logger.info("Starting API test for endpoint: \(endpoint.name)")
        
        do {
            // Validate and sanitize parameters before making the API call
            let sanitizedParameters = sanitizeParameters(parameters)
            logger.debug("Sanitized parameters: \(sanitizedParameters)")
            
            // Execute the actual API call based on endpoint type
            let response = try await executeEndpointCall(endpoint: endpoint, parameters: sanitizedParameters)
            let endTime = Date()
            let responseTime = endTime.timeIntervalSince(startTime) * 1000 // Convert to milliseconds
            
            // Validate response if expected response is provided
            let validationResult = await validationService.validateResponse(
                actual: response,
                expected: expectedResponse,
                endpoint: endpoint
            )
            
            // Create test result
            let testResult = APITestResult(
                id: testId,
                endpoint: endpoint,
                parameters: parameters,
                response: response,
                responseTime: responseTime,
                timestamp: startTime,
                status: validationResult.isValid ? .success : .failed,
                validationResult: validationResult,
                error: nil
            )
            
            // Update statistics
            await updateStatistics(result: testResult)
            
            // Store result
            storeTestResult(testResult)
            
            activeTests.remove(testId)
            
            logger.info("API test completed successfully: \(endpoint.name), response time: \(responseTime)ms")
            return testResult
            
        } catch {
            let endTime = Date()
            let responseTime = endTime.timeIntervalSince(startTime) * 1000
            
            // Create failed test result
            let testResult = APITestResult(
                id: testId,
                endpoint: endpoint,
                parameters: parameters,
                response: nil,
                responseTime: responseTime,
                timestamp: startTime,
                status: .failed,
                validationResult: APIValidationResult(isValid: false, mismatches: [], errors: [error.localizedDescription]),
                error: error
            )
            
            // Update statistics
            await updateStatistics(result: testResult)
            
            // Store result
            storeTestResult(testResult)
            
            activeTests.remove(testId)
            
            logger.error("API test failed: \(endpoint.name), error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Endpoint Execution
    
    private func executeEndpointCall(endpoint: APIEndpoint, parameters: [String: Any]) async throws -> Any {
        switch endpoint.category {
        case .authentication:
            return try await executeAuthenticationEndpoint(endpoint, parameters: parameters)
        case .labLoop:
            return try await executeLabLoopEndpoint(endpoint, parameters: parameters)
        case .health:
            return try await executeHealthEndpoint(endpoint, parameters: parameters)
        case .reports:
            return try await executeReportsEndpoint(endpoint, parameters: parameters)
        case .upload:
            return try await executeUploadEndpoint(endpoint, parameters: parameters)
        }
    }
    
    private func executeAuthenticationEndpoint(_ endpoint: APIEndpoint, parameters: [String: Any]) async throws -> Any {
        switch endpoint.name {
        case "register":
            guard let email = parameters["email"] as? String,
                  let password = parameters["password"] as? String,
                  let name = parameters["name"] as? String else {
                throw APITestingError.missingParameters(["email", "password", "name"])
            }
            
            // Create minimal user profile for registration
            let profile = UserProfile(
                dateOfBirth: parameters["dateOfBirth"] as? Date,
                gender: parameters["gender"] as? Gender
            )
            
            return try await authService.register(
                email: email,
                password: password,
                name: name,
                profile: profile
            ) as Any
            
        case "login":
            guard let email = parameters["email"] as? String,
                  let password = parameters["password"] as? String else {
                throw APITestingError.missingParameters(["email", "password"])
            }
            
            return try await authService.login(email: email, password: password) as Any
            
        case "logout":
            let currentDeviceOnly = parameters["currentDeviceOnly"] as? Bool ?? true
            return try await authService.logout(fromCurrentDeviceOnly: currentDeviceOnly) as Any
            
        case "refreshToken":
            return try await authService.refreshToken() as Any
            
        case "forgotPassword":
            guard let email = parameters["email"] as? String else {
                throw APITestingError.missingParameters(["email"])
            }
            return try await authService.forgotPassword(email: email) as Any
            
        case "getCurrentUser":
            return try await authService.getCurrentUser() as Any
            
        case "validateToken":
            return await authService.isAuthenticated() as Any
            
        default:
            throw APITestingError.unsupportedEndpoint(endpoint.name)
        }
    }
    
    private func executeLabLoopEndpoint(_ endpoint: APIEndpoint, parameters: [String: Any]) async throws -> Any {
        // Implementation for LabLoop endpoints will be added in Phase 3
        throw APITestingError.notImplemented(endpoint.name)
    }
    
    private func executeHealthEndpoint(_ endpoint: APIEndpoint, parameters: [String: Any]) async throws -> Any {
        // Implementation for Health endpoints will be added in Phase 3
        throw APITestingError.notImplemented(endpoint.name)
    }
    
    private func executeReportsEndpoint(_ endpoint: APIEndpoint, parameters: [String: Any]) async throws -> Any {
        // Implementation for Reports endpoints will be added in Phase 3
        throw APITestingError.notImplemented(endpoint.name)
    }
    
    private func executeUploadEndpoint(_ endpoint: APIEndpoint, parameters: [String: Any]) async throws -> Any {
        // Implementation for Upload endpoints will be added in Phase 3
        throw APITestingError.notImplemented(endpoint.name)
    }
    
    // MARK: - Statistics Management
    
    private func updateStatistics(result: APITestResult) async {
        totalTestsRun += 1
        
        switch result.status {
        case .success:
            successfulTests += 1
        case .failed:
            failedTests += 1
        case .running:
            break // Should not happen here
        }
        
        // Update response times
        responseTimes.append(result.responseTime)
        if responseTimes.count > maxStoredResponseTimes {
            responseTimes.removeFirst()
        }
        
        // Recalculate average response time
        averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
    
    // MARK: - Result Management
    
    private func storeTestResult(_ result: APITestResult) {
        testResults.insert(result, at: 0) // Insert at beginning for chronological order
        
        // Maintain maximum stored results
        if testResults.count > maxStoredResults {
            testResults.removeLast()
        }
    }
    
    func clearAllResults() {
        testResults.removeAll()
        totalTestsRun = 0
        successfulTests = 0
        failedTests = 0
        responseTimes.removeAll()
        averageResponseTime = 0.0
        
        logger.info("All test results cleared")
    }
    
    // MARK: - Configuration Management
    
    func saveTestConfiguration(_ config: APITestConfiguration) {
        testConfigurations[config.id] = config
        logger.info("Test configuration saved: \(config.name)")
    }
    
    func loadTestConfiguration(_ id: String) -> APITestConfiguration? {
        return testConfigurations[id]
    }
    
    func deleteTestConfiguration(_ id: String) {
        testConfigurations.removeValue(forKey: id)
        logger.info("Test configuration deleted: \(id)")
    }
    
    // MARK: - Import/Export
    
    func exportResults() {
        // TODO: Implement results export functionality
        logger.info("Export results requested")
    }
    
    func importConfiguration() {
        // TODO: Implement configuration import functionality
        logger.info("Import configuration requested")
    }
    
    func resetToDefaults() {
        clearAllResults()
        testConfigurations.removeAll()
        logger.info("Reset to defaults completed")
    }
    
    // MARK: - Connection Status
    
    private func updateConnectionStatus() {
        Task {
            // Simple connectivity check to backend
            do {
                // Try to get current user - this will validate connectivity and auth
                _ = try await authService.getCurrentUser()
                await MainActor.run {
                    self.isConnected = true
                }
            } catch {
                await MainActor.run {
                    self.isConnected = false
                }
            }
        }
    }
    
    func refreshConnectionStatus() {
        updateConnectionStatus()
    }
    
    // MARK: - Parameter Sanitization
    
    /// Sanitizes parameters to ensure they are safe for JSON serialization and API calls
    private func sanitizeParameters(_ parameters: [String: Any]) -> [String: Any] {
        var sanitized: [String: Any] = [:]
        
        for (key, value) in parameters {
            sanitized[key] = sanitizeValue(value)
        }
        
        return sanitized
    }
    
    private func sanitizeValue(_ value: Any) -> Any {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number
        case let bool as Bool:
            return bool
        case let date as Date:
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
        case let url as URL:
            return url.absoluteString
        case let array as [Any]:
            return array.map { sanitizeValue($0) }
        case let dict as [String: Any]:
            var sanitizedDict: [String: Any] = [:]
            for (k, v) in dict {
                sanitizedDict[k] = sanitizeValue(v)
            }
            return sanitizedDict
        case Optional<Any>.none:
            return NSNull()
        default:
            // Convert any other type to string representation to prevent crashes
            logger.warning("Unsupported parameter type: \(type(of: value)), converting to string")
            return String(describing: value)
        }
    }
    
    // MARK: - Persistence
    
    private func loadStoredResults() {
        // TODO: Load previously stored test results from persistent storage
    }
    
    private func saveResults() {
        // TODO: Save test results to persistent storage
    }
}

// MARK: - Supporting Enums and Errors

enum APITestingError: @preconcurrency LocalizedError {
    case missingParameters([String])
    case unsupportedEndpoint(String)
    case notImplemented(String)
    case invalidConfiguration(String)
    case networkError(Error)
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .missingParameters(let params):
            return "Missing required parameters: \(params.joined(separator: ", "))"
        case .unsupportedEndpoint(let endpoint):
            return "Unsupported endpoint: \(endpoint)"
        case .notImplemented(let endpoint):
            return "Endpoint not yet implemented: \(endpoint)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationRequired:
            return "Authentication required to test this endpoint"
        }
    }
}