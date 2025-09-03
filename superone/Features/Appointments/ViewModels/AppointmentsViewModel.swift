//
//  AppointmentsViewModel.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import Foundation
import Combine
import SwiftUI
import CoreLocation

/// ViewModel for managing appointments and lab facility bookings
@MainActor
@Observable
final class AppointmentsViewModel {
    
    // MARK: - Published Properties
    
    /// All appointments
    var appointments: [Appointment] = []
    var upcomingAppointments: [Appointment] = []
    var pastAppointments: [Appointment] = []
    
    // Enhanced appointment categorization for new UI
    var todaysAppointments: [Appointment] = []
    var tomorrowAppointments: [Appointment] = []
    var thisWeekAppointments: [Appointment] = []
    var laterAppointments: [Appointment] = []
    var recentCompletedAppointments: [Appointment] = []
    
    /// Test management
    var allTests: [AppointmentTest] = []
    var currentTests: [AppointmentTest] = []
    var completedTests: [AppointmentTest] = []
    var isLoadingTests: Bool = false
    var selectedTest: AppointmentTest?
    
    /// Tests page enhancement - radio button selection
    var selectedTestType: TestSelectionType = .individualTests {
        didSet {
            applyTestsFilters()
        }
    }
    var testPackages: [TestPackage] = []
    var individualTests: [IndividualTest] = []
    var isLoadingPackages: Bool = false
    var isLoadingIndividualTests: Bool = false
    
    /// Labs page enhancement - radio button selection
    var selectedLabServiceType: LabServiceType = .walkIn
    
    /// Available lab facilities
    var labFacilities: [LabFacility] = []
    var filteredFacilities: [LabFacility] = []
    var recommendedFacilities: [LabFacility] = []
    var regularFacilities: [LabFacility] = []
    var recentlyViewedFacilities: [LabFacility] = []
    
    /// Enhanced service type with home collection
    var serviceTypeOptions: [ServiceTypeOption] = ServiceTypeOption.allCases
    
    /// Booking state
    var selectedFacility: LabFacility?
    var selectedDate: Date = Date()
    var selectedTimeSlot: TimeSlot?
    var availableTimeSlots: [TimeSlot] = []
    
    /// Loading states
    var isLoadingAppointments: Bool = false
    var isLoadingFacilities: Bool = false
    var isLoadingTimeSlots: Bool = false
    var isBooking: Bool = false
    
    /// Search and filter
    var searchText: String = "" {
        didSet {
            applyFilters()
        }
    }
    
    /// Tests search and filter
    var testsSearchText: String = "" {
        didSet {
            applyTestsFilters()
        }
    }
    var showTestsFilterSheet: Bool = false
    
    /// Labs search and filter (keeping existing searchText for backward compatibility)
    var showLabsFilterSheet: Bool = false
    var selectedLocation: String? = nil {
        didSet {
            applyFilters()
        }
    }
    var selectedServiceType: ServiceTypeOption? = nil {
        didSet {
            applyFilters()
        }
    }
    
    // MARK: - Detailed Labs Filter Properties
    
    /// Distance filter (legacy - keeping for compatibility)
    var selectedDistanceFilter: DistanceFilter = .any {
        didSet {
            applyFilters()
        }
    }
    
    /// Distance slider value for modern filter UI
    var distanceSliderValue: Double = 25.0 {
        didSet {
            // Update the legacy filter based on slider value
            selectedDistanceFilter = distanceFilterFromSliderValue(distanceSliderValue)
            applyFilters()
        }
    }
    
    /// Lab features filters (multiple selection)
    var selectedLabFeatures: Set<LabFeature> = [] {
        didSet {
            applyFilters()
        }
    }
    
    /// Minimum rating filter
    var selectedMinimumRating: MinimumRating = .any {
        didSet {
            applyFilters()
        }
    }
    
    /// Wait time filter
    var selectedWaitTime: WaitTimeFilter = .any {
        didSet {
            applyFilters()
        }
    }
    
    /// Location Services - using modern location manager
    var locationManager = LocationManager()
    
    /// Computed properties for location UI binding
    var currentLocationText: String {
        locationManager.statusMessage
    }
    
    var isLocationLoading: Bool {
        locationManager.isFetchingLocation
    }
    
    var locationError: String? {
        locationManager.currentError?.userMessage
    }
    
    var hasLocationPermission: Bool {
        locationManager.hasLocationPermission
    }
    
    var showLocationSettings: Bool = false
    
    /// UI state
    var showBookingSheet: Bool = false
    var showAppointmentDetail: Bool = false
    var selectedAppointment: Appointment?
    var showFacilityDetail: Bool = false
    var showCancelAlert: Bool = false
    var appointmentToCancel: Appointment?
    
