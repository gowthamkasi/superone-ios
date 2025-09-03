//
//  NotificationCardUsageExamples.swift
//  SuperOne
//
//  Created by Claude Code on 2024-08-30.
//  Usage examples and implementation guide for NotificationCardView
//

import SwiftUI

/// Examples showing how to use the NotificationCardView component
/// This file demonstrates various use cases and implementation patterns
struct NotificationCardUsageExamples: View {
    
    @State private var notifications = NotificationFactory.sampleNotifications()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: HealthSpacing.xxl) {
                    // Example 1: Basic single card
                    basicCardExample
                    
                    // Example 2: Card list with all features
                    fullFeatureListExample
                    
                    // Example 3: Different notification types
                    categoryExamples
                    
                    // Example 4: Priority variations
                    priorityExamples
                    
                    // Example 5: Read/Unread states
                    stateExamples
                }
                .padding(.vertical, HealthSpacing.xl)
            }
            .background(HealthColors.background)
            .navigationTitle("Notification Card Examples")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Basic Card Example
    private var basicCardExample: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            sectionHeader("Basic Card Usage")
            
            Text("Single notification card with minimal configuration:")
                .font(HealthTypography.caption1)
                .foregroundColor(HealthColors.secondaryText)
                .padding(.horizontal, HealthSpacing.screenPadding)
            
            NotificationCardView(
                notification: notifications[0],
                onTap: {
                    print("Basic card tapped")
                }
            )
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            codeExample("""
NotificationCardView(
    notification: healthNotification,
    onTap: {
        // Handle notification tap
        navigateToReport()
    }
)
""")
        }
    }
    
    // MARK: - Full Feature List Example
    private var fullFeatureListExample: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            sectionHeader("Complete Feature Set")
            
            Text("List with all interactive features enabled:")
                .font(HealthTypography.caption1)
                .foregroundColor(HealthColors.secondaryText)
                .padding(.horizontal, HealthSpacing.screenPadding)
            
            NotificationListView(
                notifications: Array(notifications.prefix(3)),
                onNotificationTap: { notification in
                    handleNotificationTap(notification)
                },
                onMarkAsRead: { notification in
                    toggleReadStatus(notification)
                },
                onDelete: { notification in
                    deleteNotification(notification)
                }
            )
            
            codeExample("""
NotificationListView(
    notifications: notifications,
    onNotificationTap: { notification in
        navigateToDetail(notification)
    },
    onMarkAsRead: { notification in
        markAsRead(notification)
    },
    onDelete: { notification in
        deleteNotification(notification)
    }
)
""")
        }
    }
    
    // MARK: - Category Examples
    private var categoryExamples: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            sectionHeader("Category-Specific Styling")
            
            Text("Different categories show distinct colors and icons:")
                .font(HealthTypography.caption1)
                .foregroundColor(HealthColors.secondaryText)
                .padding(.horizontal, HealthSpacing.screenPadding)
            
            VStack(spacing: HealthSpacing.md) {
                // Lab Report (Green)
                NotificationCardView(
                    notification: createSampleNotification(
                        category: .labReport,
                        title: "Lab Results Ready",
                        subtitle: "Comprehensive Health Panel",
                        message: "Your blood work results are now available."
                    ),
                    onTap: { }
                )
                
                // Health Insight (Secondary Green)
                NotificationCardView(
                    notification: createSampleNotification(
                        category: .healthInsight,
                        title: "New Health Insight",
                        subtitle: "Cardiovascular Health",
                        message: "Your cholesterol levels show improvement."
                    ),
                    onTap: { }
                )
                
                // Appointment (Blue)
                NotificationCardView(
                    notification: createSampleNotification(
                        category: .appointment,
                        title: "Appointment Confirmed",
                        subtitle: "Dr. Sarah Johnson - Cardiology",
                        message: "Your appointment is scheduled for tomorrow."
                    ),
                    onTap: { }
                )
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            Text("Each category automatically gets its specific color for the accent border, icon background, and action buttons.")
                .font(HealthTypography.caption2)
                .foregroundColor(HealthColors.tertiaryText)
                .padding(.horizontal, HealthSpacing.screenPadding)
        }
    }
    
    // MARK: - Priority Examples
    private var priorityExamples: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            sectionHeader("Priority Variations")
            
            Text("Different priority levels with visual indicators:")
                .font(HealthTypography.caption1)
                .foregroundColor(HealthColors.secondaryText)
                .padding(.horizontal, HealthSpacing.screenPadding)
            
            VStack(spacing: HealthSpacing.md) {
                // Normal Priority
                NotificationCardView(
                    notification: createSampleNotification(
                        priority: .normal,
                        title: "Normal Priority",
                        message: "Standard notification with normal priority."
                    ),
                    onTap: { }
                )
                
                // High Priority
                NotificationCardView(
                    notification: createSampleNotification(
                        priority: .high,
                        title: "High Priority",
                        message: "Important notification requiring attention."
                    ),
                    onTap: { }
                )
                
                // Urgent Priority
                NotificationCardView(
                    notification: createSampleNotification(
                        priority: .urgent,
                        title: "Urgent Priority",
                        message: "Critical notification requiring immediate action."
                    ),
                    onTap: { }
                )
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
    }
    
    // MARK: - State Examples
    private var stateExamples: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            sectionHeader("Read/Unread States")
            
            Text("Visual differences between read and unread notifications:")
                .font(HealthTypography.caption1)
                .foregroundColor(HealthColors.secondaryText)
                .padding(.horizontal, HealthSpacing.screenPadding)
            
            VStack(spacing: HealthSpacing.md) {
                // Unread notification
                NotificationCardView(
                    notification: createSampleNotification(
                        isRead: false,
                        title: "Unread Notification",
                        message: "This notification hasn't been read yet. Notice the stronger border and accent styling."
                    ),
                    onTap: { }
                )
                
                // Read notification
                NotificationCardView(
                    notification: createSampleNotification(
                        isRead: true,
                        title: "Read Notification", 
                        message: "This notification has been read. Notice the subtle styling and checkmark."
                    ),
                    onTap: { }
                )
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(HealthTypography.title3)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    private func codeExample(_ code: String) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.xs) {
            Text("Code Example:")
                .font(HealthTypography.captionSmall)
                .foregroundColor(HealthColors.secondaryText)
            
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(HealthColors.primaryText)
                .padding(HealthSpacing.sm)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.sm))
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Helper Methods
    private func createSampleNotification(
        category: NotificationCategory = .labReport,
        priority: NotificationPriority = .normal,
        isRead: Bool = false,
        title: String,
        subtitle: String = "Sample Category",
        message: String
    ) -> HealthNotification {
        HealthNotification(
            title: title,
            subtitle: subtitle,
            message: message,
            category: category,
            priority: priority,
            isRead: isRead,
            actionType: .viewReport
        )
    }
    
    private func handleNotificationTap(_ notification: HealthNotification) {
        print("Notification tapped: \(notification.title)")
    }
    
    private func toggleReadStatus(_ notification: HealthNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = notification.isRead ? 
                notification.markAsUnread() : 
                notification.markAsRead()
        }
    }
    
    private func deleteNotification(_ notification: HealthNotification) {
        notifications.removeAll { $0.id == notification.id }
        print("Deleted notification: \(notification.title)")
    }
}

