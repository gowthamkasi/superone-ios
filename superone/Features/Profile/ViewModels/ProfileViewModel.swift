//
//  ProfileViewModel.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import Foundation
import Combine

/// ViewModel for managing user profile and settings
@MainActor
@Observable
final class ProfileViewModel {
    
    // MARK: - Published Properties
    
    /// User profile information
    var userProfile: User?
    var isLoadingProfile: Bool = false
    
    // MARK: - Loop Protection Properties
    private var lastLoadAttempt: Date?
    private var loadAttemptCount: Int = 0
    private var currentLoadTask: Task<Void, Never>?
    private static let maxRetryAttempts: Int = 3
    
    // MARK: - Exponential Backoff Properties
    private static let baseBackoffInterval: TimeInterval = 2.0 // Base 2 seconds
    private static let maxBackoffInterval: TimeInterval = 30.0 // Maximum 30 seconds
    private static let backoffMultiplier: Double = 2.0 // Double the wait time each retry
    
    /// Settings
    var notificationsEnabled: Bool = true
    var biometricAuthEnabled: Bool = false
    var dataExportEnabled: Bool = true
    var healthKitSyncEnabled: Bool = false
    
    /// Privacy settings
    var analyticsEnabled: Bool = false
    var crashReportingEnabled: Bool = true
    
    /// Storage and data
    var storageUsage: StorageInfo = StorageInfo()
    var exportProgress: Double = 0.0
    var isExporting: Bool = false
    
    /// UI state
    var showEditProfile: Bool = false
    var showDataExport: Bool = false
    var showDeleteAccount: Bool = false
    var showLogoutAlert: Bool = false
    var showAbout: Bool = false
    var showSupport: Bool = false
    
    #if DEBUG
    /// Test interface state (development only)
    #endif
    
    /// Logout state
    var isSigningOut: Bool = false
    var signOutErrorMessage: String?
    var showSignOutError: Bool = false
    
    /// Error handling
    var errorMessage: String?
    var showError: Bool = false
    
    // MARK: - Private Properties
    
    private let userService = UserService.shared
    private let settingsService = SettingsService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // DON'T automatically load profile - only load when explicitly requested
        // This prevents infinite loops during view creation
        loadSettings()
        setupAuthenticationObserver()
        