    /// Error handling
    var errorMessage: String?
    var showError: Bool = false
    
    // MARK: - Private Properties
    
    private let appointmentAPIService = AppointmentAPIService.shared
    private let labFacilityAPIService = LabFacilityAPIService.shared
    private let testsAPIService = TestsAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String? = nil
    
    // MARK: - Initialization
    
    init() {
        setupUserId()
        setupLocationServices()
        loadAppointments()
        // Remove automatic loadLabFacilities() - will be loaded lazily when needed
        // Remove automatic Tests loading - will be loaded lazily when needed (like Labs)
        // loadTests()
        // loadTestPackages()
        // loadIndividualTests()
    }
    
    // MARK: - User Setup
    
    private func setupUserId() {
        // Get current user ID from authentication
        // For now, use a placeholder - this should be integrated with your auth system
        currentUserId = nil // Set to nil to skip user-specific appointment loading
    }
    
    // MARK: - Location Services Setup
    
    private func setupLocationServices() {
        // Initialize location services and get current location
        getCurrentLocation()
    }
    
    /// Get current location with modern async/await pattern
    func getCurrentLocation() {
        Task {
            // Use the modern location manager with automatic error handling
            let _ = await locationManager.getCurrentLocation(forceRefresh: false)
            
            await MainActor.run {
                // Update facility search with new location if successful
                if self.locationManager.locationState == .success {
                    self.applyFilters()
                }
            }
        }
    }
    
    /// Manually refresh location
    func refreshLocation() {
        Task {
            let _ = await locationManager.getCurrentLocation(forceRefresh: true)
            
            await MainActor.run {
                // Update facility search with new location if successful
                if self.locationManager.locationState == .success {
                    self.applyFilters()
                }
            }
        }
    }
    
    /// Open location settings
    func openLocationSettings() {
        locationManager.openLocationSettings()
        showLocationSettings = false
    }
    
    /// Request location permission if needed
    func requestLocationPermission() {
        Task {
            let granted = await locationManager.requestLocationPermission()
            
            if granted {
                // Permission granted, get location
                await MainActor.run {
                    getCurrentLocation()
                }
            } else {
                // Permission denied, show settings option
                await MainActor.run {
                    showLocationSettings = true
                }
            }
        }
    }
    
    /// Handle location permission denied
    func handleLocationPermissionDenied() {
        showLocationSettings = true
    }
    
    // MARK: - Appointment Management
    
    /// Load user appointments
    func loadAppointments() {
        guard let userId = currentUserId else {
            // Skip loading appointments when no user is authenticated
            // This is expected behavior for browsing labs without authentication
            appointments = []
            categorizeAppointments()
            return
        }
        
        isLoadingAppointments = true
        
        Task {
            do {
                // Load appointments from LabLoop API
                appointments = try await appointmentAPIService.getUserAppointments(userId: userId)
                categorizeAppointments()
                
                isLoadingAppointments = false
            } catch {
                errorMessage = "Failed to load appointments: \(error.localizedDescription)"
                showError = true
                isLoadingAppointments = false
            }
        }
    }
    
    /// Refresh appointments
    func refreshAppointments() async {
        loadAppointments()
        loadLabFacilities()
    }
    
    /// Select appointment for detail view
    func selectAppointment(_ appointment: Appointment) {
        selectedAppointment = appointment
        showAppointmentDetail = true
    }
    
    /// Cancel an appointment
    func cancelAppointment(_ appointment: Appointment) {
        appointmentToCancel = appointment
        showCancelAlert = true
    }
    
