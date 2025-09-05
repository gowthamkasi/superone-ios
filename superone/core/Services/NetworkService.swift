//
//  NetworkService.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//

import Foundation
@preconcurrency import Alamofire
import Network
import Combine

/// Base network service for API communication with Super One backend
@MainActor
class NetworkService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NetworkService()
    
    // MARK: - Properties
    
    private let session: Session
    private let reachabilityManager: NetworkReachabilityManager?
    private let requestQueue = DispatchQueue(label: "com.superone.network", qos: .userInitiated)
    
    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown
    
    // MARK: - Network Connection Types
    
    enum ConnectionType {
        case wifi
        case cellular
        case unknown
        case notConnected
    }
    
    // MARK: - Custom Errors
    
    enum NetworkError: @preconcurrency LocalizedError {
        case noConnection
        case invalidResponse
        case partialResponse(Int, Int) // received bytes, expected bytes
        case authenticationRequired
        case serverError(Int)
        case requestTimeout
        case requestCancelled
        case invalidURL
        case encodingError
        case decodingError(Error)
        case unknownError(Error)
        
        var errorDescription: String? {
            switch self {
            case .noConnection:
                return "No internet connection available"
            case .invalidResponse:
                return "Invalid response from server"
            case .partialResponse(let received, let expected):
                return "Incomplete response: received \(received) bytes, expected \(expected) bytes"
            case .authenticationRequired:
                return "Authentication required"
            case .serverError(let code):
                return "Server error occurred (Code: \(code))"
            case .requestTimeout:
                return "The request timed out. Please check your connection and try again."
            case .requestCancelled:
                return "Request was cancelled"
            case .invalidURL:
                return "Invalid URL"
            case .encodingError:
                return "Failed to encode request"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .unknownError(let error):
                return "Unknown error: \(error.localizedDescription)"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .noConnection:
                return "Please check your internet connection and try again."
            case .partialResponse:
                return "Response transfer was interrupted. Please try again or check your internet connection."
            case .requestTimeout:
                return "The server is taking too long to respond. Please try again or check your internet connection."
            case .serverError:
                return "The server is experiencing issues. Please try again later."
            case .authenticationRequired:
                return "Please log in again to continue."
            default:
                return "Please try again. If the problem persists, contact support."
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Configure Alamofire session with aggressive timeout settings to prevent hanging
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15.0  // Reduced from 30s to 15s for faster failure
        configuration.timeoutIntervalForResource = 30.0  // Maximum time for entire request
        configuration.urlCache = URLCache(
            memoryCapacity: APIConfiguration.Cache.maxSize / 4,
            diskCapacity: APIConfiguration.Cache.maxSize,
            diskPath: "com.superone.network.cache"
        )
        
        // Configure waitsForConnectivity to false to fail fast if no connection
        configuration.waitsForConnectivity = false
        
        // Create session with interceptors
        session = Session(
            configuration: configuration,
            interceptor: NetworkInterceptor()
        )
        
        // Set up network reachability
        reachabilityManager = NetworkReachabilityManager()
        setupNetworkMonitoring()
        
        // Configure logging
        setupLogging()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        reachabilityManager?.startListening { [weak self] status in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(status)
            }
        }
    }
    
    private func updateConnectionStatus(_ status: NetworkReachabilityManager.NetworkReachabilityStatus) {
        switch status {
        case .notReachable:
            isConnected = false
            connectionType = .notConnected
        case .reachable(.ethernetOrWiFi):
            isConnected = true
            connectionType = .wifi
        case .reachable(.cellular):
            isConnected = true
            connectionType = .cellular
        case .unknown:
            isConnected = false
            connectionType = .unknown
        }
        
        logNetworkStatus()
    }
    
    // MARK: - Logging
    
    private func setupLogging() {
        #if DEBUG
        if APIConfiguration.Logging.enabled {
            // Add request/response logging in debug builds
        }
        #endif
    }
    
    private func logNetworkStatus() {
        let statusMessage = isConnected 
            ? "Network connected via \(connectionType)"
            : "Network not connected"
        
        if APIConfiguration.Logging.enabled {
        }
    }
    
    private func logRequest(_ request: URLRequest) {
        
        if let body = request.httpBody {
            if let bodyString = String(data: body, encoding: .utf8) {
            } else {
            }
        } else {
        }
    }
    
    nonisolated private func logResponse<T>(_ result: Result<T, Error>, for request: URLRequest) {
        switch result {
        case .success(let data):
            if let responseData = data as? Data,
               let responseString = String(data: responseData, encoding: .utf8) {
                // Response logging removed
            }
            break
        case .failure(let error):
            break
        }
    }
    
    // MARK: - Request Methods
    
    /// Generic GET request
    func get<T: Codable & Sendable>(
        _ endpoint: String,
        responseType: T.Type,
        parameters: [String: Sendable]? = nil,
        headers: HTTPHeaders? = nil,
        useCache: Bool = true
    ) async throws -> T {
        return try await performRequest(
            method: Alamofire.HTTPMethod.get,
            endpoint: endpoint,
            parameters: parameters,
            body: Optional<String>.none,
            responseType: responseType,
            headers: headers,
            useCache: useCache
        )
    }
    
    /// Generic POST request with timeout handling
    func post<T: Codable & Sendable, U: Codable & Sendable>(
        _ endpoint: String,
        body: U? = nil,
        responseType: T.Type,
        headers: HTTPHeaders? = nil,
        timeout: TimeInterval? = nil
    ) async throws -> T {
        return try await performRequest(
            method: Alamofire.HTTPMethod.post,
            endpoint: endpoint,
            body: body,
            responseType: responseType,
            headers: headers,
            timeout: timeout
        )
    }
    
    /// Generic PUT request
    func put<T: Codable & Sendable, U: Codable & Sendable>(
        _ endpoint: String,
        body: U? = nil,
        responseType: T.Type,
        headers: HTTPHeaders? = nil
    ) async throws -> T {
        return try await performRequest(
            method: Alamofire.HTTPMethod.put,
            endpoint: endpoint,
            body: body,
            responseType: responseType,
            headers: headers
        )
    }
    
    /// Generic DELETE request
    func delete<T: Codable & Sendable>(
        _ endpoint: String,
        responseType: T.Type,
        headers: HTTPHeaders? = nil
    ) async throws -> T {
        return try await performRequest(
            method: Alamofire.HTTPMethod.delete,
            endpoint: endpoint,
            body: Optional<String>.none,
            responseType: responseType,
            headers: headers
        )
    }
    
    /// Upload multipart form data
    func upload<T: Codable & Sendable>(
        _ endpoint: String,
        multipartFormData: @escaping (MultipartFormData) -> Void,
        responseType: T.Type,
        headers: HTTPHeaders? = nil,
        progressHandler: (@Sendable (Progress) -> Void)? = nil
    ) async throws -> T {
        guard isConnected else {
            throw NetworkError.noConnection
        }
        
        let url = APIConfiguration.url(for: endpoint)
        let requestHeaders = await buildHeaders(headers)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: multipartFormData,
                to: url,
                method: Alamofire.HTTPMethod.post,
                headers: requestHeaders
            )
            .uploadProgress { progress in
                DispatchQueue.main.async {
                    progressHandler?(progress)
                }
            }
            .responseData { response in
                self.handleResponse(response, responseType: responseType, continuation: continuation)
            }
        }
    }
    
    /// Get raw response data without JSON decoding (for API testing)
    func getRawData(
        _ endpoint: String,
        method: Alamofire.HTTPMethod = .get,
        parameters: [String: Sendable]? = nil,
        headers: HTTPHeaders? = nil
    ) async throws -> (data: Data, response: HTTPURLResponse) {
        guard isConnected else {
            throw NetworkError.noConnection
        }
        
        let url = APIConfiguration.url(for: endpoint)
        let requestHeaders = await buildHeaders(headers)
        
        return try await withCheckedThrowingContinuation { continuation in
            var request: DataRequest
            
            if method == .post, let params = parameters, !params.isEmpty {
                // POST request with JSON body
                request = session.request(
                    url,
                    method: method,
                    parameters: params,
                    encoding: JSONEncoding.default,
                    headers: requestHeaders
                )
                .responseData { response in
                    self.handleRawResponse(response, continuation: continuation)
                }
            } else {
                // GET request or other methods
                request = session.request(
                    url,
                    method: method,
                    parameters: parameters,
                    encoding: URLEncoding.default,
                    headers: requestHeaders
                )
                .responseData { response in
                    self.handleRawResponse(response, continuation: continuation)
                }
            }
            
            if let urlRequest = request.request {
                logRequest(urlRequest)
            }
        }
    }
    
    // MARK: - Private Request Handling
    
    private func performRequest<T: Codable & Sendable, U: Codable & Sendable>(
        method: Alamofire.HTTPMethod,
        endpoint: String,
        parameters: [String: Sendable]? = nil,
        body: U? = nil,
        responseType: T.Type,
        headers: HTTPHeaders? = nil,
        useCache: Bool = false,
        timeout: TimeInterval? = nil
    ) async throws -> T {
        guard isConnected else {
            throw NetworkError.noConnection
        }
        
        let url = APIConfiguration.url(for: endpoint)
        let requestHeaders = await buildHeaders(headers)
        
        // Use a simple timeout with Task.withTimeout when available, 
        // otherwise rely on URLSession's built-in timeout
        return try await performActualRequest(
            method: method,
            url: url,
            parameters: parameters,
            body: body,
            responseType: responseType,
            headers: requestHeaders,
            useCache: useCache
        )
    }
    
    private func performActualRequest<T: Codable & Sendable, U: Codable & Sendable>(
        method: Alamofire.HTTPMethod,
        url: String,
        parameters: [String: Sendable]? = nil,
        body: U? = nil,
        responseType: T.Type,
        headers: HTTPHeaders,
        useCache: Bool = false
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            // Prepare request parameters based on body content
            let encoding: ParameterEncoding
            
            if let body = body, method != Alamofire.HTTPMethod.get {
                // WORKAROUND: Manual JSON encoding to avoid Alamofire JSONParameterEncoder Swift 6 crash
                let jsonData: Data
                do {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .custom(NetworkService.robustISO8601DateEncoder) // Consistent with decoding strategy
                    jsonData = try encoder.encode(body)
                } catch {
                    continuation.resume(throwing: NetworkError.encodingError)
                    return
                }
                
                // Create request with raw JSON data
                var urlRequest = URLRequest(url: URL(string: url)!)
                urlRequest.httpMethod = method.rawValue
                urlRequest.httpBody = jsonData
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Add custom headers
                for header in headers {
                    urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
                }
                
                let request = session.request(urlRequest)
                    .validate()
                
                if useCache {
                    request.cacheResponse(using: ResponseCacher.cache)
                }
                
                if let urlRequest = request.request {
                    logRequest(urlRequest)
                }
                
                request.responseData { response in
                    self.handleResponse(response, responseType: responseType, continuation: continuation)
                }
                return
            } else {
                let encoding = URLEncoding.default
                
                // Handle GET requests and other methods without body
                // Create request without parameters to avoid Sendable issues
                var request: DataRequest
                if let params = parameters, !params.isEmpty {
                    // Create request with individual parameter handling
                    request = session.request(
                        url,
                        method: method,
                        parameters: [:] as [String: String], // Empty sendable parameters
                        encoding: encoding,
                        headers: headers
                    )
                } else {
                    request = session.request(
                        url,
                        method: method,
                        parameters: nil,
                        encoding: encoding,
                        headers: headers
                    )
                }
                
                // Configure caching
                if useCache {
                    request = request.cacheResponse(using: ResponseCacher.cache)
                }
                
                // Log request
                if let urlRequest = request.request {
                    logRequest(urlRequest)
                }
                
                // Execute request
                request.responseData { response in
                    self.handleResponse(response, responseType: responseType, continuation: continuation)
                }
            }
        }
    }
    
    nonisolated private func handleResponse<T: Codable & Sendable>(
        _ response: AFDataResponse<Data>,
        responseType: T.Type,
        continuation: CheckedContinuation<T, Error>
    ) {
        // Log response
        if let request = response.request {
            logResponse(response.result.mapError { $0 as Error }, for: request)
        }
        
        switch response.result {
        case .success(let data):
            // Validate response completeness before decoding
            if let httpResponse = response.response,
               let expectedLength = httpResponse.expectedContentLength as? Int,
               expectedLength > 0,
               data.count < expectedLength {
                continuation.resume(throwing: NetworkError.partialResponse(data.count, expectedLength))
                return
            }
            
            // Additional validation: check for truncated JSON
            if !validateJSONCompleteness(data) {
                continuation.resume(throwing: NetworkError.partialResponse(data.count, -1))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                // Use robust custom ISO8601 date decoding strategy to fix device vs simulator inconsistencies
                decoder.dateDecodingStrategy = .custom(NetworkService.robustISO8601DateDecoder)
                
                print("🔍 Using robust custom ISO8601 date decoding strategy")
                print("🔍 Supporting multiple ISO8601 formats with fractional seconds and timezone variations")
                
                // Log raw response data for debugging
                let rawResponseString = String(data: data, encoding: .utf8) ?? "Could not convert data to string"
                print("🔍 RAW RESPONSE DATA (Length: \(data.count) bytes):")
                print("Response Type: \(responseType)")
                print("Raw JSON: \(rawResponseString)")
                
                let decodedResponse = try decoder.decode(responseType, from: data)
                print("✅ Successfully decoded response of type: \(responseType)")
                continuation.resume(returning: decodedResponse)
            } catch {
                let rawResponseString = String(data: data, encoding: .utf8) ?? "Could not convert data to string"
                print("❌ JSON DECODING ERROR:")
                print("Response Type: \(responseType)")
                print("Raw JSON: \(rawResponseString)")
                print("Error: \(error)")
                
                if let decodingError = error as? DecodingError {
                    print("📋 DETAILED DECODING ERROR ANALYSIS:")
                    print("Error Type: \(decodingError)")
                    
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("🔑 MISSING KEY ERROR:")
                        print("   Missing key: '\(key.stringValue)'")
                        print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
                        print("   Context: \(context.debugDescription)")
                        
                    case .typeMismatch(let type, let context):
                        print("⚠️ TYPE MISMATCH ERROR:")
                        print("   Expected type: \(type)")
                        print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
                        print("   Context: \(context.debugDescription)")
                        
                        // Special handling for Date type mismatches (our main concern)
                        if type == Date.self {
                            print("📅 DATE PARSING FAILURE DETECTED:")
                            print("   This is likely the iOS date parsing issue we're fixing")
                            print("   Check if backend is sending: '1995-08-19T00:00:00.000Z' format")
                        }
                        
                    case .valueNotFound(let type, let context):
                        print("❌ VALUE NOT FOUND ERROR:")
                        print("   Missing value for type: \(type)")
                        print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
                        print("   Context: \(context.debugDescription)")
                        
                    case .dataCorrupted(let context):
                        print("💥 DATA CORRUPTED ERROR:")
                        print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
                        print("   Context: \(context.debugDescription)")
                        
                        // Check if it's our custom date parsing error
                        if context.debugDescription.contains("ISO8601 format") {
                            print("📅 CUSTOM DATE PARSING ERROR:")
                            print("   Our robust date parser failed to parse a date string")
                            print("   Backend may be sending an unexpected date format")
                        }
                        
                    @unknown default:
                        print("❓ UNKNOWN DECODING ERROR:")
                        print("   Error: \(decodingError)")
                    }
                    
                    // Additional debugging for authentication-related paths
                    let codingPathString: String
                    switch decodingError {
                    case .keyNotFound(_, let context), .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
                        codingPathString = context.codingPath.map { $0.stringValue }.joined(separator: " → ")
                    @unknown default:
                        codingPathString = "unknown"
                    }
                    
                    if codingPathString.contains("data") && codingPathString.contains("user") {
                        print("🔐 AUTHENTICATION-RELATED DECODING ERROR DETECTED:")
                        print("   This error occurs in the authentication response user data")
                        print("   Likely fields: createdAt, updatedAt, dateOfBirth")
                        print("   Path: \(codingPathString)")
                    }
                }
                continuation.resume(throwing: NetworkError.decodingError(error))
            }
            
        case .failure(let error):
            let networkError = mapAlamofireError(error, statusCode: response.response?.statusCode)
            continuation.resume(throwing: networkError)
        }
    }
    
    /// Handle raw response without JSON decoding (for API testing)
    nonisolated private func handleRawResponse(
        _ response: AFDataResponse<Data>,
        continuation: CheckedContinuation<(data: Data, response: HTTPURLResponse), Error>
    ) {
        // Log response
        if let request = response.request {
            logResponse(response.result.mapError { $0 as Error }, for: request)
        }
        
        switch response.result {
        case .success(let data):
            guard let httpResponse = response.response else {
                continuation.resume(throwing: NetworkError.invalidResponse)
                return
            }
            
            // Always return raw data, regardless of completeness or status code
            continuation.resume(returning: (data: data, response: httpResponse))
            
        case .failure(let error):
            let networkError = mapAlamofireError(error, statusCode: response.response?.statusCode)
            continuation.resume(throwing: networkError)
        }
    }
    
    /// Validates if JSON data appears to be complete
    nonisolated private func validateJSONCompleteness(_ data: Data) -> Bool {
        guard let jsonString = String(data: data, encoding: .utf8) else {
            return false
        }
        
        // Check for basic JSON structure completeness
        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Must start and end with proper JSON brackets/braces
        let hasValidStart = trimmed.hasPrefix("{") || trimmed.hasPrefix("[")
        let hasValidEnd = trimmed.hasSuffix("}") || trimmed.hasSuffix("]")
        
        // Check for common truncation indicators
        let isNotTruncated = !trimmed.hasSuffix("...")
            && !trimmed.isEmpty
            && trimmed != "{}"
            && !trimmed.contains("\"data\":{}")
        
        return hasValidStart && hasValidEnd && isNotTruncated
    }
    
    nonisolated private func mapAlamofireError(_ error: AFError, statusCode: Int?) -> NetworkError {
        switch error {
        case .sessionTaskFailed(let sessionError):
            if let urlError = sessionError as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    return .noConnection
                case .timedOut:
                    return .requestTimeout
                default:
                    return .unknownError(urlError)
                }
            }
            return .unknownError(sessionError)
            
        case .responseValidationFailed, .responseSerializationFailed:
            if let statusCode = statusCode {
                let authenticationRequiredStatusCodes = [401, 403] // Local constants
                let serverErrorStatusCodes = [500, 501, 502, 503, 504]
                let clientErrorStatusCodes = [400, 404, 409, 422] // Bad request, not found, conflict, validation errors
                
                if authenticationRequiredStatusCodes.contains(statusCode) {
                    return .authenticationRequired
                } else if serverErrorStatusCodes.contains(statusCode) {
                    return .serverError(statusCode)
                } else if clientErrorStatusCodes.contains(statusCode) {
                    // Return client error with specific status code for better handling
                    return .serverError(statusCode) // This will be caught as an error
                }
            }
            return .invalidResponse
            
        default:
            return .unknownError(error)
        }
    }
    
    private func buildHeaders(_ additionalHeaders: HTTPHeaders?) async -> HTTPHeaders {
        var headers = HTTPHeaders(APIConfiguration.Headers.standard)
        
        // Add authentication token if available
        if let token = await getAuthToken() {
            headers.add(.authorization(bearerToken: token))
        }
        
        // Add additional headers
        if let additionalHeaders = additionalHeaders {
            for header in additionalHeaders {
                headers.add(header)
            }
        }
        
        return headers
    }
    
    private func getAuthToken() async -> String? {
        // Use TokenManager like the working LabReports implementation
        return await TokenManager.shared.getValidToken()
    }
    
    // MARK: - Request Cancellation
    
    /// Cancel all active network requests by canceling the session
    func cancelAllRequests() {
        session.cancelAllRequests()
    }
    
    // MARK: - Custom Date Decoding
    
    /// Robust ISO8601 date decoder that handles device vs simulator inconsistencies
    /// Supports multiple ISO8601 formats with and without fractional seconds
    nonisolated static func robustISO8601DateDecoder(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        
        // Use en_US_POSIX locale for consistent parsing across devices and locales
        let dateFormatters = createISO8601Formatters()
        
        // Try each formatter in order of preference
        for formatter in dateFormatters {
            if let date = formatter.date(from: dateString) {
                #if DEBUG
                print("✅ Successfully parsed date '\(dateString)' using format: \(formatter.dateFormat ?? "unknown")")
                #endif
                return date
            }
        }
        
        // If all formatters fail, log the issue and throw an error
        #if DEBUG
        print("❌ Failed to parse date string: '\(dateString)'")
        print("🔍 Tried formats:")
        for formatter in dateFormatters {
            print("   - \(formatter.dateFormat ?? "unknown")")
        }
        #endif
        
        let context = DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Date string '\(dateString)' does not match any supported ISO8601 format. Expected formats: yyyy-MM-dd'T'HH:mm:ss.SSSZ, yyyy-MM-dd'T'HH:mm:ssZ, yyyy-MM-dd'T'HH:mm:ss.SSS'Z', yyyy-MM-dd'T'HH:mm:ss'Z'"
        )
        throw DecodingError.dataCorrupted(context)
    }
    
    /// Creates array of ISO8601 date formatters with fallback patterns
    /// Uses en_US_POSIX locale for device consistency and explicit UTC timezone
    nonisolated private static func createISO8601Formatters() -> [DateFormatter] {
        // ISO8601 formats in order of preference (most specific first)
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",     // 2023-12-15T10:30:45.123Z
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",   // 2023-12-15T10:30:45.123Z (literal Z)
            "yyyy-MM-dd'T'HH:mm:ssZ",         // 2023-12-15T10:30:45Z
            "yyyy-MM-dd'T'HH:mm:ss'Z'",       // 2023-12-15T10:30:45Z (literal Z)
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",  // 2023-12-15T10:30:45.123456Z (microseconds)
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'", // 2023-12-15T10:30:45.123456Z (literal Z)
            "yyyy-MM-dd'T'HH:mm:ss",          // 2023-12-15T10:30:45 (no timezone, assume UTC)
        ]
        
        return dateFormats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX") // Critical for device consistency
            formatter.timeZone = TimeZone(identifier: "UTC") // Explicit UTC timezone
            return formatter
        }
    }
    
    /// Robust ISO8601 date encoder that produces consistent format for backend
    /// Always encodes dates in the same format: yyyy-MM-dd'T'HH:mm:ss.SSS'Z'
    nonisolated static func robustISO8601DateEncoder(_ date: Date, encoder: Encoder) throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        let dateString = formatter.string(from: date)
        var container = encoder.singleValueContainer()
        try container.encode(dateString)
        
        #if DEBUG
        print("✅ Encoded date to string: '\(dateString)'")
        #endif
    }
}

