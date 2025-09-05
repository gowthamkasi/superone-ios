//
//  APIConfiguration.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//

import Foundation
import UIKit

/// API configuration for Super One backend integration
struct APIConfiguration {
    
    // MARK: - Environment Configuration
    
    enum Environment {
        case development
        case staging
        case production
        case localTest  // For testing without backend
        
        var baseURL: String {
            switch self {
            case .development:
                return "https://7cf3d2e510e2.ngrok-free.app"
            case .staging:
                return "https://staging-api.superonehealth.com"  
            case .production:
                return "https://api.superonehealth.com"
            case .localTest:
                return "https://7cf3d2e510e2.ngrok-free.app"  // This will timeout and trigger mock response
            }
        }
    }
    
    // MARK: - Current Environment
    
    #if DEBUG
    static let currentEnvironment: Environment = .development  // Use live backend
    #else
    static let currentEnvironment: Environment = .production
    #endif
    
    // MARK: - LabLoop Integration Configuration
    
    enum LabLoopEnvironment {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "https://7cf3d2e510e2.ngrok-free.app"  // LabLoop development server
            case .staging:
                return "https://staging.labloop.health"
            case .production:
                return "https://labloop.health"
            }
        }
    }
    
    #if DEBUG
    static let labLoopEnvironment: LabLoopEnvironment = .development
    #else
    static let labLoopEnvironment: LabLoopEnvironment = .production
    #endif
    
    static let labLoopBaseURL = labLoopEnvironment.baseURL
    
    // MARK: - Base Configuration
    
    static let baseURL = currentEnvironment.baseURL
    static let apiVersion = "/api"
    static let timeout: TimeInterval = 30.0
    static let cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    // MARK: - Full URLs
    
    static var fullBaseURL: String {
        return baseURL + apiVersion
    }
    
    // MARK: - API Endpoints
    
    struct Endpoints {
        
        // MARK: - Authentication
        struct Auth {
            static let register = "/mobile/auth/register"
            static let login = "/mobile/auth/login"
            static let refresh = "/mobile/auth/refresh"
            static let logout = "/mobile/auth/logout"
            static let forgotPassword = "/mobile/auth/forgot-password"
            static let validate = "/mobile/auth/validate"
            static let device = "/mobile/auth/device"
            static let changePassword = "/mobile/auth/change-password"
        }
        
        // MARK: - Mobile Endpoints
        struct Mobile {
            // Dashboard
            static let dashboardOverview = "/mobile/dashboard/overview"
            static let dashboardHealthScore = "/mobile/dashboard/health-score"
            static let dashboardStats = "/mobile/dashboard/stats"
            
            // Health Categories
            static let healthCategoriesSlider = "/mobile/health-categories/slider"
            static let healthCategoriesDetail = "/mobile/health-categories"
            static let healthCategoriesTrend = "/mobile/health-categories/trends"
            
            // Processing
            static let processingStatus = "/mobile/processing"
            
            // Appointments
            static let appointments = "/mobile/appointments"
            
            // Notifications
            static let notifications = "/mobile/notifications"
            
            // Profile  
            static let profile = "/mobile/users/profile"
            static let currentUser = "/mobile/users/me" 
            static let userDevices = "/mobile/users/devices"
            
            // Analytics
            static let analytics = "/mobile/analytics"
            
            // Reports
            static let reports = "/mobile/reports"
            
            // Recommendations
            static let recommendationsList = "/mobile/recommendations/list"
            static let recommendationsSmart = "/mobile/recommendations/smart"
            static let recommendationsAcknowledge = "/mobile/recommendations/acknowledge"
            static let recommendationsStats = "/mobile/recommendations/stats"
            static let recommendationsInsights = "/mobile/recommendations/insights"
        }
        
        // MARK: - LabLoop Integration Endpoints
        struct LabLoop {
            // Facility Discovery
            static let facilities = "/mobile/facilities"
            static let facilityDetails = "/mobile/facilities" // + "/{id}"
            static let timeslots = "/mobile/timeslots" // + "/{facilityId}"
            
            // Tests and Health Packages
            static let tests = "/mobile/tests"
            static let testDetails = "/mobile/tests" // + "/{testId}"
            static let packages = "/mobile/packages"
            static let packageDetails = "/mobile/packages" // + "/{packageId}"
            static let favorites = "/mobile/favorites/tests"
            static let searchSuggestions = "/mobile/tests/search/suggestions"
            
            // Appointment Management
            static let appointments = "/mobile/appointments"
            static let bookAppointment = "/mobile/appointments"
        }
        
        // MARK: - Upload
        struct Upload {
            static let labReport = "/mobile/upload/lab-report"
            static let labReportsBatch = "/mobile/upload/lab-reports/batch"
            static let uploadStatus = "/mobile/upload/status"
            static let uploadHistory = "/mobile/upload/history"
            static let uploadStatistics = "/mobile/upload/statistics"
            static let downloadFile = "/mobile/upload/download"
            static let deleteUpload = "/mobile/upload"
        }
        
        // MARK: - Health Analysis
        struct HealthAnalysis {
            static let generate = "/mobile/health-analysis/generate"
            static let getAnalysis = "/mobile/health-analysis"
            static let history = "/mobile/health-analysis/history"
            static let latest = "/mobile/health-analysis/latest"
            static let personalize = "/mobile/health-analysis"
            static let stats = "/mobile/health-analysis/stats"
            static let compare = "/mobile/health-analysis/compare"
        }
        
        // MARK: - Health Data
        struct Health {
            static let categories = "/mobile/health/categories"
            static let tests = "/mobile/health/tests"
            static let trends = "/mobile/health/trends"
        }
        
        // MARK: - Export
        struct Export {
            static let userData = "/mobile/export/user-data"
            static let healthReports = "/mobile/export/health-reports"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Build full URL for general API endpoint
    static func url(for endpoint: String) -> String {
        return fullBaseURL + endpoint
    }
    
    /// Build full URL for mobile-specific endpoint
    static func mobileURL(for endpoint: String) -> String {
        return fullBaseURL + endpoint
    }
    
    /// Build URL with user ID parameter
    static func mobileURL(for endpoint: String, userId: String) -> String {
        return fullBaseURL + endpoint + "/\(userId)"
    }
    
    /// Build URL with parameters
    static func url(for endpoint: String, parameters: [String: String]) -> String {
        var urlString = fullBaseURL + endpoint
        
        if !parameters.isEmpty {
            let queryItems = parameters.map { "\($0.key)=\($0.value)" }
            urlString += "?" + queryItems.joined(separator: "&")
        }
        
        return urlString
    }
    
    // MARK: - LabLoop Helper Methods
    
    /// Build full URL for LabLoop API endpoint
    static func labLoopURL(for endpoint: String) -> String {
        return labLoopBaseURL + apiVersion + endpoint
    }
    
    /// Build URL with path parameters for LabLoop API
    static func labLoopURL(for endpoint: String, pathParameters: [String: String]) -> String {
        var urlString = labLoopBaseURL + apiVersion + endpoint
        
        // Replace path parameters like {id}
        for (key, value) in pathParameters {
            urlString = urlString.replacingOccurrences(of: "{\(key)}", with: value)
        }
        
        return urlString
    }
    
    /// Build LabLoop URL with query parameters
    static func labLoopURL(for endpoint: String, queryParameters: [String: String]) -> String {
        var urlString = labLoopBaseURL + apiVersion + endpoint
        
        if !queryParameters.isEmpty {
            let queryItems = queryParameters.map { "\($0.key)=\($0.value)" }
            urlString += "?" + queryItems.joined(separator: "&")
        }
        
        return urlString
    }
    
    /// Build LabLoop URL for test details endpoint
    static func labLoopTestDetailsURL(testId: String) -> String {
        return labLoopBaseURL + apiVersion + "/mobile/tests/\(testId)"
    }
}

// MARK: - API Headers Configuration

extension APIConfiguration {
    
    struct Headers {
        static let contentType = "application/json"
        static let accept = "application/json"
        static let authorization = "Authorization"
        static let bearerPrefix = "Bearer "
        static let userAgent = "SuperOne-iOS/1.0.0"
        static let platform = "iOS"
        static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        /// Standard headers for API requests
        static var standard: [String: String] {
            var headers = [
                "Content-Type": contentType,
                "Accept": accept,
                "User-Agent": userAgent,
                "X-Platform": platform,
                "X-App-Version": appVersion,
                "X-Build-Number": buildNumber,
                "ngrok-skip-browser-warning": "true"
            ]
            
            // Add device ID header for all mobile requests
            if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
                headers["x-device-id"] = deviceId
            } else {
                headers["x-device-id"] = "unknown"
            }
            
            return headers
        }
        
        /// Headers with authentication token
        static func authenticated(token: String) -> [String: String] {
            var headers = standard
            headers[authorization] = bearerPrefix + token
            return headers
        }
        
        /// Headers for multipart form data uploads
        static var multipartFormData: [String: String] {
            var headers = standard
            headers["Content-Type"] = "multipart/form-data"
            return headers
        }
    }
}

