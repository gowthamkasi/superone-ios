//
//  LabLoopTestInterface.swift
//  SuperOne
//
//  Created by Claude Code on 2025-01-21.
//  Manual testing interface for LabLoop API integration
//

import SwiftUI

/// Manual testing interface for LabLoop APIs
struct LabLoopTestInterface: View {
    @StateObject private var testRunner = LabLoopAPIIntegrationTest()
    @State private var selectedEndpoint = 0
    @State private var testParameters = TestParameters()
    @State private var showingResults = false
    @State private var isRunningManualTest = false
    @State private var manualTestResult: String = ""
    
    let endpoints = [
        "Search Facilities",
        "Facility Details", 
        "Available Time Slots",
        "User Appointments",
        "Booking Validation"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Text("LabLoop API Test Interface")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Manual testing for all LabLoop endpoints")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Endpoint Selection
                    EndpointSelectorView(
                        selectedEndpoint: $selectedEndpoint,
                        endpoints: endpoints
                    )
                    
                    // Test Parameters Input
                    TestParametersView(
                        selectedEndpoint: selectedEndpoint,
                        parameters: $testParameters
                    )
                    
                    // Action Buttons
                    ActionButtonsView(
                        selectedEndpoint: selectedEndpoint,
                        parameters: testParameters,
                        isRunningTest: $isRunningManualTest,
                        testResult: $manualTestResult,
                        onRunTest: runManualTest
                    )
                    
                    // Manual Test Results
                    if !manualTestResult.isEmpty {
                        ManualTestResultView(result: manualTestResult)
                    }
                    
                    // Integration Test Results
                    if !testRunner.testResults.isEmpty {
                        IntegrationTestResultsView(testRunner: testRunner)
                    }
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingResults) {
            LabLoopIntegrationTestView()
        }
    }
    
    private func runManualTest(endpoint: String) {
        isRunningManualTest = true
        manualTestResult = ""
        
        Task {
            do {
                let result = try await executeManualTest(endpoint: endpoint)
                await MainActor.run {
                    manualTestResult = result
                    isRunningManualTest = false
                }
            } catch {
                await MainActor.run {
                    manualTestResult = "❌ Error: \(error.localizedDescription)"
                    isRunningManualTest = false
                }
            }
        }
    }
    
    private func executeManualTest(endpoint: String) async throws -> String {
        let facilityService = LabFacilityAPIService.shared
        let appointmentService = AppointmentAPIService.shared
        
        switch endpoint {
        case "Search Facilities":
            let location = testParameters.useLocation ? 
                (lat: testParameters.latitude, lng: testParameters.longitude) : nil
            
            let filters = testParameters.applyFilters ? FacilitySearchFilters(
                types: testParameters.facilityTypes,
                acceptsInsurance: testParameters.acceptsInsurance
            ) : nil
            
            let facilities = try await facilityService.searchFacilities(
                query: testParameters.searchQuery.isEmpty ? nil : testParameters.searchQuery,
                location: location,
                radius: testParameters.searchRadius,
                filters: filters,
                limit: testParameters.resultLimit
            )
            
            let summary = facilities.prefix(3).map { "• \($0.name) - \($0.rating)⭐" }.joined(separator: "\n")
            return "✅ Found \(facilities.count) facilities:\n\(summary)"
            
        case "Facility Details":
            // First get a facility to test with
            let facilities = try await facilityService.searchFacilities(limit: 1)
            guard let facility = facilities.first else {
                throw TestError.noResults("No facilities available")
            }
            
            let details = try await facilityService.getFacilityDetails(facilityId: facility.id)
            return "✅ Facility Details for '\(details.name)':\n• Rating: \(details.rating)/5.0\n• Services: \(details.services.count)\n• Amenities: \(details.amenities.count)\n• Phone: \(details.phoneNumber)"
            
        case "Available Time Slots":
            // First get a facility to test with
            let facilities = try await facilityService.searchFacilities(limit: 1)
            guard let facility = facilities.first else {
                throw TestError.noResults("No facilities available")
            }
            
            let testDate = testParameters.useCustomDate ? testParameters.selectedDate : Date()
            let timeSlots = try await facilityService.getAvailableTimeSlots(
                facilityId: facility.id,
                date: testDate
            )
            
            let availableSlots = timeSlots.filter { $0.isAvailable }
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            return "✅ Time Slots for \(facility.name) on \(dateFormatter.string(from: testDate)):\n• Total slots: \(timeSlots.count)\n• Available: \(availableSlots.count)\n• Example slots: \(availableSlots.prefix(3).map { $0.startTime }.joined(separator: ", "))"
            
        case "User Appointments":
            let appointments = try await appointmentService.getUserAppointments(
                userId: testParameters.testUserId
            )
            return "✅ User Appointments for ID '\(testParameters.testUserId)':\n• Found: \(appointments.count) appointments\n• Status distribution: \(getAppointmentStatusSummary(appointments))"
            
        case "Booking Validation":
            // Create test patient info
            let patientInfo = PatientBookingInfo(
                name: testParameters.patientName,
                phone: testParameters.patientPhone,
                email: testParameters.patientEmail,
                dateOfBirth: testParameters.patientDOB,
                gender: testParameters.patientGender
            )
            
            // Validate all required fields
            let validations = [
                ("Name", !patientInfo.name.isEmpty),
                ("Phone", !patientInfo.phone.isEmpty),
                ("Email", patientInfo.email.contains("@")),
                ("DOB", patientInfo.dateOfBirth < Date()),
                ("Gender", true)
            ]
            
            let validationResults = validations.map { "\($0.0): \($0.1 ? "✅" : "❌")" }.joined(separator: "\n")
            let allValid = validations.allSatisfy { $0.1 }
            
            return "\(allValid ? "✅" : "❌") Booking Validation:\n\(validationResults)\n\nOverall: \(allValid ? "All fields valid" : "Some fields invalid")"
            
        default:
            throw TestError.unexpectedResponse("Unknown endpoint")
        }
    }
    
    private func getAppointmentStatusSummary(_ appointments: [Appointment]) -> String {
        let statusCounts = appointments.reduce(into: [String: Int]()) { counts, appointment in
            let status = String(describing: appointment.status)
            counts[status, default: 0] += 1
        }
        
        if statusCounts.isEmpty {
            return "None"
        }
        
        return statusCounts.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
}

