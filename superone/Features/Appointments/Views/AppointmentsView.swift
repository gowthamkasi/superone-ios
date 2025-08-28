//
//  AppointmentsView.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Main appointments screen with upcoming/past appointments and lab facility booking
struct AppointmentsView: View {
    
    @State private var viewModel = AppointmentsViewModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: AppointmentTab = .schedules
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                tabContent
            }
            .background(HealthColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    LocationSelectorButton(
                        currentLocation: viewModel.locationManager.currentLocationText ?? "Getting location...",
                        onLocationChange: {
                            // Refresh location when user taps
                            viewModel.refreshLocation()
                        }
                    )
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showBookingSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(HealthColors.primary)
                            .font(.system(size: 24))
                    }
                }
            }
            .refreshable {
                await viewModel.refreshAppointments()
            }
            .onAppear {
                // Proactively request location when view appears if permissions are available
                if viewModel.locationManager.hasLocationPermission && 
                   viewModel.locationManager.locationState == .idle {
                    viewModel.getCurrentLocation()
                }
            }
            .onChange(of: viewModel.locationManager.currentLocationText) { oldValue, newValue in
                // This ensures the UI updates when location changes
                print("🔄 Location updated in UI: \(newValue ?? "nil")")
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToTestsTab"))) { _ in
                // Switch to Tests tab when navigated from Reports
                selectedTab = .tests
            }
            .sheet(isPresented: $viewModel.showBookingSheet) {
                BookingSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showAppointmentDetail) {
                if let appointment = viewModel.selectedAppointment {
                    AppointmentDetailSheet(appointment: appointment)
                }
            }
            .sheet(isPresented: $viewModel.showFacilityDetail) {
                if let facility = viewModel.selectedFacility {
                    FacilityDetailSheet(facility: facility)
                }
            }
            .sheet(isPresented: $viewModel.showTestsFilterSheet) {
                TestsFilterSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showLabsFilterSheet) {
                LabsFilterSheet(viewModel: viewModel)
            }
            .alert("Cancel Appointment", isPresented: $viewModel.showCancelAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm", role: .destructive) {
                    viewModel.confirmCancellation()
                }
            } message: {
                Text("Are you sure you want to cancel this appointment? This action cannot be undone.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AppointmentTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: HealthSpacing.xs) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        
                        Text(tab.title)
                            .font(HealthTypography.captionMedium)
                    }
                    .foregroundColor(selectedTab == tab ? HealthColors.primary : HealthColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HealthSpacing.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(HealthColors.secondaryBackground)
        .overlay(
            Rectangle()
                .fill(HealthColors.secondaryText.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .schedules:
            schedulesView
        case .tests:
            testsView
        case .labs:
            labsView
        }
    }
    
    // MARK: - Schedules View
    
    private var schedulesView: some View {
        ScrollView {
            LazyVStack(spacing: HealthSpacing.lg) {
                if viewModel.isLoadingAppointments && viewModel.upcomingAppointments.isEmpty {
                    ForEach(0..<3, id: \.self) { _ in
                        AppointmentCardSkeleton()
                    }
                } else if viewModel.upcomingAppointments.isEmpty {
                    EmptySchedulesView {
                        selectedTab = .labs
                    }
                } else {
                    // Today's Schedule Banner
                    if viewModel.todaysAppointments.count > 0 {
                        TodaysScheduleBanner(appointments: viewModel.todaysAppointments)
                    }
                    
                    // Grouped appointments
                    AppointmentGroupsView(
                        todayAppointments: viewModel.todaysAppointments,
                        tomorrowAppointments: viewModel.tomorrowAppointments,
                        thisWeekAppointments: viewModel.thisWeekAppointments,
                        laterAppointments: viewModel.laterAppointments,
                        onSelectAppointment: { appointment in
                            viewModel.selectAppointment(appointment)
                        },
                        onCancelAppointment: { appointment in
                            viewModel.cancelAppointment(appointment)
                        }
                    )
                    
                    // Recent completed appointments preview
                    if !viewModel.recentCompletedAppointments.isEmpty {
                        RecentCompletedSection(
                            appointments: viewModel.recentCompletedAppointments,
                            onSelectAppointment: { appointment in
                                viewModel.selectAppointment(appointment)
                            }
                        )
                    }
                }
                
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.top, HealthSpacing.lg)
            .padding(.bottom, HealthSpacing.xl)
        }
    }
    
    // MARK: - Tests View
    
    private var testsView: some View {
        ScrollView {
            LazyVStack(spacing: HealthSpacing.lg) {
                // Search bar
                TestsSearchBar(
                    searchText: $viewModel.testsSearchText,
                    onFilterTap: {
                        viewModel.showTestsFilterSheet = true
                    }
                )
                
                // Radio button selection for test type
                RadioButtonSelector(
                    selectedType: viewModel.selectedTestType,
                    onSelectionChange: { type in
                        viewModel.selectTestType(type)
                    }
                )
                
                // Content based on selected test type
                if viewModel.selectedTestType == .healthPackages {
                    healthPackagesContent
                } else {
                    individualTestsContent
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.top, HealthSpacing.lg)
            .padding(.bottom, HealthSpacing.xl)
        }
    }
    
    // MARK: - Health Packages Content
    
    @ViewBuilder
    private var healthPackagesContent: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.xl) {
            ForEach(viewModel.testPackages) { package in
                TestPackageCard(
                    package: package,
                    onBook: {
                        // Handle package booking
                    },
                    onViewDetails: {
                        // Navigation handled by NavigationLink in card
                    }
                )
            }
        }
    }
    
    // MARK: - Individual Tests Content
    
    @ViewBuilder
    private var individualTestsContent: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.xl) {
            ForEach(viewModel.individualTests) { test in
                IndividualTestCard(
                    test: test,
                    onBook: {
                        // Handle individual test booking
                    },
                    onViewDetails: {
                        // Navigation handled by NavigationLink in card
                    }
                )
            }
        }
    }
    
    // MARK: - Labs View
    
    private var labsView: some View {
        ScrollView {
            LazyVStack(spacing: HealthSpacing.lg) {
                // Search bar
                LabsSearchBar(
                    viewModel: viewModel,
                    onFilterTap: {
                        viewModel.showLabsFilterSheet = true
                    }
                )
                
                // Radio button selection for service type
                LabServiceTypeSelector(
                    selectedType: viewModel.selectedLabServiceType,
                    onSelectionChange: { type in
                        viewModel.selectLabServiceType(type)
                    }
                )
                
                // Content based on selected service type
                if viewModel.selectedLabServiceType == .walkIn {
                    walkInLabsContent
                } else {
                    homeCollectionContent
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.top, HealthSpacing.lg)
            .padding(.bottom, HealthSpacing.xl)
        }
        .onAppear {
            // Lazy load lab facilities only when Labs tab is accessed
            viewModel.loadLabFacilitiesIfNeeded()
        }
    }
    
    // MARK: - Walk-in Labs Content
    
    @ViewBuilder
    private var walkInLabsContent: some View {
        if viewModel.isLoadingFacilities && viewModel.filteredFacilities.isEmpty {
            VStack(spacing: HealthSpacing.lg) {
                ForEach(0..<4, id: \.self) { _ in
                    FacilityCardSkeleton()
                }
            }
        } else if viewModel.filteredFacilities.isEmpty {
            EmptyFacilitiesView()
        } else {
            VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                // Featured/Recommended labs
                if !viewModel.recommendedFacilities.isEmpty {
                    LabsSection(
                        title: "⭐ Recommended for You",
                        facilities: viewModel.recommendedFacilities,
                        onBook: { facility in
                            viewModel.selectFacility(facility)
                        },
                        onViewDetails: { facility in
                            viewModel.showFacilityDetails(facility)
                        }
                    )
                }
                
                // Regular lab listings
                LabsSection(
                    title: viewModel.recommendedFacilities.isEmpty ? "Available Labs" : "More Labs",
                    facilities: viewModel.regularFacilities,
                    onBook: { facility in
                        viewModel.selectFacility(facility)
                    },
                    onViewDetails: { facility in
                        viewModel.showFacilityDetails(facility)
                    }
                )
                
                // Recently viewed labs
                if !viewModel.recentlyViewedFacilities.isEmpty {
                    RecentlyViewedSection(facilities: viewModel.recentlyViewedFacilities) { facility in
                        viewModel.showFacilityDetails(facility)
                    }
                }
            }
        }
    }
    
    // MARK: - Home Collection Content
    
    @ViewBuilder
    private var homeCollectionContent: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.xl) {
            // Home collection services
            HomeCollectionSection(viewModel: viewModel)
            
            // Quick test booking
            QuickTestBookingSection()
        }
    }
    
}

