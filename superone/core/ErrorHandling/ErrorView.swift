//
//  ErrorView.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI
import Combine

/// Comprehensive error display component for different error scenarios
struct ErrorView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    init(
        error: AppError,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Error Icon
            Image(systemName: error.category.icon)
                .font(.system(size: 60))
                .foregroundColor(colorForCategory(error.category))
                .symbolRenderingMode(.hierarchical)
            
            // Error Content
            VStack(spacing: HealthSpacing.md) {
                Text(errorTitle)
                    .font(HealthTypography.headingMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(error.errorDescription ?? "An unexpected error occurred")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HealthSpacing.lg)
                
                if let recoverySuggestion = error.recoverySuggestion {
                    Text(recoverySuggestion)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.tertiaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HealthSpacing.xl)
                }
            }
            
            // Action Buttons
            VStack(spacing: HealthSpacing.md) {
                if error.canRetry, let onRetry = onRetry {
                    HealthPrimaryButton("Try Again") {
                        onRetry()
                    }
                    .frame(maxWidth: 200)
                }
                
                if error.requiresUserAction {
                    HealthSecondaryButton(actionButtonTitle) {
                        handleUserAction()
                    }
                    .frame(maxWidth: 200)
                }
                
                if let onDismiss = onDismiss {
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.secondaryText)
                }
            }
        }
        .padding(HealthSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var errorTitle: String {
        switch error.category {
        case .network:
            return "Connection Problem"
        case .authentication:
            return "Authentication Required"
        case .data:
            return "Data Error"
        case .processing:
            return "Processing Error"
        case .health:
            return "Health Data Issue"
        case .appointment:
            return "Appointment Error"
        case .general:
            return "Something Went Wrong"
        }
    }
    
    private var actionButtonTitle: String {
        switch error {
        case .biometricNotEnrolled:
            return "Open Settings"
        case .healthKitPermissionDenied:
            return "Enable Permissions"
        case .tokenExpired:
            return "Log In Again"
        case .versionNotSupported:
            return "Update App"
        case .accountLocked:
            return "Contact Support"
        default:
            return "Settings"
        }
    }
    
    private func colorForCategory(_ category: ErrorCategory) -> Color {
        switch category {
        case .network:
            return HealthColors.healthWarning
        case .authentication:
            return HealthColors.healthCritical
        case .data:
            return HealthColors.healthWarning
        case .processing:
            return HealthColors.primary
        case .health:
            return HealthColors.healthGood
        case .appointment:
            return HealthColors.primary
        case .general:
            return HealthColors.secondaryText
        }
    }
    
    private func handleUserAction() {
        switch error {
        case .biometricNotEnrolled, .healthKitPermissionDenied:
            openSettings()
        case .tokenExpired:
            // Handle re-authentication
            break
        case .versionNotSupported:
            openAppStore()
        case .accountLocked:
            openSupport()
        default:
            openSettings()
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func openAppStore() {
        // Open App Store for app updates
        if let appStoreUrl = URL(string: "https://apps.apple.com/app/super-one-health/id123456789") {
            UIApplication.shared.open(appStoreUrl)
        }
    }
    
    private func openSupport() {
        // Open support contact
        if let supportUrl = URL(string: "mailto:support@superonehealth.com") {
            UIApplication.shared.open(supportUrl)
        }
    }
}

// MARK: - Inline Error View

/// Compact error view for inline display in lists and cards
struct InlineErrorView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Image(systemName: error.category.icon)
                .font(.system(size: 20))
                .foregroundColor(colorForCategory(error.category))
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text("Error")
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(error.errorDescription ?? "Something went wrong")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if error.canRetry, let onRetry = onRetry {
                Button("Retry") {
                    onRetry()
                }
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primary)
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                .stroke(colorForCategory(error.category).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func colorForCategory(_ category: ErrorCategory) -> Color {
        switch category {
        case .network:
            return HealthColors.healthWarning
        case .authentication:
            return HealthColors.healthCritical
        case .data:
            return HealthColors.healthWarning
        case .processing:
            return HealthColors.primary
        case .health:
            return HealthColors.healthGood
        case .appointment:
            return HealthColors.primary
        case .general:
            return HealthColors.secondaryText
        }
    }
}

// MARK: - Error Alert

/// Alert-style error display for critical errors
struct ErrorAlert: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Header
            HStack {
                Image(systemName: error.category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(colorForCategory(error.category))
                
                Text("Error")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                Text(error.errorDescription ?? "An unexpected error occurred")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.primaryText)
                
                if let recoverySuggestion = error.recoverySuggestion {
                    Text(recoverySuggestion)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            // Actions
            HStack(spacing: HealthSpacing.md) {
                if error.canRetry, let onRetry = onRetry {
                    HealthSecondaryButton("Try Again") {
                        onRetry()
                        onDismiss()
                    }
                }
                
                HealthPrimaryButton("OK") {
                    onDismiss()
                }
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.background)
        .cornerRadius(HealthCornerRadius.sheet)
        .healthCardShadow()
        .padding(HealthSpacing.lg)
    }
    
    private func colorForCategory(_ category: ErrorCategory) -> Color {
        switch category {
        case .network:
            return HealthColors.healthWarning
        case .authentication:
            return HealthColors.healthCritical
        case .data:
            return HealthColors.healthWarning
        case .processing:
            return HealthColors.primary
        case .health:
            return HealthColors.healthGood
        case .appointment:
            return HealthColors.primary
        case .general:
            return HealthColors.secondaryText
        }
    }
}

// MARK: - Preview

#Preview("Error View - Network") {
    ErrorView(
        error: .networkUnavailable,
        onRetry: { },
        onDismiss: { }
    )
}

#Preview("Inline Error View") {
    InlineErrorView(
        error: .ocrProcessingFailed,
        onRetry: { }
    )
    .padding()
}

#Preview("Error Alert") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        ErrorAlert(
            error: .biometricFailed,
            onRetry: { },
            onDismiss: {  }
        )
    }
}