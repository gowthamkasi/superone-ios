import SwiftUI

/// Main dashboard view with booking-focused interface and comprehensive health services
/// 
/// This view has been updated to prioritize lab test booking over health score display,
/// featuring:
/// - LabBookingHeroCard: Primary CTA for test booking
/// - ServiceOptionsGrid: Four main service types (Online Booking, Home Collection, Test Packages, Quick Tests)
/// - QuickActionsBar: Common actions with prominent "Book Now" button
/// - FeaturedPackagesSection: Health test packages with pricing and details
///
/// Legacy components (HealthScoreCard, QuickOverviewSection, RecentActivitySection) 
/// have been replaced to better serve the lab booking workflow.
struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var isInitialized = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                // Replace LazyVStack with VStack for better performance with small datasets
                VStack(alignment: .leading, spacing: HealthSpacing.sectionSpacing) {
                    // Header Section
                    DashboardHeaderView(
                        locationManager: viewModel.locationManager,
                        notificationCount: viewModel.notificationCount,
                        onNotificationTap: viewModel.handleNotificationTap,
                        onLocationChange: {
                            // Handle location change - could show location picker sheet
                            print("Location change tapped from dashboard")
                        }
                    )
                    .padding(.horizontal, HealthSpacing.screenPadding)
                    
                    // Lab Booking Hero Card - PRIMARY CTA for booking tests
                    LabBookingHeroCard {
                        // Navigate to main booking flow
                        viewModel.handleQuickAction(.bookTest)
                    }
                    .padding(.horizontal, HealthSpacing.screenPadding)
                    
                    // Service Options - Horizontal layout with circular buttons
                    ServiceOptionsGrid(
                        onOnlineBookingTap: {
                            viewModel.handleQuickAction(.bookTest)
                        },
                        onHomeCollectionTap: {
                            // TODO: Implement home collection flow
                            viewModel.handleQuickAction(.bookTest)
                        },
                        onTestPackagesTap: {
                            viewModel.navigateToAllPackages()
                        },
                        onQuickTestsTap: {
                            // TODO: Implement quick tests flow
                            viewModel.handleQuickAction(.bookTest)
                        }
                    )
                    
                    // Quick Actions - Grid layout with detailed cards
                    QuickActionsBar(
                        onBookNow: {
                            viewModel.handleQuickAction(.bookTest)
                        },
                        onFindLabs: {
                            viewModel.handleQuickAction(.findLabs)
                        },
                        onViewPackages: {
                            viewModel.navigateToAllPackages()
                        },
                        onTrackSample: {
                            // TODO: Implement sample tracking
                            viewModel.handleQuickAction(.viewReports)
                        }
                    )
                    
                    
                    // Bottom spacing for tab bar (handled by safe area)
                    Spacer()
                        .frame(height: HealthSpacing.xl)
                }
                .padding(.top, HealthSpacing.md)
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            .scrollTargetBehavior(.viewAligned)
            .onScrollGeometryChange(for: CGPoint.self) { geometry in
                geometry.contentOffset
            } action: { oldValue, newValue in
                handleScrollPositionChange(from: oldValue, to: newValue)
            }
            .background(HealthColors.background.ignoresSafeArea())
            .overlay(
                // Loading overlay
                Group {
                    if viewModel.isLoading {
                        LoadingOverlay(message: "Loading dashboard...", isVisible: true)
                    }
                }
            )
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
                Button("Retry") {
                    Task {
                        await viewModel.refreshData()
                    }
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .onAppear {
            // Initialize dashboard view
            if !isInitialized {
                isInitialized = true
            }
        }
        .task {
            // Initial data load happens in viewModel init
            // This ensures we have fresh data when view appears
            await viewModel.refreshData()
        }
    }
    
    // MARK: - Private Methods
    
    private func handleScrollPositionChange(from oldValue: CGPoint, to newValue: CGPoint) {
        // Enhanced scroll handling for iOS 18+
        let scrollDelta = newValue.y - oldValue.y
        
        // Trigger haptic feedback for significant scroll events
        if abs(scrollDelta) > 50 {
            HapticFeedback.light()
        }
        
        // Optimize performance by batching scroll updates
        viewModel.updateScrollPosition(newValue.y)
    }
}

// MARK: - Dashboard Header View with Simple One-Time Animation
struct DashboardHeaderView: View {
    @Bindable var locationManager: LocationManager
    let notificationCount: Int
    let onNotificationTap: () -> Void
    let onLocationChange: () -> Void
    
    @State private var hasAppeared = false
    @State private var showLocation = false
    @State private var showNotification = false
    