    /// Confirm appointment cancellation
    func confirmCancellation() {
        guard let appointment = appointmentToCancel,
              let userId = currentUserId else { return }
        
        Task {
            do {
                // Cancel appointment through LabLoop API
                let success = try await appointmentAPIService.cancelAppointment(
                    appointmentId: appointment.id,
                    userId: userId,
                    reason: "Cancelled by user"
                )
                
                if success {
                    appointments.removeAll { $0.id == appointment.id }
                    categorizeAppointments()
                }
                
                appointmentToCancel = nil
                showCancelAlert = false
            } catch {
                errorMessage = "Failed to cancel appointment: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    // MARK: - Lab Facility Management
    
    /// Load lab facilities from LabLoop API only when needed (lazy loading)
    func loadLabFacilitiesIfNeeded() {
        // Skip if already loaded or currently loading
        guard labFacilities.isEmpty && !isLoadingFacilities else { return }
        
        loadLabFacilities()
    }
    
    /// Load available lab facilities
    func loadLabFacilities() {
        isLoadingFacilities = true
        
        Task {
            do {
                // Load lab facilities from LabLoop API
                labFacilities = try await labFacilityAPIService.searchFacilities()
                
                // Keep facilities empty if API returns empty - no fallback mock data
                
                applyFilters()
                isLoadingFacilities = false
            } catch {
                errorMessage = "Failed to load facilities: \(error.localizedDescription)"
                showError = true
                
                // Keep facilities empty on API failure - no fallback mock data
                applyFilters()
                isLoadingFacilities = false
            }
        }
    }
    
    // Removed createSampleFacilities method - no hardcoded facility data
    
    /// Select facility and show booking sheet
    func selectFacility(_ facility: LabFacility) {
        selectedFacility = facility
        showBookingSheet = true
        loadAvailableTimeSlots()
    }
    
    /// Show facility details
    func showFacilityDetails(_ facility: LabFacility) {
        selectedFacility = facility
        showFacilityDetail = true
    }
    
    // MARK: - Booking Management
    
    /// Load available time slots for selected facility and date
    func loadAvailableTimeSlots() {
        guard let facility = selectedFacility else { return }
        
        isLoadingTimeSlots = true
        selectedTimeSlot = nil
        
        Task {
            do {
                // Load time slots from LabLoop API
                availableTimeSlots = try await labFacilityAPIService.getAvailableTimeSlots(
                    facilityId: facility.id,
                    date: selectedDate
                )
                
                isLoadingTimeSlots = false
            } catch {
                errorMessage = "Failed to load time slots: \(error.localizedDescription)"
                showError = true
                isLoadingTimeSlots = false
            }
        }
    }
    
    /// Book appointment with selected facility and time slot
    func bookAppointment() {
        guard let facility = selectedFacility,
              let timeSlot = selectedTimeSlot,
              let userId = currentUserId else { return }
        
        isBooking = true
        
        Task {
            do {
                // Create patient information (in a real app, this would come from user profile)
                let patientInfo = PatientBookingInfo(
                    name: "Current User", // Replace with actual user name
                    phone: "+1555000000", // Replace with actual user phone
                    email: "user@test.local", // Replace with actual user email
                    dateOfBirth: Date(timeIntervalSince1970: 0), // Replace with actual DOB
                    gender: .male // Replace with actual gender
                )
                
                // Default tests - in real app, user would select these
                let requestedTests = ["blood_work_basic"]
                
                // Book appointment through LabLoop API
                let bookingResult = try await appointmentAPIService.bookAppointment(
                    facilityId: facility.id,
                    serviceType: .visitLab, // Default to lab visit
                    appointmentDate: selectedDate,
                    timeSlot: timeSlot,
                    requestedTests: requestedTests,
                    patientInfo: patientInfo,
                    homeAddress: nil,
                    notes: "Appointment booked through SuperOne",
                    userId: userId
                )
                
                // Add booked appointment to local list
                appointments.append(bookingResult.appointment)
                categorizeAppointments()
                
                // Reset booking state
                selectedFacility = nil
                selectedTimeSlot = nil
                showBookingSheet = false
                isBooking = false
                
            } catch {
                errorMessage = "Failed to book appointment: \(error.localizedDescription)"
                showError = true
                isBooking = false
            }
        }
    }
    
    // MARK: - Search and Filter
    
    /// Apply search and filter criteria with all detailed filters
    func applyFilters() {
        var filtered = labFacilities
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { facility in
                facility.name.localizedCaseInsensitiveContains(searchText) ||
                facility.location.localizedCaseInsensitiveContains(searchText) ||
                facility.services.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply location filter
        if let location = selectedLocation {
            filtered = filtered.filter { $0.location.contains(location) }
        } else if locationManager.currentLocation != nil {
            // Sort by proximity to current location (simplified)
            filtered = filtered.sorted { facility1, facility2 in
                // This is a simplified distance comparison
                // In a real app, you'd calculate actual distances
                return facility1.name.localizedCaseInsensitiveCompare(facility2.name) == .orderedAscending
            }
        }
        
        // Apply distance filter
        if selectedDistanceFilter != .any,
           let maxDistance = selectedDistanceFilter.maxDistanceKm {
            // For now, use a simplified distance parsing from the distance string
            // In production, this should use actual coordinates
            filtered = filtered.filter { facility in
                let distanceString = facility.distance
                if let distanceValue = extractDistanceValue(from: distanceString) {
                    return distanceValue <= maxDistance
                }
                return true // Include facilities without distance info
            }
        }
        
        // Apply lab features filter
        if !selectedLabFeatures.isEmpty {
            filtered = filtered.filter { facility in
                selectedLabFeatures.allSatisfy { feature in
                    feature.isSupported(by: facility)
                }
            }
        }
        
        // Apply minimum rating filter
        if selectedMinimumRating != .any,
           let minimumRating = selectedMinimumRating.minimumValue {
            filtered = filtered.filter { facility in
                facility.rating >= minimumRating
            }
        }
        
        // Apply wait time filter
        if selectedWaitTime != .any,
           let maxWaitTime = selectedWaitTime.maxWaitMinutes {
            filtered = filtered.filter { facility in
                // Estimate wait time based on facility characteristics
                var estimatedWaitTime = 15 // Default wait time
                
                // Reduce wait time for 24-hour facilities
                if facility.operatingHours.contains("24") {
                    estimatedWaitTime = 5
                }
                
                // Increase wait time for hospitals (typically busier)
                if facility.type == .hospital {
                    estimatedWaitTime = 25
                }
                
                // Reduce wait time if walk-ins are not accepted (appointments only)
                if !facility.isWalkInAvailable {
                    estimatedWaitTime = 10
                }
                
                return estimatedWaitTime <= maxWaitTime
            }
        }
        
        // Apply lab service type filter (new radio button selection)
        switch selectedLabServiceType {
        case .walkIn:
            filtered = filtered.compactMap { facility in
                (facility.isWalkInAvailable || facility.type != .homeCollection) ? facility : nil
            }
        case .homeCollection:
            filtered = filtered.compactMap { facility in
                facility.offersHomeCollection ? facility : nil
            }
        }
        
        // Apply service type filter (legacy - keeping for compatibility)
        if let serviceTypeOption = selectedServiceType {
            filtered = filtered.compactMap { facility in
                switch serviceTypeOption {
                case .labVisit:
                    return (facility.isWalkInAvailable || facility.type != .homeCollection) ? facility : nil
                case .homeCollection:
                    return facility.offersHomeCollection ? facility : nil
                }
            }
        }
        
        filteredFacilities = filtered
        categorizeFacilities()
    }
    
    /// Extract distance value from a distance string like "2.3 km" or "1.5 miles"
    private func extractDistanceValue(from distanceString: String) -> Double? {
        // Extract numeric value from strings like "2.3 km", "1.5 miles", etc.
        let scanner = Scanner(string: distanceString)
        var distance: Double = 0
        
        if scanner.scanDouble(&distance) {
            // Convert miles to km if needed
            if distanceString.lowercased().contains("mile") {
                return distance * 1.60934 // Convert miles to km
            }
            return distance
        }
        
        return nil
    }
    
    /// Search facilities with real-time LabLoop API integration
    func searchFacilitiesWithQuery(_ query: String) {
        searchText = query
        
        // Debounce search to avoid too many API calls
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            guard searchText == query else { return } // Check if search text changed
            
            await performLiveFacilitySearch()
        }
    }
    
    /// Perform live facility search with current filters
    private func performLiveFacilitySearch() async {
        isLoadingFacilities = true
        
        do {
            // Build search filters
            let searchFilters = FacilitySearchFilters(
                types: [], // Could be set based on selectedServiceType
                priceRanges: [],
                minimumRating: nil,
                features: [],
                homeCollection: nil,
                sameDay: nil,
                is24Hours: nil,
                acceptsInsurance: nil
            )
            
            // Search with LabLoop API using current location if available
            let searchLocation = locationManager.currentLocation?.coordinate
            
            labFacilities = try await labFacilityAPIService.searchFacilities(
                query: searchText.isEmpty ? nil : searchText,
                location: searchLocation != nil ? (lat: searchLocation!.latitude, lng: searchLocation!.longitude) : nil,
                radius: 50.0, // 50km default radius
                filters: searchFilters,
                page: 1,
                limit: 20
            )
            
            applyFilters()
            isLoadingFacilities = false
            
        } catch {
            errorMessage = "Failed to search facilities: \(error.localizedDescription)"
            showError = true
            isLoadingFacilities = false
        }
    }
    
    /// Clear all filters
    func clearFilters() {
        searchText = ""
        selectedLocation = nil
        selectedServiceType = nil
        applyFilters()
    }
    
    // MARK: - Lab Filter Management
    
    /// Reset all lab filters to default values
    func resetLabFilters() {
        selectedDistanceFilter = .any
        distanceSliderValue = 25.0
        selectedLabFeatures.removeAll()
        selectedMinimumRating = .any
        selectedWaitTime = .any
        // Note: We don't call applyFilters() here to allow batched updates
    }
    
    /// Apply lab filters and trigger UI update
    func applyLabFilters() {
        applyFilters()
    }
    
    /// Apply tests filters and reload data (mirrors applyFilters for Labs)
    func applyTestsFilters() {
        switch selectedTestType {
        case .individualTests:
            loadIndividualTests()  // Direct call, no caching
        case .healthPackages:
            loadTestPackages()     // Direct call, no caching
        }
    }
    
    /// Toggle a lab feature filter
    func toggleLabFeature(_ feature: LabFeature) {
        if selectedLabFeatures.contains(feature) {
            selectedLabFeatures.remove(feature)
        } else {
            selectedLabFeatures.insert(feature)
        }
    }
    
    /// Check if a lab feature is currently selected
    func isLabFeatureSelected(_ feature: LabFeature) -> Bool {
        return selectedLabFeatures.contains(feature)
    }
    
    /// Check if any filters are active (excluding search text)
    var hasActiveFilters: Bool {
        return selectedDistanceFilter != .any ||
               !selectedLabFeatures.isEmpty ||
               selectedMinimumRating != .any ||
               selectedWaitTime != .any ||
               selectedServiceType != nil ||
               selectedLocation != nil
    }
    
    /// Convert slider value to corresponding distance filter
    private func distanceFilterFromSliderValue(_ value: Double) -> DistanceFilter {
        if value >= 25.0 {
            return .any
        } else if value >= 10.0 {
            return .within25km
        } else if value >= 5.0 {
            return .within10km
        } else if value >= 2.0 {
            return .within5km
        } else {
            return .within2km
        }
    }
    
    
    // MARK: - Private Methods
    
    private func categorizeAppointments() {
        let now = Date()
        let calendar = Calendar.current
        
        // Split into upcoming and past
        upcomingAppointments = appointments.filter { $0.appointmentDateTime > now }.sorted { $0.appointmentDateTime < $1.appointmentDateTime }
        pastAppointments = appointments.filter { $0.appointmentDateTime <= now }.sorted { $0.appointmentDateTime > $1.appointmentDateTime }
        
        // Enhanced categorization for new UI
        todaysAppointments = upcomingAppointments.filter { calendar.isDateInToday($0.date) }
        
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        tomorrowAppointments = upcomingAppointments.filter { calendar.isDate($0.date, inSameDayAs: tomorrow) }
        
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? now
        thisWeekAppointments = upcomingAppointments.filter { 
            !calendar.isDateInToday($0.date) && 
            !calendar.isDate($0.date, inSameDayAs: tomorrow) &&
            $0.date >= weekStart && $0.date < weekEnd
        }
        
        laterAppointments = upcomingAppointments.filter { $0.date >= weekEnd }
        
        // Recent completed appointments (last 30 days)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        recentCompletedAppointments = pastAppointments.filter { 
            $0.date >= thirtyDaysAgo && $0.status == .completed 
        }.prefix(5).map { $0 }
    }
    
    // MARK: - Test Management
    
    /// Load user tests
    func loadTests() {
        guard currentUserId != nil else {
            // For demo purposes, create sample tests
            allTests = []
            categorizeTests()
            return
        }
        
        isLoadingTests = true
        
        Task {
            // In a real app, this would load from the health analysis backend
            // do {
            //     allTests = try await testAPIService.getUserTests(userId: userId)
            // } catch {
            //     errorMessage = "Failed to load tests: \(error.localizedDescription)"
            //     showError = true
            // }
            
            // For now, using empty array for demo
            allTests = []
            categorizeTests()
            isLoadingTests = false
        }
    }
    
    /// Categorize tests by status
    private func categorizeTests() {
        currentTests = allTests.filter { $0.status == .scheduled || $0.status == .processing }
        completedTests = allTests.filter { $0.status == .completed }.sorted { $0.completedDate ?? Date() > $1.completedDate ?? Date() }
    }
    
    /// Select test for detail view
    func selectTest(_ test: AppointmentTest) {
        selectedTest = test
        // Show test detail sheet
    }
    
    // MARK: - Enhanced Lab Management
    
    /// Categorize facilities by type
    private func categorizeFacilities() {
        recommendedFacilities = Array(filteredFacilities.compactMap { $0.isRecommended ? $0 : nil }.prefix(3))
        regularFacilities = filteredFacilities.compactMap { !$0.isRecommended ? $0 : nil }
        
        // Load recently viewed facilities (from UserDefaults or persistent storage)
        recentlyViewedFacilities = [] // Load from storage
    }
    
    // MARK: - Health Packages and Individual Tests Management
    
    /// Load test packages from LabLoop API
    func loadTestPackages() {
        // TODO: Replace with actual LabLoop API call
        // testPackages = try await testsAPIService.fetchHealthPackages()
        testPackages = [] // No hardcoded test data - use real API data
    }
    
    /// Load individual tests from LabLoop API
    func loadIndividualTests() {
        isLoadingIndividualTests = true
        
        Task {
            do {
                // Load individual tests from API using our TestsAPIService
                let response = try await testsAPIService.searchTests(
                    query: testsSearchText.isEmpty ? nil : testsSearchText,
                    category: nil,
                    offset: 0,
                    limit: 20
                )
                
                // Convert TestItemData to IndividualTest for UI compatibility
                individualTests = response.tests.map { testItem in
                    IndividualTest(
                        id: testItem.id,
                        name: testItem.name,
                        icon: testItem.icon,
                        description: testItem.description,
                        price: Int(testItem.price.replacingOccurrences(of: "₹", with: "").replacingOccurrences(of: ",", with: "")) ?? 0,
                        sampleType: testItem.sampleType.displayName,
                        category: testItem.category.rawValue,
                        fastingRequired: testItem.fasting.required != "none"
                    )
                }
                
                isLoadingIndividualTests = false
            } catch {
                errorMessage = "Failed to load tests: \(error.localizedDescription)"
                showError = true
                individualTests = [] // Clear tests on error
                isLoadingIndividualTests = false
            }
        }
    }
    
    /// Select test type (health packages or individual tests)
    func selectTestType(_ type: TestSelectionType) {
        selectedTestType = type  // This will trigger didSet -> applyTestsFilters()
    }
    
    /// Select lab service type (walk-in or home collection)
    func selectLabServiceType(_ type: LabServiceType) {
        selectedLabServiceType = type
        applyFilters() // Re-filter facilities based on new selection
    }
    
}

// MARK: - Supporting Models

struct Appointment: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let facilityName: String
    let facilityId: String
    let date: Date
    let timeSlot: TimeSlot
    let serviceType: ServiceType
    var status: AppointmentStatus
    let location: String
    let notes: String?
    
    init(
        id: String = UUID().uuidString,
        facilityName: String,
        facilityId: String,
        date: Date,
        timeSlot: TimeSlot,
        serviceType: ServiceType,
        status: AppointmentStatus,
        location: String,
        notes: String? = nil
    ) {
        self.id = id
        self.facilityName = facilityName
        self.facilityId = facilityId
        self.date = date
        self.timeSlot = timeSlot
        self.serviceType = serviceType
        self.status = status
        self.location = location
        self.notes = notes
    }
    
    var appointmentDateTime: Date {
        let calendar = Calendar.current
        let timeComponents = timeSlot.startTime.split(separator: ":")
        guard let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]) else {
            return date
        }
        
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var displayTime: String {
        return timeSlot.displayTime
    }
}


