//
//  AppFlowManager.swift
//  SuperOne
//
//  Created by Claude Code on 1/30/25.
//  Centralized app flow state management for authentication and onboarding
//

import Foundation

/// Represents the current app flow state
enum AppFlow: Equatable, Sendable {
    case initialWelcome     // True first time or completely fresh start
    case onboarding        // New user path with account creation
    case authentication    // Returning user needs to log in
    case authenticated     // Already logged in and ready for main app
}

/// Centralized manager for app flow state detection and management
@MainActor
@Observable
class AppFlowManager {
    
    // MARK: - Singleton
    static let shared = AppFlowManager()
    
    // MARK: - Observable Properties
    var currentFlow: AppFlow = .initialWelcome
    var isLoading: Bool = true
    var hasDetectedInitialState: Bool = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainHelper.shared
    private let tokenManager = TokenManager.shared
    
    // UserDefaults Keys
    private struct Keys {
        static let hasEverCompletedOnboarding = "has_ever_completed_onboarding"
        static let hasEverHadAccount = "has_ever_had_account"
        static let lastKnownUserEmail = "last_known_user_email"
        static let appVersion = "app_version"
    }
    
    // MARK: - Initialization
    private init() {
        // Private init for singleton
    }
    
    // MARK: - Public Methods
    
    /// Detect initial app flow state on app launch
    func detectInitialFlow() async {
        isLoading = true
        
        // 1. Check if user has valid stored authentication
        if await checkStoredAuthentication() {
            currentFlow = .authenticated
            isLoading = false
            hasDetectedInitialState = true
            return
        }
        
        // 2. Check if user has ever completed onboarding
        let hasCompletedOnboarding = userDefaults.bool(forKey: Keys.hasEverCompletedOnboarding)
        let hasEverHadAccount = userDefaults.bool(forKey: Keys.hasEverHadAccount)
        
        // 3. Determine appropriate flow
        if !hasCompletedOnboarding && !hasEverHadAccount {
            // True first time user
            currentFlow = .initialWelcome
        } else if hasCompletedOnboarding || hasEverHadAccount {
            // User has used app before but not authenticated
            currentFlow = .authentication
        } else {
            // Fallback to initial welcome
            currentFlow = .initialWelcome
        }
        
        isLoading = false
        hasDetectedInitialState = true
        
    }
    
    /// User chose to start onboarding (new user path)
    func startOnboarding() {
        currentFlow = .onboarding
    }
    
    /// User chose to log in (existing user path)
    func startAuthentication() {
        currentFlow = .authentication
    }
    
    /// User completed onboarding with account creation
    func completeOnboarding() {
        // Update immediately since we're already on MainActor
        userDefaults.set(true, forKey: Keys.hasEverCompletedOnboarding)
        userDefaults.set(true, forKey: Keys.hasEverHadAccount)
        currentFlow = .authenticated
    }
    
    /// User successfully authenticated
    func completeAuthentication(email: String) {
        
        // Update immediately since we're already on MainActor
        userDefaults.set(true, forKey: Keys.hasEverHadAccount)
        storeLastKnownEmail(email)
        currentFlow = .authenticated
    }
    
    /// User signed out
    func signOut() {
        // Don't reset onboarding completion - user has been through the process
        // Just require re-authentication
        currentFlow = .authentication
    }
    
    /// Reset app to fresh state (for testing or "start fresh" scenarios)
    func resetToFreshState() {
        userDefaults.removeObject(forKey: Keys.hasEverCompletedOnboarding)
        userDefaults.removeObject(forKey: Keys.hasEverHadAccount)
        userDefaults.removeObject(forKey: Keys.lastKnownUserEmail)
        currentFlow = .initialWelcome
    }
    
    // MARK: - State Queries
    
    /// Check if user has ever completed onboarding
    var hasEverCompletedOnboarding: Bool {
        return userDefaults.bool(forKey: Keys.hasEverCompletedOnboarding)
    }
    
    /// Check if user has ever had an account
    var hasEverHadAccount: Bool {
        return userDefaults.bool(forKey: Keys.hasEverHadAccount)
    }
    
    /// Get last known user email for smart pre-fill
    var lastKnownEmail: String? {
        return userDefaults.string(forKey: Keys.lastKnownUserEmail)
    }
    
    /// Check if this might be a reinstall scenario
    var isPossibleReinstall: Bool {
        // User has account history but no current authentication
        return hasEverHadAccount && !tokenManager.hasStoredTokens()
    }
    
    // MARK: - Private Methods
    
    private func checkStoredAuthentication() async -> Bool {
        
        // Simple check for stored tokens - let AuthenticationManager handle the refresh logic
        let hasTokens = tokenManager.hasStoredTokens()
        
        if hasTokens {
            return true
        } else {
            return false
        }
    }
    
    private func storeLastKnownEmail(_ email: String) {
        userDefaults.set(email, forKey: Keys.lastKnownUserEmail)
    }
    
    private func trackAppVersion() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let storedVersion = userDefaults.string(forKey: Keys.appVersion)
        
        if storedVersion != currentVersion {
            userDefaults.set(currentVersion, forKey: Keys.appVersion)
            
            // Could add version-specific migration logic here if needed
        }
    }
}

// MARK: - Debug Helpers

extension AppFlowManager {
    
    /// Get debug information about current state
    var debugInfo: String {
        return """
        AppFlowManager Debug Info:
        - Current Flow: \(currentFlow)
        - Has Ever Completed Onboarding: \(hasEverCompletedOnboarding)
        - Has Ever Had Account: \(hasEverHadAccount)
        - Last Known Email: \(lastKnownEmail ?? "none")
        - Has Stored Tokens: \(tokenManager.hasStoredTokens())
        - Is Possible Reinstall: \(isPossibleReinstall)
        - Is Loading: \(isLoading)
        - Has Detected Initial State: \(hasDetectedInitialState)
        """
    }
    
    /// Print debug information
    func printDebugInfo() {
    }
}