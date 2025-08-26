//
//  LocationManager.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import Foundation
import CoreLocation
import SwiftUI

/// Modern iOS 18+ location services manager with CLServiceSession support and privacy-first design
@MainActor
@Observable
final class LocationManager: NSObject, Sendable {
    
    // MARK: - Location State
    
    /// Current location authorization status
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Current location detection state
    var locationState: LocationState = .idle
    
    /// Current location as readable address string
    var currentLocationText: String?
    
    /// Current location coordinates
    var currentLocation: CLLocation?
    
    /// Current location error if any
    var currentError: LocationError?
    
    /// Whether location services are available on device
    var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    /// Whether we have valid location permission
    var hasLocationPermission: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
    
    /// Whether location is currently being fetched
    var isFetchingLocation: Bool {
        switch locationState {
        case .requesting, .fetching:
            return true
        default:
            return false
        }
    }
    
    /// User-friendly status message for UI display
    var statusMessage: String {
        switch locationState {
        case .idle:
            return "Tap to get location"
        case .requesting:
            return "Allow location access"
        case .fetching:
            return "Getting your location..."
        case .success:
            return currentLocationText ?? "Location detected"
        case .failed(let error):
            return error.userMessage
        }
    }
    
    // MARK: - Configuration
    
    /// Location accuracy for different use cases
    private let locationAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters
    
    /// Maximum age for cached location (5 minutes)
    private let locationCacheTimeout: TimeInterval = 300
    
    /// Request timeout (30 seconds)
    private let requestTimeout: TimeInterval = 30.0
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    // CLGeocoder will be created on-demand to avoid Sendable issues
    private var serviceSession: CLServiceSession?
    private var locationTimer: Timer?
    private var currentLocationContinuation: CheckedContinuation<CLLocation, Error>?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationServices()
        
