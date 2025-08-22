//
//  LabLoopModels.swift
//  SuperOne
//
//  Created by Claude Code on 2025-01-21.
//  LabLoop API Integration Models
//

@preconcurrency import Foundation

// MARK: - LabLoop API Response Models

/// Standard LabLoop Mobile API response wrapper
struct LabLoopAPIResponse<T: Codable>: Codable, @unchecked Sendable {
    let success: Bool
    let data: T
    let message: String?
    let timestamp: String
    let error: LabLoopError?
    let pagination: LabLoopPagination?
}

/// LabLoop API error structure
struct LabLoopError: Codable, Sendable {
    let code: String
    let message: String
    let userMessage: String
    let retryable: Bool
    let actions: [LabLoopErrorAction]?
}

/// LabLoop API error action
struct LabLoopErrorAction: Codable, Sendable {
    let type: String // "retry", "login", "contact_support"
    let label: String
}

/// LabLoop API pagination
struct LabLoopPagination: Codable, Sendable {
    let page: Int
    let limit: Int
    let total: Int
    let hasMore: Bool
    
    nonisolated enum CodingKeys: String, CodingKey {
        case page, limit, total
        case hasMore = "has_more"
    }
}

// MARK: - LabLoop Facility Models

/// LabLoop facility from API
struct LabLoopFacility: Codable, Sendable {
    let id: String
    let name: String
    let type: String // "hospital", "lab", "collection_center"
    let address: LabLoopAddress
    let distance: Double? // Distance from user location in km
    let rating: Double // Average rating (0-5)
    let reviewCount: Int
    let priceRange: String // "$", "$$", "$$$"
    let features: [String] // ["Same day", "Home service", "Parking", "24/7"]
    let nextAvailable: String // "Tomorrow 9AM", "Today 2PM"
    let workingHours: LabLoopWorkingHours
    let contactInfo: LabLoopContactInfo
    let services: [String] // Available test categories
    let amenities: [String] // ["Parking", "Wheelchair accessible", "WiFi"]
    let certifications: [String] // ["NABL", "CAP", "ISO"]
    let thumbnail: String? // Base64 or URL
    let isVerified: Bool
    let acceptsInsurance: Bool
    let homeCollectionAvailable: Bool
    let averageWaitTime: Int // in minutes
    let totalTests: Int // number of tests conducted
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, type, address, distance, rating
        case reviewCount = "review_count"
        case priceRange = "price_range"
        case features
        case nextAvailable = "next_available"
        case workingHours = "working_hours"
        case contactInfo = "contact_info"
        case services, amenities, certifications, thumbnail
        case isVerified = "is_verified"
        case acceptsInsurance = "accepts_insurance"
        case homeCollectionAvailable = "home_collection_available"
        case averageWaitTime = "average_wait_time"
        case totalTests = "total_tests"
    }
}

/// LabLoop facility address
struct LabLoopAddress: Codable, Sendable {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let coordinates: LabLoopCoordinates?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case street, city, state
        case zipCode = "zip_code"
        case coordinates
    }
}

/// LabLoop coordinates
struct LabLoopCoordinates: Codable, Sendable {
    let lat: Double
    let lng: Double
}

/// LabLoop working hours
struct LabLoopWorkingHours: Codable, Sendable {
    let open: String
    let close: String
    let days: [String]
    let is24Hours: Bool
    
    nonisolated enum CodingKeys: String, CodingKey {
        case open, close, days
        case is24Hours = "is24_hours"
    }
}

/// LabLoop contact info
struct LabLoopContactInfo: Codable, Sendable {
    let phone: String
    let email: String?
    let website: String?
}

/// LabLoop facility search response
struct LabLoopFacilitySearchResponse: Codable, @unchecked Sendable {
    let facilities: [LabLoopFacility]
    let totalCount: Int
    let searchRadius: Double
    let userLocation: LabLoopUserLocation?
    let suggestedFilters: LabLoopSuggestedFilters
    
    nonisolated enum CodingKeys: String, CodingKey {
        case facilities
        case totalCount = "total_count"
        case searchRadius = "search_radius"
        case userLocation = "user_location"
        case suggestedFilters = "suggested_filters"
    }
}

/// LabLoop user location
struct LabLoopUserLocation: Codable, Sendable {
    let lat: Double
    let lng: Double
    let address: String
}

/// LabLoop suggested filters
struct LabLoopSuggestedFilters: Codable, Sendable {
    let type: [LabLoopFilterOption]
    let priceRange: [LabLoopFilterOption]
    let features: [LabLoopFilterOption]
    