// MARK: - New Component Views

// MARK: - Schedules Components

struct TodaysScheduleBanner: View {
    let appointments: [Appointment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Header with date
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(HealthColors.primary)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text("Today, \(Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))")
                        .font(HealthTypography.headline)
                        .foregroundColor(HealthColors.primaryText)
                    
                    if let nextAppointment = appointments.first {
                        Text("Next: \(nextAppointment.serviceType.displayName) in \(nextAppointment.timeUntilAppointment)")
                            .font(HealthTypography.body)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
                
                Spacer()
            }
            
            // Quick actions
            HStack(spacing: HealthSpacing.md) {
                Button("View Details") {
                    // Handle view details
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primary)
                .padding(.horizontal, HealthSpacing.lg)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.primary.opacity(0.1))
                .cornerRadius(HealthCornerRadius.button)
                
                Button("Get Directions") {
                    // Handle directions
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(.white)
                .padding(.horizontal, HealthSpacing.lg)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.primary)
                .cornerRadius(HealthCornerRadius.button)
                
                Spacer()
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct AppointmentGroupsView: View {
    let todayAppointments: [Appointment]
    let tomorrowAppointments: [Appointment]
    let thisWeekAppointments: [Appointment]
    let laterAppointments: [Appointment]
    let onSelectAppointment: (Appointment) -> Void
    let onCancelAppointment: (Appointment) -> Void
    
    var body: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Today's appointments
            if !todayAppointments.isEmpty {
                AppointmentGroup(
                    title: "Today",
                    appointments: todayAppointments,
                    onSelectAppointment: onSelectAppointment,
                    onCancelAppointment: onCancelAppointment
                )
            }
            
            // Tomorrow's appointments
            if !tomorrowAppointments.isEmpty {
                AppointmentGroup(
                    title: "Tomorrow, \(Date().addingTimeInterval(86400).formatted(.dateTime.month(.abbreviated).day()))",
                    appointments: tomorrowAppointments,
                    onSelectAppointment: onSelectAppointment,
                    onCancelAppointment: onCancelAppointment
                )
            }
            
            // This week's appointments
            if !thisWeekAppointments.isEmpty {
                AppointmentGroup(
                    title: "This Week",
                    appointments: thisWeekAppointments,
                    onSelectAppointment: onSelectAppointment,
                    onCancelAppointment: onCancelAppointment
                )
            }
            
            // Later appointments
            if !laterAppointments.isEmpty {
                AppointmentGroup(
                    title: "Later",
                    appointments: laterAppointments,
                    onSelectAppointment: onSelectAppointment,
                    onCancelAppointment: onCancelAppointment
                )
            }
        }
    }
}