// MARK: - Supporting Views

struct EndpointSelectorView: View {
    @Binding var selectedEndpoint: Int
    let endpoints: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Endpoint to Test")
                .font(.headline)
                .fontWeight(.semibold)
            
            Picker("Endpoint", selection: $selectedEndpoint) {
                ForEach(0..<endpoints.count, id: \.self) { index in
                    Text(endpoints[index]).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TestParametersView: View {
    let selectedEndpoint: Int
    @Binding var parameters: TestParameters
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Test Parameters")
                .font(.headline)
                .fontWeight(.semibold)
            
            switch selectedEndpoint {
            case 0: // Search Facilities
                FacilitySearchParametersView(parameters: $parameters)
            case 1: // Facility Details
                Text("Uses first facility from search - no parameters needed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            case 2: // Time Slots
                TimeSlotParametersView(parameters: $parameters)
            case 3: // User Appointments
                UserAppointmentParametersView(parameters: $parameters)
            case 4: // Booking Validation
                BookingValidationParametersView(parameters: $parameters)
            default:
                Text("No parameters required")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FacilitySearchParametersView: View {
    @Binding var parameters: TestParameters
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Search query (optional)", text: $parameters.searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Toggle("Use Location", isOn: $parameters.useLocation)
            
            if parameters.useLocation {
                HStack {
                    TextField("Latitude", value: $parameters.latitude, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Longitude", value: $parameters.longitude, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Search Radius: \(Int(parameters.searchRadius)) km")
                        .font(.caption)
                    Slider(value: $parameters.searchRadius, in: 1...50, step: 1)
                }
            }
            
            Toggle("Apply Filters", isOn: $parameters.applyFilters)
            
            if parameters.applyFilters {
                Toggle("Accepts Insurance", isOn: $parameters.acceptsInsurance)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Result Limit: \(parameters.resultLimit)")
                    .font(.caption)
                Slider(value: Binding(
                    get: { Double(parameters.resultLimit) },
                    set: { parameters.resultLimit = Int($0) }
                ), in: 1...20, step: 1)
            }
        }
    }
}

struct TimeSlotParametersView: View {
    @Binding var parameters: TestParameters
    
    var body: some View {
        VStack(spacing: 12) {
            Toggle("Use Custom Date", isOn: $parameters.useCustomDate)
            
            if parameters.useCustomDate {
                DatePicker("Select Date", selection: $parameters.selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
            } else {
                Text("Using today's date")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct UserAppointmentParametersView: View {
    @Binding var parameters: TestParameters
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Test User ID", text: $parameters.testUserId)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text("Enter a valid MongoDB ObjectId (24 hex characters) or use the default test ID")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct BookingValidationParametersView: View {
    @Binding var parameters: TestParameters
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Patient Name", text: $parameters.patientName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Patient Phone", text: $parameters.patientPhone)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Patient Email", text: $parameters.patientEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            DatePicker("Date of Birth", selection: $parameters.patientDOB, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
            
            Picker("Gender", selection: $parameters.patientGender) {
                Text("Male").tag(Gender.male)
                Text("Female").tag(Gender.female)
                Text("Other").tag(Gender.other)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

struct ActionButtonsView: View {
    let selectedEndpoint: Int
    let parameters: TestParameters
    @Binding var isRunningTest: Bool
    @Binding var testResult: String
    let onRunTest: (String) -> Void
    
    let endpoints = [
        "Search Facilities",
        "Facility Details", 
        "Available Time Slots",
        "User Appointments",
        "Booking Validation"
    ]
    
    var body: some View {
        VStack(spacing: 15) {
            Button(action: {
                onRunTest(endpoints[selectedEndpoint])
            }) {
                HStack {
                    if isRunningTest {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.circle.fill")
                    }
                    
                    Text(isRunningTest ? "Testing..." : "Run Test")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isRunningTest ? Color.gray : Color.green)
                .cornerRadius(10)
            }
            .disabled(isRunningTest)
            
            if !testResult.isEmpty {
                Button(action: {
                    testResult = ""
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Result")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct ManualTestResultView: View {
    let result: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Test Result")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView {
                Text(result)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct IntegrationTestResultsView: View {
    @ObservedObject var testRunner: LabLoopAPIIntegrationTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Integration Test Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // This would show the full test interface
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ForEach(testRunner.testResults.prefix(3)) { result in
                HStack {
                    Circle()
                        .fill(result.status.color)
                        .frame(width: 8, height: 8)
                    
                    Text(result.testName)
                        .font(.caption)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(result.formattedDuration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Test Parameters Model

struct TestParameters {
    // Facility Search Parameters
    var searchQuery: String = ""
    var useLocation: Bool = false
    var latitude: Double = 37.7749  // San Francisco
    var longitude: Double = -122.4194
    var searchRadius: Double = 10.0
    var applyFilters: Bool = false
    var facilityTypes: [String] = ["lab", "collection_center"]
    var acceptsInsurance: Bool = false
    var resultLimit: Int = 10
    
    // Time Slot Parameters
    var useCustomDate: Bool = false
    var selectedDate: Date = Date()
    
    // User Appointment Parameters
    var testUserId: String = "6751234567890123456789ab" // Mock ObjectId
    
    // Booking Validation Parameters
    var patientName: String = "Test Patient"
    var patientPhone: String = "+1234567890"
    var patientEmail: String = "test@example.com"
    var patientDOB: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    var patientGender: Gender = .male
}

// MARK: - Preview

#Preview {
    LabLoopTestInterface()
}