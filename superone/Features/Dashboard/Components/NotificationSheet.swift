//
//  NotificationSheet.swift
//  SuperOne
//
//  Created by Claude Code on 2024-12-20.
//  Health notification management sheet with InfoCard-style design
//

import SwiftUI

/// Health notification management sheet following established design patterns
@MainActor
struct NotificationSheet: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    // MARK: - State
    @State private var notifications: [HealthNotification] = []
    @State private var filteredNotifications: [HealthNotification] = []
    @State private var selectedFilter: NotificationFilter = .all
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var showingDeleteConfirmation: Bool = false
    @State private var notificationToDelete: HealthNotification?
    @State private var showingMarkAllReadConfirmation: Bool = false
    
    // MARK: - Services
    private let healthDataService: HealthDataServiceProtocol
    
    // MARK: - Initialization
    init(healthDataService: HealthDataServiceProtocol? = nil) {
        self.healthDataService = healthDataService ?? ProductionHealthDataService()
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    HealthColors.background
                        .ignoresSafeArea()
                    
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error: error)
                    } else {
                        contentView(geometry: geometry)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(HealthTypography.buttonSecondary)
                    .foregroundColor(HealthColors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Mark All Read", action: showMarkAllReadConfirmation)
                        Button("Clear All", role: .destructive) {
                            Task {
                                await clearAllNotifications()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(HealthColors.primary)
                    }
                    .disabled(notifications.isEmpty)
                }
            }
        }
        .task {
            await loadNotifications()
        }
        .refreshable {
            await loadNotifications()
        }
        .confirmationDialog(
            "Mark All Read",
            isPresented: $showingMarkAllReadConfirmation,
            titleVisibility: .visible
        ) {
            Button("Mark All Read") {
                Task {
                    await markAllNotificationsAsRead()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will mark all notifications as read.")
        }
        .confirmationDialog(
            "Delete Notification",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let notification = notificationToDelete {
                    Task {
                        await deleteNotification(notification)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This notification will be permanently deleted.")
        }
    }
    
    // MARK: - Content Views
    
    private func contentView(geometry: GeometryProxy) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HealthSpacing.lg) {
                // Filter Section
                filterSection
                
                // Notifications List
                if filteredNotifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
                
                // Bottom spacing for safe area
                Spacer()
                    .frame(height: HealthSpacing.xl)
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.top, HealthSpacing.md)
        }
        .scrollContentBackground(.hidden)
    }
    
    private var loadingView: some View {
        VStack(spacing: HealthSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: HealthColors.primary))
                .scaleEffect(1.2)
            
            Text("Loading notifications...")
                .healthTextStyle(.subheadline, color: HealthColors.secondaryText)
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: HealthSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(HealthColors.healthWarning)
            
            Text("Error Loading Notifications")
                .healthTextStyle(.headline, color: HealthColors.primaryText)
            
            Text(error)
                .healthTextStyle(.body, color: HealthColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HealthSpacing.xl)
            
            Button("Try Again") {
                Task {
                    await loadNotifications()
                }
            }
            .font(HealthTypography.buttonPrimary)
            .foregroundColor(.white)
            .frame(height: HealthSpacing.buttonHeight)
            .frame(maxWidth: 200)
            .background(HealthColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
        }
        .padding(HealthSpacing.xl)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: HealthSpacing.lg) {
            Image(systemName: "bell.slash")
                .font(.system(size: 64))
                .foregroundColor(HealthColors.secondaryText)
                .padding(.top, HealthSpacing.xxxl)
            
            Text("No Notifications")
                .healthTextStyle(.title2, color: HealthColors.primaryText)
            
            Text(emptyStateMessage)
                .healthTextStyle(.body, color: HealthColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HealthSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HealthSpacing.xxxl)
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "You're all caught up! No notifications at this time."
        case .unread:
            return "All notifications have been read."
        case .labReports:
            return "No lab report notifications."
        case .healthInsights:
            return "No health insight notifications."
        case .appointments:
            return "No appointment notifications."
        case .recommendations:
            return "No recommendation notifications."
        case .alerts:
            return "No health alert notifications."
        }
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HealthSpacing.sm) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        count: getFilterCount(for: filter)
                    ) {
                        selectedFilter = filter
                        applyFilter()
                        HapticFeedback.light()
                    }
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
        .scrollContentBackground(.hidden)
    }
    
    private var notificationsList: some View {
        LazyVStack(spacing: HealthSpacing.md) {
            ForEach(filteredNotifications) { notification in
                NotificationCard(
                    notification: notification,
                    onTap: {
                        handleNotificationTap(notification)
                    },
                    onMarkAsRead: {
                        Task {
                            await markNotificationAsRead(notification)
                        }
                    },
                    onDelete: {
                        notificationToDelete = notification
                        showingDeleteConfirmation = true
                    }
                )
                .id(notification.id)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadNotifications() async {
        isLoading = true
        errorMessage = nil
        
        do {
            notifications = try await healthDataService.fetchNotifications()
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func applyFilter() {
        filteredNotifications = NotificationFactory.filterNotifications(notifications, by: selectedFilter)
    }
    
    private func getFilterCount(for filter: NotificationFilter) -> Int {
        let filtered = NotificationFactory.filterNotifications(notifications, by: filter)
        return filter == .unread ? filtered.count : 0 // Only show count for unread
    }
    
    private func handleNotificationTap(_ notification: HealthNotification) {
        HapticFeedback.light()
        
        // Mark as read if not already
        if !notification.isRead {
            Task {
                await markNotificationAsRead(notification)
            }
        }
        
        // Handle notification action
        if let actionType = notification.actionType {
            handleNotificationAction(actionType, metadata: notification.metadata)
        }
    }
    
    private func handleNotificationAction(_ actionType: NotificationActionType, metadata: NotificationMetadata?) {
        // TODO: Implement navigation to appropriate views based on action type
        print("Handling notification action: \(actionType)")
        
        // For now, just dismiss the sheet
        // In a real app, you would navigate to the appropriate view
        dismiss()
    }
    
    private func markNotificationAsRead(_ notification: HealthNotification) async {
        guard !notification.isRead else { return }
        
        do {
            let updatedNotification = try await healthDataService.markNotificationAsRead(notification.id)
            
            // Update local notifications array
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = updatedNotification
                applyFilter()
            }
        } catch {
            // Handle error - could show a toast or alert
            print("Error marking notification as read: \(error)")
        }
    }
    
    private func markAllNotificationsAsRead() async {
        do {
            notifications = try await healthDataService.markAllNotificationsAsRead()
            applyFilter()
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to mark all notifications as read"
        }
    }
    
    private func deleteNotification(_ notification: HealthNotification) async {
        do {
            try await healthDataService.deleteNotification(notification.id)
            
            // Remove from local array
            notifications.removeAll { $0.id == notification.id }
            applyFilter()
            
            HapticFeedback.light()
        } catch {
            errorMessage = "Failed to delete notification"
        }
    }
    
    private func clearAllNotifications() async {
        do {
            try await healthDataService.clearAllNotifications()
            notifications.removeAll()
            applyFilter()
            HapticFeedback.light()
        } catch {
            errorMessage = "Failed to clear notifications"
        }
    }
    
    private func showMarkAllReadConfirmation() {
        showingMarkAllReadConfirmation = true
    }
}

// MARK: - Filter Chip Component

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: HealthSpacing.xs) {
                Text(title)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(isSelected ? .white : HealthColors.primaryText)
                
                if count > 0 {
                    Text("\(count)")
                        .font(HealthTypography.captionSmall)
                        .foregroundColor(isSelected ? .white : .white)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(
                            Circle().fill(isSelected ? Color.white.opacity(0.3) : Color.red)
                        )
                }
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.xs)
            .background(
                Capsule().fill(
                    isSelected ? HealthColors.primary : HealthColors.secondaryBackground
                )
            )
            .overlay(
                Capsule().stroke(
                    isSelected ? HealthColors.primary : HealthColors.border,
                    lineWidth: isSelected ? 0 : 1
                )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notification Card Component

private struct NotificationCard: View {
    let notification: HealthNotification
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        InfoCard(
            title: notification.title,
            subtitle: notification.subtitle,
            icon: notification.category.icon,
            accentColor: notification.category.color,
            backgroundStyle: notification.isRead ? .standard : .highlighted
        ) {
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                // Message
                Text(notification.message)
                    .healthTextStyle(.body, color: HealthColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Metadata row
                HStack {
                    // Time and priority
                    HStack(spacing: HealthSpacing.xs) {
                        Text(notification.timeAgoString)
                            .healthTextStyle(.caption1, color: HealthColors.tertiaryText)
                        
                        if notification.priority != .normal {
                            Divider()
                                .frame(height: 12)
                            
                            HStack(spacing: HealthSpacing.xs) {
                                Circle()
                                    .fill(notification.priority.badgeColor)
                                    .frame(width: 6, height: 6)
                                
                                Text(notification.priority.displayName)
                                    .healthTextStyle(.caption1, color: notification.priority.color)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: HealthSpacing.sm) {
                        if !notification.isRead {
                            Button(action: onMarkAsRead) {
                                Image(systemName: "circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(HealthColors.secondaryText)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(HealthColors.healthExcellent)
                        }
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(HealthColors.healthCritical)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Action button if available
                if let actionType = notification.actionType {
                    Button(action: onTap) {
                        HStack(spacing: HealthSpacing.xs) {
                            Image(systemName: actionType.icon)
                                .font(.system(size: 14))
                            
                            Text(actionType.displayName)
                                .font(HealthTypography.buttonSmall)
                        }
                        .foregroundColor(HealthColors.primary)
                        .padding(.horizontal, HealthSpacing.md)
                        .padding(.vertical, HealthSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                                .fill(HealthColors.primary.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, HealthSpacing.xs)
                }
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(
            minimumDuration: 0.1,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAction(.default) {
            onTap()
        }
    }
    
    private var accessibilityLabel: String {
        let readStatus = notification.isRead ? "Read" : "Unread"
        return "\(readStatus) notification: \(notification.title). \(notification.subtitle). \(notification.message)"
    }
    
    private var accessibilityHint: String {
        if let actionType = notification.actionType {
            return "Double tap to \(actionType.displayName.lowercased())"
        }
        return "Double tap to view details"
    }
}

// MARK: - Preview

#Preview {
    NotificationSheet()
}

#Preview("Empty State") {
    NotificationSheet()
        .onAppear {
            // Would show empty state
        }
}