struct AppointmentGroup: View {
    let title: String
    let appointments: [Appointment]
    let onSelectAppointment: (Appointment) -> Void
    let onCancelAppointment: (Appointment) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text(title)
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
                .padding(.horizontal, HealthSpacing.lg)
            
            VStack(spacing: HealthSpacing.md) {
                ForEach(appointments) { appointment in
                    EnhancedAppointmentCard(
                        appointment: appointment,
                        onTap: { onSelectAppointment(appointment) },
                        onCancel: appointment.status == .confirmed ? { onCancelAppointment(appointment) } : nil
                    )
                }
            }
        }
    }
}

struct EnhancedAppointmentCard: View {
    let appointment: Appointment
    let onTap: () -> Void
    let onCancel: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                // Header
                HStack {
                    HStack(spacing: HealthSpacing.sm) {
                        Image(systemName: appointment.serviceType.icon)
                            .foregroundColor(HealthColors.primary)
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                            Text(appointment.serviceType.displayName)
                                .font(HealthTypography.bodyMedium)
                                .foregroundColor(HealthColors.primaryText)
                            
                            Text("\(appointment.displayTime)")
                                .font(HealthTypography.body)
                                .foregroundColor(HealthColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    AppointmentStatusBadge(status: appointment.status)
                }
                
                Text(appointment.facilityName)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.secondaryText)
                
                // Enhanced info section
                VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                    // Preparation checklist for today's appointments
                    if Calendar.current.isDateInToday(appointment.date) {
                        PreparationChecklist(appointment: appointment)
                    }
                    
                    // Location and payment info
                    HStack {
                        Label("\(appointment.distanceText) • \(appointment.travelTime)", systemImage: "location")
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primary)
                        
                        Spacer()
                        
                        Label("₹\(appointment.cost) • \(appointment.paymentStatus)", systemImage: "creditcard")
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                    
                    // Action buttons
                    HStack(spacing: HealthSpacing.sm) {
                        if Calendar.current.isDateInToday(appointment.date) {
                            Button("Get Directions") {
                                // Handle directions
                            }
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primary)
                        } else {
                            Button("View Details") {
                                onTap()
                            }
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primary)
                        }
                        
                        Button("Reschedule") {
                            // Handle reschedule
                        }
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                        
                        if let onCancel = onCancel {
                            Button("Cancel") {
                                onCancel()
                            }
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.healthCritical)
                        }
                        
                        Spacer()
                    }
                }
                .padding(HealthSpacing.md)
                .background(HealthColors.tertiaryBackground)
                .cornerRadius(HealthCornerRadius.md)
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PreparationChecklist: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(HealthColors.healthWarning)
                    .font(.system(size: 16))
                
                Text("Reminder: \(appointment.preparationReminder)")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primaryText)
            }
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text("Preparation:")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                ForEach(appointment.preparationSteps, id: \.self) { step in
                    HStack(spacing: HealthSpacing.xs) {
                        Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "clock")
                            .foregroundColor(step.isCompleted ? HealthColors.healthGood : HealthColors.healthWarning)
                            .font(.system(size: 12))
                        
                        Text(step.description)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                            .strikethrough(step.isCompleted)
                    }
                }
            }
        }
        .padding(HealthSpacing.sm)
        .background(HealthColors.healthWarning.opacity(0.05))
        .cornerRadius(HealthCornerRadius.sm)
    }
}


struct RecentCompletedSection: View {
    let appointments: [Appointment]
    let onSelectAppointment: (Appointment) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Recent Completed")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                ForEach(appointments.prefix(3)) { appointment in
                    CompletedAppointmentRow(appointment: appointment) {
                        onSelectAppointment(appointment)
                    }
                }
                
                if appointments.count > 3 {
                    Button("View All History") {
                        // Handle view all history
                    }
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HealthSpacing.sm)
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
        }
    }
}

struct CompletedAppointmentRow: View {
    let appointment: Appointment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text("\(appointment.serviceType.displayName) - \(appointment.displayDate)")
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    HStack(spacing: HealthSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(HealthColors.healthGood)
                            .font(.system(size: 12))
                        
                        Text(appointment.resultStatus)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(spacing: HealthSpacing.xs) {
                    Button("View Report") {
                        onTap()
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                    
                    if appointment.needsFollowUp {
                        Button("Book Follow-up") {
                            // Handle follow-up booking
                        }
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.healthWarning)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptySchedulesView: View {
    let onFindLabs: () -> Void
    
    var body: some View {
        VStack(spacing: HealthSpacing.xl) {
            VStack(spacing: HealthSpacing.lg) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 60))
                    .foregroundColor(HealthColors.primary)
                
                VStack(spacing: HealthSpacing.sm) {
                    Text("No Upcoming Appointments")
                        .font(HealthTypography.headline)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text("Schedule your next health check-up")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(HealthSpacing.xl)
    }
}

// MARK: - Tests Tab Components





struct TestsSection: View {
    let title: String
    let tests: [HealthTest]
    let onTestTap: (HealthTest) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text(title)
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                // For demo purposes, show placeholder test cards
                TestCard(
                    testName: "Complete Blood Count (CBC)",
                    status: "Scheduled",
                    appointmentInfo: "Tomorrow 9:30 AM",
                    facilityName: "LabLoop Central Lab",
                    onTap: {}
                )
                
                TestCard(
                    testName: "Lipid Profile",
                    status: "Results Available",
                    appointmentInfo: "Completed: Aug 15, 2025",
                    facilityName: "LabLoop Central Lab",
                    onTap: {}
                )
            }
        }
    }
}

struct TestCard: View {
    let testName: String
    let status: String
    let appointmentInfo: String
    let facilityName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                        Text(testName)
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(HealthColors.primaryText)
                            .multilineTextAlignment(.leading)
                        