    nonisolated enum CodingKeys: String, CodingKey {
        case type
        case priceRange = "price_range"
        case features
    }
}

/// LabLoop filter option
struct LabLoopFilterOption: Codable, Sendable {
    let value: String
    let count: Int
    let label: String
}

/// LabLoop facility details (extended from facility)
struct LabLoopFacilityDetails: Codable, @unchecked Sendable {
    let id: String
    let name: String
    let type: String
    let address: LabLoopAddress
    let distance: Double?
    let rating: Double
    let reviewCount: Int
    let priceRange: String
    let features: [String]
    let nextAvailable: String
    let workingHours: LabLoopWorkingHours
    let contactInfo: LabLoopContactInfo
    let services: [String]
    let amenities: [String]
    let certifications: [String]
    let thumbnail: String?
    let isVerified: Bool
    let acceptsInsurance: Bool
    let homeCollectionAvailable: Bool
    let averageWaitTime: Int
    let totalTests: Int
    
    // Additional details
    let description: String
    let gallery: [String] // Array of image URLs
    let equipment: [String]
    let specializations: [String]
    let doctors: [LabLoopDoctor]
    let recentReviews: [LabLoopReview]
    let priceList: [LabLoopTestPrice]
    let operationalStats: LabLoopOperationalStats
    let socialMedia: LabLoopSocialMedia?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, type, address, distance, rating
        case reviewCount = "review_count"
        case priceRange = "price_range"
        case features
        case nextAvailable = "next_available"
        case workingHours = "working_hours"
        case contactInfo = "contact_info"
        case services, amenities, certifications, thumbnail
        case isVerified = "is_verified"
        case acceptsInsurance = "accepts_insurance"
        case homeCollectionAvailable = "home_collection_available"
        case averageWaitTime = "average_wait_time"
        case totalTests = "total_tests"
        case description, gallery, equipment, specializations, doctors
        case recentReviews = "recent_reviews"
        case priceList = "price_list"
        case operationalStats = "operational_stats"
        case socialMedia = "social_media"
    }
}

/// LabLoop doctor
struct LabLoopDoctor: Codable, Sendable {
    let id: String
    let name: String
    let specialization: String
    let experience: Int
}

/// LabLoop review
struct LabLoopReview: Codable, Sendable {
    let id: String
    let patientName: String
    let rating: Int
    let comment: String
    let date: String
    let verified: Bool
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case patientName = "patient_name"
        case rating, comment, date, verified
    }
}

/// LabLoop test price
struct LabLoopTestPrice: Codable, Sendable {
    let testId: String
    let testName: String
    let category: String
    let price: Double
    let discountedPrice: Double?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case testId = "test_id"
        case testName = "test_name"
        case category, price
        case discountedPrice = "discounted_price"
    }
}

/// LabLoop operational stats
struct LabLoopOperationalStats: Codable, Sendable {
    let averageReportTime: Int // in hours
    let sameDay: Bool
    let homeCollection: Bool
    let onlineReports: Bool
    
    nonisolated enum CodingKeys: String, CodingKey {
        case averageReportTime = "average_report_time"
        case sameDay = "same_day"
        case homeCollection = "home_collection"
        case onlineReports = "online_reports"
    }
}

/// LabLoop social media
struct LabLoopSocialMedia: Codable, Sendable {
    let facebook: String?
    let twitter: String?
    let linkedin: String?
}

// MARK: - LabLoop Appointment Models

/// LabLoop appointment from API
struct LabLoopAppointment: Codable, @unchecked Sendable {
    let id: String
    let appointmentId: String
    let appointmentDate: String
    let timeSlot: String
    let status: String // 'scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled'
    let appointmentType: String // 'visit_lab', 'home_collection'
    let facility: LabLoopAppointmentFacility
    let tests: [LabLoopAppointmentTest]
    let patient: LabLoopAppointmentPatient
    let collector: LabLoopCollector?
    let totalCost: Double
    let estimatedDuration: Int // in minutes
    let specialInstructions: String?
    let homeAddress: String? // for home collection
    let canReschedule: Bool
    let canCancel: Bool
    let createdAt: String
    let updatedAt: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case appointmentId = "appointment_id"
        case appointmentDate = "appointment_date"
        case timeSlot = "time_slot"
        case status
        case appointmentType = "appointment_type"
        case facility, tests, patient, collector
        case totalCost = "total_cost"
        case estimatedDuration = "estimated_duration"
        case specialInstructions = "special_instructions"
        case homeAddress = "home_address"
        case canReschedule = "can_reschedule"
        case canCancel = "can_cancel"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// LabLoop appointment facility info
struct LabLoopAppointmentFacility: Codable, Sendable {
    let id: String
    let name: String
    let type: String
    let address: String
    let phone: String
    let distance: Double?
}

/// LabLoop appointment test
struct LabLoopAppointmentTest: Codable, Sendable {
    let id: String
    let name: String
    let category: String
    let price: Double
}

/// LabLoop appointment patient
struct LabLoopAppointmentPatient: Codable, Sendable {
    let id: String
    let name: String
    let phone: String
    let age: Int
    let gender: String
}

/// LabLoop collector
struct LabLoopCollector: Codable, Sendable {
    let id: String
    let name: String
    let phone: String
    let rating: Double
}

/// LabLoop timeslot
struct LabLoopTimeslot: Codable, Sendable {
    let time: String // HH:MM format
    let date: String // YYYY-MM-DD format
    let available: Bool
    let price: Double? // Special pricing for time slot
    let duration: Int // in minutes
    let maxCapacity: Int
    let currentBookings: Int
    let facilityId: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case time, date, available, price, duration
        case maxCapacity = "max_capacity"
        case currentBookings = "current_bookings"
        case facilityId = "facility_id"
    }
}

