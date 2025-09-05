//
//  AppointmentAPIService.swift
//  SuperOne
//
//  Created by Claude Code on 2025-01-21.
//  LabLoop Appointment API Integration Service
//

@preconcurrency import Foundation
@preconcurrency import Alamofire

/// Service for interacting with LabLoop appointment booking APIs
final class AppointmentAPIService {
    
    // MARK: - Singleton
    
    static let shared = AppointmentAPIService()
    
    // MARK: - Properties
    
    private let networkService = NetworkService.shared
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Appointment Management
    
    /// Get user appointments from LabLoop
    /// - Parameters:
    ///   - userId: User ID to fetch appointments for
    ///   - status: Optional status filter
    ///   - offset: Number of records to skip (default: 0)
    ///   - limit: Number of results per page
    /// - Returns: Array of appointments
    func getUserAppointments(
        userId: String,
        status: AppointmentStatus? = nil,
        offset: Int = 0,
        limit: Int = 10
    ) async throws -> [Appointment] {
        
        // Build query parameters
        var queryParams: [String: String] = [
            "userId": userId,
            "offset": String(offset),
            "limit": String(limit)
        ]
        
        // Add status filter if provided
        if let status = status {
            queryParams["status"] = status.labloopString
        }
        
        // Build URL with query parameters
        let url = APIConfiguration.labLoopURL(
            for: APIConfiguration.Endpoints.LabLoop.appointments,
            queryParameters: queryParams
        )
        
        do {
            // Make request to LabLoop API
            let response: LabLoopAPIResponse<[LabLoopAppointment]> = try await makeLabLoopRequest(url: url)
            
            // Check response success
            guard response.success else {
                throw AppointmentAPIError.fetchFailed(response.error?.userMessage ?? "Failed to fetch appointments")
            }
            
            // Convert LabLoop appointments to iOS models
            let appointments = response.data.map { $0.toAppointment() }
            
            return appointments
            
        } catch {
            if error is AppointmentAPIError {
                throw error
            } else {
                throw AppointmentAPIError.networkError(error)
            }
        }
    }
    
    /// Book a new appointment
    /// - Parameters:
    ///   - facilityId: The facility to book with
    ///   - serviceType: Type of service (visit_lab or home_collection)
    ///   - appointmentDate: Date for the appointment
    ///   - timeSlot: Selected time slot
    ///   - requestedTests: Array of test IDs
    ///   - patientInfo: Patient information
    ///   - homeAddress: Home address (required for home collection)
    ///   - notes: Optional notes
    ///   - userId: User ID for booking
    /// - Returns: Booking confirmation details
    func bookAppointment(
        facilityId: String,
        serviceType: AppointmentType,
        appointmentDate: Date,
        timeSlot: TimeSlot,
        requestedTests: [String],
        patientInfo: PatientBookingInfo,
        homeAddress: HomeCollectionAddress? = nil,
        notes: String? = nil,
        userId: String
    ) async throws -> AppointmentBookingResult {
        
        // Format date for API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: appointmentDate)
        
        // Create booking request
        let bookingRequest = LabLoopAppointmentBookingRequest(
            facilityId: facilityId,
            serviceType: serviceType.labloopString,
            appointmentDate: dateString,
            timeSlot: timeSlot.startTime,
            requestedTests: requestedTests,
            patientInfo: LabLoopPatientInfo(
                name: patientInfo.name,
                phone: patientInfo.phone,
                email: patientInfo.email,
                dateOfBirth: patientInfo.dateOfBirthString,
                gender: patientInfo.gender.rawValue
            ),
            homeCollectionAddress: homeAddress?.toLabLoopHomeAddress(),
            notes: notes,
            preferredCollector: nil
        )
        
        // Build URL
        let url = APIConfiguration.labLoopURL(for: APIConfiguration.Endpoints.LabLoop.bookAppointment)
        
        do {
            // Make POST request to LabLoop API
            let response: LabLoopAPIResponse<LabLoopAppointmentBookingResponse> = try await makeLabLoopBookingRequest(
                url: url,
                body: bookingRequest,
                userId: userId
            )
            
            // Check response success
            guard response.success else {
                throw AppointmentAPIError.bookingFailed(response.error?.userMessage ?? "Failed to book appointment")
            }
            
            // Convert booking response to iOS model
            let bookingResult = response.data.toAppointmentBookingResult()
            
            return bookingResult
            
        } catch {
            if error is AppointmentAPIError {
                throw error
            } else {
                throw AppointmentAPIError.networkError(error)
            }
        }
    }
    