                        Text(appointmentInfo)
                            .font(HealthTypography.body)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text(status)
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(status.contains("Available") ? HealthColors.healthGood : HealthColors.healthWarning)
                        .padding(.horizontal, HealthSpacing.sm)
                        .padding(.vertical, 4)
                        .background((status.contains("Available") ? HealthColors.healthGood : HealthColors.healthWarning).opacity(0.1))
                        .cornerRadius(12)
                }
                
                Text(facilityName)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                
                // Action buttons
                HStack(spacing: HealthSpacing.sm) {
                    if status.contains("Available") {
                        Button("View Report") { onTap() }
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primary)
                        
                        Button("Download PDF") {}
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primary)
                        
                        Button("Share") {}
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primary)
                    } else {
                        Button("View Details") { onTap() }
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primary)
                        
                        Button("Reschedule") {}
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primary)
                    }
                    
                    Spacer()
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TestsSearchBar: View {
    @Binding var searchText: String
    let onFilterTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(HealthColors.secondaryText)
            
            TextField("Search tests or results...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(HealthTypography.body)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            Button(action: onFilterTap) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(HealthColors.primary)
            }
        }
        .padding(.horizontal, HealthSpacing.lg)
        .padding(.vertical, HealthSpacing.md)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.button)
    }
}

struct LabsSearchBar: View {
    @Bindable var viewModel: AppointmentsViewModel
    let onFilterTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(HealthColors.secondaryText)
            
            TextField("Search labs, tests, or areas...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(HealthTypography.body)
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            Button(action: onFilterTap) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(HealthColors.primary)
            }
        }
        .padding(.horizontal, HealthSpacing.lg)
        .padding(.vertical, HealthSpacing.md)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.button)
    }
}



struct EmptyTestsView: View {
    let onFindLabs: () -> Void
    
    var body: some View {
        VStack(spacing: HealthSpacing.xl) {
            VStack(spacing: HealthSpacing.lg) {
                Image(systemName: "testtube.2")
                    .font(.system(size: 60))
                    .foregroundColor(HealthColors.primary)
                
                VStack(spacing: HealthSpacing.sm) {
                    Text("No Tests Yet")
                        .font(HealthTypography.headline)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text("Start your health journey by booking your first test")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(HealthSpacing.xl)
    }
}

struct QuickBookTestSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Book New Test")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                QuickTestRow(
                    icon: "drop.fill",
                    testName: "Complete Blood Count",
                    price: "₹500",
                    description: "Comprehensive blood analysis"
                )
                
                QuickTestRow(
                    icon: "heart.fill",
                    testName: "Lipid Profile",
                    price: "₹800",
                    description: "Heart health assessment"
                )
                
                QuickTestRow(
                    icon: "flame.fill",
                    testName: "Diabetes Panel",
                    price: "₹600",
                    description: "Blood sugar monitoring"
                )
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct QuickTestRow: View {
    let icon: String
    let testName: String
    let price: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(HealthColors.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                HStack {
                    Text(testName)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Spacer()
                    
                    Text(price)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                }
                
                Text(description)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Button("Quick Book") {}
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primary)
                .padding(.horizontal, HealthSpacing.sm)
                .padding(.vertical, 4)
                .background(HealthColors.primary.opacity(0.1))
                .cornerRadius(12)
        }
        .padding(.vertical, HealthSpacing.xs)
    }
}

struct HealthTrendsPreview: View {
    let viewModel: AppointmentsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Your Health Trends")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                HealthTrendRow(
                    title: "Cholesterol: Improving",
                    subtitle: "Down 25 mg/dL since February",
                    status: .improving
                )
                
                HealthTrendRow(
                    title: "Blood Sugar: Stable",
                    subtitle: "Consistent good control",
                    status: .stable
                )
                
                HealthTrendRow(
                    title: "Vitamin D: Needs Attention",
                    subtitle: "Below optimal range",
                    status: .needsAttention
                )
            }
            
            Button("View Detailed Analysis") {}
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, HealthSpacing.sm)
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct HealthTrendRow: View {
    let title: String
    let subtitle: String
    let status: TrendStatus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                HStack {
                    Text(title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Image(systemName: status.icon)
                        .foregroundColor(status.color)
                        .font(.system(size: 16))
                }
                
                Text(subtitle)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
        }
    }
}

enum TrendStatus {
    case improving
    case stable
    case needsAttention
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .needsAttention: return "arrow.down.right"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return HealthColors.healthGood
        case .stable: return HealthColors.primary
        case .needsAttention: return HealthColors.healthWarning
        }
    }
}

struct TestCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    SkeletonRectangle(width: 180, height: 16)
                    SkeletonRectangle(width: 140, height: 14)
                }
                
                Spacer()
                
                SkeletonRectangle(width: 80, height: 24)
            }
            
            SkeletonRectangle(width: 160, height: 14)
            
            HStack(spacing: HealthSpacing.sm) {
                SkeletonRectangle(width: 80, height: 20)
                SkeletonRectangle(width: 60, height: 20)
                Spacer()
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

// MARK: - Labs Tab Components


struct QuickFilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Button(title) {}
            .font(HealthTypography.captionRegular)
            .foregroundColor(isSelected ? .white : HealthColors.secondaryText)
            .padding(.horizontal, HealthSpacing.sm)
            .padding(.vertical, 4)
            .background(isSelected ? HealthColors.primary : HealthColors.secondaryText.opacity(0.1))
            .cornerRadius(16)
    }
}

