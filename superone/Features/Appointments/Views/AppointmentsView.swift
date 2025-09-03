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
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(AppFlowManager.self) private var flowManager
    @State private var selectedTab: AppointmentTab = .schedules
    
    var body: some View {
        NavigationStack {
            // CRITICAL AUTHENTICATION GUARD - Redirect to login immediately without intermediate screen
            if !authManager.isAuthenticated || !TokenManager.shared.hasStoredTokens() {
                // Show minimal loading state while redirecting to login
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: HealthColors.primary))
                    Text("Redirecting to login...")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .padding(.top, HealthSpacing.sm)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(HealthColors.background.ignoresSafeArea())
                .navigationTitle("Appointments")
                .onAppear {
                    // Immediate redirect to login screen via AppFlowManager
                    Task { @MainActor in
                        // Force logout if tokens are invalid to clear state
                        if !TokenManager.shared.hasStoredTokens() && authManager.isAuthenticated {
                            try? await authManager.signOut()
                        } else {
                            // Direct flow redirect to authentication screen
                            flowManager.signOut()
                        }
                    }
                }
            } else {
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
                UniversalTestsFilterSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showLabsFilterSheet) {
                UniversalLabsFilterSheet(viewModel: viewModel)
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
            } // End of authenticated content
        } // End of NavigationStack
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AppointmentTab.allCases, id: \.self) { tab in
                Button(action: { 
                    selectedTab = tab
                    // Trigger API call when switching to Tests tab
                    if tab == .tests {
                        switch viewModel.selectedTestType {
                        case .individualTests:
                            viewModel.loadIndividualTests()
                        case .healthPackages:
                            viewModel.loadTestPackages()
                        }
                    }
                }) {
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
                    SkeletonList(count: 5, staggerDelay: 0.12) { index in
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
                UnifiedSearchBar(
                    searchText: $viewModel.testsSearchText,
                    placeholder: "Search tests or results...",
                    hasActiveFilters: false, // Tests tab doesn't currently have active filter tracking
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
        .onAppear {
            // Load tests data when Tests tab is accessed (mirrors Labs tab behavior)
            switch viewModel.selectedTestType {
            case .individualTests:
                viewModel.loadIndividualTests()    // Direct call like Labs
            case .healthPackages:
                viewModel.loadTestPackages()       // Direct call like Labs
            }
        }
    }
    
    // MARK: - Health Packages Content
    
    @ViewBuilder
    private var healthPackagesContent: some View {
        if viewModel.isLoadingPackages && viewModel.testPackages.isEmpty {
            SkeletonList(count: 4, staggerDelay: 0.1) { index in
                CardSkeleton(showImage: true, imageSize: CGSize(width: 80, height: 60), contentLines: 3)
            }
        } else if viewModel.testPackages.isEmpty {
            VStack(spacing: HealthSpacing.lg) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48))
                    .foregroundColor(HealthColors.secondaryText)
                Text("No health packages available")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                Text("Check back later for available packages")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, HealthSpacing.xxxxl)
        } else {
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
    }
    
    // MARK: - Individual Tests Content
    
    @ViewBuilder
    private var individualTestsContent: some View {
        if viewModel.isLoadingIndividualTests && viewModel.individualTests.isEmpty {
            SkeletonList(count: 5, staggerDelay: 0.1) { index in
                TestCardSkeleton()
            }
        } else if viewModel.individualTests.isEmpty {
            VStack(spacing: HealthSpacing.lg) {
                Image(systemName: "testtube.2")
                    .font(.system(size: 48))
                    .foregroundColor(HealthColors.secondaryText)
                Text("No individual tests available")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                Text("Check back later for available tests")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, HealthSpacing.xxxxl)
        } else {
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
    }
    
    // MARK: - Labs View
    
    private var labsView: some View {
        ScrollView {
            LazyVStack(spacing: HealthSpacing.lg) {
                // Search bar
                UnifiedSearchBar(
                    searchText: $viewModel.searchText,
                    placeholder: "Search labs, tests, or areas...",
                    hasActiveFilters: viewModel.hasActiveFilters,
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
            SkeletonList(count: 6, staggerDelay: 0.1) { index in
                LabFacilitySkeleton()
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
            // Home collection services - Real API integration pending
            HomeCollectionPlaceholder()
            
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
                // Real test cards will be populated from API data
                // Mock data removed for production security
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

// TestsSearchBar has been replaced by UnifiedSearchBar component
// Located at: Design/Components/UnifiedSearchBar.swift

// LabsSearchBar has been replaced by UnifiedSearchBar component
// Located at: Design/Components/UnifiedSearchBar.swift



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
                // Real test options will be loaded from API
                // No hardcoded test data for production security
                Text("Loading available tests...")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                
                // No hardcoded test data shown - only real API data
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
                // Health trends will be loaded from API - no hardcoded data
                Text("No health trends available")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, HealthSpacing.lg)
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
                    Text("• Pricing varies by test • Call for details")
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

struct HomeCollectionPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("🏠 Home Collection Services")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                // TODO: Integrate with real Home Collection API
                // Real home collection services will be loaded from API
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    Text("Home collection services are currently being set up.")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text("Please visit our lab facilities for now, or check back later for home collection options.")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.leading)
                    
                    Button("Find Lab Facilities") {
                        // This will switch to walk-in labs
                        // Implementation note: Add callback to parent view
                    }
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HealthSpacing.sm)
                    .background(HealthColors.primary)
                    .cornerRadius(HealthCornerRadius.button)
                }
                .padding(HealthSpacing.lg)
                .background(HealthColors.secondaryBackground)
                .cornerRadius(HealthCornerRadius.card)
                .healthCardShadow()
            }
        }
    }
}

// HomeCollectionCard removed - contained hardcoded mock data
// Real home collection services will be implemented with API integration

struct QuickTestBookingSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Quick Book Popular Tests")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                // Real test booking options will be loaded from API
                // Mock data removed for production security
                Text("Loading available tests...")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                
                // No hardcoded test booking data shown - only real API data
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
                // Recently viewed facilities will be loaded from API - no hardcoded data
                Text("No recently viewed facilities")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, HealthSpacing.lg)
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


// MARK: - Preview