struct TimeSlot: Codable, Equatable, Sendable {
    let startTime: String
    let endTime: String
    let isAvailable: Bool
    
    init(startTime: String, endTime: String, isAvailable: Bool = true) {
        self.startTime = startTime
        self.endTime = endTime
        self.isAvailable = isAvailable
    }
    
    var displayTime: String {
        return "\(startTime) - \(endTime)"
    }
}

// AppointmentStatus is now defined in BackendModels.swift to avoid duplication
// Use the consolidated version with Sendable conformance

// ServiceType is now defined in BackendModels.swift to avoid duplication
// Use the consolidated version with Sendable conformance

// MARK: - New Model Types

/// Enhanced service type options for the new UI
enum ServiceTypeOption: String, CaseIterable, Sendable {
    case labVisit = "Lab Visit"
    case homeCollection = "Home Collection"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .labVisit: return "building.2.crop.circle"
        case .homeCollection: return "house.fill"
        }
    }
}


enum TestStatus: String, Codable, CaseIterable, Sendable {
    case scheduled = "Scheduled"
    case processing = "Processing"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .scheduled: return "clock"
        case .processing: return "arrow.clockwise"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .scheduled: return HealthColors.healthWarning
        case .processing: return HealthColors.primary
        case .completed: return HealthColors.healthGood
        case .cancelled: return HealthColors.healthCritical
        }
    }
}

