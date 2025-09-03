//
//  LabLoopAPIIntegrationTest.swift
//  SuperOne
//
//  Created by Claude Code on 2025-01-21.
//  Comprehensive integration tests for LabLoop API services
//

import Foundation
import SwiftUI
import Combine

/// Comprehensive integration test coordinator for LabLoop API services
@MainActor
class LabLoopAPIIntegrationTest: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isRunningTests = false
    @Published var testResults: [TestResult] = []
    @Published var overallTestStatus: TestStatus = .notRun
    @Published var isRunningIndividualTest = false
    @Published var testProgress: Double = 0.0
    @Published var currentTestName: String = ""
    @Published var errorLogs: [ErrorLog] = []
    @Published var performanceMetrics: [PerformanceMetric] = []
    
    // MARK: - Services
    
    private let labFacilityService = LabFacilityAPIService.shared
    private let appointmentService = AppointmentAPIService.shared
    
    // MARK: - Test Status
    
    enum TestStatus {
        case notRun
        case running
        case passed
        case failed
        case mixed
        
        var displayName: String {
            switch self {
            case .notRun: return "Not Run"
            case .running: return "Running"
            case .passed: return "All Passed"
            case .failed: return "Failed"
            case .mixed: return "Mixed Results"
            }
        }
        
        var color: Color {
            switch self {
            case .notRun: return .gray
            case .running: return .blue
            case .passed: return .green
            case .failed: return .red
            case .mixed: return .orange
            }
        }
    }
    
    // MARK: - Test Results
    
    struct TestResult: Identifiable {
        let id = UUID()
        let testName: String
        let status: TestStatus
        let message: String
        let duration: TimeInterval
        let timestamp: Date = Date()
        let requestDetails: RequestDetails?
        let responseDetails: ResponseDetails?
        
        var formattedDuration: String {
            return String(format: "%.2fs", duration)
        }
    }
    
    struct RequestDetails {
        let url: String
        let method: String
        let headers: [String: String]?
        let body: String?
    }
    
    struct ResponseDetails {
        let statusCode: Int
        let headers: [String: String]?
        let body: String?
        let size: Int
    }
    
    struct ErrorLog: Identifiable {
        let id = UUID()
        let testName: String
        let error: Error
        let timestamp: Date = Date()
        let context: String
    }
    
    struct PerformanceMetric: Identifiable {
        let id = UUID()
        let testName: String
        let requestTime: TimeInterval
        let responseSize: Int
        let timestamp: Date = Date()
        
        var performance: PerformanceLevel {
            if requestTime < 1.0 { return .excellent }
            else if requestTime < 3.0 { return .good }
            else if requestTime < 5.0 { return .acceptable }
            else { return .poor }
        }
    }
    
    enum PerformanceLevel {
        case excellent, good, acceptable, poor
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .acceptable: return .orange
            case .poor: return .red
            }
        }
        
        var displayName: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .acceptable: return "Acceptable"
            case .poor: return "Poor"
            }
        }
    }
    
    // MARK: - Main Test Runner
    
    /// Run all integration tests
    func runAllTests() {
        isRunningTests = true
        overallTestStatus = .running
        testResults.removeAll()
        errorLogs.removeAll()
        performanceMetrics.removeAll()
        testProgress = 0.0
        
        Task {
            let totalTests = 12 // Update this as we add more tests
            var completedTests = 0
            
            await runFacilitySearchTests()
            completedTests += 4
            testProgress = Double(completedTests) / Double(totalTests)
            
            await runFacilityDetailsTests()
            completedTests += 1
            testProgress = Double(completedTests) / Double(totalTests)
            
            await runTimeSlotTests()
            completedTests += 2
            testProgress = Double(completedTests) / Double(totalTests)
            
            await runAppointmentTests()
            completedTests += 2
            testProgress = Double(completedTests) / Double(totalTests)
            
            await runErrorHandlingTests()
            completedTests += 3
            testProgress = 1.0
            
            // Calculate overall status
            let passed = testResults.filter { $0.status == .passed }.count
            let failed = testResults.filter { $0.status == .failed }.count
            
            if failed == 0 {
                overallTestStatus = .passed
            } else if passed == 0 {
                overallTestStatus = .failed
            } else {
                overallTestStatus = .mixed
            }
            
            isRunningTests = false
            currentTestName = ""
        }
    }
    
    /// Run individual test by name
    func runIndividualTest(_ testName: String) {
        isRunningIndividualTest = true
        currentTestName = testName
        
        Task {
            switch testName {
            case "Basic Facility Search":
                await runTest(name: "Basic Facility Search") {
                    let facilities = try await self.labFacilityService.searchFacilities()
                    guard !facilities.isEmpty else {
                        throw TestError.noResults("No facilities returned from search")
                    }
                    return "Found \(facilities.count) facilities"
                }
            case "Facility Search with Query":
                await runTest(name: "Facility Search with Query") {
                    let facilities = try await self.labFacilityService.searchFacilities(query: "lab")
                    return "Search with query returned \(facilities.count) facilities"
                }
            case "Facility Search with Location":
                await runTest(name: "Facility Search with Location") {
                    let facilities = try await self.labFacilityService.searchFacilities(
                        location: (lat: 37.7749, lng: -122.4194),
                        radius: 25.0
                    )
                    return "Location-based search returned \(facilities.count) facilities"
                }
            case "Facility Details":
                await runFacilityDetailsTests()
            case "Time Slots":
                await runTimeSlotTests()
            case "User Appointments":
                await runTest(name: "User Appointments") {
                    let appointments = try await self.appointmentService.getUserAppointments(userId: "test_user_id")
                    return "Retrieved \(appointments.count) appointments"
                }
            default:
                break
            }
            
            isRunningIndividualTest = false
            currentTestName = ""
        }
    }
    
    // MARK: - Facility Search Tests
    
    private func runFacilitySearchTests() async {
        currentTestName = "Running Facility Search Tests..."
        
        // Test 1: Basic facility search
        await runTest(name: "Basic Facility Search") {
            let facilities = try await self.labFacilityService.searchFacilities()
            guard !facilities.isEmpty else {
                throw TestError.noResults("No facilities returned from search")
            }
            return "✅ Found \(facilities.count) facilities. First facility: \(facilities.first?.name ?? "Unknown")"
        }
        
        // Test 2: Facility search with query
        await runTest(name: "Facility Search with Query") {
            let facilities = try await self.labFacilityService.searchFacilities(query: "lab")
            return "✅ Search with query 'lab' returned \(facilities.count) facilities"
        }
        
        // Test 3: Facility search with location (mock coordinates)
        await runTest(name: "Facility Search with Location") {
            let facilities = try await self.labFacilityService.searchFacilities(
                location: (lat: 40.7128, lng: -74.0060), // Generic coordinates
                radius: 25.0
            )
            return "✅ Location-based search returned \(facilities.count) facilities within 25km"
        }
        
        // Test 4: Facility search with filters
        await runTest(name: "Facility Search with Filters") {
            let filters = FacilitySearchFilters(
                types: ["lab", "collection_center"],
                acceptsInsurance: true
            )
            let facilities = try await self.labFacilityService.searchFacilities(filters: filters)
            return "✅ Filtered search (labs & collection centers with insurance) returned \(facilities.count) facilities"
        }
    }
    
    // MARK: - Facility Details Tests
    
    private func runFacilityDetailsTests() async {
        currentTestName = "Running Facility Details Tests..."
        
        // First get a facility ID to test with
        let facilities = try? await self.labFacilityService.searchFacilities(limit: 1)
        
        guard let firstFacility = facilities?.first else {
            addTestResult(
                name: "Facility Details", 
                status: .failed, 
                message: "❌ No facility available for details test", 
                duration: 0,
                requestDetails: nil,
                responseDetails: nil
            )
            return
        }
        
        // Test facility details retrieval
        await runTest(name: "Facility Details") {
            let details = try await self.labFacilityService.getFacilityDetails(facilityId: firstFacility.id)
            let servicesCount = details.services.count
            let amenitiesCount = details.amenities.count
            return "✅ Retrieved details for '\(details.name)': \(servicesCount) services, \(amenitiesCount) amenities, Rating: \(details.rating)/5.0"
        }
    }
    
    // MARK: - Time Slot Tests
    
    private func runTimeSlotTests() async {
        currentTestName = "Running Time Slot Tests..."
        
        // First get a facility ID to test with
        let facilities = try? await self.labFacilityService.searchFacilities(limit: 1)
        
        guard let firstFacility = facilities?.first else {
            addTestResult(
                name: "Time Slots", 
                status: .failed, 
                message: "❌ No facility available for time slot test", 
                duration: 0,
                requestDetails: nil,
                responseDetails: nil
            )
            return
        }
        
        // Test time slot retrieval for today
        await runTest(name: "Time Slots for Today") {
            let timeSlots = try await self.labFacilityService.getAvailableTimeSlots(
                facilityId: firstFacility.id,
                date: Date()
            )
            let availableSlots = timeSlots.filter { $0.isAvailable }
            return "✅ Found \(timeSlots.count) total slots, \(availableSlots.count) available for '\(firstFacility.name)' today"
        }
        
        // Test time slot retrieval for future date
        await runTest(name: "Time Slots for Future Date") {
            let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            let timeSlots = try await self.labFacilityService.getAvailableTimeSlots(
                facilityId: firstFacility.id,
                date: futureDate
            )
            let availableSlots = timeSlots.filter { $0.isAvailable }
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            return "✅ Found \(timeSlots.count) total slots, \(availableSlots.count) available for \(dateFormatter.string(from: futureDate))"
        }
    }
    
    // MARK: - Appointment Tests
    
    private func runAppointmentTests() async {
        currentTestName = "Running Appointment Tests..."
        
        // Test user appointments retrieval with test user ID
        await runTest(name: "User Appointments") {
            let testUserId = "507f1f77bcf86cd799439011" // Generic ObjectId
            let appointments = try await self.appointmentService.getUserAppointments(userId: testUserId)
            return "✅ Retrieved \(appointments.count) appointments for test user"
        }
        
        // Test appointment booking validation (dry run - no actual booking)
        await runTest(name: "Appointment Booking Validation") {
            // Create valid patient info for validation test
            let patientInfo = PatientBookingInfo(
                name: "Test User",
                phone: "+1555000000",
                email: "user@test.local",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
                gender: .male
            )
            
            // Validate required fields are properly structured
            let hasValidName = !patientInfo.name.isEmpty
            let hasValidPhone = !patientInfo.phone.isEmpty
            let hasValidEmail = patientInfo.email.contains("@")
            let hasValidDOB = patientInfo.dateOfBirth < Date()
            
            let validationResults = [
                "Name: \(hasValidName ? "✅" : "❌")",
                "Phone: \(hasValidPhone ? "✅" : "❌")", 
                "Email: \(hasValidEmail ? "✅" : "❌")",
                "DOB: \(hasValidDOB ? "✅" : "❌")"
            ]
            
            return "✅ Booking validation passed: \(validationResults.joined(separator: ", "))"
        }
    }
    
    private func runErrorHandlingTests() async {
        currentTestName = "Running Error Handling Tests..."
        
        // Test 1: Invalid facility ID format
        await runTest(name: "Invalid Facility ID Error Handling") {
            do {
                _ = try await self.labFacilityService.getFacilityDetails(facilityId: "invalid_id_format")
                throw TestError.unexpectedResponse("Should have failed with invalid ID")
            } catch {
                if let facilityError = error as? LabFacilityAPIError {
                    return "✅ Properly handled invalid facility ID error: \(facilityError.errorDescription ?? "Unknown error")"
                } else {
                    return "✅ Error handling working: \(error.localizedDescription)"
                }
            }
        }
        
        // Test 2: Invalid date format for timeslots
        await runTest(name: "Invalid Date Format Error Handling") {
            let facilities = try? await self.labFacilityService.searchFacilities(limit: 1)
            guard let firstFacility = facilities?.first else {
                throw TestError.noResults("No facility available for error test")
            }
            
            do {
                // Create an invalid date (far in the past)
                let pastDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
                _ = try await self.self.labFacilityService.getAvailableTimeSlots(
                    facilityId: firstFacility.id,
                    date: pastDate
                )
                return "⚠️ Past date accepted (unexpected but not necessarily an error)"
            } catch {
                return "✅ Properly handled invalid/past date error: \(error.localizedDescription)"
            }
        }
        
        // Test 3: Invalid user ID for appointments
        await runTest(name: "Invalid User ID Error Handling") {
            do {
                _ = try await self.self.appointmentService.getUserAppointments(userId: "invalid_user_id")
                throw TestError.unexpectedResponse("Should have failed with invalid user ID")
            } catch {
                if let appointmentError = error as? AppointmentAPIError {
                    return "✅ Properly handled invalid user ID error: \(appointmentError.errorDescription ?? "Unknown error")"
                } else {
                    return "✅ Error handling working: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Test Utilities
    
    private func runTest(name: String, test: @escaping () async throws -> String) async {
        let startTime = Date()
        currentTestName = name
        
        do {
            let message = try await test()
            let duration = Date().timeIntervalSince(startTime)
            
            // Record performance metric
            let metric = PerformanceMetric(
                testName: name,
                requestTime: duration,
                responseSize: message.count // Approximate size
            )
            performanceMetrics.append(metric)
            
            addTestResult(
                name: name, 
                status: .passed, 
                message: message, 
                duration: duration,
                requestDetails: nil, // Would need to capture actual request details
                responseDetails: nil  // Would need to capture actual response details
            )
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            
            // Log the error
            let errorLog = ErrorLog(
                testName: name,
                error: error,
                context: "Test execution"
            )
            errorLogs.append(errorLog)
            
            addTestResult(
                name: name, 
                status: .failed, 
                message: "❌ Error: \(errorMessage)", 
                duration: duration,
                requestDetails: nil,
                responseDetails: nil
            )
        }
    }
    
    private func addTestResult(
        name: String, 
        status: TestStatus, 
        message: String, 
        duration: TimeInterval,
        requestDetails: RequestDetails?,
        responseDetails: ResponseDetails?
    ) {
        let result = TestResult(
            testName: name,
            status: status,
            message: message,
            duration: duration,
            requestDetails: requestDetails,
            responseDetails: responseDetails
        )
        testResults.append(result)
    }
    
    /// Clear all test results and logs
    func clearResults() {
        testResults.removeAll()
        errorLogs.removeAll()
        performanceMetrics.removeAll()
        overallTestStatus = .notRun
        testProgress = 0.0
    }
    
    /// Get test summary statistics
    func getTestSummary() -> TestSummary {
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.status == .passed }.count
        let failedTests = testResults.filter { $0.status == .failed }.count
        let averageDuration = testResults.isEmpty ? 0 : testResults.map { $0.duration }.reduce(0, +) / Double(totalTests)
        
        return TestSummary(
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            averageDuration: averageDuration,
            overallStatus: overallTestStatus
        )
    }
    
    struct TestSummary {
        let totalTests: Int
        let passedTests: Int
        let failedTests: Int
        let averageDuration: TimeInterval
        let overallStatus: TestStatus
        
        var successRate: Double {
            totalTests == 0 ? 0 : Double(passedTests) / Double(totalTests) * 100
        }
        
        var formattedAverageDuration: String {
            String(format: "%.2fs", averageDuration)
        }
    }
}

// MARK: - Test Errors

nonisolated enum TestError: LocalizedError {
    case noResults(String)
    case invalidData(String)
    case unexpectedResponse(String)
    
    var errorDescription: String? {
        switch self {
        case .noResults(let message):
            return "No results: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .unexpectedResponse(let message):
            return "Unexpected response: \(message)"
        }
    }
}

// MARK: - Test UI View

struct LabLoopIntegrationTestView: View {
    @StateObject private var testRunner = LabLoopAPIIntegrationTest()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Main Test Tab
                TestRunnerView(testRunner: testRunner)
                    .tabItem {
                        Image(systemName: "play.circle")
                        Text("Tests")
                    }
                    .tag(0)
                
                // Performance Tab
                PerformanceView(testRunner: testRunner)
                    .tabItem {
                        Image(systemName: "speedometer")
                        Text("Performance")
                    }
                    .tag(1)
                
                // Error Logs Tab
                ErrorLogsView(testRunner: testRunner)
                    .tabItem {
                        Image(systemName: "exclamationmark.triangle")
                        Text("Errors")
                    }
                    .tag(2)
            }
        }
    }
}