struct LabsSection: View {
    let title: String
    let facilities: [LabFacility]
    let onBook: (LabFacility) -> Void
    let onViewDetails: (LabFacility) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text(title)
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                // For now, show enhanced facility cards using existing data
                ForEach(facilities.prefix(3)) { facility in
                    EnhancedFacilityCard(
                        facility: facility,
                        onBook: { onBook(facility) },
                        onViewDetails: { onViewDetails(facility) }
                    )
                }
            }
        }
    }
}

struct EnhancedFacilityCard: View {
    let facility: LabFacility
    let onBook: () -> Void
    let onViewDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Header with enhanced info
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(facility.name)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(2)
                    
                    Text(facility.location)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: HealthSpacing.xs) {
                    HStack(spacing: HealthSpacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundColor(HealthColors.healthWarning)
                            .font(.system(size: 12))
                        
                        Text(facility.displayRating)
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primaryText)
                    }
                    
                    Text("(\(facility.reviewCount) reviews)")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            // Enhanced status info
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                HStack {
                    Label("Current wait: 15 min", systemImage: "clock")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.healthGood)
                    
                    Spacer()
                    
                    if facility.acceptsWalkIns {
                        Label("Walk-ins OK", systemImage: "checkmark.circle.fill")
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.healthGood)
                    }
                }
                
                HStack {
                    Label("Digital reports in 24h", systemImage: "doc.text")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                    
                    Spacer()
                    
                    Label("Free parking", systemImage: "car.fill")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                }
            }
            
            // Sample pricing
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text("Sample Pricing:")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                HStack {
                    Text("• CBC - ₹500 • Lipid Profile - ₹800")
                    Spacer()
                }
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.secondaryText)
                
                Text("Next Available: Today 3:00 PM")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.healthGood)
            }
            
            // Enhanced action buttons
            HStack(spacing: HealthSpacing.md) {
                Button("View All Tests") {
                    onViewDetails()
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.primary.opacity(0.1))
                .cornerRadius(HealthCornerRadius.button)
                
                Button("Book Appointment") {
                    onBook()
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.primary)
                .cornerRadius(HealthCornerRadius.button)
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct HomeCollectionSection: View {
    let viewModel: AppointmentsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("🏠 Home Collection Services")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                HomeCollectionCard(
                    serviceName: "MedHome Diagnostics",
                    rating: 4.7,
                    availability: "Today 6PM-8PM",
                    collectionFee: "₹200 (waived >₹1500)",
                    coverage: "Service across Pune"
                )
            }
        }
    }
}

struct HomeCollectionCard: View {
    let serviceName: String
    let rating: Double
    let availability: String
    let collectionFee: String
    let coverage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(serviceName)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    HStack(spacing: HealthSpacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundColor(HealthColors.healthWarning)
                            .font(.system(size: 12))
                        
                        Text(String(format: "%.1f", rating))
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primaryText)
                        
                        Text("• \(coverage)")
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                HStack {
                    Label("Available: \(availability)", systemImage: "calendar")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.healthGood)
                    
                    Spacer()
                }
                
                HStack {
                    Label("Collection fee: \(collectionFee)", systemImage: "creditcard")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                    
                    Spacer()
                }
                
                HStack {
                    Label("Same day reports", systemImage: "doc.text")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                    
                    Spacer()
                }
            }
            
            HStack(spacing: HealthSpacing.md) {
                Button("Schedule Collection") {}
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HealthSpacing.sm)
                    .background(HealthColors.primary)
                    .cornerRadius(HealthCornerRadius.button)
                
                Button("Call Service") {}
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HealthSpacing.sm)
                    .background(HealthColors.primary.opacity(0.1))
                    .cornerRadius(HealthCornerRadius.button)
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct QuickTestBookingSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Quick Book Popular Tests")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                QuickTestBookingRow(
                    testName: "Complete Blood Count",
                    availability: "Available at 8 nearby labs",
                    price: "From ₹450"
                )
                
                QuickTestBookingRow(
                    testName: "Lipid Profile",
                    availability: "Available at 12 nearby labs",
                    price: "From ₹700"
                )
                
                QuickTestBookingRow(
                    testName: "Diabetes Panel",
                    availability: "Available at 6 nearby labs",
                    price: "From ₹550"
                )
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct QuickTestBookingRow: View {
    let testName: String
    let availability: String
    let price: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(testName)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("\(availability) • \(price)")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
            
            Button("Quick Book") {}
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primary)
                .padding(.horizontal, HealthSpacing.md)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.primary.opacity(0.1))
                .cornerRadius(HealthCornerRadius.button)
        }
        .padding(.vertical, HealthSpacing.xs)
    }
}

struct RecentlyViewedSection: View {
    let facilities: [LabFacility]
    let onViewDetails: (LabFacility) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Recently Viewed")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                // For demo, show placeholder recently viewed
                RecentlyViewedRow(
                    facilityName: "LabLoop Central Laboratory",
                    timeViewed: "Viewed 2 hours ago",
                    rating: "⭐ 4.8"
                )
                
