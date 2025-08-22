//
//  LocationPermissionView.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI
import CoreLocation

/// Educational view for requesting location permissions with clear user benefits
struct LocationPermissionView: View {
    @Bindable var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isRequestingPermission = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Hero section
                heroSection
                
                // Benefits section
                benefitsSection
                
                // Action buttons
                actionButtonsSection
            }
            .navigationTitle("Location Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .disabled(isRequestingPermission)
                }
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Location icon
            ZStack {
                Circle()
                    .fill(HealthColors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "location.fill")
                    .font(.system(size: 48))
                    .foregroundColor(HealthColors.primary)
            }
            
            VStack(spacing: HealthSpacing.md) {
                Text("Find Labs Near You")
                    .font(HealthTypography.headingLarge)
                    .foregroundColor(HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("We'll use your location to help you discover nearby labs and healthcare facilities for convenient appointments.")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
        .padding(.vertical, HealthSpacing.xxl)
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.lg) {
            Text("What you get:")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                LocationBenefitRow(
                    icon: "map",
                    title: "Nearby Lab Discovery",
                    description: "Find the closest labs and testing centers"
                )
                
                LocationBenefitRow(
                    icon: "clock",
                    title: "Faster Booking",
                    description: "Skip manual location entry for appointments"
                )
                
                LocationBenefitRow(
                    icon: "car",
                    title: "Home Collection",
                    description: "Enable home sample collection services"
                )
                
                LocationBenefitRow(
                    icon: "shield",
                    title: "Privacy Protected",
                    description: "Location is only used when you're using the app"
                )
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: HealthSpacing.md) {
            // Primary action - Allow Location
            Button {
                requestLocationPermission()
            } label: {
                HStack {
                    if isRequestingPermission {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "location.fill")
                    }
                    
                    Text("Allow Location Access")
                        .font(HealthTypography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.md)
                .background(HealthColors.primary)
                .foregroundColor(.white)
                .cornerRadius(HealthCornerRadius.button)
            }
            .disabled(isRequestingPermission)
            
            // Secondary action - Manual location
            Button("Enter Location Manually") {
                dismiss()
            }
            .font(HealthTypography.bodyMedium)
            .foregroundColor(HealthColors.primary)
            .padding(.vertical, HealthSpacing.sm)
            
            // Privacy note
            Text("Your location is encrypted and never shared with third parties")
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HealthSpacing.lg)
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
        .padding(.bottom, HealthSpacing.xl)
    }
    
    // MARK: - Actions
    
    private func requestLocationPermission() {
        isRequestingPermission = true
        
        Task {
            let granted = await locationManager.requestLocationPermission()
            
            await MainActor.run {
                isRequestingPermission = false
                
                if granted {
                    // Permission granted, try to get location
                    Task {
                        _ = await locationManager.getCurrentLocation(forceRefresh: true)
                        await MainActor.run {
                            dismiss()
                        }
                    }
                } else {
                    // Permission denied, show settings option
                    showSettingsAlert()
                }
            }
        }
    }
    
    private func showSettingsAlert() {
        // In a real implementation, you'd use an alert or action sheet
        // For now, we'll just open settings directly
        locationManager.openLocationSettings()
    }
}

// MARK: - Supporting Views

struct LocationBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: HealthSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(HealthColors.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(HealthColors.primary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(description)
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
        }
    }
}

// MARK: - Previews

#Preview("Location Permission") {
    LocationPermissionView(locationManager: LocationManager.mock())
}

#Preview("Location Permission - Dark") {
    LocationPermissionView(locationManager: LocationManager.mock())
        .preferredColorScheme(.dark)
}

#Preview("Permission Denied") {
    LocationPermissionView(locationManager: LocationManager.mockError(.permissionDenied))
}