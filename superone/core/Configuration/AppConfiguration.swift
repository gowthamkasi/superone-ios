//
//  AppConfiguration.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import Foundation
import Combine
import UIKit

/// App configuration management for different environments
struct AppConfiguration {
    
    // MARK: - Current Configuration
    
    static let current: AppConfiguration = {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }()
    
    /// Base URL as string for backward compatibility
    static var baseURL: String {
        return current.apiBaseURL.absoluteString
    }
    
    // MARK: - Environment Configurations
    
    static let development = AppConfiguration(
        environment: .development,
        apiBaseURL: URL(string: "https://7cf3d2e510e2.ngrok-free.app")!,
        wsBaseURL: URL(string: "ws://55922b22d8d8.ngrok-free.app")!,
        enableLogging: true,
        enableAnalytics: false,
        enableCrashReporting: false,
        maxRetryAttempts: 3,
        requestTimeout: 30,
        features: FeatureFlags(
            aiAnalysis: true,         // Enable AI analysis for backend OCR integration
            pushNotifications: false,
            biometricAuth: true,
            healthKitSync: true,
            appointmentBooking: false, // Use mock data
            dataExport: true,
            offlineMode: true,
            ocrUpload: false,         // Enable for testing
            locationServices: true    // Enable location services for lab discovery
        )
    )
    
    static let staging = AppConfiguration(
        environment: .staging,
        apiBaseURL: URL(string: "https://staging-api.superonehealth.com")!,
        wsBaseURL: URL(string: "wss://staging-api.superonehealth.com")!,
        enableLogging: true,
        enableAnalytics: true,
        enableCrashReporting: true,
        maxRetryAttempts: 3,
        requestTimeout: 30,
        features: FeatureFlags(
            aiAnalysis: true,
            pushNotifications: true,
            biometricAuth: true,
            healthKitSync: true,
            appointmentBooking: true,
            dataExport: true,
            offlineMode: true,
            ocrUpload: false,         // Enable for QA testing
            locationServices: true    // Enable location services
        )
    )
    
    static let production = AppConfiguration(
        environment: .production,
        apiBaseURL: URL(string: "https://api.superonehealth.com")!,
        wsBaseURL: URL(string: "wss://api.superonehealth.com")!,
        enableLogging: false,
        enableAnalytics: true,
        enableCrashReporting: true,
        maxRetryAttempts: 5,
        requestTimeout: 60,
        features: FeatureFlags(
            aiAnalysis: true,
            pushNotifications: true,
            biometricAuth: true,
            healthKitSync: true,
            appointmentBooking: true,
            dataExport: true,
            offlineMode: true,
            ocrUpload: false,         // Disable in production initially
            locationServices: true    // Enable location services
        )
    )
    
    // MARK: - Properties
    
    let environment: Environment
    let apiBaseURL: URL
    let wsBaseURL: URL
    let enableLogging: Bool
    let enableAnalytics: Bool
    let enableCrashReporting: Bool
    let maxRetryAttempts: Int
    let requestTimeout: TimeInterval
    let features: FeatureFlags
    
    // MARK: - Environment Type
    
    enum Environment: String, CaseIterable {
        case development = "Development"
        case staging = "Staging"
        case production = "Production"
        
        var isDevelopment: Bool {
            return self == .development
        }
        
        var isProduction: Bool {
            return self == .production
        }
    }
    
    // MARK: - Feature Flags
    
    struct FeatureFlags {
        let aiAnalysis: Bool
        let pushNotifications: Bool
        let biometricAuth: Bool
        let healthKitSync: Bool
        let appointmentBooking: Bool
        let dataExport: Bool
        let offlineMode: Bool
        let ocrUpload: Bool
        let locationServices: Bool
        
        // Runtime feature flag checking
        func isEnabled(_ feature: Feature) -> Bool {
            switch feature {
            case .aiAnalysis:
                return aiAnalysis
            case .pushNotifications:
                return pushNotifications
            case .biometricAuth:
                return biometricAuth
            case .healthKitSync:
                return healthKitSync
            case .appointmentBooking:
                return appointmentBooking
            case .dataExport:
                return dataExport
            case .offlineMode:
                return offlineMode
            case .ocrUpload:
                return ocrUpload
            case .locationServices:
                return locationServices
            }
        }
    }
    
