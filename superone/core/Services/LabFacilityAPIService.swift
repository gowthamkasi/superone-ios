//
//  LabFacilityAPIService.swift
//  SuperOne
//
//  Created by Claude Code on 2025-01-21.
//  LabLoop Lab Facility API Integration Service
//

@preconcurrency import Foundation
@preconcurrency import Alamofire

/// Service for interacting with LabLoop facility discovery APIs
final class LabFacilityAPIService {
    
    // MARK: - Singleton
    
    static let shared = LabFacilityAPIService()
    
    // MARK: - Properties
    
    private let networkService = NetworkService.shared
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Lab Facility Discovery
    
    /// Search for lab facilities with filters
    /// - Parameters:
    ///   - query: Optional search query text
    ///   - location: User location coordinates
    ///   - radius: Search radius in kilometers
    ///   - filters: Facility search filters
    ///   - page: Page number for pagination
    ///   - limit: Number of results per page
    /// - Returns: Array of lab facilities
    func searchFacilities(
        query: String? = nil,
        location: (lat: Double, lng: Double)? = nil,
        radius: Double = 10.0,
        filters: FacilitySearchFilters? = nil,
        page: Int = 1,
        limit: Int = 10
    ) async throws -> [LabFacility] {
        
        // Build query parameters
        var queryParams: [String: String] = [
            "page": String(page),
            "limit": String(limit)
        ]
        
        // Add search query
        if let query = query, !query.isEmpty {
            queryParams["query"] = query
        }
        
        // Add location parameters
        if let location = location {
            queryParams["lat"] = String(location.lat)
            queryParams["lng"] = String(location.lng)
            queryParams["radius"] = String(radius)
        }
        
        // Add filters
        if let filters = filters {
            // Facility types
            if !filters.types.isEmpty {
                queryParams["type"] = filters.types.joined(separator: ",")
            }
            
            // Price range
            if !filters.priceRanges.isEmpty {
                queryParams["priceRange"] = filters.priceRanges.joined(separator: ",")
            }
            
            // Rating filter
            if let minRating = filters.minimumRating {
                queryParams["rating"] = String(minRating)
            }
            
            // Features
            if !filters.features.isEmpty {
                queryParams["features"] = filters.features.joined(separator: ",")
            }
            
            // Boolean filters
            if let homeCollection = filters.homeCollection {
                queryParams["homeCollection"] = String(homeCollection)
            }
            
            if let sameDay = filters.sameDay {
                queryParams["sameDay"] = String(sameDay)
            }
            
            if let is24Hours = filters.is24Hours {
                queryParams["is24Hours"] = String(is24Hours)
            }
            
            if let acceptsInsurance = filters.acceptsInsurance {
                queryParams["acceptsInsurance"] = String(acceptsInsurance)
            }
        }
        
        // Build URL with query parameters
        let url = APIConfiguration.labLoopURL(
            for: APIConfiguration.Endpoints.LabLoop.facilities,
            queryParameters: queryParams
        )
        
        do {
            // Make request to LabLoop API
            let response: LabLoopAPIResponse<LabLoopFacilitySearchResponse> = try await makeLabLoopRequest(url: url)
            
            // Check response success
            guard response.success else {
                throw LabFacilityAPIError.searchFailed(response.error?.userMessage ?? "Search failed")
            }
            
            // Convert LabLoop facilities to iOS models
            let facilities = response.data.facilities.map { $0.toLabFacility() }
            
            return facilities
            
        } catch {
            if error is LabFacilityAPIError {
                throw error
            } else {
                throw LabFacilityAPIError.networkError(error)
            }
        }
    }
    
    /// Get detailed information for a specific facility
    /// - Parameters:
    ///   - facilityId: The facility ID
    ///   - facilityType: Type of facility (hospital, lab, collection_center)
    /// - Returns: Detailed facility information
    func getFacilityDetails(facilityId: String, facilityType: FacilityType = .collectionCenter) async throws -> LabFacilityDetails {
        
        // Build URL with path parameter
        let url = APIConfiguration.labLoopURL(
            for: APIConfiguration.Endpoints.LabLoop.facilityDetails + "/\(facilityId)",
            queryParameters: ["type": facilityType.rawValue]
        )
        
        do {
            // Make request to LabLoop API
            let response: LabLoopAPIResponse<LabLoopFacilityDetails> = try await makeLabLoopRequest(url: url)
            
            // Check response success
            guard response.success else {
                throw LabFacilityAPIError.facilityNotFound(response.error?.userMessage ?? "Facility not found")
            }
            
            // Convert LabLoop facility details to iOS model
            let facilityDetails = response.data.toLabFacilityDetails()
            
            return facilityDetails
            
        } catch {
            if error is LabFacilityAPIError {
                throw error
            } else {
                throw LabFacilityAPIError.networkError(error)
            }
        }
    }
    