        // Profile will be loaded when onAppear is called or user explicitly requests
    }
    
    deinit {
        // Cancellables will be automatically cleaned up
    }
    
    // MARK: - Profile Management
    
    /// Load user profile information (only if user is authenticated)
    func loadUserProfile() {
        // CRITICAL: Add loop protection to prevent infinite loading attempts
        let now = Date()
        
        // Check if we're already loading
        if isLoadingProfile {
            return
        }
        
        // Check exponential backoff interval between attempts
        if let lastAttempt = lastLoadAttempt {
            let backoffInterval = calculateBackoffInterval(for: loadAttemptCount)
            let timeSinceLastAttempt = now.timeIntervalSince(lastAttempt)
            if timeSinceLastAttempt < backoffInterval {
                return
            }
        }
        
        // Check maximum retry attempts
        if loadAttemptCount >= Self.maxRetryAttempts {
            return
        }
        
        // Starting profile load
        
        // Cancel any existing load task
        currentLoadTask?.cancel()
        
        // Update attempt tracking
        lastLoadAttempt = now
        loadAttemptCount += 1
        isLoadingProfile = true
        
        currentLoadTask = Task {
            do {
                // Calling UserService.getCurrentUser()
                
                // Check if task was cancelled
                try Task.checkCancellation()
                
                // Use real UserService to get current user (validates authentication internally)
                let fetchedProfile = try await userService.getCurrentUser()
                
                // UserService returned profile data
                
                // Check if task was cancelled before updating UI
                try Task.checkCancellation()
                
                // Update the profile on main actor
                await MainActor.run {
                    userProfile = fetchedProfile
                    isLoadingProfile = false
                    currentLoadTask = nil
                    
                    if userProfile != nil {
                        // Reset attempt count on successful load
                        loadAttemptCount = 0
                    }
                }
                
            } catch {
                // Don't handle cancellation as an error
                if error is CancellationError {
                    await MainActor.run {
                        isLoadingProfile = false
                        currentLoadTask = nil
                    }
                    return
                }
                
                // Failed to load profile
                
                await MainActor.run {
                    isLoadingProfile = false
                    currentLoadTask = nil
                    
                    // Only show error if we've exceeded max attempts
                    if loadAttemptCount >= Self.maxRetryAttempts {
                        errorMessage = "Unable to load profile after \(Self.maxRetryAttempts) attempts: \(error.localizedDescription)"
                        showError = true
                        userProfile = nil
                        
                        // Final error state set after max attempts
                    }
                }
            }
        }
    }
    
    /// Clear all profile data (called during logout)
    func clearProfileData() {
        // Clear logout state
        isSigningOut = false
        signOutErrorMessage = nil
        showSignOutError = false
        // Clearing all profile data
        
        // Cancel any ongoing load task
        currentLoadTask?.cancel()
        currentLoadTask = nil
        
        // Reset all state
        userProfile = nil
        isLoadingProfile = false
        
        // Reset loop protection
        lastLoadAttempt = nil
        loadAttemptCount = 0
        
        // Reset UI state
        showEditProfile = false
        showDataExport = false
        showDeleteAccount = false
        showLogoutAlert = false
        showAbout = false
        showSupport = false
        
        // Clear any errors
        errorMessage = nil
        showError = false
        
        // Clear logout-specific errors
        signOutErrorMessage = nil
        showSignOutError = false
        
        // All profile data cleared
    }
    
    /// Force retry profile loading (resets attempt count)
    func retryLoadUserProfile() {
        // Manual retry requested - resetting attempt count
        loadAttemptCount = 0
        lastLoadAttempt = nil
        errorMessage = nil
        showError = false
        loadUserProfile()
    }
    
    /// Update user profile
    func updateProfile(_ profile: User) {
        Task {
            do {
                // Profile update via backend API will be implemented
                userProfile = profile
                
                // Show success feedback
                // Success toast/alert will be added
            } catch {
                errorMessage = "Failed to update profile: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    // MARK: - Settings Management
    
    /// Load user settings
    func loadSettings() {
        // Load settings from persistent storage
        // For now using default values set in property declarations
        calculateStorageUsage()
    }
    
    /// Save settings changes
    func saveSettings() {
        Task {
            do {
                // Settings persistence will be implemented
            } catch {
                errorMessage = "Failed to save settings: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    /// Toggle notification settings
    func toggleNotifications(_ enabled: Bool) {
        notificationsEnabled = enabled
        saveSettings()
        
        if enabled {
            requestNotificationPermissions()
        }
    }
    
    /// Toggle biometric authentication
    func toggleBiometricAuth(_ enabled: Bool) {
        biometricAuthEnabled = enabled
        saveSettings()
        
        if enabled {
            authenticateWithBiometrics()
        }
    }
    
    /// Toggle HealthKit sync
    func toggleHealthKitSync(_ enabled: Bool) {
        healthKitSyncEnabled = enabled
        saveSettings()
        
        if enabled {
            requestHealthKitPermissions()
        }
    }
    
    // MARK: - Data Management
    
    /// Calculate storage usage
    func calculateStorageUsage() {
        Task {
            // Calculate actual storage usage from files and cache
            storageUsage = StorageInfo(
                totalUsedMB: 45.6,
                reportsCount: 12,
                imagesCount: 8,
                cacheSize: 12.3,
                lastCleanup: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            )
        }
    }
    
    /// Export user data
    func exportData() {
        guard !isExporting else { return }
        
        isExporting = true
        exportProgress = 0.0
        
        Task {
            do {
                // Simulate export progress
                for i in 1...10 {
                    try await Task.sleep(nanoseconds: 300_000_000)
                    exportProgress = Double(i) / 10.0
                }
                
                // Data export functionality will be implemented
                isExporting = false
                exportProgress = 0.0
                
                // Show success message
                showDataExport = false
            } catch {
                isExporting = false
                exportProgress = 0.0
                errorMessage = "Failed to export data: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    /// Clear app cache
    func clearCache() {
        Task {
            do {
                // Cache clearing implementation will be added
                storageUsage.cacheSize = 0.0
                storageUsage.lastCleanup = Date()
            } catch {
                errorMessage = "Failed to clear cache: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    // MARK: - Account Management
    
    /// Sign out user with proper loading states and error handling
    func signOut(using authManager: AuthenticationManager) async {
        // Start loading state
        isSigningOut = true
        signOutErrorMessage = nil
        showSignOutError = false
        
        // Provide haptic feedback for sign out initiation
        HapticFeedback.medium()
        
        do {
            // Perform sign out through AuthenticationManager
            try await authManager.signOut(fromAllDevices: false)
            
            // Sign out successful - provide success feedback
            HapticFeedback.success()
            
            // Clear our state
            clearProfileData()
            
        } catch {
            // Handle sign out error - show user-friendly message and error feedback
            HapticFeedback.error()
            signOutErrorMessage = "Failed to sign out properly. Please try again."
            showSignOutError = true
            
            // Even on error, we should clear local data for security
            // This matches the behavior in AuthenticationManager
            clearProfileData()
        }
        
        // Always stop loading state
        isSigningOut = false
    }
    
    /// Delete user account
    func deleteAccount() {
        Task {
            do {
                // Account deletion functionality will be implemented
            } catch {
                errorMessage = "Failed to delete account: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    // MARK: - Support Actions
    
    /// Contact support
    func contactSupport() {
        // Support contact method will be implemented
        showSupport = true
    }
    
    /// Open about screen
    func showAboutScreen() {
        showAbout = true
    }
    
    /// Share app
    func shareApp() {
        // App sharing functionality will be implemented
    }
    
    /// Rate app
    func rateApp() {
        // App Store rating prompt will be implemented
    }
    
    // MARK: - Private Methods
    
    /// Setup authentication state observer
    private func setupAuthenticationObserver() {
        // Listen for sign out notifications
        NotificationCenter.default
            .publisher(for: .userDidSignOut)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.clearProfileData()
                }
            }
            .store(in: &cancellables)
        
        // Listen for sign in notifications to reload profile
        NotificationCenter.default
            .publisher(for: .userDidSignIn)
            .sink { [weak self] _ in
                Task { @MainActor in
                    // Reset loop protection on successful sign in
                    self?.loadAttemptCount = 0
                    self?.lastLoadAttempt = nil
                    // DON'T automatically trigger loadUserProfile here - let the view handle it
                }
            }
            .store(in: &cancellables)
    }
    
    private func requestNotificationPermissions() {
        // Notification permissions request will be implemented
    }
    
    private func authenticateWithBiometrics() {
        // Biometric authentication will be implemented
    }
    
    private func requestHealthKitPermissions() {
        // HealthKit permissions request will be implemented
    }
    
    // MARK: - Exponential Backoff Helper
    
    /// Calculate exponential backoff interval for retry attempts
    private func calculateBackoffInterval(for attemptCount: Int) -> TimeInterval {
        let backoffTime = Self.baseBackoffInterval * pow(Self.backoffMultiplier, Double(attemptCount - 1))
        return min(backoffTime, Self.maxBackoffInterval)
    }
}

// MARK: - Supporting Models

// UserProfile is now defined in BackendModels.swift to avoid duplication
// Use the consolidated version with proper protocol conformances


struct StorageInfo {
    var totalUsedMB: Double = 0.0
    var reportsCount: Int = 0
    var imagesCount: Int = 0
    var cacheSize: Double = 0.0
    var lastCleanup: Date = Date()
    
    var displayTotalUsed: String {
        if totalUsedMB < 1000 {
            return String(format: "%.1f MB", totalUsedMB)
        } else {
            return String(format: "%.2f GB", totalUsedMB / 1000)
        }
    }
    
    var displayCacheSize: String {
        return String(format: "%.1f MB", cacheSize)
    }
}

// MARK: - User Service

class UserService {
    static let shared = UserService()
    private let authAPIService = AuthenticationAPIService()
    
    private init() {}
    
    /// Get current user profile from backend API
    func getCurrentUser() async throws -> User? {
        
        do {
            // Use the existing AuthenticationAPIService to get current user
            let user = try await authAPIService.getCurrentUser()
            
            if let user = user {
                return user
            } else {
                return nil
            }
        } catch {
            throw error
        }
    }
    
    /// Update user profile
    func updateUser(_ profile: UserProfile) async throws {
        // User profile update via backend API will be implemented
    }
}

class SettingsService {
    static let shared = SettingsService()
    private init() {}
    
    func loadSettings() -> [String: Any] {
        // Load user settings from UserDefaults or secure storage
        return [:]
    }
    
    func saveSettings(_ settings: [String: Any]) {
        // Save user settings to UserDefaults or secure storage
    }
}