    enum Feature {
        case aiAnalysis
        case pushNotifications
        case biometricAuth
        case healthKitSync
        case appointmentBooking
        case dataExport
        case offlineMode
        case ocrUpload
        case locationServices
    }
    
    // MARK: - App Information
    
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.superone.health"
    }
    
    var displayName: String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Super One"
    }
    
    // MARK: - Device Information
    
    var deviceModel: String {
        return UIDevice.current.model
    }
    
    var systemVersion: String {
        return UIDevice.current.systemVersion
    }
    
    var deviceIdentifier: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
    
    // MARK: - Security Configuration
    
    var certificatePinning: Bool {
        return environment.isProduction
    }
    
    var allowSelfSignedCertificates: Bool {
        return environment.isDevelopment
    }
    
    var encryptionRequired: Bool {
        return true // Always require encryption
    }
    
    // MARK: - Cache Configuration
    
    var cacheMaxSize: Int {
        switch environment {
        case .development:
            return 50 * 1024 * 1024  // 50MB
        case .staging:
            return 100 * 1024 * 1024 // 100MB
        case .production:
            return 200 * 1024 * 1024 // 200MB
        }
    }
    
    var cacheExpiration: TimeInterval {
        return 24 * 60 * 60 // 24 hours
    }
    
    // MARK: - Analytics Configuration
    
    var analyticsConfiguration: AnalyticsConfiguration {
        return AnalyticsConfiguration(
            enabled: enableAnalytics,
            sessionTimeout: 30 * 60, // 30 minutes
            batchSize: environment.isDevelopment ? 1 : 50,
            flushInterval: environment.isDevelopment ? 5 : 60 // seconds
        )
    }
    
    struct AnalyticsConfiguration {
        let enabled: Bool
        let sessionTimeout: TimeInterval
        let batchSize: Int
        let flushInterval: TimeInterval
    }
    
    // MARK: - Debug Information
    
    var debugDescription: String {
        return """
        Environment: \(environment.rawValue)
        API Base URL: \(apiBaseURL.absoluteString)
        App Version: \(appVersion) (\(buildNumber))
        Device: \(deviceModel) iOS \(systemVersion)
        Features: AI=\(features.aiAnalysis), Biometric=\(features.biometricAuth), HealthKit=\(features.healthKitSync), Location=\(features.locationServices)
        """
    }
}

// MARK: - Configuration Extensions

extension AppConfiguration {
    
    /// Check if a specific feature is enabled
    func isFeatureEnabled(_ feature: Feature) -> Bool {
        return features.isEnabled(feature)
    }
    
    /// Get API endpoint URL for a specific path
    func apiURL(for path: String) -> URL {
        return apiBaseURL.appendingPathComponent(path)
    }
    
    /// Get WebSocket URL for a specific path
    func wsURL(for path: String) -> URL {
        return wsBaseURL.appendingPathComponent(path)
    }
    
    /// Get configuration value for key with fallback
    func value<T>(for key: String, fallback: T) -> T {
        if let value = Bundle.main.infoDictionary?[key] as? T {
            return value
        }
        return fallback
    }
}

// MARK: - Runtime Configuration

class RuntimeConfiguration: ObservableObject {
    @Published var currentConfig: AppConfiguration
    
    init() {
        self.currentConfig = AppConfiguration.current
    }
    
    /// Update configuration at runtime (for testing/debugging)
    func updateConfiguration(_ config: AppConfiguration) {
        self.currentConfig = config
    }
    
