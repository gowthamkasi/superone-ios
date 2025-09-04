//
//  LocationUtils.swift
//  SuperOne
//
//  Created by Claude Code on 2025-01-28.
//  Location utility functions for distance calculation and formatting
//

import Foundation
import CoreLocation

/// Utility class for location-related calculations
final class LocationUtils {
    
    // MARK: - Distance Calculations
    
    /// Calculate distance between two coordinates
    /// - Parameters:
    ///   - from: Source coordinates
    ///   - to: Destination coordinates
    /// - Returns: Distance in kilometers
    static func calculateDistance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let sourceLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let destinationLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        
        let distanceInMeters = sourceLocation.distance(from: destinationLocation)
        return distanceInMeters / 1000.0 // Convert to kilometers
    }
    
    /// Calculate distance from user location to facility
    /// - Parameters:
    ///   - userLocation: User's current location
    ///   - facilityCoordinates: Facility coordinates
    /// - Returns: Distance in kilometers, nil if user location unavailable
    static func calculateDistanceFromUser(
        userLocation: CLLocation?,
        to facilityCoordinates: (lat: Double, lng: Double)
    ) -> Double? {
        guard let userLocation = userLocation else { return nil }
        
        let facilityLocation = CLLocation(
            latitude: facilityCoordinates.lat,
            longitude: facilityCoordinates.lng
        )
        
        let distanceInMeters = userLocation.distance(from: facilityLocation)
        return distanceInMeters / 1000.0 // Convert to kilometers
    }
    
    // MARK: - Distance Formatting
    
    /// Format distance for UI display
    /// - Parameter distanceKm: Distance in kilometers
    /// - Returns: Formatted string like "2.3 km" or "350 m"
    static func formatDistance(_ distanceKm: Double?) -> String {
        guard let distanceKm = distanceKm else { return "Distance unavailable" }
        
        if distanceKm < 0.1 {
            // Show meters for very short distances
            let meters = Int(distanceKm * 1000)
            return "\(meters) m"
        } else if distanceKm < 1.0 {
            // Show meters for distances under 1km
            let meters = Int(distanceKm * 1000)
            return "\(meters) m"
        } else if distanceKm < 10.0 {
            // Show 1 decimal place for distances under 10km
            return String(format: "%.1f km", distanceKm)
        } else {
            // Show whole kilometers for longer distances
            return "\(Int(round(distanceKm))) km"
        }
    }
    
    /// Format distance with "away" suffix for UI
    /// - Parameter distanceKm: Distance in kilometers
    /// - Returns: Formatted string like "2.3 km away"
    static func formatDistanceWithSuffix(_ distanceKm: Double?) -> String {
        let formattedDistance = formatDistance(distanceKm)
        
        if formattedDistance == "Distance unavailable" {
            return formattedDistance
        }
        
        return "\(formattedDistance) away"
    }
    
    // MARK: - Location Validation
    
    /// Check if coordinates are valid
    /// - Parameter coordinates: Coordinates to validate
    /// - Returns: True if coordinates are valid
    static func isValidCoordinate(_ coordinates: (lat: Double, lng: Double)) -> Bool {
        let latitude = coordinates.lat
        let longitude = coordinates.lng
        
        return latitude >= -90.0 && latitude <= 90.0 &&
               longitude >= -180.0 && longitude <= 180.0 &&
               !(latitude == 0.0 && longitude == 0.0) // Exclude null island
    }
    
    /// Check if CLLocationCoordinate2D is valid
    /// - Parameter coordinate: CoreLocation coordinate to validate
    /// - Returns: True if coordinate is valid
    static func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return CLLocationCoordinate2DIsValid(coordinate) &&
               !(coordinate.latitude == 0.0 && coordinate.longitude == 0.0)
    }
    
    // MARK: - Coordinate Conversion
    
    /// Convert tuple coordinates to CLLocationCoordinate2D
    /// - Parameter coordinates: Tuple coordinates
    /// - Returns: CLLocationCoordinate2D
    static func toCoordinate(_ coordinates: (lat: Double, lng: Double)) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: coordinates.lat,
            longitude: coordinates.lng
        )
    }
    
    /// Convert CLLocationCoordinate2D to tuple
    /// - Parameter coordinate: CoreLocation coordinate
    /// - Returns: Tuple coordinates
    static func toTuple(_ coordinate: CLLocationCoordinate2D) -> (lat: Double, lng: Double) {
        return (lat: coordinate.latitude, lng: coordinate.longitude)
    }
    
    // MARK: - Distance Filtering
    
    /// Check if facility is within specified distance from user
    /// - Parameters:
    ///   - facilityCoordinates: Facility coordinates
    ///   - userLocation: User's current location
    ///   - maxDistanceKm: Maximum distance in kilometers
    /// - Returns: True if facility is within distance
    static func isWithinDistance(
        facilityCoordinates: (lat: Double, lng: Double),
        from userLocation: CLLocation?,
        maxDistanceKm: Double
    ) -> Bool {
        guard let distance = calculateDistanceFromUser(
            userLocation: userLocation,
            to: facilityCoordinates
        ) else {
            return true // Include facilities if user location unavailable
        }
        
        return distance <= maxDistanceKm
    }
    
    // MARK: - Travel Time Estimation
    
    /// Estimate travel time based on distance (rough approximation)
    /// - Parameter distanceKm: Distance in kilometers
    /// - Returns: Estimated travel time string
    static func estimateTravelTime(_ distanceKm: Double?) -> String {
        guard let distanceKm = distanceKm else { return "Travel time unavailable" }
        
        // Rough estimates based on average city driving speeds
        let timeMinutes: Int
        
        if distanceKm < 1.0 {
            timeMinutes = max(5, Int(distanceKm * 10)) // 5-10 min for short distances
        } else if distanceKm < 5.0 {
            timeMinutes = Int(distanceKm * 8) // ~8 min per km for medium distances
        } else {
            timeMinutes = Int(distanceKm * 5) // ~5 min per km for longer distances
        }
        
        if timeMinutes < 60 {
            return "\(timeMinutes) min drive"
        } else {
            let hours = timeMinutes / 60
            let remainingMinutes = timeMinutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h drive"
            } else {
                return "\(hours)h \(remainingMinutes)m drive"
            }
        }
    }
}

// MARK: - Extensions

extension CLLocation {
    /// Create CLLocation from tuple coordinates
    convenience init(coordinates: (lat: Double, lng: Double)) {
        self.init(latitude: coordinates.lat, longitude: coordinates.lng)
    }
}

extension CLLocationCoordinate2D {
    /// Create coordinate from tuple
    init(coordinates: (lat: Double, lng: Double)) {
        self.init(latitude: coordinates.lat, longitude: coordinates.lng)
    }
    
    /// Convert to tuple
    var asTuple: (lat: Double, lng: Double) {
        return (lat: latitude, lng: longitude)
    }
}