                RecentlyViewedRow(
                    facilityName: "Downtown Collection Center",
                    timeViewed: "Viewed yesterday",
                    rating: "⭐ 4.5"
                )
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct RecentlyViewedRow: View {
    let facilityName: String
    let timeViewed: String
    let rating: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(facilityName)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("\(timeViewed) • \(rating)")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
            
            HStack(spacing: HealthSpacing.sm) {
                Button("View Details") {}
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                
                Button("Book Now") {}
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
            }
        }
        .padding(.vertical, HealthSpacing.xs)
    }
}

// MARK: - Supporting Types

enum AppointmentTab: String, CaseIterable {
    case schedules = "Schedules"
    case tests = "Tests"
    case labs = "Labs"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .schedules: return "calendar"
        case .tests: return "testtube.2"
        case .labs: return "magnifyingglass"
        }
    }
}

// MARK: - Supporting Views


struct AppointmentCard: View {
    let appointment: Appointment
    let onTap: () -> Void
    let onCancel: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                        Text(appointment.facilityName)
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(HealthColors.primaryText)
                            .lineLimit(1)
                        
                        Text(appointment.location)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    AppointmentStatusBadge(status: appointment.status)
                }
                
                // Date and time
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(HealthColors.primary)
                        .frame(width: 16)
                    
                    Text(appointment.displayDate)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: "clock")
                        .foregroundColor(HealthColors.primary)
                        .frame(width: 16)
                    
                    Text(appointment.displayTime)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                }
                
                // Service type and actions
                HStack {
                    HStack(spacing: HealthSpacing.xs) {
                        Image(systemName: appointment.serviceType.icon)
                            .foregroundColor(HealthColors.primary)
                            .frame(width: 16)
                        
                        Text(appointment.serviceType.displayName)
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primaryText)
                    }
                    
                    Spacer()
                    
                    if let onCancel = onCancel, appointment.status == .confirmed {
                        Button("Cancel") {
                            onCancel()
                        }
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.healthCritical)
                    }
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FacilityCard: View {
    let facility: LabFacility
    let onBook: () -> Void
    let onViewDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(facility.name)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(2)
                    
                    Text(facility.location)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: HealthSpacing.xs) {
                    HStack(spacing: HealthSpacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundColor(HealthColors.healthWarning)
                            .font(.system(size: 12))
                        
                        Text(facility.displayRating)
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.primaryText)
                    }
                    
                    Text("(\(facility.reviewCount) reviews)")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            // Wait time and operating info
            HStack {
                Label("15 min wait", systemImage: "clock")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                
                Spacer()
                
                if facility.acceptsWalkIns {
                    Label("Walk-ins OK", systemImage: "checkmark.circle.fill")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.healthGood)
                }
            }
            
            // Services
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HealthSpacing.xs) {
                    ForEach(Array(facility.services.prefix(3)), id: \.self) { service in
                        Text(service)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.primary)
                            .padding(.horizontal, HealthSpacing.sm)
                            .padding(.vertical, 4)
                            .background(HealthColors.primary.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    if facility.services.count > 3 {
                        Text("+\(facility.services.count - 3) more")
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                            .padding(.horizontal, HealthSpacing.sm)
                            .padding(.vertical, 4)
                            .background(HealthColors.secondaryText.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: HealthSpacing.md) {
                Button("View Details") {
                    onViewDetails()
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.primary.opacity(0.1))
                .cornerRadius(HealthCornerRadius.button)
                
                Button("Book Now") {
                    onBook()
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.primary)
                .cornerRadius(HealthCornerRadius.button)
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct AppointmentStatusBadge: View {
    let status: AppointmentStatus
    
    var body: some View {
        HStack(spacing: HealthSpacing.xs) {
            Image(systemName: status.icon)
                .font(.system(size: 10, weight: .medium))
            
            Text(status.displayName)
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, HealthSpacing.sm)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .foregroundColor(status.color)
        .cornerRadius(12)
    }
}

struct ServiceFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HealthTypography.captionMedium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, HealthSpacing.md)
                .padding(.vertical, HealthSpacing.sm)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyAppointmentsView: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: HealthSpacing.xl) {
            VStack(spacing: HealthSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(HealthColors.primary)
                
                VStack(spacing: HealthSpacing.sm) {
                    Text(title)
                        .font(HealthTypography.headline)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text(message)
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HealthSpacing.xl)
                }
            }
            
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(buttonTitle) {
                    buttonAction()
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(.white)
                .padding(.horizontal, HealthSpacing.xl)
                .padding(.vertical, HealthSpacing.md)
                .background(HealthColors.primary)
                .cornerRadius(HealthCornerRadius.button)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(HealthSpacing.xl)
    }
}

struct EmptyFacilitiesView: View {
    var body: some View {
        VStack(spacing: HealthSpacing.lg) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 60))
                .foregroundColor(HealthColors.primary)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("No Facilities Found")
                    .font(HealthTypography.headline)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("Try adjusting your search terms or filters to find nearby lab facilities.")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HealthSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(HealthSpacing.xl)
    }
}

// MARK: - Skeleton Views