// MARK: - API Response Configuration

extension APIConfiguration {
    
    struct Response {
        static let successStatusCodes = 200...299
        static let authenticationRequiredStatusCodes = [401, 403]
        static let serverErrorStatusCodes = 500...599
        static let retryableStatusCodes = [408, 429, 502, 503, 504]
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 1.0
    }
}

// MARK: - Logging Configuration

extension APIConfiguration {
    
    struct Logging {
        #if DEBUG
        static let enabled = true
        static let logLevel: LogLevel = .verbose
        #else
        static let enabled = false
        static let logLevel: LogLevel = .error
        #endif
        
        enum LogLevel {
            case verbose  // All requests and responses
            case info     // Basic request info
            case error    // Only errors
            case none     // No logging
        }
    }
}

// MARK: - Cache Configuration

extension APIConfiguration {
    
    struct Cache {
        static let enabled = true
        static let maxSize: Int = 50 * 1024 * 1024 // 50MB
        static let defaultExpiration: TimeInterval = 300 // 5 minutes
        
        struct Expiration {
            static let userProfile: TimeInterval = 3600 // 1 hour
            static let healthScore: TimeInterval = 1800 // 30 minutes
            static let recommendations: TimeInterval = 3600 // 1 hour
            static let healthCategories: TimeInterval = 1800 // 30 minutes
            static let uploadHistory: TimeInterval = 300 // 5 minutes
        }
    }
}