    /// Cancel an appointment
    /// - Parameters:
    ///   - appointmentId: ID of the appointment to cancel
    ///   - userId: User ID
    ///   - reason: Optional cancellation reason
    /// - Returns: Success confirmation
    func cancelAppointment(
        appointmentId: String,
        userId: String,
        reason: String? = nil
    ) async throws -> Bool {
        
        // Build URL for cancellation (typically a PUT or DELETE request)
        let url = APIConfiguration.labLoopURL(
            for: APIConfiguration.Endpoints.LabLoop.appointments + "/\(appointmentId)/cancel"
        )
        
        // Create cancellation request body
        let cancellationRequest = AppointmentCancellationRequest(
            userId: userId,
            reason: reason
        )
        
        do {
            // Make request to LabLoop API
            let response: LabLoopAPIResponse<AppointmentCancellationResponse> = try await makeLabLoopBookingRequest(
                url: url,
                body: cancellationRequest,
                userId: userId,
                method: .put
            )
            
            // Check response success
            guard response.success else {
                throw AppointmentAPIError.cancellationFailed(response.error?.userMessage ?? "Failed to cancel appointment")
            }
            
            return response.data.cancelled
            
        } catch {
            if error is AppointmentAPIError {
                throw error
            } else {
                throw AppointmentAPIError.networkError(error)
            }
        }
    }
    
    /// Reschedule an appointment
    /// - Parameters:
    ///   - appointmentId: ID of the appointment to reschedule
    ///   - newDate: New appointment date
    ///   - newTimeSlot: New time slot
    ///   - userId: User ID
    /// - Returns: Updated appointment details
    func rescheduleAppointment(
        appointmentId: String,
        newDate: Date,
        newTimeSlot: TimeSlot,
        userId: String
    ) async throws -> Appointment {
        
        // Format date for API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: newDate)
        
        // Build URL for rescheduling
        let url = APIConfiguration.labLoopURL(
            for: APIConfiguration.Endpoints.LabLoop.appointments + "/\(appointmentId)/reschedule"
        )
        
        // Create reschedule request body
        let rescheduleRequest = AppointmentRescheduleRequest(
            newDate: dateString,
            newTimeSlot: newTimeSlot.startTime,
            userId: userId
        )
        
        do {
            // Make request to LabLoop API
            let response: LabLoopAPIResponse<LabLoopAppointment> = try await makeLabLoopBookingRequest(
                url: url,
                body: rescheduleRequest,
                userId: userId,
                method: .put
            )
            
            // Check response success
            guard response.success else {
                throw AppointmentAPIError.rescheduleFailed(response.error?.userMessage ?? "Failed to reschedule appointment")
            }
            
            // Convert to iOS appointment model
            let appointment = response.data.toAppointment()
            
            return appointment
            
        } catch {
            if error is AppointmentAPIError {
                throw error
            } else {
                throw AppointmentAPIError.networkError(error)
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Make a generic GET request to LabLoop API
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
                            decoder.dateDecodingStrategy = .custom(NetworkService.robustISO8601DateDecoder)
                            nonisolated(unsafe) let decodedResponse = try decoder.decode(T.self, from: data)
                            continuation.resume(returning: decodedResponse)
                        } catch {
                            continuation.resume(throwing: AppointmentAPIError.decodingError(error))
                        }
                    case .failure(let error):
                        nonisolated(unsafe) let service = self
                        let mappedError = service.mapAlamofireError(error, statusCode: response.response?.statusCode)
                        continuation.resume(throwing: mappedError)
                    }
                }
        }
    }
    
    /// Make a POST/PUT request to LabLoop API with body
    private func makeLabLoopBookingRequest<T: Codable, U: Codable>(
        url: String,
        body: U,
        userId: String,
        method: Alamofire.HTTPMethod = .post
    ) async throws -> T {
        
        var mutableUrlRequest = URLRequest(url: URL(string: url)!)
        mutableUrlRequest.httpMethod = method.rawValue
        mutableUrlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableUrlRequest.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        // Encode request body
        do {
            let jsonData = try JSONEncoder().encode(body)
            mutableUrlRequest.httpBody = jsonData
        } catch {
            throw AppointmentAPIError.encodingError(error)
        }
        
        let urlRequest = mutableUrlRequest // Make immutable copy for closure
        
        return try await withCheckedThrowingContinuation { @Sendable continuation in
            AF.request(urlRequest)
                .validate()
                .responseData { @Sendable response in
                    switch response.result {
                    case .success(let data):
                        do {
                            nonisolated(unsafe) let decoder = JSONDecoder()
                            decoder.dateDecodingStrategy = .custom(NetworkService.robustISO8601DateDecoder)
                            nonisolated(unsafe) let decodedResponse = try decoder.decode(T.self, from: data)
                            continuation.resume(returning: decodedResponse)
                        } catch {
                            continuation.resume(throwing: AppointmentAPIError.decodingError(error))
                        }
                    case .failure(let error):
                        nonisolated(unsafe) let service = self
                        let mappedError = service.mapAlamofireError(error, statusCode: response.response?.statusCode)
                        continuation.resume(throwing: mappedError)
                    }
                }
        }
    }
    
    /// Map Alamofire errors to custom appointment errors
    nonisolated private func mapAlamofireError(_ error: AFError, statusCode: Int?) -> AppointmentAPIError {
        if let statusCode = statusCode {
            switch statusCode {
            case 400:
                return .invalidRequest("Invalid appointment request")
            case 401:
                return .authenticationRequired("Authentication required")
            case 404:
                return .appointmentNotFound("Appointment not found")
            case 409:
                return .conflictError("Appointment time slot no longer available")
            case 422:
                return .validationError("Invalid appointment data")
            case 500...599:
                return .serverError("Server error occurred")
            default:
                return .networkError(error)
            }
        } else {
            return .networkError(error)
        }
    }
}