/// LabLoop timeslot availability response
struct LabLoopTimeslotAvailability: Codable, @unchecked Sendable {
    let facilityId: String
    let facilityName: String
    let date: String
    let slots: [LabLoopTimeslot]
    let specialOffers: [LabLoopSpecialOffer]?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case facilityId = "facility_id"
        case facilityName = "facility_name"
        case date, slots
        case specialOffers = "special_offers"
    }
}

/// LabLoop special offer
struct LabLoopSpecialOffer: Codable, Sendable {
    let id: String
    let title: String
    let description: String
    let discount: Double
    let validUntil: String
    
    nonisolated enum CodingKeys: String, CodingKey {
        case id, title, description, discount
        case validUntil = "valid_until"
    }
}

/// LabLoop appointment booking request
struct LabLoopAppointmentBookingRequest: Codable, Sendable {
    let facilityId: String
    let serviceType: String // "visit_lab" | "home_collection"
    let appointmentDate: String
    let timeSlot: String
    let requestedTests: [String]
    let patientInfo: LabLoopPatientInfo
    let homeCollectionAddress: LabLoopHomeAddress?
    let notes: String?
    let preferredCollector: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case facilityId = "facility_id"
        case serviceType = "service_type"
        case appointmentDate = "appointment_date"
        case timeSlot = "time_slot"
        case requestedTests = "requested_tests"
        case patientInfo = "patient_info"
        case homeCollectionAddress = "home_collection_address"
        case notes
        case preferredCollector = "preferred_collector"
    }
}

/// LabLoop patient info for booking
struct LabLoopPatientInfo: Codable, Sendable {
    let name: String
    let phone: String
    let email: String
    let dateOfBirth: String
    let gender: String // 'male' | 'female' | 'other'
    
    nonisolated enum CodingKeys: String, CodingKey {
        case name, phone, email
        case dateOfBirth = "date_of_birth"
        case gender
    }
}

/// LabLoop home collection address
struct LabLoopHomeAddress: Codable, Sendable {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let specialInstructions: String?
    
    nonisolated enum CodingKeys: String, CodingKey {
        case street, city, state
        case zipCode = "zip_code"
        case specialInstructions = "special_instructions"
    }
}

/// LabLoop appointment booking response
struct LabLoopAppointmentBookingResponse: Codable, @unchecked Sendable {
    let appointment: LabLoopAppointment
    let confirmationNumber: String
    let estimatedCost: Double
    let paymentRequired: Bool
    let nextSteps: [String]
    
    nonisolated enum CodingKeys: String, CodingKey {
        case appointment
        case confirmationNumber = "confirmation_number"
        case estimatedCost = "estimated_cost"
        case paymentRequired = "payment_required"
        case nextSteps = "next_steps"
    }
}

// MARK: - Model Conversion Extensions

extension LabLoopFacility {
    /// Convert LabLoop facility to iOS LabFacility model
    func toLabFacility() -> LabFacility {
        return LabFacility(
            id: self.id,
            name: self.name,
            location: "\(self.address.city), \(self.address.state)",
            services: self.services.compactMap { ServiceType.from(string: $0) },
            rating: self.rating,
            reviewCount: self.reviewCount,
            estimatedWaitTime: self.averageWaitTime,
            operatingHours: "\(self.workingHours.open) - \(self.workingHours.close)",
            phoneNumber: self.contactInfo.phone,
            acceptsInsurance: self.acceptsInsurance,
            acceptsWalkIns: true // Default to true for LabLoop facilities
        )
    }
}