struct TestResult: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let value: String
    let unit: String?
    let normalRange: String?
    let status: ResultStatus
    
    init(
        id: String = UUID().uuidString,
        name: String,
        value: String,
        unit: String? = nil,
        normalRange: String? = nil,
        status: ResultStatus
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.unit = unit
        self.normalRange = normalRange
        self.status = status
    }
}

enum ResultStatus: String, Codable, CaseIterable, Sendable {
    case normal = "Normal"
    case abnormal = "Abnormal"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .normal: return HealthColors.healthGood
        case .abnormal: return HealthColors.healthWarning
        case .critical: return HealthColors.healthCritical
        }
    }
}

/// Preparation step for appointments
struct PreparationStep: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let description: String
    let isCompleted: Bool
    let dueTime: Date?
    
    init(
        id: String = UUID().uuidString,
        description: String,
        isCompleted: Bool = false,
        dueTime: Date? = nil
    ) {
        self.id = id
        self.description = description
        self.isCompleted = isCompleted
        self.dueTime = dueTime
    }
}

// MARK: - Extensions

extension Appointment {
    /// Time until appointment in human readable format
    var timeUntilAppointment: String {
        let timeInterval = appointmentDateTime.timeIntervalSinceNow
        if timeInterval < 0 {
            return "Started"
        }
        
        let hours = Int(timeInterval / 3600)
        if hours < 1 {
            let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(minutes) min"
        } else if hours < 24 {
            return "\(hours) hours"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days) days"
        }
    }
    
    /// Distance and travel time text
    var distanceText: String {
        // This would be calculated from user's location
        return "2.3 km"
    }
    
    var travelTime: String {
        return "15 min drive"
    }
    
    /// Cost and payment status
    var cost: Int {
        return 500 // This would come from the appointment details
    }
    
    var paymentStatus: String {
        return "Pre-paid" // This would be dynamic based on payment status
    }
    
    /// Preparation reminder text
    var preparationReminder: String {
        switch serviceType {
        case .bloodWork, .urinalysis, .lipidPanel, .metabolicPanel:
            return "Fast for 12 hours"
        default:
            return "Bring ID and insurance card"
        }
    }
    
    /// Preparation steps for the appointment
    var preparationSteps: [PreparationStep] {
        switch serviceType {
        case .bloodWork, .urinalysis, .lipidPanel, .metabolicPanel:
            return [
                PreparationStep(description: "Fast for 12 hours", isCompleted: true),
                PreparationStep(description: "Drink plenty of water", isCompleted: true),
                PreparationStep(description: "Bring ID and insurance card", isCompleted: false),
                PreparationStep(description: "Leave home by 2:00 PM", isCompleted: false)
            ]
        default:
            return [
                PreparationStep(description: "Bring ID and insurance card", isCompleted: false),
                PreparationStep(description: "Arrive 15 minutes early", isCompleted: false)
            ]
        }
    }
    
    /// Result status for completed appointments
    var resultStatus: String {
        if status == .completed {
            return "Results available • Normal ranges"
        } else {
            return "Results pending"
        }
    }
    
    /// Whether appointment needs follow-up
    var needsFollowUp: Bool {
        // This would be determined based on test results
        return false
    }
}