// MARK: - Date Handling Extensions

extension Date {
    /// Parse date from string using the same robust ISO8601 parser as NetworkService
    static func fromRobustISO8601String(_ dateString: String) -> Date? {
        let formatters = NetworkService.getISO8601Formatters()
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    /// Convert date to robust ISO8601 string using the same formatter as NetworkService
    func toRobustISO8601String() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: self)
    }
}

extension NetworkService {
    /// Expose the private formatters method for testing and utility use
    static func getISO8601Formatters() -> [DateFormatter] {
        return createISO8601Formatters()
    }
}

// MARK: - Network Interceptor

nonisolated private final class NetworkInterceptor: RequestInterceptor {
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var adaptedRequest = urlRequest
        
        // Add standard headers if not present
        let standardHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "SuperOne-iOS/1.0.0"
        ]
        for (key, value) in standardHeaders {
            if adaptedRequest.value(forHTTPHeaderField: key) == nil {
                adaptedRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        completion(.success(adaptedRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse else {
            completion(.doNotRetry)
            return
        }
        
        // Only retry for server errors and specific client errors (reduced scope to prevent hanging)
        // 408: Request Timeout, 429: Too Many Requests
        // 502: Bad Gateway, 503: Service Unavailable (temporarily retry these)
        let retryableStatusCodes = [408, 429, 502, 503]
        let maxRetryAttempts = 2  // Reduced from 3 to 2 to fail faster
        let baseRetryDelay = 0.5  // Reduced from 1.0 to 0.5 seconds
        
        
        if retryableStatusCodes.contains(response.statusCode) {
            if request.retryCount < maxRetryAttempts {
                // Reduced exponential backoff: 0.5s, 1s
                let delay = baseRetryDelay * pow(2.0, Double(request.retryCount))
                completion(.retryWithDelay(delay))
            } else {
                completion(.doNotRetry)
            }
        } else {
            completion(.doNotRetry)
        }
    }
}

// MARK: - Response Caching

extension NetworkService {
    
    nonisolated private struct ResponseCacher: CachedResponseHandler {
        static let cache = ResponseCacher()
        
        func dataTask(
            _ task: URLSessionDataTask,
            willCacheResponse response: CachedURLResponse,
            completion: @escaping (CachedURLResponse?) -> Void
        ) {
            // Cache successful responses only
            if let httpResponse = response.response as? HTTPURLResponse {
                let successStatusCodes = Array(200...299) // Local constant for 2xx success codes
                if successStatusCodes.contains(httpResponse.statusCode) {
                    completion(response)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
}

// MARK: - Convenience Methods

extension NetworkService {
    
    /// Mobile-specific GET request
    func getMobile<T: Codable & Sendable>(
        _ endpoint: String,
        userId: String,
        responseType: T.Type,
        parameters: [String: Sendable]? = nil,
        useCache: Bool = true
    ) async throws -> T {
        let fullEndpoint = APIConfiguration.mobileURL(for: endpoint, userId: userId)
        return try await get(fullEndpoint, responseType: responseType, parameters: parameters, useCache: useCache)
    }
    
    /// Check if request should be retried
    func shouldRetry(error: Error) -> Bool {
        if case NetworkError.noConnection = error {
            return isConnected
        }
        if case NetworkError.partialResponse = error {
            return isConnected
        }
        return false
    }
}