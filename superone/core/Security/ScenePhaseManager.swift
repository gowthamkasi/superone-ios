//
//  ScenePhaseManager.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Scene phase management for app security (simplified without biometric logic)
//

import SwiftUI
import UIKit

/// Manages app scene phase transitions with basic security enhancements
/// Provides blur overlay for privacy protection
@MainActor
@Observable
class ScenePhaseManager {
    
    // MARK: - Observable Properties
    var showBlurOverlay = false
    var requiresBiometricAuth = false // Keep for UI compatibility but not used
    var isAppInBackground = false
    
    // MARK: - Private Properties
    private let authManager: AuthenticationManager
    private var backgroundTime: Date?
    
    // MARK: - Initialization
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
    }
    
    // MARK: - Scene Phase Handling
    
    /// Handle app transitioning to background/inactive state
    func handleAppGoingToBackground() {
        
        backgroundTime = Date()
        isAppInBackground = true
        
        // Show blur overlay immediately for privacy
        showBlurOverlay = true
        
        // Clear any sensitive data from memory if needed
        clearSensitiveDataFromMemory()
    }
    
    /// Handle app becoming active
    func handleAppBecomingActive() {
        
        isAppInBackground = false
        
        // For now, just remove blur overlay immediately
        // In the future, we can add logic to check if re-authentication is needed
        removeBlurOverlay()
        
        backgroundTime = nil
    }
    
    /// Handle successful biometric re-authentication (kept for UI compatibility)
    func handleBiometricAuthSuccess() {
        
        requiresBiometricAuth = false
        removeBlurOverlay()
    }
    
    /// Handle failed biometric re-authentication (kept for UI compatibility)
    func handleBiometricAuthFailure() {
        
        // For now, just remove overlay - in future can implement sign out
        requiresBiometricAuth = false
        removeBlurOverlay()
    }
    
    // MARK: - Private Methods
    
    private func removeBlurOverlay() {
        withAnimation(.easeOut(duration: 0.3)) {
            showBlurOverlay = false
        }
    }
    
    private func clearSensitiveDataFromMemory() {
        // Clear any sensitive data that shouldn't persist in memory
        // This could include clearing form data, temporary tokens, etc.
    }
}

// MARK: - Blur Overlay View

struct BlurOverlayView: View {
    let isVisible: Bool
    
    var body: some View {
        Group {
            if isVisible {
                ZStack {
                    // Blur effect
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    // App logo/icon for branding
                    VStack(spacing: 20) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(HealthColors.primary)
                        
                        Text("Super One")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(HealthColors.primaryText)
                        
                        Text("Your health data is protected")
                            .font(.subheadline)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(duration: 0.5), value: isVisible)
                }
                .allowsHitTesting(true) // Prevent interaction with underlying content
                .zIndex(999) // Ensure it's on top
            }
        }
    }
}

// MARK: - Simplified Biometric Re-auth View (for UI compatibility)

struct BiometricReauthView: View {
    let isVisible: Bool
    let onSuccess: () -> Void
    let onFailure: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Group {
            if isVisible {
                ZStack {
                    // Background blur
                    Rectangle()
                        .fill(.regularMaterial)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 60))
                                .foregroundColor(HealthColors.primary)
                            
                            Text("Authentication Required")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(HealthColors.primaryText)
                            
                            Text("Please authenticate to continue")
                                .font(.body)
                                .foregroundColor(HealthColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Continue Button (simplified - no actual biometric auth)
                        Button(action: {
                            // For now, just call success
                            onSuccess()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                    .font(.system(size: 20, weight: .medium))
                                
                                Text("Continue")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(HealthColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(HealthCornerRadius.button)
                        }
                        
                        // Cancel Button
                        Button("Cancel") {
                            onCancel()
                        }
                        .font(.body)
                        .foregroundColor(HealthColors.secondaryText)
                    }
                    .padding(HealthSpacing.screenPadding)
                    .background(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                            .fill(HealthColors.background)
                            .shadow(radius: 10)
                    )
                    .padding(HealthSpacing.screenPadding)
                }
                .allowsHitTesting(true)
                .zIndex(1000)
            }
        }
    }
}