extension LabFacility {
    /// Whether facility offers appointments
    var offersAppointments: Bool {
        return true // Most facilities offer appointments
    }
    
    /// Whether facility accepts walk-ins (derived from existing property)
    var acceptsWalkIns: Bool {
        return isWalkInAvailable
    }
}

// MARK: - New Model Types for Enhanced Tests Page

/// Test selection type enum
enum TestSelectionType: String, CaseIterable, Sendable {
    case individualTests = "Tests"
    case healthPackages = "Health Packages"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .healthPackages: return "heart.text.square.fill"
        case .individualTests: return "testtube.2"
        }
    }
}

/// Lab service type enum for lab selection
enum LabServiceType: String, CaseIterable, Sendable {
    case walkIn = "Walk-in"
    case homeCollection = "Home Collection"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .walkIn: return "building.2.crop.circle"
        case .homeCollection: return "house.fill"
        }
    }
}

/// Test package model for comprehensive test bundles (renamed to avoid conflict with existing HealthPackage)
struct TestPackage: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let price: Int
    let testCount: Int
    let categories: [String]
    
    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        description: String,
        price: Int,
        testCount: Int,
        categories: [String]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.price = price
        self.testCount = testCount
        self.categories = categories
    }
    
    var displayPrice: String {
        return "₹\(price)"
    }
    
    var testCountText: String {
        return "\(testCount) tests included"
    }
    
    var categoriesText: String {
        return categories.joined(separator: " • ")
    }
}

