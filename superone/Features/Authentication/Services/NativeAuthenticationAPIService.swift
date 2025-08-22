//
//  NativeAuthenticationAPIService.swift
//  SuperOne
//
//  Created by Claude Code on 1/31/25.
//  Native URLSession-based authentication service to replace Alamofire for authentication endpoints only
//

import Foundation
import Combine

/// Native authentication API service using URLSession to avoid Alamofire Swift 6 crashes
class NativeAuthenticationAPIService: ObservableObject {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let baseURL: String
    private let keychainHelper: KeychainHelper
    
    // MARK: - Initialization
    
    init(
        baseURL: String = APIConfiguration.baseURL,
        keychainHelper: KeychainHelper = KeychainHelper.shared
    ) {
        self.baseURL = baseURL
        self.keychainHelper = keychainHelper
        
        // Configure URLSession with proper timeouts
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        configuration.waitsForConnectivity = true
        
        self.session = URLSession(configuration: configuration)
        
    }
    
    // MARK: - Authentication Methods
    
    /// Register a new user using native URLSession
    func register(
        email: String,
        password: String,
        name: String,
        profile: UserProfile?
    ) async throws -> AuthResponse {
        
        // Split name into firstName and lastName
        let nameParts = name.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        
        // Format date of birth for backend
        let dateOfBirthString: String
        if let dateOfBirth = profile?.dateOfBirth {
            dateOfBirthString = dateOfBirth.iso8601String
        } else {
            // Use a placeholder date for registration
            let calendar = Calendar.current
            let defaultDate = calendar.date(byAdding: .year, value: -25, to: Date()) ?? Date()
            dateOfBirthString = defaultDate.iso8601String
        }
        
        // Debug gender value transformation
        let genderRawValue = profile?.gender?.rawValue ?? "not_specified"
        
        let request = APIRegisterRequest(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirthString,
            gender: genderRawValue,
            diagnosisDate: nil
        )
        
        
        // Debug JSON serialization to verify exact payload
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(request)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "Could not convert to string"
        } catch {
        }
        
        // Test JSON encoding before sending
        let jsonData: Data
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            jsonData = try encoder.encode(request)
            let testString = String(data: jsonData, encoding: .utf8) ?? "Could not convert to string"
        } catch {
            throw error
        }
        
        // Perform native URLSession request
        let url = URL(string: APIConfiguration.mobileURL(for: APIConfiguration.Endpoints.Auth.register))!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = jsonData
        urlRequest.timeoutInterval = 20.0
        
        
        let (responseData, response): (Data, URLResponse)
        do {
            (responseData, response) = try await session.data(for: urlRequest)
        } catch {
            throw mapNetworkError(error)
        }
        
        // Handle HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NativeAuthError.invalidResponse
        }
        
        
        // Log response data
        if let responseString = String(data: responseData, encoding: .utf8) {
        }
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let authResponse: AuthResponse
        do {
            authResponse = try decoder.decode(AuthResponse.self, from: responseData)
        } catch {
            throw NativeAuthError.decodingFailed(error)
        }
        
        // Store tokens if registration successful
        if authResponse.success, let authData = authResponse.data {
            try await storeAuthTokens(authData.tokens)
        } else {
        }
        
        return authResponse
    }
    
    /// Login user using native URLSession
    func login(email: String, password: String) async throws -> AuthResponse {
        
        let request = APILoginRequest(email: email, password: password)
        
        // Encode JSON
        let jsonData: Data
        do {
            jsonData = try JSONEncoder().encode(request)
        } catch {
            throw NativeAuthError.encodingFailed(error)
        }
        
        // Create request
        let url = URL(string: APIConfiguration.mobileURL(for: APIConfiguration.Endpoints.Auth.login))!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = jsonData
        urlRequest.timeoutInterval = 15.0
        
        
        // Perform request
        let (responseData, response): (Data, URLResponse)
        do {
            (responseData, response) = try await session.data(for: urlRequest)
        } catch {
            throw mapNetworkError(error)
        }
        
        // Handle response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NativeAuthError.invalidResponse
        }
        
        
        // Log response data
        if let responseString = String(data: responseData, encoding: .utf8) {
        }
        
        // Decode response
        let authResponse: AuthResponse
        do {
            authResponse = try JSONDecoder().decode(AuthResponse.self, from: responseData)
        } catch {
            throw NativeAuthError.decodingFailed(error)
        }
        
        // Store tokens if login successful
        if authResponse.success, let authData = authResponse.data {
            try await storeAuthTokens(authData.tokens)
        } else {
        }
        
        return authResponse
    }
    
    // MARK: - Token Management
    
    /// Store authentication tokens securely
    private func storeAuthTokens(_ tokens: AuthTokens) async throws {
        await keychainHelper.storeAuthToken(tokens.accessToken)
        await keychainHelper.storeRefreshToken(tokens.refreshToken)
    }
    
    // MARK: - Error Mapping
    
    private func mapNetworkError(_ error: Error) -> NativeAuthError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .requestTimeout
            case .notConnectedToInternet, .networkConnectionLost:
                return .noConnection
            case .cancelled:
                return .requestCancelled
            default:
                return .networkError(urlError.localizedDescription)
            }
        } else {
            return .unknownError(error.localizedDescription)
        }
    }
}

// MARK: - Native Auth Error Types

enum NativeAuthError: @preconcurrency LocalizedError, Sendable {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case requestTimeout
    case noConnection
    case requestCancelled
    case invalidResponse
    case networkError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "Request encoding failed: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Response decoding failed: \(error.localizedDescription)"
        case .requestTimeout:
            return "Request timed out. Please check your internet connection and try again."
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .requestCancelled:
            return "Request was cancelled"
        case .invalidResponse:
            return "Invalid server response"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .requestTimeout:
            return "The server is taking too long to respond. Please check your internet connection and try again."
        case .noConnection:
            return "Please check your network settings and try again."
        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
}