        // Auto-request location if permissions are already granted
        if hasLocationPermission {
            Task {
                _ = await getCurrentLocation()
            }
        }
    }
    
    
    // MARK: - Public Methods
    
    /// Request current location with modern async/await pattern
    /// - Parameter forceRefresh: Whether to ignore cached location
    /// - Returns: Formatted address string
    func getCurrentLocation(forceRefresh: Bool = false) async -> String {
        // Return cached location if valid and not forcing refresh
        if !forceRefresh,
           let cached = currentLocationText,
           let location = currentLocation,
           location.timestamp.timeIntervalSinceNow > -locationCacheTimeout {
            return cached
        }
        
        do {
            let location = try await requestLocation()
            let address = await reverseGeocodeLocation(location)
            
            await MainActor.run {
                self.currentLocation = location
                self.currentLocationText = address
                self.locationState = .success
                self.currentError = nil
            }
            
            return address
        } catch {
            let locationError = LocationError.from(error)
            
            await MainActor.run {
                self.currentError = locationError
                self.locationState = .failed(locationError)
            }
            
            // Return fallback location
            return getFallbackLocationText()
        }
    }
    
    /// Request location permission with user-friendly flow
    func requestLocationPermission() async -> Bool {
        guard isLocationServicesEnabled else {
            await MainActor.run {
                self.currentError = .locationServicesDisabled
                self.locationState = .failed(.locationServicesDisabled)
            }
            return false
        }
        
        let currentStatus = locationManager.authorizationStatus
        
        // Already have permission
        if currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways {
            return true
        }
        
        // Permission denied permanently
        if currentStatus == .denied || currentStatus == .restricted {
            await MainActor.run {
                self.currentError = .permissionDenied
                self.locationState = .failed(.permissionDenied)
            }
            return false
        }
        
        // Request permission
        await MainActor.run {
            self.locationState = .requesting
            self.currentError = nil
        }
        
        return await withCheckedContinuation { continuation in
            // Store continuation for delegate callback
            Task { @MainActor in
                self.permissionContinuation = continuation
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    /// Reset location state and clear cache
    func resetLocationState() {
        locationState = .idle
        currentLocationText = nil
        currentLocation = nil
        currentError = nil
        invalidateTimer()
        serviceSession?.invalidate()
        serviceSession = nil
    }
    
    /// Open iOS Settings app for location permissions
    func openLocationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        Task {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                await UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    /// Get detailed location info for debugging
    func getLocationDetails() -> LocationDetails {
        LocationDetails(
            isServicesEnabled: isLocationServicesEnabled,
            authorizationStatus: authorizationStatus,
            locationState: locationState,
            currentLocation: currentLocation,
            currentError: currentError,
            lastUpdated: currentLocation?.timestamp
        )
    }
    
    // MARK: - Private Properties for Continuations
    
    private var permissionContinuation: CheckedContinuation<Bool, Never>?
    
    // MARK: - Private Methods
    
    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = locationAccuracy
        locationManager.distanceFilter = 50 // Update every 50 meters
        
        // Update initial authorization status
        authorizationStatus = locationManager.authorizationStatus
        
        // Create service session for iOS 18+ privacy enhancements
        if #available(iOS 18.0, *) {
            serviceSession = CLServiceSession(
                authorization: .whenInUse,
                fullAccuracyPurposeKey: "PreciseLocationForNearbyLabs"
            )
        }
    }
    
    private func requestLocation() async throws -> CLLocation {
        // Check prerequisites
        guard isLocationServicesEnabled else {
            throw LocationError.locationServicesDisabled
        }
        
        if !hasLocationPermission {
            // Try to request permission first
            let granted = await requestLocationPermission()
            guard granted else {
                throw LocationError.permissionDenied
            }
        }
        
        await MainActor.run {
            self.locationState = .fetching
            self.currentError = nil
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                self.currentLocationContinuation = continuation
                
                // Start timeout timer
                self.locationTimer = Timer.scheduledTimer(withTimeInterval: self.requestTimeout, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.handleLocationTimeout()
                    }
                }
                
                // Request single location update
                self.locationManager.requestLocation()
            }
        }
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) async -> String {
        // First, try to get cached result if location hasn't changed much
        if let cached = currentLocationText,
           let currentLoc = currentLocation,
           location.distance(from: currentLoc) < 100 { // Within 100 meters
            return cached
        }
        
        do {
            // Create geocoder on-demand to avoid Sendable issues
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                let formattedAddress = formatPlacemark(placemark)
                print("✅ Geocoding successful: \(formattedAddress)")
                return formattedAddress
            } else {
                print("⚠️ Geocoding returned no placemarks")
                return formatCoordinatesWithFallback(location.coordinate)
            }
        } catch {
            // Enhanced error handling for different geocoding failure types
            print("❌ Geocoding failed: \(error.localizedDescription)")
            
            if let clError = error as? CLError {
                switch clError.code {
                case .network:
                    // Network error - try again with timeout or fallback
                    print("🌐 Network error during geocoding - using coordinates")
                case .geocodeFoundNoResult:
                    print("📍 No geocoding results found - location may be remote")
                case .geocodeCanceled:
                    print("⏸️ Geocoding was canceled")
                default:
                    print("🔍 Other geocoding error: \(clError.localizedDescription)")
                }
            }
            
            return formatCoordinatesWithFallback(location.coordinate)
        }
    }
    
    private func formatPlacemark(_ placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        // Show only area and city - no state/country for UI display
        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        // Fallback to name if no locality/subLocality available
        if components.isEmpty, let name = placemark.name {
            components.append(name)
        }
        
        let address = components.joined(separator: ", ")
        return address.isEmpty ? "Location Found" : address
    }
    
    private func formatCoordinates(_ coordinate: CLLocationCoordinate2D) -> String {
        return String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }
    
    private func formatCoordinatesWithFallback(_ coordinate: CLLocationCoordinate2D) -> String {
        // For UI display, show simplified location when geocoding fails
        return "Current Location"
    }
    
    private func getFallbackLocationText() -> String {
        if let current = currentLocationText {
            return current
        }
        return "Location not available"
    }
    
    private func handleLocationSuccess(_ location: CLLocation) {
        invalidateTimer()
        
        // Ensure we only resume once and clean up properly
        if let continuation = currentLocationContinuation {
            currentLocationContinuation = nil
            continuation.resume(returning: location)
        }
    }
    
    private func handleLocationFailure(_ error: Error) {
        invalidateTimer()
        
        let locationError = LocationError.from(error)
        currentError = locationError
        locationState = .failed(locationError)
        
        // Ensure we only resume once and clean up properly
        if let continuation = currentLocationContinuation {
            currentLocationContinuation = nil
            continuation.resume(throwing: locationError)
        }
    }
    
    private func handleLocationTimeout() {
        locationManager.stopUpdatingLocation()
        handleLocationFailure(LocationError.timeout)
    }
    
    private func invalidateTimer() {
        locationTimer?.invalidate()
        locationTimer = nil
    }
    
    /// Cleanup method to be called when the manager is no longer needed
    func cleanup() async {
        invalidateTimer()
        locationManager.stopUpdatingLocation()
        
        // Cancel any pending continuation to prevent leaks
        if let continuation = currentLocationContinuation {
            currentLocationContinuation = nil
            continuation.resume(throwing: LocationError.cancelled)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            handleLocationSuccess(location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            handleLocationFailure(error)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            
            // Handle permission continuation if waiting
            if let continuation = self.permissionContinuation {
                self.permissionContinuation = nil
                
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    continuation.resume(returning: true)
                    // Auto-request location when permissions are granted
                    Task {
                        _ = await self.getCurrentLocation()
                    }
                case .denied, .restricted:
                    self.currentError = .permissionDenied
                    self.locationState = .failed(.permissionDenied)
                    continuation.resume(returning: false)
                case .notDetermined:
                    // Still waiting for user response
                    break
                @unknown default:
                    self.currentError = .unknown
                    self.locationState = .failed(.unknown)
                    continuation.resume(returning: false)
                }
            } else if status == .authorizedWhenInUse || status == .authorizedAlways {
                // Auto-request location when permissions are granted outside of permission flow
                if self.locationState == .idle {
                    Task {
                        _ = await self.getCurrentLocation()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

/// Current state of location detection
enum LocationState: Equatable {
    case idle
    case requesting
    case fetching
    case success
    case failed(LocationError)
    
    var isLoading: Bool {
        switch self {
        case .requesting, .fetching:
            return true
        default:
            return false
        }
    }
    
    var hasError: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}

/// Location service errors with user-friendly messaging
enum LocationError: Error, LocalizedError, Equatable, Sendable {
    case locationServicesDisabled
    case permissionDenied
    case locationUnavailable
    case networkError
    case timeout
    case geocodingFailed
    case cancelled
    case unknown
    
    /// Technical error description for debugging
    nonisolated var errorDescription: String? {
        switch self {
        case .locationServicesDisabled:
            return "Location services are disabled system-wide"
        case .permissionDenied:
            return "Location permission denied or restricted"
        case .locationUnavailable:
            return "Current location could not be determined"
        case .networkError:
            return "Network error during location request"
        case .timeout:
            return "Location request timed out"
        case .geocodingFailed:
            return "Failed to convert coordinates to address"
        case .cancelled:
            return "Location request was cancelled"
        case .unknown:
            return "Unknown location error"
        }
    }
    
    /// User-friendly message for UI display
    var userMessage: String {
        switch self {
        case .locationServicesDisabled:
            return "Location services are turned off"
        case .permissionDenied:
            return "Location access needed"
        case .locationUnavailable:
            return "Can't find your location"
        case .networkError:
            return "Network issue"
        case .timeout:
            return "Location request timed out"
        case .geocodingFailed:
            return "Using coordinates"
        case .cancelled:
            return "Location cancelled"
        case .unknown:
            return "Location error"
        }
    }
    
    /// Recovery suggestion for users
    nonisolated var recoverySuggestion: String {
        switch self {
        case .locationServicesDisabled:
            return "Enable Location Services in Settings > Privacy & Security > Location Services"
        case .permissionDenied:
            return "Allow location access in Settings > SuperOne Health > Location"
        case .locationUnavailable, .timeout:
            return "Try again or select location manually"
        case .networkError:
            return "Check your internet connection and try again"
        case .geocodingFailed:
            return "Location found but address unavailable"
        case .cancelled:
            return "Location request was stopped"
        case .unknown:
            return "Try restarting the app"
        }
    }
    
    /// Create LocationError from system error
    static func from(_ error: Error) -> LocationError {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                return .permissionDenied
            case .locationUnknown:
                return .locationUnavailable
            case .network:
                return .networkError
            case .geocodeFoundNoResult, .geocodeFoundPartialResult, .geocodeCanceled:
                return .geocodingFailed
            default:
                return .unknown
            }
        }
        
        return .unknown
    }
}

/// Detailed location information for debugging and analytics
struct LocationDetails {
    let isServicesEnabled: Bool
    let authorizationStatus: CLAuthorizationStatus
    let locationState: LocationState
    let currentLocation: CLLocation?
    let currentError: LocationError?
    let lastUpdated: Date?
    
    var debugDescription: String {
        var info: [String] = []
        
        info.append("Services: \(isServicesEnabled ? "Enabled" : "Disabled")")
        info.append("Auth: \(authorizationStatus.debugDescription)")
        info.append("State: \(locationState)")
        
        if let location = currentLocation {
            info.append("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            info.append("Accuracy: ±\(location.horizontalAccuracy)m")
            
            if let updated = lastUpdated {
                let age = Date().timeIntervalSince(updated)
                info.append("Age: \(Int(age))s")
            }
        }
        
        if let error = currentError {
            info.append("Error: \(error.userMessage)")
        }
        
        return info.joined(separator: " | ")
    }
}

// MARK: - Extensions

extension CLAuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "When In Use"
        @unknown default:
            return "Unknown(\(rawValue))"
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension LocationManager {
    /// Create mock location manager for SwiftUI previews
    static func mock(
        state: LocationState = .success,
        location: String = "Mumbai, Maharashtra, IN",
        authStatus: CLAuthorizationStatus = .authorizedWhenInUse
    ) -> LocationManager {
        let manager = LocationManager()
        manager.locationState = state
        manager.currentLocationText = location
        manager.authorizationStatus = authStatus
        
        // Mock coordinate for Mumbai
        if let mockLocation = CLLocation(latitude: 19.0760, longitude: 72.8777) as CLLocation? {
            manager.currentLocation = mockLocation
        }
        
        return manager
    }
    
    /// Create mock with error state
    static func mockError(_ error: LocationError) -> LocationManager {
        let manager = LocationManager()
        manager.locationState = .failed(error)
        manager.currentError = error
        manager.authorizationStatus = error == .permissionDenied ? .denied : .authorizedWhenInUse
        return manager
    }
}
#endif