    /// Toggle feature flag at runtime (development only)
    func toggleFeature(_ feature: AppConfiguration.Feature) {
        guard currentConfig.environment.isDevelopment else { return }
        
        // Create new feature flags with toggled feature
        var newFeatures = currentConfig.features
        
        switch feature {
        case .aiAnalysis:
            newFeatures = AppConfiguration.FeatureFlags(
                aiAnalysis: !newFeatures.aiAnalysis,
                pushNotifications: newFeatures.pushNotifications,
                biometricAuth: newFeatures.biometricAuth,
                healthKitSync: newFeatures.healthKitSync,
                appointmentBooking: newFeatures.appointmentBooking,
                dataExport: newFeatures.dataExport,
                offlineMode: newFeatures.offlineMode,
                ocrUpload: newFeatures.ocrUpload,
                locationServices: newFeatures.locationServices
            )
        case .pushNotifications:
            newFeatures = AppConfiguration.FeatureFlags(
                aiAnalysis: newFeatures.aiAnalysis,
                pushNotifications: !newFeatures.pushNotifications,
                biometricAuth: newFeatures.biometricAuth,
                healthKitSync: newFeatures.healthKitSync,
                appointmentBooking: newFeatures.appointmentBooking,
                dataExport: newFeatures.dataExport,
                offlineMode: newFeatures.offlineMode,
                ocrUpload: newFeatures.ocrUpload,
                locationServices: newFeatures.locationServices
            )
        // Add other cases as needed
        default:
            break
        }
        
        // Update configuration with new features
        let newConfig = AppConfiguration(
            environment: currentConfig.environment,
            apiBaseURL: currentConfig.apiBaseURL,
            wsBaseURL: currentConfig.wsBaseURL,
            enableLogging: currentConfig.enableLogging,
            enableAnalytics: currentConfig.enableAnalytics,
            enableCrashReporting: currentConfig.enableCrashReporting,
            maxRetryAttempts: currentConfig.maxRetryAttempts,
            requestTimeout: currentConfig.requestTimeout,
            features: newFeatures
        )
        
        updateConfiguration(newConfig)
    }
}

// MARK: - App Config Constants

extension AppConfiguration {
    
    /// Bundle identifier for the app
    nonisolated static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.superone.health"
    }
    
    /// App version string
    nonisolated static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Debug flag
    nonisolated static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - AppConfig Compatibility Structure

/// Compatibility structure for AppConfig references
struct AppConfig {
    /// API Configuration
    struct API {
        nonisolated static let baseURL = "https://api.superonehealth.com"
        nonisolated static let timeout: TimeInterval = 30.0
        nonisolated static let apiVersion = "v1"
        
        struct Endpoints {
            nonisolated static let auth = "/auth"
            nonisolated static let users = "/users"
            
            struct Mobile {
                nonisolated static let dashboard = "/mobile/dashboard"
                nonisolated static let profile = "/mobile/profile"
            }
        }
    }
    
    /// App Information
    nonisolated static let appName = "Super One"
    nonisolated static let appVersion = "1.0.0"
    
    /// Error Handling Configuration
    struct ErrorHandling {
        nonisolated static let maxRetryAttempts = 3
        nonisolated static let retryDelay = 2.0
        nonisolated static let exponentialBackoffMultiplier = 2.0
    }
    
    /// Security configuration
    struct Security {
        nonisolated static let tokenExpirationBuffer: TimeInterval = 300 // 5 minutes
        nonisolated static let maxLoginAttempts = 5
        nonisolated static let lockoutDuration: TimeInterval = 900 // 15 minutes
    }
    
    /// Keychain configuration keys  
    struct KeychainKeys {
        nonisolated static let authToken = "auth_token"
        nonisolated static let refreshToken = "refresh_token"
        nonisolated static let userCredentials = "user_credentials"
        nonisolated static let biometricData = "biometric_data"
        nonisolated static let encryptionKey = "encryption_key"
        nonisolated static let userSettings = "user_settings"
        nonisolated static let healthData = "health_data"
        nonisolated static let sessionData = "session_data"
        nonisolated static let biometricEnabled = "biometric_enabled"
    }
}

// MARK: - Additional Configuration Extensions

extension AppConfiguration {
    struct UserDefaultsKeys {
        static let onboardingComplete = "onboarding_complete"
        static let biometricAuthEnabled = "biometric_auth_enabled"
        static let healthKitPermissionGranted = "healthkit_permission_granted"
        static let selectedHealthGoals = "selected_health_goals"
        static let notificationPreferences = "notification_preferences"
        static let lastSyncDate = "last_sync_date"
        static let appLaunchCount = "app_launch_count"
        static let privacyPolicyAccepted = "privacy_policy_accepted"
    }
    
    struct NotificationIdentifiers {
        static let healthAlert = "health_alert"
        static let appointmentReminder = "appointment_reminder"
        static let reportReady = "report_ready"
        static let recommendation = "recommendation"
    }
}