struct AppointmentCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    SkeletonRectangle(width: 150, height: 16)
                    SkeletonRectangle(width: 200, height: 14)
                }
                
                Spacer()
                
                SkeletonRectangle(width: 60, height: 24)
            }
            
            HStack {
                SkeletonRectangle(width: 80, height: 16)
                Spacer()
                SkeletonRectangle(width: 60, height: 16)
            }
            
            HStack {
                SkeletonRectangle(width: 100, height: 14)
                Spacer()
                SkeletonRectangle(width: 50, height: 14)
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct FacilityCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    SkeletonRectangle(width: 160, height: 16)
                    SkeletonRectangle(width: 220, height: 14)
                }
                
                Spacer()
                
                SkeletonRectangle(width: 40, height: 14)
            }
            
            HStack {
                SkeletonRectangle(width: 80, height: 14)
                Spacer()
                SkeletonRectangle(width: 70, height: 14)
            }
            
            HStack(spacing: HealthSpacing.xs) {
                SkeletonRectangle(width: 70, height: 20)
                SkeletonRectangle(width: 60, height: 20)
                SkeletonRectangle(width: 80, height: 20)
            }
            
            HStack(spacing: HealthSpacing.md) {
                SkeletonRectangle(width: nil, height: 36)
                SkeletonRectangle(width: nil, height: 36)
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct SkeletonRectangle: View {
    let width: CGFloat?
    let height: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(HealthColors.secondaryText.opacity(0.3))
            .frame(width: width, height: height)
            .cornerRadius(4)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                HealthColors.background.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                    .offset(x: isAnimating ? 200 : -200)
                    .animation(
                        Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .onAppear {
                isAnimating = true
            }
            .clipped()
    }
}

// MARK: - Enhanced Tests Page Components

struct RadioButtonSelector: View {
    let selectedType: TestSelectionType
    let onSelectionChange: (TestSelectionType) -> Void
    
    var body: some View {
        HStack(spacing: HealthSpacing.lg) {
            ForEach(TestSelectionType.allCases, id: \.self) { type in
                RadioButton(
                    title: type.displayName,
                    icon: type.icon,
                    isSelected: selectedType == type,
                    onTap: { onSelectionChange(type) }
                )
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LabServiceTypeSelector: View {
    let selectedType: LabServiceType
    let onSelectionChange: (LabServiceType) -> Void
    
    var body: some View {
        HStack(spacing: HealthSpacing.lg) {
            ForEach(LabServiceType.allCases, id: \.self) { type in
                RadioButton(
                    title: type.displayName,
                    icon: type.icon,
                    isSelected: selectedType == type,
                    onTap: { onSelectionChange(type) }
                )
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RadioButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: HealthSpacing.xs) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
            }
            .padding(.horizontal, HealthSpacing.sm)
            .padding(.vertical, HealthSpacing.xs)
            .background(isSelected ? HealthColors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(HealthCornerRadius.button)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TestPackageCard: View {
    let package: TestPackage
    let onBook: () -> Void
    let onViewDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.lg) {
            // Header with icon and name
            HStack {
                Image(systemName: package.icon)
                    .foregroundColor(HealthColors.primary)
                    .font(.system(size: 28))
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(package.name)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(package.testCountText)
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: HealthSpacing.xs) {
                    Text(package.displayPrice)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text("All inclusive")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            
            // Description
            Text(package.description)
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
                .lineLimit(3)
            
            // Categories
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HealthSpacing.xs) {
                        ForEach(package.categories, id: \.self) { category in
                            Text(category)
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(HealthColors.primary)
                                .padding(.horizontal, HealthSpacing.sm)
                                .padding(.vertical, 4)
                                .background(HealthColors.primary.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // Book button
            HStack {
                NavigationLink(destination: HealthPackageDetailsView(packageId: package.id)) {
                    Text("View Details")
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HealthSpacing.sm)
                        .background(HealthColors.primary.opacity(0.1))
                        .cornerRadius(HealthCornerRadius.button)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button("Book Package") {
                    onBook()
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.primary)
                .cornerRadius(HealthCornerRadius.button)
            }
        }
        .padding(HealthSpacing.xl)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct IndividualTestCard: View {
    let test: IndividualTest
    let onBook: () -> Void
    let onViewDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.lg) {
            // Header with icon and name
            HStack {
                Image(systemName: test.icon)
                    .foregroundColor(HealthColors.primary)
                    .font(.system(size: 24))
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(test.name)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(test.categoryWithSampleText)
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: HealthSpacing.xs) {
                    Text(test.displayPrice)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    if test.fastingRequired {
                        HStack(spacing: HealthSpacing.xs) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text("Fasting")
                                .font(HealthTypography.captionRegular)
                        }
                        .foregroundColor(HealthColors.healthWarning)
                    }
                }
            }
            
            // Description
            Text(test.description)
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
                .lineLimit(2)
            
            // Test info badges
            HStack(spacing: HealthSpacing.sm) {
                Label(test.sampleType, systemImage: "drop.fill")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                    .padding(.horizontal, HealthSpacing.sm)
                    .padding(.vertical, 4)
                    .background(HealthColors.primary.opacity(0.1))
                    .cornerRadius(12)
                
                if test.fastingRequired {
                    Label("Fasting Required", systemImage: "clock.fill")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.healthWarning)
                        .padding(.horizontal, HealthSpacing.sm)
                        .padding(.vertical, 4)
                        .background(HealthColors.healthWarning.opacity(0.1))
                        .cornerRadius(12)
                } else {
                    Label("No Fasting", systemImage: "checkmark.circle.fill")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.healthGood)
                        .padding(.horizontal, HealthSpacing.sm)
                        .padding(.vertical, 4)
                        .background(HealthColors.healthGood.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            
            // Book button
            HStack {
                NavigationLink(destination: TestDetailsView(testId: test.id)) {
                    Text("Test Details")
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HealthSpacing.sm)
                        .background(HealthColors.primary.opacity(0.1))
                        .cornerRadius(HealthCornerRadius.button)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button("Book Test") {
                    onBook()
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.primary)
                .cornerRadius(HealthCornerRadius.button)
            }
        }
        .padding(HealthSpacing.xl)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

// MARK: - Filter Sheets

struct TestsFilterSheet: View {
    @Bindable var viewModel: AppointmentsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                    
                    // Test Categories
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        Text("Test Categories")
                            .font(HealthTypography.headline)
                            .foregroundColor(HealthColors.primaryText)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: HealthSpacing.md) {
                            AppointmentFilterChip(title: "Blood Tests", isSelected: false) { }
                            AppointmentFilterChip(title: "Heart Health", isSelected: false) { }
                            AppointmentFilterChip(title: "Diabetes", isSelected: false) { }
                            AppointmentFilterChip(title: "Thyroid", isSelected: false) { }
                            AppointmentFilterChip(title: "Liver Function", isSelected: false) { }
                            AppointmentFilterChip(title: "Kidney Function", isSelected: false) { }
                            AppointmentFilterChip(title: "Vitamins", isSelected: false) { }
                            AppointmentFilterChip(title: "Hormones", isSelected: false) { }
                        }
                    }
                    
                    // Price Range
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        Text("Price Range")
                            .font(HealthTypography.headline)
                            .foregroundColor(HealthColors.primaryText)
                        
                        VStack(spacing: HealthSpacing.sm) {
                            AppointmentFilterChip(title: "Under ₹500", isSelected: false) { }
                            AppointmentFilterChip(title: "₹500 - ₹1000", isSelected: false) { }
                            AppointmentFilterChip(title: "₹1000 - ₹2000", isSelected: false) { }
                            AppointmentFilterChip(title: "Above ₹2000", isSelected: false) { }
                        }
                    }
                    
                    // Test Requirements
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        Text("Test Requirements")
                            .font(HealthTypography.headline)
                            .foregroundColor(HealthColors.primaryText)
                        
                        VStack(spacing: HealthSpacing.sm) {
                            AppointmentFilterChip(title: "No Fasting Required", isSelected: false) { }
                            AppointmentFilterChip(title: "Fasting Required", isSelected: false) { }
                            AppointmentFilterChip(title: "Same Day Results", isSelected: false) { }
                            AppointmentFilterChip(title: "Home Collection Available", isSelected: false) { }
                        }
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .padding(.vertical, HealthSpacing.lg)
            }
            .navigationTitle("Filter Tests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        // Reset filters
                    }
                    .foregroundColor(HealthColors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                    .foregroundColor(HealthColors.primary)
                }
            }
        }
    }
}

struct LabsFilterSheet: View {
    @Bindable var viewModel: AppointmentsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                    
                    // Distance
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        Text("Distance")
                            .font(HealthTypography.headline)
                            .foregroundColor(HealthColors.primaryText)
                        
                        VStack(spacing: HealthSpacing.sm) {
                            AppointmentFilterChip(title: "Within 2 km", isSelected: false) { }
                            AppointmentFilterChip(title: "Within 5 km", isSelected: false) { }
                            AppointmentFilterChip(title: "Within 10 km", isSelected: false) { }
                            AppointmentFilterChip(title: "Within 25 km", isSelected: false) { }
                        }
                    }
                    
                    // Lab Features
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        Text("Lab Features")
                            .font(HealthTypography.headline)
                            .foregroundColor(HealthColors.primaryText)
                        
                        VStack(spacing: HealthSpacing.sm) {
                            AppointmentFilterChip(title: "Walk-ins Accepted", isSelected: false) { }
                            AppointmentFilterChip(title: "Home Collection", isSelected: false) { }
                            AppointmentFilterChip(title: "Same Day Reports", isSelected: false) { }
                            AppointmentFilterChip(title: "Digital Reports", isSelected: false) { }
                            AppointmentFilterChip(title: "Free Parking", isSelected: false) { }
                            AppointmentFilterChip(title: "24 Hours Open", isSelected: false) { }
                        }
                    }
                    
                    // Rating
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        Text("Minimum Rating")
                            .font(HealthTypography.headline)
                            .foregroundColor(HealthColors.primaryText)
                        
                        VStack(spacing: HealthSpacing.sm) {
                            AppointmentFilterChip(title: "4.5+ Stars", isSelected: false) { }
                            AppointmentFilterChip(title: "4.0+ Stars", isSelected: false) { }
                            AppointmentFilterChip(title: "3.5+ Stars", isSelected: false) { }
                            AppointmentFilterChip(title: "Any Rating", isSelected: true) { }
                        }
                    }
                    
                    // Wait Time
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        Text("Expected Wait Time")
                            .font(HealthTypography.headline)
                            .foregroundColor(HealthColors.primaryText)
                        
                        VStack(spacing: HealthSpacing.sm) {
                            AppointmentFilterChip(title: "Under 15 min", isSelected: false) { }
                            AppointmentFilterChip(title: "15-30 min", isSelected: false) { }
                            AppointmentFilterChip(title: "30-60 min", isSelected: false) { }
                            AppointmentFilterChip(title: "Any wait time", isSelected: true) { }
                        }
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .padding(.vertical, HealthSpacing.lg)
            }
            .navigationTitle("Filter Labs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        // Reset filters
                    }
                    .foregroundColor(HealthColors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                    .foregroundColor(HealthColors.primary)
                }
            }
        }
    }
}

struct AppointmentFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(isSelected ? .white : HealthColors.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .padding(.horizontal, HealthSpacing.lg)
            .padding(.vertical, HealthSpacing.md)
            .background(isSelected ? HealthColors.primary : HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .stroke(isSelected ? HealthColors.primary : HealthColors.secondaryText.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Appointments View") {
    AppointmentsView()
        .environmentObject(AppState())
}

#Preview("Appointments View - Empty") {
    AppointmentsView()
        .environmentObject(AppState())
}
