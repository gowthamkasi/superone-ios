//
//  NotificationCardView.swift
//  SuperOne
//
//  Created by Claude Code on 2024-08-30.
//  Enhanced notification card component with proper borders and visual separation
//

import SwiftUI

/// Enhanced notification card component with distinct borders and visual hierarchy
/// Features category-specific styling, proper shadows, and iOS 18 design principles
@MainActor
struct NotificationCardView: View {
    
    // MARK: - Properties
    let notification: HealthNotification
    let onTap: () -> Void
    let onMarkAsRead: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Initialization
    init(
        notification: HealthNotification,
        onTap: @escaping () -> Void,
        onMarkAsRead: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.notification = notification
        self.onTap = onTap
        self.onMarkAsRead = onMarkAsRead
        self.onDelete = onDelete
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main card content
                VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                    // Header row with category indicator
                    headerRow
                    
                    // Message content
                    messageSection
                    
                    // Metadata and actions
                    footerSection
                    
                    // Action button if available
                    if let actionType = notification.actionType {
                        actionButton(for: actionType)
                            .padding(.top, HealthSpacing.sm)
                    }
                }
                .padding(HealthSpacing.lg)
            }
            .background(cardBackground)
            .overlay(
                // Category accent border
                categoryAccentBorder,
                alignment: .leading
            )
            .overlay(
                // Card border
                RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.xl))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowOffset
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0.1,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAction(.default) {
            onTap()
        }
        .contextMenu {
            contextMenuItems
        }
    }
    
    // MARK: - Header Row
    private var headerRow: some View {
        HStack(spacing: HealthSpacing.sm) {
            // Category icon with background
            categoryIcon
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .lineLimit(1)
                
                if !notification.subtitle.isEmpty {
                    Text(notification.subtitle)
                        .font(HealthTypography.caption1)
                        .foregroundColor(HealthColors.secondaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                unreadIndicator
            }
            
            // Priority badge if needed
            if notification.priority != .normal {
                priorityBadge
            }
        }
    }
    
    // MARK: - Category Icon
    private var categoryIcon: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(notification.category.color.opacity(0.12))
                .frame(width: 40, height: 40)
            
            // Icon
            Image(systemName: notification.category.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(notification.category.color)
        }
    }
    
    // MARK: - Message Section
    private var messageSection: some View {
        Text(notification.message)
            .font(HealthTypography.body)
            .foregroundColor(HealthColors.primaryText)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 2) // Slight indent for better hierarchy
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        HStack(alignment: .center, spacing: HealthSpacing.sm) {
            // Timestamp
            HStack(spacing: HealthSpacing.xs) {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(HealthColors.tertiaryText)
                
                Text(notification.timeAgoString)
                    .font(HealthTypography.caption2)
                    .foregroundColor(HealthColors.tertiaryText)
            }
            
            Spacer()
            
            // Action buttons
            actionButtonsRow
        }
    }
    
    // MARK: - Action Buttons Row
    private var actionButtonsRow: some View {
        HStack(spacing: HealthSpacing.sm) {
            // Mark as read/unread button
            if let onMarkAsRead = onMarkAsRead {
                Button(action: onMarkAsRead) {
                    Image(systemName: notification.isRead ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(notification.isRead ? HealthColors.healthGood : HealthColors.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Delete button
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(HealthColors.healthCritical)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Action Button
    private func actionButton(for actionType: NotificationActionType) -> some View {
        Button(action: onTap) {
            HStack(spacing: HealthSpacing.xs) {
                Image(systemName: actionType.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(actionType.displayName)
                    .font(HealthTypography.buttonSmall)
            }
            .foregroundColor(notification.category.color)
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                    .fill(notification.category.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                            .stroke(notification.category.color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Unread Indicator
    private var unreadIndicator: some View {
        Circle()
            .fill(notification.category.color)
            .frame(width: 8, height: 8)
    }
    
    // MARK: - Priority Badge
    private var priorityBadge: some View {
        HStack(spacing: HealthSpacing.xs) {
            Circle()
                .fill(notification.priority.badgeColor)
                .frame(width: 6, height: 6)
            
            Text(notification.priority.displayName.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(notification.priority.color)
        }
        .padding(.horizontal, HealthSpacing.xs)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(notification.priority.color.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(notification.priority.color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Category Accent Border
    private var categoryAccentBorder: some View {
        Rectangle()
            .fill(notification.category.color)
            .frame(width: 4)
            .clipShape(
                .rect(
                    topLeadingRadius: HealthCornerRadius.xl,
                    bottomLeadingRadius: HealthCornerRadius.xl
                )
            )
    }
    
    // MARK: - Context Menu
    private var contextMenuItems: some View {
        Group {
            if let onMarkAsRead = onMarkAsRead {
                Button(action: onMarkAsRead) {
                    Label(
                        notification.isRead ? "Mark as Unread" : "Mark as Read",
                        systemImage: notification.isRead ? "circle" : "checkmark.circle"
                    )
                }
            }
            
            Button(action: onTap) {
                Label("Open", systemImage: "eye")
            }
            
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var cardBackground: Color {
        if notification.isRead {
            return Color(.secondarySystemBackground)
        } else {
            // Slightly highlighted background for unread notifications
            return notification.category.color.opacity(0.02)
                .blendMode(.overlay)
                .background(Color(.secondarySystemBackground))
        }
    }
    
    private var borderColor: Color {
        if notification.isRead {
            return Color(.separator).opacity(0.5)
        } else {
            return notification.category.color.opacity(0.15)
        }
    }
    
    private var borderWidth: CGFloat {
        return notification.isRead ? 0.5 : 1.0
    }
    
    private var shadowColor: Color {
        if colorScheme == .dark {
            return Color.black.opacity(0.3)
        } else {
            return notification.isRead ? 
                Color.black.opacity(0.04) : 
                notification.category.color.opacity(0.08)
        }
    }
    
    private var shadowRadius: CGFloat {
        return notification.isRead ? 2 : 4
    }
    
    private var shadowOffset: CGFloat {
        return notification.isRead ? 1 : 2
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

// MARK: - Notification Card List Component

/// Container view for displaying a list of notification cards with proper spacing
struct NotificationCardListView: View {
    let notifications: [HealthNotification]
    let onNotificationTap: (HealthNotification) -> Void
    let onMarkAsRead: ((HealthNotification) -> Void)?
    let onDelete: ((HealthNotification) -> Void)?
    
    var body: some View {
        LazyVStack(spacing: HealthSpacing.md) {
            ForEach(notifications) { notification in
                NotificationCardView(
                    notification: notification,
                    onTap: { onNotificationTap(notification) },
                    onMarkAsRead: onMarkAsRead != nil ? { onMarkAsRead!(notification) } : nil,
                    onDelete: onDelete != nil ? { onDelete!(notification) } : nil
                )
                .id(notification.id)
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
}

// MARK: - Preview

#Preview("Single Card - Unread") {
    ScrollView {
        VStack(spacing: HealthSpacing.lg) {
            NotificationCardView(
                notification: NotificationFactory.sampleNotifications()[0],
                onTap: { print("Tapped notification") },
                onMarkAsRead: { print("Mark as read") },
                onDelete: { print("Delete notification") }
            )
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
        .padding(.vertical, HealthSpacing.xl)
    }
    .background(HealthColors.background)
}

#Preview("Single Card - Read") {
    ScrollView {
        VStack(spacing: HealthSpacing.lg) {
            NotificationCardView(
                notification: NotificationFactory.sampleNotifications()[2], // Read notification
                onTap: { print("Tapped notification") },
                onMarkAsRead: { print("Mark as unread") },
                onDelete: { print("Delete notification") }
            )
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
        .padding(.vertical, HealthSpacing.xl)
    }
    .background(HealthColors.background)
}

#Preview("Multiple Cards") {
    ScrollView {
        NotificationCardListView(
            notifications: NotificationFactory.sampleNotifications(),
            onNotificationTap: { notification in
                print("Tapped: \(notification.title)")
            },
            onMarkAsRead: { notification in
                print("Mark as read: \(notification.title)")
            },
            onDelete: { notification in
                print("Delete: \(notification.title)")
            }
        )
        .padding(.vertical, HealthSpacing.xl)
    }
    .background(HealthColors.background)
}

#Preview("Dark Mode") {
    ScrollView {
        NotificationCardListView(
            notifications: Array(NotificationFactory.sampleNotifications().prefix(3)),
            onNotificationTap: { notification in
                print("Tapped: \(notification.title)")
            },
            onMarkAsRead: { notification in
                print("Mark as read: \(notification.title)")
            },
            onDelete: { notification in
                print("Delete: \(notification.title)")
            }
        )
        .padding(.vertical, HealthSpacing.xl)
    }
    .background(HealthColors.background)
    .preferredColorScheme(.dark)
}