/// Individual test model for specific medical tests
struct IndividualTest: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let price: Int
    let sampleType: String
    let category: String
    let fastingRequired: Bool
    
    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        description: String,
        price: Int,
        sampleType: String,
        category: String,
        fastingRequired: Bool
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.price = price
        self.sampleType = sampleType
        self.category = category
        self.fastingRequired = fastingRequired
    }
    
    var displayPrice: String {
        return "₹\(price)"
    }
    
    var sampleTypeText: String {
        return "Sample: \(sampleType)"
    }
    
    var fastingText: String {
        return fastingRequired ? "Fasting required" : "No fasting required"
    }
    
    var categoryWithSampleText: String {
        return "\(category) • \(sampleType)"
    }
}

// MARK: - Integration Notes

// MARK: - Appointment-Specific Models (renamed to avoid conflicts)

/// Lab facility model specifically for appointment booking (renamed from AppointmentLabFacility)
struct AppointmentAppointmentLabFacility: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let location: String
    let services: [ServiceType]
    let rating: Double
    let reviewCount: Int
    let estimatedWaitTime: Int
    let operatingHours: String
    let phoneNumber: String
    let acceptsInsurance: Bool
    let acceptsWalkIns: Bool
    
    var displayRating: String {
        return String(format: "%.1f", rating)
    }
    
    var waitTimeText: String {
        return "\(estimatedWaitTime) min wait"
    }
}