// MARK: - Integration Guide

struct NotificationCardIntegrationGuide: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                    integrationInstructions
                    designPrinciples
                    accessibilityFeatures
                    customizationOptions
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .padding(.vertical, HealthSpacing.xl)
            }
            .background(HealthColors.background)
            .navigationTitle("Integration Guide")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var integrationInstructions: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Integration Instructions")
                .font(HealthTypography.title2)
                .foregroundColor(HealthColors.primaryText)
            
            Text("The NotificationCardView component is designed to replace the existing notification display system with enhanced visual design and better user experience.")
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                bulletPoint("Import the component in your view files")
                bulletPoint("Replace existing notification cards with NotificationCardView")
                bulletPoint("Use NotificationCardListView for lists of notifications")
                bulletPoint("Implement the callback handlers for user interactions")
                bulletPoint("Test in both light and dark mode environments")
            }
        }
    }
    
    private var designPrinciples: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Design Principles")
                .font(HealthTypography.title2)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                bulletPoint("16px corner radius for modern iOS 18 feel")
                bulletPoint("Category-specific left accent borders for visual hierarchy")
                bulletPoint("Subtle shadows that adapt to read/unread state")
                bulletPoint("Proper spacing and typography hierarchy")
                bulletPoint("Health-focused green color palette with semantic colors")
                bulletPoint("Visual indicators for unread status and priority levels")
            }
        }
    }
    
    private var accessibilityFeatures: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Accessibility Features")
                .font(HealthTypography.title2)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                bulletPoint("VoiceOver support with descriptive labels")
                bulletPoint("Contextual accessibility hints for actions")
                bulletPoint("Proper touch target sizes (44pt minimum)")
                bulletPoint("High contrast support for vision accessibility")
                bulletPoint("Dynamic Type support for text scaling")
                bulletPoint("Context menus for additional interaction options")
            }
        }
    }
    
    private var customizationOptions: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Customization Options")
                .font(HealthTypography.title2)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                bulletPoint("Optional mark as read/unread functionality")
                bulletPoint("Optional delete functionality")
                bulletPoint("Automatic category-specific styling")
                bulletPoint("Priority badge display for high/urgent items")
                bulletPoint("Action button integration based on notification type")
                bulletPoint("Long press context menus for power users")
            }
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: HealthSpacing.sm) {
            Text("•")
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.primary)
                .frame(width: 12, alignment: .leading)
            
            Text(text)
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.primaryText)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Preview