extension LabLoopAppointment {
    /// Convert LabLoop appointment to iOS Appointment model
    func toAppointment() -> Appointment {
        // Parse date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: self.appointmentDate) ?? Date()
        
        // Create TimeSlot
        let timeSlot = TimeSlot(
            startTime: self.timeSlot,
            endTime: self.timeSlot, // LabLoop uses single time, iOS expects range
            isAvailable: true
        )
        
        // Map status
        let mappedStatus = AppointmentStatus.from(labloopStatus: self.status)
        
        // Map service type
        let mappedServiceType = ServiceType.from(labloopType: self.appointmentType)
        
        return Appointment(
            id: self.id,
            facilityName: self.facility.name,
            facilityId: self.facility.id,
            date: date,
            timeSlot: timeSlot,
            serviceType: mappedServiceType,
            status: mappedStatus,
            location: self.facility.address,
            notes: self.specialInstructions
        )
    }
}

extension LabLoopTimeslot {
    /// Convert LabLoop timeslot to iOS TimeSlot model
    func toTimeSlot() -> TimeSlot {
        // Calculate end time (add duration to start time)
        let startComponents = self.time.split(separator: ":")
        guard startComponents.count == 2,
              let startHour = Int(startComponents[0]),
              let startMinute = Int(startComponents[1]) else {
            return TimeSlot(startTime: self.time, endTime: self.time, isAvailable: self.available)
        }
        
        let totalMinutes = startHour * 60 + startMinute + self.duration
        let endHour = totalMinutes / 60
        let endMinute = totalMinutes % 60
        let endTime = String(format: "%02d:%02d", endHour, endMinute)
        
        return TimeSlot(
            startTime: self.time,
            endTime: endTime,
            isAvailable: self.available
        )
    }
}

// MARK: - Enum Mapping Extensions

extension ServiceType {
    static func from(string: String) -> ServiceType? {
        switch string.lowercased() {
        case "blood_work", "blood work": return .bloodWork
        case "urinalysis": return .urinalysis
        case "lipid_panel", "lipid panel": return .lipidPanel
        case "metabolic_panel", "metabolic panel": return .metabolicPanel
        case "thyroid_function", "thyroid function": return .thyroidFunction
        case "diabetic_panel", "diabetic panel": return .diabeticPanel
        case "hormonal_panel", "hormonal panel": return .hormonalPanel
        case "allergy_panel", "allergy panel": return .allergyPanel
        case "inflammatory_markers", "inflammatory markers": return .inflammatoryMarkers
        case "tumor_markers", "tumor markers": return .tumorMarkers
        case "imaging": return .imaging
        case "consultation": return .consultation
        case "vaccination": return .vaccination
        case "physical_exam", "physical exam": return .physicalExam
        default: return .other
        }
    }
    
    static func from(labloopType: String) -> ServiceType {
        switch labloopType {
        case "visit_lab": return .bloodWork // Default for lab visits
        case "home_collection": return .bloodWork // Default for home collection
        default: return .bloodWork
        }
    }
    
    var labloopString: String {
        switch self {
        case .bloodWork: return "blood_work"
        case .urinalysis: return "urinalysis"
        case .lipidPanel: return "lipid_panel"
        case .metabolicPanel: return "metabolic_panel"
        case .thyroidFunction: return "thyroid_function"
        case .diabeticPanel: return "diabetic_panel"
        case .hormonalPanel: return "hormonal_panel"
        case .allergyPanel: return "allergy_panel"
        case .inflammatoryMarkers: return "inflammatory_markers"
        case .tumorMarkers: return "tumor_markers"
        case .imaging: return "imaging"
        case .consultation: return "consultation"
        case .vaccination: return "vaccination"
        case .physicalExam: return "physical_exam"
        case .other: return "other"
        }
    }
}

extension AppointmentStatus {
    static func from(labloopStatus: String) -> AppointmentStatus {
        switch labloopStatus {
        case "scheduled": return .scheduled
        case "confirmed": return .confirmed
        case "in_progress": return .inProgress
        case "completed": return .completed
        case "cancelled": return .cancelled
        default: return .pending
        }
    }
    
    var labloopString: String {
        switch self {
        case .pending: return "pending"
        case .scheduled: return "scheduled"
        case .confirmed: return "confirmed"
        case .checkedIn: return "confirmed"
        case .inProgress: return "in_progress"
        case .completed: return "completed"
        case .cancelled: return "cancelled"
        case .noShow: return "cancelled"
        case .rescheduled: return "scheduled"
        }
    }
}