    var body: some View {
        HStack {
            // Location selector button
            LocationSelectorButton(
                currentLocation: locationManager.currentLocationText ?? "Getting location...",
                onLocationChange: onLocationChange
            )
            .opacity(showLocation ? 1 : 0)
            .offset(x: showLocation ? 0 : -20)
            .scaleEffect(showLocation ? 1.0 : 0.9)
            .animation(.spring(duration: 0.4, bounce: 0.1).delay(0.1), value: showLocation)
            
            Spacer()
            
            // Notification button with badge and simple animation
            NotificationButton(
                count: notificationCount,
                onTap: onNotificationTap
            )
            .opacity(showNotification ? 1 : 0)
            .scaleEffect(showNotification ? 1.0 : 0.3)
            .rotationEffect(.degrees(showNotification ? 0 : 45))
            .animation(.spring(duration: 0.4, bounce: 0.4).delay(0.3), value: showNotification)
        }
        .onAppear {
            // Only animate once when the view first appears
            if !hasAppeared {
                hasAppeared = true
                startSimpleHeaderAnimation()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startSimpleHeaderAnimation() {
        // Animate elements sequentially, only once
        showLocation = true
        showNotification = true
    }
}

// MARK: - Legacy Components (Kept for reference - can be removed in future)
// QuickOverviewSection and RecentActivitySection have been replaced by
// ServiceOptionsGrid, QuickActionsBar, and FeaturedPackagesSection

// MARK: - Legacy Health Categories (Kept for potential future use)
// HealthCategoriesSlider has been replaced by ServiceOptionsGrid for booking focus
// Remove showingHealthCategories state and related UI when confirmed not needed

// MARK: - Notification Button
struct NotificationButton: View {
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Image(systemName: "bell")
                    .font(.system(size: 24))
                    .foregroundColor(HealthColors.primary)
                
                if count > 0 {
                    Badge(count: count)
                        .offset(x: 12, y: -12)
                }
            }
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Badge
struct Badge: View {
    let count: Int
    
    var body: some View {
        Text("\(min(count, 99))")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(minWidth: 16, minHeight: 16)
            .background(Circle().fill(Color.red))
            .scaleEffect(count > 0 ? 1.0 : 0.0)
            .animation(.spring(duration: 0.3, bounce: 0.5), value: count)
    }
}

// LoadingOverlay is defined in core/UI/LoadingView.swift to avoid duplication

// MARK: - Lab Report Processing Activity Models

/// Activity type for lab report processing activities
enum LabActivityType {
    case labProcessing
    case labCompleted
    case labFailed
    
    var color: Color {
        switch self {
        case .labProcessing:
            return HealthColors.primary
        case .labCompleted:
            return HealthColors.healthExcellent
        case .labFailed:
            return HealthColors.healthCritical
        }
    }
}

/// Model for lab report processing activities shown in dashboard
struct LabReportProcessingActivity: Identifiable, Codable {
    let id: String
    let documentId: String
    let fileName: String
    let status: ProcessingStatus
    let startTime: Date
    let endTime: Date?
    let biomarkersExtracted: Int?
    let confidence: Double?
    
    init(
        id: String = UUID().uuidString,
        documentId: String,
        fileName: String,
        status: ProcessingStatus,
        startTime: Date,
        endTime: Date? = nil,
        biomarkersExtracted: Int? = nil,
        confidence: Double? = nil
    ) {
        self.id = id
        self.documentId = documentId
        self.fileName = fileName
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.biomarkersExtracted = biomarkersExtracted
        self.confidence = confidence
    }
    
    var timeAgo: String {
        let relevantTime = endTime ?? startTime
        let interval = Date().timeIntervalSince(relevantTime)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    var activityTitle: String {
        switch status {
        case .pending, .uploading, .preprocessing:
            return "Lab Report Uploading"
        case .processing, .analyzing, .extracting:
            return "Processing Lab Report"
        case .validating:
            return "Validating Data"
        case .completed:
            return "Lab Report Analyzed"
        case .failed:
            return "Processing Failed"
        case .cancelled:
            return "Processing Cancelled"
        case .paused:
            return "Processing Paused"
        case .retrying:
            return "Retrying Processing"
        }
    }
    
    var activitySubtitle: String {
        switch status {
        case .completed:
            if let count = biomarkersExtracted {
                return "Found \(count) biomarkers"
            } else {
                return fileName
            }
        case .failed:
            return "Tap to retry"
        case .processing, .analyzing, .extracting:
            return "Analyzing \(fileName)"
        default:
            return fileName
        }
    }
    
    var activityIcon: String {
        switch status {
        case .pending, .uploading:
            return "arrow.up.circle"
        case .preprocessing, .processing, .analyzing, .extracting, .validating:
            return "doc.text.magnifyingglass"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.circle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .retrying:
            return "arrow.clockwise.circle"
        }
    }
    
    var activityType: LabActivityType {
        switch status {
        case .pending, .uploading, .preprocessing, .processing, .analyzing, .extracting, .validating, .retrying, .paused:
            return .labProcessing
        case .completed:
            return .labCompleted
        case .failed, .cancelled:
            return .labFailed
        }
    }
}

/// Specialized activity item for lab report processing
struct LabReportActivityItem: View {
    let activity: LabReportProcessingActivity
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            // Icon with processing animation for active states
            ZStack {
                Circle()
                    .fill(activity.activityType.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                if activity.status.isActive {
                    // Animated processing indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: activity.activityType.color))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: activity.activityIcon)
                        .font(.system(size: 18))
                        .foregroundColor(activity.activityType.color)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(activity.activityTitle)
                    .font(HealthTypography.subheadline)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(activity.activitySubtitle)
                    .font(HealthTypography.caption1)
                    .foregroundColor(HealthColors.secondaryText)
                    .lineLimit(1)
                
                // Progress indicator for active processing
                if activity.status.isActive {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle(tint: activity.activityType.color))
                        .frame(height: 2)
                }
            }
            
            Spacer()
            
            // Time and status
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.timeAgo)
                    .font(HealthTypography.caption2)
                    .foregroundColor(HealthColors.tertiaryText)
                
                if let confidence = activity.confidence, activity.status == .completed {
                    Text("\(Int(confidence * 100))%")
                        .font(HealthTypography.caption2)
                        .foregroundColor(activity.activityType.color)
                }
            }
        }
        .padding(.vertical, HealthSpacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            // Navigate to lab report details or retry processing
            handleActivityTap()
        }
    }
    
    private func handleActivityTap() {
        // Navigation to lab report details or retry options will be implemented
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(AppState())
}

#Preview("Loading State") {
    DashboardView()
        .environmentObject(AppState())
        .onAppear {
            // Simulate loading state for preview
        }
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}