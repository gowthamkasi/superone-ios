//
//  LocationStatusView.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI
import CoreLocation

/// Compact location status display with error handling and user actions
struct LocationStatusView: View {
    @Bindable var locationManager: LocationManager
    
    @State private var showingPermissionView = false
    @State private var showingErrorAlert = false
    @State private var debugMode = false
    
    var body: some View {
        HStack(spacing: HealthSpacing.sm) {
            // Status indicator
            statusIndicator
            
            // Location content
            locationContent
            
            Spacer()
            
            // Action button
            actionButton
        }
        .padding(.horizontal, HealthSpacing.md)
        .padding(.vertical, HealthSpacing.sm)
        .background(backgroundColor)
        .cornerRadius(HealthCornerRadius.card)
        .sheet(isPresented: $showingPermissionView) {
            LocationPermissionView(locationManager: locationManager)
        }
        .alert("Location Error", isPresented: $showingErrorAlert) {
            Button("Try Again") {
                Task {
                    _ = await locationManager.getCurrentLocation(forceRefresh: true)
                }
            }
            
            if locationManager.currentError == .permissionDenied || 
               locationManager.currentError == .locationServicesDisabled {
                Button("Open Settings") {
                    locationManager.openLocationSettings()
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            if let error = locationManager.currentError {
                Text(error.recoverySuggestion)
            }
        }
        .onChange(of: locationManager.locationState) { oldState, newState in
            print("🔄 LocationStatusView: State changed from \(oldState) to \(newState)")
            if case .success = newState, let locationText = locationManager.currentLocationText {
                print("📍 LocationStatusView: Location updated to \(locationText)")
            }
        }
        .onTapGesture(count: 3) {
            debugMode.toggle()
            print("🐛 Debug mode: \(debugMode ? "ON" : "OFF")")
        }
        .overlay(
            debugMode ? debugOverlay : nil,
            alignment: .bottom
        )
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicator: some View {
        Group {
            switch locationManager.locationState {
            case .idle:
                Image(systemName: "location")
                    .foregroundColor(HealthColors.secondaryText)
                
            case .requesting, .fetching:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: HealthColors.primary))
                    .scaleEffect(0.8)
                
            case .success:
                Image(systemName: "location.fill")
                    .foregroundColor(HealthColors.healthGood)
                
            case .failed(let error):
                Image(systemName: errorIcon(for: error))
                    .foregroundColor(HealthColors.healthCritical)
            }
        }
        .frame(width: 20, height: 20)
    }
    
    // MARK: - Location Content
    
    private var locationContent: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.xs) {
            Text(primaryText)
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primaryText)
                .lineLimit(1)
            
            if let secondaryText = secondaryText {
                Text(secondaryText)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Group {
            switch locationManager.locationState {
            case .idle:
                Button("Get Location") {
                    if locationManager.hasLocationPermission {
                        Task {
                            _ = await locationManager.getCurrentLocation(forceRefresh: true)
                        }
                    } else {
                        showingPermissionView = true
                    }
                }
                .buttonStyle(LocationActionButtonStyle())
                
            case .requesting, .fetching:
                // No action button while loading
                EmptyView()
                
            case .success:
                Button("Refresh") {
                    Task {
                        _ = await locationManager.getCurrentLocation(forceRefresh: true)
                    }
                }
                .buttonStyle(LocationActionButtonStyle())
                
            case .failed:
                Button("Retry") {
                    if locationManager.currentError == .permissionDenied {
                        showingPermissionView = true
                    } else {
                        showingErrorAlert = true
                    }
                }
                .buttonStyle(LocationActionButtonStyle(isError: true))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch locationManager.locationState {
        case .failed:
            return HealthColors.healthCritical.opacity(0.1)
        case .success:
            return HealthColors.healthGood.opacity(0.1)
        default:
            return HealthColors.secondaryBackground
        }
    }
    
    private var primaryText: String {
        switch locationManager.locationState {
        case .idle:
            return "Tap to get your location"
        case .requesting:
            return "Allow location access"
        case .fetching:
            return "Finding your location..."
        case .success:
            return locationManager.currentLocationText ?? "Location detected"
        case .failed(let error):
            return error.userMessage
        }
    }
    
    private var secondaryText: String? {
        switch locationManager.locationState {
        case .idle:
            return "Find nearby labs automatically"
        case .requesting:
            return "Needed for lab discovery"
        case .fetching:
            return "Please wait..."
        case .success:
            if let location = locationManager.currentLocation {
                let accuracy = Int(location.horizontalAccuracy)
                return "Accurate to ±\(accuracy)m"
            }
            return nil
        case .failed(let error):
            return "Tap Retry for options"
        }
    }
    
    private func errorIcon(for error: LocationError) -> String {
        switch error {
        case .locationServicesDisabled, .permissionDenied:
            return "location.slash"
        case .networkError:
            return "wifi.slash"
        case .timeout:
            return "clock.badge.exclamationmark"
        case .cancelled:
            return "xmark.circle"
        case .locationUnavailable, .geocodingFailed, .unknown:
            return "location.slash.fill"
        }
    }
    
    // MARK: - Debug Overlay
    
    @ViewBuilder
    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.xs) {
            Text("🐛 DEBUG INFO")
                .font(HealthTypography.captionMedium)
                .foregroundColor(.white)
            
            Text("State: \(String(describing: locationManager.locationState))")
                .font(HealthTypography.captionRegular)
                .foregroundColor(.white)
            
            Text("Permission: \(locationManager.authorizationStatus.debugDescription)")
                .font(HealthTypography.captionRegular)
                .foregroundColor(.white)
            
            if let location = locationManager.currentLocation {
                Text("Coords: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(.white)
                
                Text("Accuracy: ±\(Int(location.horizontalAccuracy))m")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(.white)
                
                Text("Age: \(Int(Date().timeIntervalSince(location.timestamp)))s")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(.white)
            }
            
            if let text = locationManager.currentLocationText {
                Text("Address: \(text)")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(.white)
            }
            
            if let error = locationManager.currentError {
                Text("Error: \(error.userMessage)")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(.red)
            }
        }
        .padding(HealthSpacing.sm)
        .background(Color.black.opacity(0.8))
        .cornerRadius(HealthCornerRadius.sm)
        .offset(y: 40)
    }
}

// MARK: - Supporting Styles

struct LocationActionButtonStyle: ButtonStyle {
    let isError: Bool
    
    init(isError: Bool = false) {
        self.isError = isError
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HealthTypography.captionMedium)
            .foregroundColor(isError ? HealthColors.healthCritical : HealthColors.primary)
            .padding(.horizontal, HealthSpacing.sm)
            .padding(.vertical, HealthSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                    .stroke(isError ? HealthColors.healthCritical : HealthColors.primary, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                            .fill(configuration.isPressed ? 
                                  (isError ? HealthColors.healthCritical.opacity(0.1) : HealthColors.primary.opacity(0.1)) : 
                                  Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Location Status - Idle") {
    VStack(spacing: HealthSpacing.md) {
        LocationStatusView(locationManager: LocationManager.mock(state: .idle))
        LocationStatusView(locationManager: LocationManager.mock(state: .fetching))
        LocationStatusView(locationManager: LocationManager.mock(state: .success))
        LocationStatusView(locationManager: LocationManager.mockError(.permissionDenied))
    }
    .padding()
}

#Preview("Location Status - Dark") {
    VStack(spacing: HealthSpacing.md) {
        LocationStatusView(locationManager: LocationManager.mock(state: .success))
        LocationStatusView(locationManager: LocationManager.mockError(.timeout))
    }
    .padding()
    .preferredColorScheme(.dark)
}