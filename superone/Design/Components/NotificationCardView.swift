//
//  NotificationCardView.swift
//  SuperOne
//
//  Created by Claude Code on 2024-08-30.
//  Enhanced notification card component with proper borders and visual separation
//

import SwiftUI

/// Native iOS notification card component with full horizontal space utilization
/// Features clean design without action buttons, optimized for List integration
@MainActor
struct NotificationCardView: View {
    
    // MARK: - Properties
    let notification: HealthNotification
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Initialization
    init(
        notification: HealthNotification,
        onTap: @escaping () -> Void
    ) {
        self.notification = notification
        self.onTap = onTap
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            // Add haptic feedback for native iOS feel
            HapticFeedback.light()
            onTap()
        }) {
            HStack(spacing: HealthSpacing.md) {
                // Category accent border + icon
                categoryIconSection
                
                // Main content
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    // Header with title, subtitle, and indicators
                    headerSection
                    
                    // Message content
                    messageContent
                    
                    // Timestamp
                    timestampSection
                }
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, HealthSpacing.md)
            .padding(.horizontal, HealthSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay(
                // Category accent border (left edge)
                categoryAccentBorder,
                alignment: .leading
            )
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            // Subtle card container with border and shadow for visual separation
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAction(.default) {
            onTap()
        }
    }
    
    // MARK: - Category Icon Section
    private var categoryIconSection: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(notification.category.color.opacity(0.15))
                .frame(width: 36, height: 36)
            
            // Icon
            Image(systemName: notification.category.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(notification.category.color)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: HealthSpacing.sm) {
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                
                if !notification.subtitle.isEmpty {
                    Text(notification.subtitle)
                        .font(HealthTypography.caption1)
                        .foregroundColor(HealthColors.secondaryText)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
            }
            
            Spacer()
            
            // Indicators row
            HStack(spacing: HealthSpacing.xs) {
                // Priority badge if needed
                if notification.priority != .normal {
                    priorityBadge
                }
                
                // Unread indicator
                if !notification.isRead {
                    unreadIndicator
                }
            }
        }
    }
    
    
    // MARK: - Message Content
    private var messageContent: some View {
        Text(notification.message)
            .font(HealthTypography.body)
            .foregroundColor(HealthColors.primaryText)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Timestamp Section
    private var timestampSection: some View {
        HStack(spacing: HealthSpacing.xs) {
            Image(systemName: "clock")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(HealthColors.tertiaryText)
            
            Text(notification.timeAgoString)
                .font(HealthTypography.caption2)
                .foregroundColor(HealthColors.tertiaryText)
        }
    }
    
    
    
    // MARK: - Unread Indicator
    private var unreadIndicator: some View {
        Circle()
            .fill(notification.category.color)
            .frame(width: 8, height: 8)
    }
    
    // MARK: - Priority Badge
    private var priorityBadge: some View {
        Circle()
            .fill(notification.priority.badgeColor)
            .frame(width: 6, height: 6)
    }
    
    // MARK: - Category Accent Border
    private var categoryAccentBorder: some View {
        Rectangle()
            .fill(notification.category.color)
            .frame(width: 3)
    }
    
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var cardBackground: some View {
        if notification.isRead {
            Color(.systemBackground)
        } else {
            // Slightly highlighted background for unread notifications
            notification.category.color.opacity(0.03)
                .background(Color(.systemBackground))
        }
    }
    
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        let readStatus = notification.isRead ? "Read" : "Unread"
        let priority = notification.priority != .normal ? ", \(notification.priority.displayName) priority" : ""
        return "\(readStatus) \(notification.category.displayName.lowercased()) notification\(priority): \(notification.title). \(notification.subtitle). \(notification.message)"
    }
    
    private var accessibilityHint: String {
        if let actionType = notification.actionType {
            return "Double tap to \(actionType.displayName.lowercased())"
        }
        return "Double tap to view details"
    }
}

// MARK: - Notification List Component

/// Native iOS List component for notification cards with swipe-to-delete functionality
struct NotificationListView: View {
    let notifications: [HealthNotification]
    let onNotificationTap: (HealthNotification) -> Void
    let onMarkAsRead: ((HealthNotification) -> Void)?
    let onDelete: ((HealthNotification) -> Void)?
    
    var body: some View {
        List {
            ForEach(notifications) { notification in
                NotificationCardView(
                    notification: notification,
                    onTap: { onNotificationTap(notification) }
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing) {
                    // Delete action
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            HapticFeedback.medium()
                            onDelete(notification)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    
                    // Mark as read/unread action
                    if let onMarkAsRead = onMarkAsRead {
                        Button {
                            HapticFeedback.light()
                            onMarkAsRead(notification)
                        } label: {
                            if notification.isRead {
                                Label("Mark as Unread", systemImage: "circle")
                            } else {
                                Label("Mark as Read", systemImage: "checkmark.circle")
                            }
                        }
                        .tint(notification.isRead ? HealthColors.healthWarning : HealthColors.healthGood)
                    }
                }
                .id(notification.id)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Preview