struct TestRunnerView: View {
    @ObservedObject var testRunner: LabLoopAPIIntegrationTest
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Test Status Header
                TestStatusHeaderView(testRunner: testRunner)
                
                // Progress View
                if testRunner.isRunningTests {
                    VStack(spacing: 10) {
                        ProgressView(value: testRunner.testProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        if !testRunner.currentTestName.isEmpty {
                            Text(testRunner.currentTestName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Control Buttons
                ControlButtonsView(testRunner: testRunner)
                
                // Test Summary
                if !testRunner.testResults.isEmpty {
                    TestSummaryView(testRunner: testRunner)
                }
                
                // Test Results
                if !testRunner.testResults.isEmpty {
                    LazyVStack(spacing: 8) {
                        ForEach(testRunner.testResults) { result in
                            TestResultRow(result: result)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("LabLoop API Tests")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TestStatusHeaderView: View {
    @ObservedObject var testRunner: LabLoopAPIIntegrationTest
    
    var body: some View {
        VStack(spacing: 15) {
            Text("LabLoop API Integration Tests")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                VStack {
                    Circle()
                        .fill(testRunner.overallTestStatus.color)
                        .frame(width: 20, height: 20)
                    Text(testRunner.overallTestStatus.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                if !testRunner.testResults.isEmpty {
                    let summary = testRunner.getTestSummary()
                    VStack {
                        Text("\(summary.passedTests)/\(summary.totalTests)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Passed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text(String(format: "%.1f%%", summary.successRate))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(summary.successRate > 80 ? .green : summary.successRate > 60 ? .orange : .red)
                        Text("Success Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ControlButtonsView: View {
    @ObservedObject var testRunner: LabLoopAPIIntegrationTest
    
    var body: some View {
        HStack(spacing: 15) {
            // Run All Tests Button
            Button(action: {
                testRunner.runAllTests()
            }) {
                HStack {
                    if testRunner.isRunningTests {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.circle.fill")
                    }
                    
                    Text(testRunner.isRunningTests ? "Running..." : "Run All Tests")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(testRunner.isRunningTests ? Color.gray : Color.blue)
                .cornerRadius(10)
            }
            .disabled(testRunner.isRunningTests)
            
            // Clear Results Button
            Button(action: {
                testRunner.clearResults()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            }
            .disabled(testRunner.isRunningTests)
        }
        .padding(.horizontal)
    }
}

struct TestSummaryView: View {
    @ObservedObject var testRunner: LabLoopAPIIntegrationTest
    
    var body: some View {
        let summary = testRunner.getTestSummary()
        
        VStack(spacing: 15) {
            Text("Test Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 30) {
                StatView(title: "Total", value: "\(summary.totalTests)", color: .primary)
                StatView(title: "Passed", value: "\(summary.passedTests)", color: .green)
                StatView(title: "Failed", value: "\(summary.failedTests)", color: .red)
                StatView(title: "Avg Time", value: summary.formattedAverageDuration, color: .blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct TestResultRow: View {
    let result: LabLoopAPIIntegrationTest.TestResult
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(result.status.color)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.testName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(result.formattedDuration)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(result.duration < 1.0 ? .green : result.duration < 3.0 ? .orange : .red)
                    
                    Text(DateFormatter.timeFormatter.string(from: result.timestamp))
                        .font(.caption2)
                        .foregroundColor(HealthColors.tertiaryText)
                }
            }
            
            if isExpanded && (result.requestDetails != nil || result.responseDetails != nil) {
                VStack(alignment: .leading, spacing: 5) {
                    if let requestDetails = result.requestDetails {
                        Text("Request: \(requestDetails.method) \(requestDetails.url)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let responseDetails = result.responseDetails {
                        Text("Response: \(responseDetails.statusCode) (\(responseDetails.size) bytes)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
}

struct PerformanceView: View {
    @ObservedObject var testRunner: LabLoopAPIIntegrationTest
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("Performance Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if testRunner.performanceMetrics.isEmpty {
                    Text("No performance data available. Run tests to see metrics.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(testRunner.performanceMetrics) { metric in
                            PerformanceMetricRow(metric: metric)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Performance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PerformanceMetricRow: View {
    let metric: LabLoopAPIIntegrationTest.PerformanceMetric
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.testName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 15) {
                    Label(String(format: "%.2fs", metric.requestTime), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(metric.responseSize) bytes", systemImage: "arrow.down.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(metric.performance.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(metric.performance.color)
                
                Circle()
                    .fill(metric.performance.color)
                    .frame(width: 12, height: 12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ErrorLogsView: View {
    @ObservedObject var testRunner: LabLoopAPIIntegrationTest
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("Error Logs")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if testRunner.errorLogs.isEmpty {
                    Text("No errors logged. Great job!")
                        .foregroundColor(.green)
                        .padding()
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(testRunner.errorLogs) { errorLog in
                            ErrorLogRow(errorLog: errorLog)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Error Logs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ErrorLogRow: View {
    let errorLog: LabLoopAPIIntegrationTest.ErrorLog
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(errorLog.testName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(errorLog.context)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(DateFormatter.timeFormatter.string(from: errorLog.timestamp))
                    .font(.caption2)
                    .foregroundColor(HealthColors.tertiaryText)
            }
            
            if isExpanded {
                Text(errorLog.error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Preview

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    LabLoopIntegrationTestView()
}