    /// Get available time slots for a facility
    /// - Parameters:
    ///   - facilityId: The facility ID
    ///   - date: Date to check availability (YYYY-MM-DD format)
    /// - Returns: Array of available time slots
    func getAvailableTimeSlots(facilityId: String, date: Date) async throws -> [TimeSlot] {
        
        // Format date for API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Build URL
        let url = APIConfiguration.labLoopURL(
            for: APIConfiguration.Endpoints.LabLoop.timeslots + "/\(facilityId)",
            queryParameters: ["date": dateString]
        )
        
        do {
            // Make request to LabLoop API
            let response: LabLoopAPIResponse<LabLoopTimeslotAvailability> = try await makeLabLoopRequest(url: url)
            
            // Check response success
            guard response.success else {
                throw LabFacilityAPIError.timeslotsNotAvailable(response.error?.userMessage ?? "Timeslots not available")
            }
            
            // Convert LabLoop timeslots to iOS models
            let timeSlots = response.data.slots.map { $0.toTimeSlot() }
            
            return timeSlots
            
        } catch {
            if error is LabFacilityAPIError {
                throw error
            } else {
                throw LabFacilityAPIError.networkError(error)
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Make a generic request to LabLoop API with proper error handling
    private func makeLabLoopRequest<T: Codable>(url: String) async throws -> T {
        let urlRequest = URLRequest(url: URL(string: url)!)
        
        return try await withCheckedThrowingContinuation { @Sendable continuation in
            AF.request(urlRequest)
                .validate()
                .responseData { @Sendable response in
                    switch response.result {
                    case .success(let data):
                        do {
                            nonisolated(unsafe) let decoder = JSONDecoder()
                            decoder.dateDecodingStrategy = .iso8601
                            nonisolated(unsafe) let decodedResponse = try decoder.decode(T.self, from: data)
                            continuation.resume(returning: decodedResponse)
                        } catch {
                            continuation.resume(throwing: LabFacilityAPIError.decodingError(error))
                        }
                    case .failure(let error):
                        // Map Alamofire errors to custom errors
                        let mappedError: LabFacilityAPIError
                        if let statusCode = response.response?.statusCode {
                            switch statusCode {
                            case 404:
                                mappedError = LabFacilityAPIError.facilityNotFound("Facility not found")
                            case 400:
                                mappedError = LabFacilityAPIError.invalidRequest("Invalid request parameters")
                            case 500...599:
                                mappedError = LabFacilityAPIError.serverError("Server error occurred")
                            default:
                                mappedError = LabFacilityAPIError.networkError(error)
                            }
                        } else {
                            mappedError = LabFacilityAPIError.networkError(error)
                        }
                        continuation.resume(throwing: mappedError)
                    }
                }
        }
    }
}

// MARK: - Supporting Models

/// Facility search filters for LabLoop API
struct FacilitySearchFilters {
    let types: [String]  // ["hospital", "lab", "collection_center"]
    let priceRanges: [String]  // ["$", "$$", "$$$"]
    let minimumRating: Double?
    let features: [String]  // ["Same day", "Home service", "Parking", "24/7"]
    let homeCollection: Bool?
    let sameDay: Bool?
    let is24Hours: Bool?
    let acceptsInsurance: Bool?
    
    init(
        types: [String] = [],
        priceRanges: [String] = [],
        minimumRating: Double? = nil,
        features: [String] = [],
        homeCollection: Bool? = nil,
        sameDay: Bool? = nil,
        is24Hours: Bool? = nil,
        acceptsInsurance: Bool? = nil
    ) {
        self.types = types
        self.priceRanges = priceRanges
        self.minimumRating = minimumRating
        self.features = features
        self.homeCollection = homeCollection
        self.sameDay = sameDay
        self.is24Hours = is24Hours
        self.acceptsInsurance = acceptsInsurance
    }
}

/// Facility type enumeration
enum FacilityType: String, CaseIterable {
    case hospital = "hospital"
    case lab = "lab"
    case collectionCenter = "collection_center"
    
    var displayName: String {
        switch self {
        case .hospital: return "Hospital"
        case .lab: return "Laboratory"
        case .collectionCenter: return "Collection Center"
        }
    }
}

/// Detailed facility information for iOS (mapped from LabLoop)
struct LabFacilityDetails: Sendable {
    let id: String
    let name: String
    let type: FacilityType
    let address: String
    let coordinates: (lat: Double, lng: Double)?
    let distance: Double? // in km
    let rating: Double
    let reviewCount: Int
    let priceRange: String
    let features: [String]
    let nextAvailable: String
    let workingHours: String
    let phoneNumber: String
    let email: String?
    let website: String?
    let services: [ServiceType]
    let amenities: [String]
    let certifications: [String]
    let acceptsInsurance: Bool
    let averageWaitTime: Int
    let totalTests: Int
    
    // Additional details
    let description: String
    let gallery: [String]
    let equipment: [String]
    let specializations: [String]
    let operationalStats: OperationalStats
}

/// Operational statistics for a facility
struct OperationalStats {
    let averageReportTime: Int // in hours
    let sameDay: Bool
    let homeCollection: Bool
    let onlineReports: Bool
}

// MARK: - Error Handling

/// Custom errors for Lab Facility API operations
enum LabFacilityAPIError: LocalizedError, Sendable {
    case searchFailed(String)
    case facilityNotFound(String)
    case timeslotsNotAvailable(String)
    case invalidRequest(String)
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    
    nonisolated var errorDescription: String? {
        switch self {
        case .searchFailed(let message):
            return "Facility search failed: \(message)"
        case .facilityNotFound(let message):
            return "Facility not found: \(message)"
        case .timeslotsNotAvailable(let message):
            return "Timeslots not available: \(message)"
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        }
    }
    
    nonisolated var recoverySuggestion: String? {
        switch self {
        case .searchFailed, .timeslotsNotAvailable:
            return "Please try again or adjust your search criteria."
        case .facilityNotFound:
            return "Please check the facility ID and try again."
        case .invalidRequest:
            return "Please check your request parameters."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        case .networkError:
            return "Please check your internet connection and try again."
        case .decodingError:
            return "There was an issue processing the server response. Please try again."
        }
    }
}

// MARK: - Model Extensions

extension LabLoopFacilityDetails {
    /// Convert LabLoop facility details to iOS model
    func toLabFacilityDetails() -> LabFacilityDetails {
        let facilityType = FacilityType(rawValue: self.type) ?? .collectionCenter
        let coordinates = self.address.coordinates.map { ($0.lat, $0.lng) }
        
        return LabFacilityDetails(
            id: self.id,
            name: self.name,
            type: facilityType,
            address: "\(self.address.street), \(self.address.city), \(self.address.state) \(self.address.zipCode)",
            coordinates: coordinates,
            distance: self.distance,
            rating: self.rating,
            reviewCount: self.reviewCount,
            priceRange: self.priceRange,
            features: self.features,
            nextAvailable: self.nextAvailable,
            workingHours: "\(self.workingHours.open) - \(self.workingHours.close)",
            phoneNumber: self.contactInfo.phone,
            email: self.contactInfo.email,
            website: self.contactInfo.website,
            services: self.services.compactMap { ServiceType.from(string: $0) },
            amenities: self.amenities,
            certifications: self.certifications,
            acceptsInsurance: self.acceptsInsurance,
            averageWaitTime: self.averageWaitTime,
            totalTests: self.totalTests,
            description: self.description,
            gallery: self.gallery,
            equipment: self.equipment,
            specializations: self.specializations,
            operationalStats: OperationalStats(
                averageReportTime: self.operationalStats.averageReportTime,
                sameDay: self.operationalStats.sameDay,
                homeCollection: self.operationalStats.homeCollection,
                onlineReports: self.operationalStats.onlineReports
            )
        )
    }
}