/// Health test model specifically for appointment management (renamed from AppointmentTest)
struct AppointmentTest: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let category: String
    let status: TestStatus
    let scheduledDate: Date?
    let completedDate: Date?
    let facilityName: String
    let results: [TestResult]?
    let aiInsights: String?
    let cost: Int
    let needsFollowUp: Bool
}

// MARK: - Filter Enums

/// Distance filter options for lab search
enum DistanceFilter: String, CaseIterable, Sendable {
    case within2km = "Within 2 km"
    case within5km = "Within 5 km"
    case within10km = "Within 10 km"
    case within25km = "Within 25 km"
    case any = "Any Distance"
    
    var displayName: String { rawValue }
    
    var maxDistanceKm: Double? {
        switch self {
        case .within2km: return 2.0
        case .within5km: return 5.0
        case .within10km: return 10.0
        case .within25km: return 25.0
        case .any: return nil
        }
    }
}

/// Lab feature filter options (supports multiple selection)
enum LabFeature: String, CaseIterable, Sendable {
    case walkInsAccepted = "Walk-ins Accepted"
    case homeCollection = "Home Collection"
    case sameDayReports = "Same Day Reports"
    case digitalReports = "Digital Reports"
    case freeParking = "Free Parking"
    case twentyFourHours = "24 Hours Open"
    
    var displayName: String { rawValue }
    
    /// Check if a lab facility supports this feature
    func isSupported(by facility: LabFacility) -> Bool {
        switch self {
        case .walkInsAccepted:
            return facility.isWalkInAvailable
        case .homeCollection:
            return facility.offersHomeCollection
        case .sameDayReports:
            // Check if services include same-day or fast reporting
            return facility.services.contains { service in
                service.lowercased().contains("same day") || 
                service.lowercased().contains("rapid") ||
                service.lowercased().contains("fast")
            }
        case .digitalReports:
            // Most modern facilities offer digital reports
            // This could be enhanced with actual facility data
            return facility.type != .homeCollection // Home collection typically offers digital reports
        case .freeParking:
            // Check if address/location mentions parking or if it's a hospital/large facility
            return facility.type == .hospital || 
                   facility.address?.lowercased().contains("parking") == true ||
                   facility.location.lowercased().contains("parking")
        case .twentyFourHours:
            // Check operating hours for 24-hour indication
            return facility.operatingHours.contains("24") || 
                   facility.operatingHours.lowercased().contains("24 hours") ||
                   facility.operatingHours.lowercased().contains("24/7")
        }
    }
}

/// Minimum rating filter options
enum MinimumRating: String, CaseIterable, Sendable {
    case fourPointFivePlus = "4.5+ Stars"
    case fourPointZeroPlus = "4.0+ Stars"
    case threePointFivePlus = "3.5+ Stars"
    case any = "Any Rating"
    
    var displayName: String { rawValue }
    
    var minimumValue: Double? {
        switch self {
        case .fourPointFivePlus: return 4.5
        case .fourPointZeroPlus: return 4.0
        case .threePointFivePlus: return 3.5
        case .any: return nil
        }
    }
}

/// Wait time filter options
enum WaitTimeFilter: String, CaseIterable, Sendable {
    case under15min = "Under 15 min"
    case fifteenToThirtyMin = "15-30 min"
    case thirtyToSixtyMin = "30-60 min"
    case any = "Any wait time"
    
    var displayName: String { rawValue }
    
    var maxWaitMinutes: Int? {
        switch self {
        case .under15min: return 15
        case .fifteenToThirtyMin: return 30
        case .thirtyToSixtyMin: return 60
        case .any: return nil
        }
    }
}

/*
 LabLoop API Integration Complete
 
 The AppointmentsViewModel now integrates with:
 - AppointmentLabFacilityAPIService: For facility discovery and time slot management
 - AppointmentAPIService: For appointment booking, cancellation, and management
 
 Key Features Implemented:
 - Real-time facility search with LabLoop API
 - Time slot availability checking
 - Appointment booking with patient information
 - Appointment cancellation and rescheduling
 - Error handling for all API operations
 
 Integration Points:
 - Facility search: /api/mobile/facilities
 - Facility details: /api/mobile/facilities/{id}
 - Time slots: /api/mobile/timeslots/{facilityId}?date={date}
 - User appointments: /api/mobile/appointments?userId={id}
 - Book appointment: POST /api/mobile/appointments
 - Cancel appointment: PUT /api/mobile/appointments/{id}/cancel
 
 TODO for Production:
 - Integrate with actual user authentication for currentUserId
 - Get patient information from user profile
 - Add location services for nearby facility search
 - Implement appointment reminders and notifications
 */