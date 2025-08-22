//
//  AppError.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import Foundation
import Combine

/// Comprehensive error types for the Super One app
enum AppError: LocalizedError, Equatable {
    
    // MARK: - Network Errors
    case networkUnavailable
    case serverError(code: Int)
    case invalidResponse
    case requestTimeout
    case unauthorized
    case forbidden
    case notFound
    case tooManyRequests
    
    // MARK: - Authentication Errors
    case biometricNotAvailable
    case biometricNotEnrolled
    case biometricFailed
    case authenticationFailed
    case tokenExpired
    case accountLocked
    
    // MARK: - Data Errors
    case dataCorruption
    case storageError
    case syncFailed
    case importFailed
    case exportFailed
    case invalidFileFormat
    
    // MARK: - OCR Processing Errors
    case ocrProcessingFailed
    case imageQualityTooLow
    case documentNotSupported
    case extractionFailed
    case noTextFound
    
    // MARK: - Health Data Errors
    case healthKitNotAvailable
    case healthKitPermissionDenied
    case healthKitAuthorizationFailed
    case invalidHealthData
    
    // MARK: - Appointment Errors
    case facilityNotAvailable
    case timeSlotUnavailable
    case bookingFailed
    case cancellationFailed
    
    // MARK: - General Errors
    case unknown(Error)
    case featureNotAvailable
    case maintenanceMode
    case versionNotSupported
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.networkUnavailable, .networkUnavailable),
             (.invalidResponse, .invalidResponse),
             (.requestTimeout, .requestTimeout),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.tooManyRequests, .tooManyRequests),
             (.biometricNotAvailable, .biometricNotAvailable),
             (.biometricNotEnrolled, .biometricNotEnrolled),
             (.biometricFailed, .biometricFailed),
             (.authenticationFailed, .authenticationFailed),
             (.tokenExpired, .tokenExpired),
             (.accountLocked, .accountLocked),
             (.dataCorruption, .dataCorruption),
             (.storageError, .storageError),
             (.syncFailed, .syncFailed),
             (.importFailed, .importFailed),
             (.exportFailed, .exportFailed),
             (.invalidFileFormat, .invalidFileFormat),
             (.ocrProcessingFailed, .ocrProcessingFailed),
             (.imageQualityTooLow, .imageQualityTooLow),
             (.documentNotSupported, .documentNotSupported),
             (.extractionFailed, .extractionFailed),
             (.noTextFound, .noTextFound),
             (.healthKitNotAvailable, .healthKitNotAvailable),
             (.healthKitPermissionDenied, .healthKitPermissionDenied),
             (.healthKitAuthorizationFailed, .healthKitAuthorizationFailed),
             (.invalidHealthData, .invalidHealthData),
             (.facilityNotAvailable, .facilityNotAvailable),
             (.timeSlotUnavailable, .timeSlotUnavailable),
             (.bookingFailed, .bookingFailed),
             (.cancellationFailed, .cancellationFailed),
             (.featureNotAvailable, .featureNotAvailable),
             (.maintenanceMode, .maintenanceMode),
             (.versionNotSupported, .versionNotSupported):
            return true
        case let (.serverError(lhsCode), .serverError(rhsCode)):
            return lhsCode == rhsCode
        case let (.unknown(lhsError), .unknown(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
    
    // MARK: - Error Descriptions
    
    nonisolated var errorDescription: String? {
        switch self {
        // Network Errors
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .serverError(let code):
            return "Server error occurred (Code: \(code)). Please try again later."
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .requestTimeout:
            return "Request timed out. Please check your connection and try again."
        case .unauthorized:
            return "You are not authorized to perform this action. Please log in again."
        case .forbidden:
            return "Access denied. You don't have permission for this action."
        case .notFound:
            return "The requested resource was not found."
        case .tooManyRequests:
            return "Too many requests. Please wait a moment before trying again."
            
        // Authentication Errors
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometricNotEnrolled:
            return "No biometric data enrolled. Please set up Face ID or Touch ID in Settings."
        case .biometricFailed:
            return "Biometric authentication failed. Please try again or use your passcode."
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials and try again."
        case .tokenExpired:
            return "Your session has expired. Please log in again."
        case .accountLocked:
            return "Your account has been temporarily locked for security reasons."
            
        // Data Errors
        case .dataCorruption:
            return "Data corruption detected. Please restart the app or contact support."
        case .storageError:
            return "Unable to save data. Please check available storage space."
        case .syncFailed:
            return "Failed to sync data. Please check your connection and try again."
        case .importFailed:
            return "Failed to import data. Please check the file format and try again."
        case .exportFailed:
            return "Failed to export data. Please try again or contact support."
        case .invalidFileFormat:
            return "Invalid file format. Please select a supported file type."
            
        // OCR Processing Errors
        case .ocrProcessingFailed:
            return "Failed to process document. Please try with a clearer image."
        case .imageQualityTooLow:
            return "Image quality is too low. Please take a clearer photo."
        case .documentNotSupported:
            return "Document type not supported. Please try with a lab report."
        case .extractionFailed:
            return "Failed to extract data from document. Please verify it's a lab report."
        case .noTextFound:
            return "No text found in document. Please ensure the image is clear and readable."
            
        // Health Data Errors
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device."
        case .healthKitPermissionDenied:
            return "Health data access denied. Please enable permissions in Settings."
        case .healthKitAuthorizationFailed:
            return "Failed to authorize HealthKit access. Please try again."
        case .invalidHealthData:
            return "Invalid health data detected. Please verify your data."
            
        // Appointment Errors
        case .facilityNotAvailable:
            return "Selected facility is currently unavailable. Please choose another."
        case .timeSlotUnavailable:
            return "Selected time slot is no longer available. Please choose another time."
        case .bookingFailed:
            return "Failed to book appointment. Please try again or contact the facility."
        case .cancellationFailed:
            return "Failed to cancel appointment. Please contact the facility directly."
            
        // General Errors
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        case .featureNotAvailable:
            return "This feature is not available yet. Please check for app updates."
        case .maintenanceMode:
            return "The app is currently under maintenance. Please try again later."
        case .versionNotSupported:
            return "This app version is no longer supported. Please update to the latest version."
        }
    }
    
    // MARK: - Recovery Suggestions
    
    nonisolated var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your Wi-Fi or cellular connection and try again."
        case .serverError:
            return "Wait a few minutes and try again. If the problem persists, contact support."
        case .biometricNotEnrolled:
            return "Go to Settings > Face ID & Passcode to set up biometric authentication."
        case .healthKitPermissionDenied:
            return "Go to Settings > Health > Data Access & Devices > Super One to enable permissions."
        case .imageQualityTooLow:
            return "Ensure good lighting and hold the camera steady when taking photos."
        case .tokenExpired:
            return "Log out and log back in to refresh your session."
        case .versionNotSupported:
            return "Visit the App Store to download the latest version."
        default:
            return "Try again or contact support if the problem persists."
        }
    }
    
    // MARK: - Error Categories
    
    nonisolated var category: ErrorCategory {
        switch self {
        case .networkUnavailable, .serverError, .invalidResponse, .requestTimeout, .tooManyRequests:
            return .network
        case .biometricNotAvailable, .biometricNotEnrolled, .biometricFailed, .authenticationFailed, .tokenExpired, .accountLocked, .unauthorized, .forbidden:
            return .authentication
        case .dataCorruption, .storageError, .syncFailed, .importFailed, .exportFailed, .invalidFileFormat:
            return .data
        case .ocrProcessingFailed, .imageQualityTooLow, .documentNotSupported, .extractionFailed, .noTextFound:
            return .processing
        case .healthKitNotAvailable, .healthKitPermissionDenied, .healthKitAuthorizationFailed, .invalidHealthData:
            return .health
        case .facilityNotAvailable, .timeSlotUnavailable, .bookingFailed, .cancellationFailed:
            return .appointment
        case .unknown, .featureNotAvailable, .maintenanceMode, .versionNotSupported, .notFound:
            return .general
        }
    }
    
    // MARK: - User Action Required
    
    nonisolated var requiresUserAction: Bool {
        switch self {
        case .biometricNotEnrolled, .healthKitPermissionDenied, .tokenExpired, .versionNotSupported, .accountLocked:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Retry Availability
    
    nonisolated var canRetry: Bool {
        switch self {
        case .networkUnavailable, .serverError, .requestTimeout, .ocrProcessingFailed, .syncFailed, .bookingFailed:
            return true
        case .biometricNotEnrolled, .healthKitPermissionDenied, .versionNotSupported, .accountLocked, .invalidFileFormat:
            return false
        default:
            return true
        }
    }
}

// MARK: - Error Category

enum ErrorCategory {
    case network
    case authentication
    case data
    case processing
    case health
    case appointment
    case general
    
    nonisolated var icon: String {
        switch self {
        case .network:
            return "wifi.exclamationmark"
        case .authentication:
            return "person.badge.shield.checkmark.fill"
        case .data:
            return "externaldrive.badge.exclamationmark"
        case .processing:
            return "doc.text.magnifyingglass"
        case .health:
            return "heart.text.square"
        case .appointment:
            return "calendar.badge.exclamationmark"
        case .general:
            return "exclamationmark.triangle"
        }
    }
    
    nonisolated var color: String {
        switch self {
        case .network:
            return "HealthColors.healthWarning"
        case .authentication:
            return "HealthColors.healthCritical"
        case .data:
            return "HealthColors.healthWarning"
        case .processing:
            return "HealthColors.primary"
        case .health:
            return "HealthColors.healthGood"
        case .appointment:
            return "HealthColors.primary"
        case .general:
            return "HealthColors.secondaryText"
        }
    }
}