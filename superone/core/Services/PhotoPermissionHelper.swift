//
//  PhotoPermissionHelper.swift
//  SuperOne
//
//  Created by Claude Code on 8/3/25.
//  Utility for managing photo library permissions across the app

import Foundation
import Photos
import UIKit
import Combine

/// Helper class for managing photo library permissions with user-friendly messages
@MainActor
class PhotoPermissionHelper: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = PhotoPermissionHelper()
    
    private init() {}
    
    // MARK: - Published Properties
    
    @Published var currentStatus: PHAuthorizationStatus = .notDetermined
    @Published var isMonitoring: Bool = false
    
    // MARK: - Private Properties
    
    private nonisolated(unsafe) var notificationObserver: NSObjectProtocol?
    
    // MARK: - Permission Status Checking
    
    /// Get current photo library authorization status
    func getCurrentStatus() -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        currentStatus = status
        return status
    }
    
    /// Check if we have sufficient permissions for photo library access
    func hasPhotoLibraryAccess() -> Bool {
        let status = getCurrentStatus()
        return status == .authorized || status == .limited
    }
    
    /// Request photo library permission with proper error handling
    func requestPhotoLibraryPermission() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            currentStatus = status
        }
        return status
    }
    
    // MARK: - User-Friendly Messages
    
    /// Get user-friendly status description
    func getStatusDescription(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Full photo library access granted"
        case .limited:
            return "Limited photo access granted"
        case .denied:
            return "Photo library access denied"
        case .restricted:
            return "Photo library access restricted by device policies"
        case .notDetermined:
            return "Photo library permission not yet requested"
        @unknown default:
            return "Unknown photo library permission status"
        }
    }
    
    /// Get actionable message for user when permissions are needed
    func getActionableMessage(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized, .limited:
            return "You can now select photos from your library to upload lab reports."
            
        case .denied:
            return "To upload photos from your library, please enable photo access in Settings → Privacy & Security → Photos → SuperOne Health."
            
        case .restricted:
            return "Photo library access is restricted on this device. You may need to contact your device administrator."
            
        case .notDetermined:
            return "SuperOne Health needs access to your photo library to upload lab reports. Tap 'Allow Access' to continue."
            
        @unknown default:
            return "There was an issue with photo library permissions. Please try again or contact support."
        }
    }
    
    /// Get the appropriate call-to-action button title
    func getActionButtonTitle(_ status: PHAuthorizationStatus) -> String? {
        switch status {
        case .authorized, .limited:
            return nil // No action needed
            
        case .denied, .restricted:
            return "Open Settings"
            
        case .notDetermined:
            return "Allow Access"
            
        @unknown default:
            return "Try Again"
        }
    }
    
    // MARK: - Action Handlers
    
    /// Handle the action when user taps the action button
    func handlePermissionAction(_ status: PHAuthorizationStatus) async -> Bool {
        switch status {
        case .authorized, .limited:
            return true // Already have access
            
        case .denied, .restricted:
            // Open app settings
            await openAppSettings()
            return false // User needs to manually enable
            
        case .notDetermined:
            // Request permission
            let newStatus = await requestPhotoLibraryPermission()
            return newStatus == .authorized || newStatus == .limited
            
        @unknown default:
            return false
        }
    }
    
    /// Open the app's settings page
    private func openAppSettings() async {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            await UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - Permission Monitoring
    
    /// Start monitoring photo library permission changes
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Initial status check
        _ = getCurrentStatus()
        
        // Monitor status changes (check every time app becomes active)
        notificationObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshStatus()
            }
        }
    }
    
    /// Stop monitoring permission changes
    func stopMonitoring() {
        isMonitoring = false
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
    }
    
    /// Refresh the current permission status
    private func refreshStatus() {
        let newStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if newStatus != currentStatus {
            currentStatus = newStatus
        }
    }
    
    deinit {
        // Clean up notification observer without accessing main actor properties
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Permission Error Types

/// Errors that can occur during photo permission handling
enum PhotoPermissionError: LocalizedError {
    case permissionDenied
    case permissionRestricted
    case unknownStatus
    case settingsUnavailable
    
    nonisolated var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photo library access was denied"
        case .permissionRestricted:
            return "Photo library access is restricted"
        case .unknownStatus:
            return "Unknown permission status"
        case .settingsUnavailable:
            return "Cannot open settings"
        }
    }
    
    nonisolated var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Enable photo access in Settings → Privacy & Security → Photos"
        case .permissionRestricted:
            return "Contact your device administrator to enable photo access"
        case .unknownStatus:
            return "Restart the app and try again"
        case .settingsUnavailable:
            return "Manually open Settings and navigate to Privacy → Photos"
        }
    }
}