// MARK: - Supporting Models

/// Appointment type for booking
enum AppointmentType: String, CaseIterable {
    case visitLab = "visit_lab"
    case homeCollection = "home_collection"
    
    var displayName: String {
        switch self {
        case .visitLab: return "Visit Lab"
        case .homeCollection: return "Home Collection"
        }
    }
    
    var labloopString: String {
        return self.rawValue
    }
}

/// Patient information for appointment booking
struct PatientBookingInfo {
    let name: String
    let phone: String
    let email: String
    let dateOfBirth: Date
    let gender: Gender
    
    var dateOfBirthString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: dateOfBirth)
    }
}

/// Home collection address information
struct HomeCollectionAddress {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let specialInstructions: String?
    
    func toLabLoopHomeAddress() -> LabLoopHomeAddress {
        return LabLoopHomeAddress(
            street: street,
            city: city,
            state: state,
            zipCode: zipCode,
            specialInstructions: specialInstructions
        )
    }
}

/// Appointment booking result
struct AppointmentBookingResult: Sendable {
    let appointment: Appointment
    let confirmationNumber: String
    let estimatedCost: Double
    let paymentRequired: Bool
    let nextSteps: [String]
}

/// Internal request models for API calls
private struct AppointmentCancellationRequest: Codable, Sendable {
    let userId: String
    let reason: String?
}

private struct AppointmentCancellationResponse: Codable, @unchecked Sendable {
    let cancelled: Bool
    let message: String?
}

private struct AppointmentRescheduleRequest: Codable, Sendable {
    let newDate: String
    let newTimeSlot: String
    let userId: String
}

// MARK: - Error Handling

/// Custom errors for Appointment API operations
enum AppointmentAPIError: LocalizedError, Sendable {
    case fetchFailed(String)
    case bookingFailed(String)
    case cancellationFailed(String)
    case rescheduleFailed(String)
    case appointmentNotFound(String)
    case invalidRequest(String)
    case authenticationRequired(String)
    case conflictError(String)
    case validationError(String)
    case serverError(String)
    case networkError(Error)
    case encodingError(Error)
    case decodingError(Error)
    
    nonisolated var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to fetch appointments: \(message)"
        case .bookingFailed(let message):
            return "Appointment booking failed: \(message)"
        case .cancellationFailed(let message):
            return "Failed to cancel appointment: \(message)"
        case .rescheduleFailed(let message):
            return "Failed to reschedule appointment: \(message)"
        case .appointmentNotFound(let message):
            return "Appointment not found: \(message)"
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .authenticationRequired(let message):
            return "Authentication required: \(message)"
        case .conflictError(let message):
            return "Scheduling conflict: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Request encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Response parsing error: \(error.localizedDescription)"
        }
    }
    
    nonisolated var recoverySuggestion: String? {
        switch self {
        case .fetchFailed, .bookingFailed, .cancellationFailed, .rescheduleFailed:
            return "Please try again or contact support if the problem persists."
        case .appointmentNotFound:
            return "Please check the appointment details and try again."
        case .invalidRequest, .validationError:
            return "Please check your input and try again."
        case .authenticationRequired:
            return "Please log in again and try again."
        case .conflictError:
            return "Please select a different time slot."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        case .networkError:
            return "Please check your internet connection and try again."
        case .encodingError, .decodingError:
            return "There was an issue processing the request. Please try again."
        }
    }
}

// MARK: - Model Extensions

extension LabLoopAppointmentBookingResponse {
    /// Convert LabLoop booking response to iOS model
    func toAppointmentBookingResult() -> AppointmentBookingResult {
        return AppointmentBookingResult(
            appointment: self.appointment.toAppointment(),
            confirmationNumber: self.confirmationNumber,
            estimatedCost: self.estimatedCost,
            paymentRequired: self.paymentRequired,
            nextSteps: self.nextSteps
        )
    }
}