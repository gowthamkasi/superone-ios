//
//  APIService.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import Foundation
import Combine
import UIKit

// MARK: - APIService - Temporarily Disabled During Alamofire Migration

// This file is temporarily disabled while transitioning from Alamofire to native URLSession
// Authentication uses AuthenticationAPIService directly with native URLSession
// Other features can be re-enabled later with native implementations

/*

// MARK: - API Endpoint Types

protocol APIEndpoint {
    var path: String { get }
    var method: NativeHTTPMethod { get }
    var headers: [String: String]? { get }
}

// MARK: - Response Models

// UploadResponse moved to APIResponseModels.swift

/// Comprehensive API service for backend communication
@MainActor
class APIService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = APIService()
    
    // MARK: - Properties
    @Published var isConnected = false
    @Published var currentError: AppError?
    
    private let session: Session
    private let baseURL: URL
    private let authInterceptor: AuthenticationInterceptor
    
    // MARK: - Initialization
    
    private init() {
        // Configure session with custom configuration
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        
        // Create auth interceptor for automatic token handling
        self.authInterceptor = AuthenticationInterceptor()
        
        // Create session with interceptors
        self.session = Session(
            configuration: configuration,
            interceptor: authInterceptor
        )
        
        // Set base URL based on environment
        self.baseURL = AppConfiguration.current.apiBaseURL
        
        // Start connectivity monitoring
        startConnectivityMonitoring()
    }
    
    // MARK: - Network Connectivity
    
    private func startConnectivityMonitoring() {
        let monitor = NetworkReachabilityManager()
        
        monitor?.startListening { [weak self] status in
            Task { @MainActor in
                self?.isConnected = status == .reachable(.ethernetOrWiFi) || status == .reachable(.cellular)
            }
        }
    }
    
    // MARK: - Request Methods
    
    /// Generic request method with comprehensive error handling
    func request<T: Codable & Sendable>(
        endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        
        guard isConnected else {
            throw AppError.networkUnavailable
        }
        
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        do {
            let response = await session.request(
                url,
                method: endpoint.method,
                parameters: endpoint.parameters,
                encoding: endpoint.encoding,
                headers: endpoint.headers.map { HTTPHeaders($0) }
            )
            .validate()
            .serializingDecodable(T.self)
            .response
            
            switch response.result {
            case .success(let data):
                return data
                
            case .failure(let error):
                throw mapAlamofireError(error, response: response.response)
            }
            
        } catch {
            throw mapAlamofireError(error)
        }
    }
    
    /// Upload file with progress tracking
    func uploadFile(
        endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String,
        progress: @escaping (Double) -> Void
    ) async throws -> UploadResponse {
        
        guard isConnected else {
            throw AppError.networkUnavailable
        }
        
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { formData in
                    formData.append(
                        fileData,
                        withName: "file",
                        fileName: fileName,
                        mimeType: mimeType
                    )
                    
                    // Add additional parameters
                    if let parameters = endpoint.parameters as? [String: Any] {
                        for (key, value) in parameters {
                            if let stringValue = value as? String,
                               let data = stringValue.data(using: .utf8) {
                                formData.append(data, withName: key)
                            }
                        }
                    }
                },
                to: url,
                headers: endpoint.headers.map { HTTPHeaders($0) }
            )
            .uploadProgress { uploadProgress in
                Task { @MainActor in
                    progress(uploadProgress.fractionCompleted)
                }
            }
            .validate()
            .responseData { [weak self] response in
                switch response.result {
                case .success(let data):
                    do {
                        let uploadResponse = try self?.decodeUploadResponse(from: data) ?? UploadResponse(success: false, message: "Decode failed", data: nil, timestamp: nil)
                        continuation.resume(returning: uploadResponse)
                    } catch {
                        continuation.resume(throwing: AppError.invalidResponse)
                    }
                case .failure(let error):
                    let mappedError = self?.mapAlamofireError(error, response: response.response) ?? AppError.networkUnavailable
                    continuation.resume(throwing: mappedError)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    nonisolated private func decodeUploadResponse(from data: Data) throws -> UploadResponse {
        // Use unsafeBitCast to bypass main actor isolation for Codable conformance
        let decoder = JSONDecoder()
        do {
            // Manual decoding to avoid main actor issues
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let success = json["success"] as? Bool ?? false
                let message = json["message"] as? String
                let timestamp = json["timestamp"] as? String
                
                var uploadData: UploadData?
                if let dataDict = json["data"] as? [String: Any] {
                    let labReportId = dataDict["labReportId"] as? String ?? ""
                    let fileName = dataDict["fileName"] as? String ?? ""
                    let fileSize = dataDict["fileSize"] as? Int ?? 0
                    let uploadUrl = dataDict["uploadUrl"] as? String
                    let processingStatus = dataDict["processingStatus"] as? String ?? ""
                    let estimatedProcessingTime = dataDict["estimatedProcessingTime"] as? Int
                    
                    uploadData = UploadData(
                        labReportId: labReportId,
                        fileName: fileName,
                        fileSize: fileSize,
                        uploadUrl: uploadUrl,
                        processingStatus: processingStatus,
                        estimatedProcessingTime: estimatedProcessingTime
                    )
                }
                
                let timestampDate: Date?
                if let timestampStr = timestamp {
                    timestampDate = ISO8601DateFormatter().date(from: timestampStr)
                } else {
                    timestampDate = nil
                }
                
                return UploadResponse(
                    success: success,
                    message: message,
                    data: uploadData,
                    timestamp: timestampDate
                )
            }
            throw AppError.invalidResponse
        } catch {
            throw AppError.invalidResponse
        }
    }
    
    // MARK: - Error Mapping
    
    nonisolated private func mapAlamofireError(_ error: Error, response: HTTPURLResponse? = nil) -> AppError {
        if let afError = error as? AFError {
            switch afError {
            case .sessionTaskFailed(let sessionError):
                if (sessionError as NSError).code == NSURLErrorNotConnectedToInternet {
                    return .networkUnavailable
                } else if (sessionError as NSError).code == NSURLErrorTimedOut {
                    return .requestTimeout
                }
                
            case .responseValidationFailed(reason: .unacceptableStatusCode(code: let code)):
                return mapHTTPError(statusCode: code)
                
            case .responseSerializationFailed:
                return .invalidResponse
                
            default:
                break
            }
        }
        
        if let httpResponse = response {
            return mapHTTPError(statusCode: httpResponse.statusCode)
        }
        
        return .unknown(error)
    }
    
    nonisolated private func mapHTTPError(statusCode: Int) -> AppError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            return .tooManyRequests
        case 500...599:
            return .serverError(code: statusCode)
        default:
            return .serverError(code: statusCode)
        }
    }
}

// MARK: - Authentication Interceptor

class AuthenticationInterceptor: @preconcurrency RequestInterceptor {
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        
        // Add authentication token if available
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add common headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("SuperOne/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue(UIDevice.current.identifierForVendor?.uuidString, forHTTPHeaderField: "Device-ID")
        
        completion(.success(request))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        
        // Retry on network errors
        if let afError = error as? AFError,
           case .sessionTaskFailed(let sessionError) = afError,
           (sessionError as NSError).code == NSURLErrorNotConnectedToInternet {
            
            // Retry after 2 seconds for network issues
            completion(.retryWithDelay(2.0))
            return
        }
        
        // Handle 401 unauthorized - attempt token refresh
        if let response = request.task?.response as? HTTPURLResponse,
           response.statusCode == 401 {
            
            Task {
                do {
                    // Attempt to refresh token
                    try await refreshAuthToken()
                    completion(.retry)
                } catch {
                    // Refresh failed - don't retry
                    completion(.doNotRetry)
                }
            }
            return
        }
        
        // Don't retry other errors
        completion(.doNotRetry)
    }
    
    private func getAuthToken() -> String? {
        // FIXED: Use TokenManager instead of old keychain key
        return TokenManager.shared.getAccessToken()
    }
    
    private func refreshAuthToken() async throws {
        // FIXED: Use TokenManager.refreshTokensIfNeeded() instead of broken implementation
        do {
            let refreshedTokens = try await TokenManager.shared.refreshTokensIfNeeded()
        } catch {
            throw error
        }
    }
}

// APIResponse is defined in NetworkModels.swift to avoid duplication
// APIEndpoint is defined in NetworkService.swift to avoid duplication
// UploadResponse is now defined at the top of the file to avoid duplication

// MARK: - Health API Endpoints

enum HealthAPIEndpoint: APIEndpoint {
    
    case uploadLabReport(Data)
    case getAnalysis(reportId: String)
    case getReports(page: Int, limit: Int)
    case getDashboardData
    case bookAppointment(facilityId: String, date: Date, serviceType: String)
    case getFacilities(location: String, radius: Double)
    case getUserProfile
    case updateProfile(ProfileData)
    
    var path: String {
        switch self {
        case .uploadLabReport:
            return "/api/v1/reports/upload"
        case .getAnalysis(let reportId):
            return "/api/v1/reports/\(reportId)/analysis"
        case .getReports:
            return "/api/v1/reports"
        case .getDashboardData:
            return "/api/v1/dashboard"
        case .bookAppointment:
            return "/api/v1/appointments"
        case .getFacilities:
            return "/api/v1/facilities"
        case .getUserProfile:
            return "/api/v1/user/profile"
        case .updateProfile:
            return "/api/v1/user/profile"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .uploadLabReport, .bookAppointment, .updateProfile:
            return .post
        case .getAnalysis, .getReports, .getDashboardData, .getFacilities, .getUserProfile:
            return .get
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .getReports(let page, let limit):
            return ["page": page, "limit": limit]
        case .bookAppointment(let facilityId, let date, let serviceType):
            return [
                "facilityId": facilityId,
                "date": ISO8601DateFormatter().string(from: date),
                "serviceType": serviceType
            ]
        case .getFacilities(let location, let radius):
            return ["location": location, "radius": radius]
        case .updateProfile(let profileData):
            // Create sendable dictionary manually
            var params: Parameters = [:]
            if let name = profileData.name { params["name"] = name }
            if let email = profileData.email { params["email"] = email }
            if let dateOfBirth = profileData.dateOfBirth { 
                params["dateOfBirth"] = ISO8601DateFormatter().string(from: dateOfBirth)
            }
            if let gender = profileData.gender { params["gender"] = gender }
            if let height = profileData.height { params["height"] = height }
            if let weight = profileData.weight { params["weight"] = weight }
            if let healthGoals = profileData.healthGoals { params["healthGoals"] = healthGoals }
            return params
        default:
            return nil
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .bookAppointment, .updateProfile:
            return JSONEncoding.default
        default:
            return URLEncoding.default
        }
    }
    
    var headers: [String: String]? {
        return nil // Common headers added by interceptor
    }
}

// MARK: - Profile Data Model

struct ProfileData: Codable {
    let name: String?
    let email: String?
    let dateOfBirth: Date?
    let gender: String?
    let height: Double?
    let weight: Double?
    let healthGoals: [String]?
    
    func asDictionary() throws -> [String: Any] {
        var dictionary: [String: Any] = [:]
        
        if let name = name { dictionary["name"] = name }
        if let email = email { dictionary["email"] = email }
        if let dateOfBirth = dateOfBirth { 
            dictionary["dateOfBirth"] = ISO8601DateFormatter().string(from: dateOfBirth)
        }
        if let gender = gender { dictionary["gender"] = gender }
        if let height = height { dictionary["height"] = height }
        if let weight = weight { dictionary["weight"] = weight }
        if let healthGoals = healthGoals { dictionary["healthGoals"] = healthGoals }
        
        return dictionary
    }
}

*/

// APIService temporarily disabled - use AuthenticationAPIService for authentication
// and NativeAuthenticationAPIService for native URLSession implementations