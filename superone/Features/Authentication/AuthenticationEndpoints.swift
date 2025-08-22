import Foundation

// MARK: - Native HTTP Method Enum

enum NativeHTTPMethod: String, Sendable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Simplified Native Authentication Endpoints

/// Simplified native authentication endpoints (no protocol conformance needed)
struct AuthenticationEndpoints {
    
    // MARK: - Base Configuration
    
    static let baseURL = APIConfiguration.baseURL
    
    // MARK: - Endpoint Paths (using APIConfiguration)
    
    static let login = APIConfiguration.Endpoints.Auth.login
    static let register = APIConfiguration.Endpoints.Auth.register
    static let refresh = APIConfiguration.Endpoints.Auth.refresh
    static let logout = APIConfiguration.Endpoints.Auth.logout
    static let forgotPassword = APIConfiguration.Endpoints.Auth.forgotPassword
    static let validateToken = APIConfiguration.Endpoints.Auth.validate
    static let changePassword = APIConfiguration.Endpoints.Auth.changePassword
    static let device = APIConfiguration.Endpoints.Auth.device
    
    // MARK: - User Profile Endpoints (using APIConfiguration)
    
    static let currentUser = APIConfiguration.Endpoints.Mobile.currentUser
    static let userProfile = APIConfiguration.Endpoints.Mobile.profile
    static let userDevices = APIConfiguration.Endpoints.Mobile.userDevices
    
    // MARK: - Mobile Specific Endpoints (using APIConfiguration)
    
    static let mobileDashboard = APIConfiguration.Endpoints.Mobile.dashboardOverview
    
    // MARK: - Helper Methods
    
    /// Build full URL for authentication endpoint
    static func fullURL(for endpoint: String) -> String {
        return APIConfiguration.mobileURL(for: endpoint)
    }
    
    /// Build full URL with parameters
    static func fullURL(for endpoint: String, parameters: [String: String]) -> String {
        var urlString = APIConfiguration.mobileURL(for: endpoint)
        
        if !parameters.isEmpty {
            let queryItems = parameters.map { "\($0.key)=\($0.value)" }
            urlString += "?" + queryItems.joined(separator: "&")
        }
        
        return urlString
    }
}

// MARK: - Request Models

// LoginRequest and RegistrationRequest are already defined in BackendModels.swift and NetworkModels.swift