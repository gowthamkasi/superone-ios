//
//  NotificationModels.swift
//  SuperOne
//
//  Created by Claude Code on 2024-12-20.
//  Notification system models with Swift 6.0+ concurrency safety
//

import Foundation
import SwiftUI

// MARK: - Notification Models

/// Notification item representing health-related notifications and alerts
struct HealthNotification: Identifiable, Sendable, Codable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let message: String
    let category: NotificationCategory
    let priority: NotificationPriority
    let timestamp: Date
    let isRead: Bool
    let actionType: NotificationActionType?
    let metadata: NotificationMetadata?
    
    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        message: String,
        category: NotificationCategory,
        priority: NotificationPriority = .normal,
        timestamp: Date = Date(),
        isRead: Bool = false,
        actionType: NotificationActionType? = nil,
        metadata: NotificationMetadata? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.message = message
        self.category = category
        self.priority = priority
        self.timestamp = timestamp
        self.isRead = isRead
        self.actionType = actionType
        self.metadata = metadata
    }
}

// MARK: - Notification Categories

/// Health-focused notification categories
enum NotificationCategory: String, CaseIterable, Sendable, Codable {
    case labReport = "lab_report"
    case healthInsight = "health_insight"
    case appointment = "appointment"
    case recommendation = "recommendation"
    case alert = "alert"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .labReport:
            return "Lab Reports"
        case .healthInsight:
            return "Health Insights"
        case .appointment:
            return "Appointments"
        case .recommendation:
            return "Recommendations"
        case .alert:
            return "Health Alerts"
        case .system:
            return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .labReport:
            return "doc.text"
        case .healthInsight:
            return "brain.head.profile"
        case .appointment:
            return "calendar"
        case .recommendation:
            return "lightbulb"
        case .alert:
            return "exclamationmark.triangle"
        case .system:
            return "gear"
        }
    }
    
    var color: Color {
        switch self {
        case .labReport:
            return HealthColors.primary
        case .healthInsight:
            return HealthColors.secondary
        case .appointment:
            return .blue
        case .recommendation:
            return .orange
        case .alert:
            return .red
        case .system:
            return .gray
        }
    }
}

// MARK: - Notification Priority

/// Notification priority levels
enum NotificationPriority: String, CaseIterable, Sendable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .normal:
            return "Normal"
        case .high:
            return "High"
        case .urgent:
            return "Urgent"
        }
    }
    
    var color: Color {
        switch self {
        case .low:
            return HealthColors.secondaryText
        case .normal:
            return HealthColors.primary
        case .high:
            return .orange
        case .urgent:
            return .red
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .low, .normal:
            return .clear
        case .high:
            return .orange
        case .urgent:
            return .red
        }
    }
}

// MARK: - Notification Action Types

/// Actions that can be taken from notifications
enum NotificationActionType: String, CaseIterable, Sendable, Codable {
    case viewReport = "view_report"
    case bookAppointment = "book_appointment"
    case viewInsight = "view_insight"
    case acceptRecommendation = "accept_recommendation"
    case dismissAlert = "dismiss_alert"
    case openSettings = "open_settings"
    
    var displayName: String {
        switch self {
        case .viewReport:
            return "View Report"
        case .bookAppointment:
            return "Book Appointment"
        case .viewInsight:
            return "View Details"
        case .acceptRecommendation:
            return "Learn More"
        case .dismissAlert:
            return "Dismiss"
        case .openSettings:
            return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .viewReport:
            return "doc.text"
        case .bookAppointment:
            return "calendar.badge.plus"
        case .viewInsight:
            return "eye"
        case .acceptRecommendation:
            return "checkmark.circle"
        case .dismissAlert:
            return "xmark.circle"
        case .openSettings:
            return "gear"
        }
    }
}

// MARK: - Notification Metadata

/// Additional metadata for notifications
struct NotificationMetadata: Sendable, Codable, Hashable {
    let reportId: String?
    let appointmentId: String?
    let insightId: String?
    let recommendationId: String?
    let alertId: String?
    let deepLinkPath: String?
    let badgeCount: Int?
    let expiresAt: Date?
    
    init(
        reportId: String? = nil,
        appointmentId: String? = nil,
        insightId: String? = nil,
        recommendationId: String? = nil,
        alertId: String? = nil,
        deepLinkPath: String? = nil,
        badgeCount: Int? = nil,
        expiresAt: Date? = nil
    ) {
        self.reportId = reportId
        self.appointmentId = appointmentId
        self.insightId = insightId
        self.recommendationId = recommendationId
        self.alertId = alertId
        self.deepLinkPath = deepLinkPath
        self.badgeCount = badgeCount
        self.expiresAt = expiresAt
    }
}

// MARK: - Notification Filter Options

/// Filter options for notification display
enum NotificationFilter: String, CaseIterable, Sendable {
    case all = "all"
    case unread = "unread"
    case labReports = "lab_reports"
    case healthInsights = "health_insights"
    case appointments = "appointments"
    case recommendations = "recommendations"
    case alerts = "alerts"
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .unread:
            return "Unread"
        case .labReports:
            return "Lab Reports"
        case .healthInsights:
            return "Health Insights"
        case .appointments:
            return "Appointments"
        case .recommendations:
            return "Recommendations"
        case .alerts:
            return "Alerts"
        }
    }
    
    var category: NotificationCategory? {
        switch self {
        case .all, .unread:
            return nil
        case .labReports:
            return .labReport
        case .healthInsights:
            return .healthInsight
        case .appointments:
            return .appointment
        case .recommendations:
            return .recommendation
        case .alerts:
            return .alert
        }
    }
}

// MARK: - Notification Extensions

extension HealthNotification {
    /// Time ago string for display
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    /// Check if notification has expired
    var isExpired: Bool {
        guard let expiresAt = metadata?.expiresAt else { return false }
        return Date() > expiresAt
    }
    
    /// Mark notification as read
    func markAsRead() -> HealthNotification {
        return HealthNotification(
            id: id,
            title: title,
            subtitle: subtitle,
            message: message,
            category: category,
            priority: priority,
            timestamp: timestamp,
            isRead: true,
            actionType: actionType,
            metadata: metadata
        )
    }
    
    /// Mark notification as unread
    func markAsUnread() -> HealthNotification {
        return HealthNotification(
            id: id,
            title: title,
            subtitle: subtitle,
            message: message,
            category: category,
            priority: priority,
            timestamp: timestamp,
            isRead: false,
            actionType: actionType,
            metadata: metadata
        )
    }
}

// MARK: - Notification Factory

/// Factory for creating sample notifications
struct NotificationFactory: Sendable {
    
    /// Generate sample health notifications
    static func sampleNotifications() -> [HealthNotification] {
        let now = Date()
        
        return [
            // Lab Report Notifications
            HealthNotification(
                title: "Lab Results Ready",
                subtitle: "Comprehensive Health Panel",
                message: "Your blood work results are now available. Overall health score improved by 12 points.",
                category: .labReport,
                priority: .normal,
                timestamp: Calendar.current.date(byAdding: .minute, value: -30, to: now) ?? now,
                isRead: false,
                actionType: .viewReport,
                metadata: NotificationMetadata(
                    reportId: "RPT-2024-001",
                    deepLinkPath: "/reports/RPT-2024-001",
                    badgeCount: 1
                )
            ),
            
            // Health Insight Notifications
            HealthNotification(
                title: "New Health Insight",
                subtitle: "Cardiovascular Health",
                message: "Your cholesterol levels show improvement. Consider maintaining your current diet and exercise routine.",
                category: .healthInsight,
                priority: .normal,
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: now) ?? now,
                isRead: false,
                actionType: .viewInsight,
                metadata: NotificationMetadata(
                    insightId: "INS-2024-CV-003",
                    deepLinkPath: "/insights/cardiovascular",
                    badgeCount: 1
                )
            ),
            
            // Appointment Notifications
            HealthNotification(
                title: "Appointment Confirmed",
                subtitle: "Dr. Sarah Johnson - Cardiology",
                message: "Your appointment is scheduled for tomorrow at 2:00 PM at City Medical Center.",
                category: .appointment,
                priority: .high,
                timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: now) ?? now,
                isRead: true,
                actionType: .bookAppointment,
                metadata: NotificationMetadata(
                    appointmentId: "APT-2024-12-456",
                    deepLinkPath: "/appointments/APT-2024-12-456"
                )
            ),
            
            // Recommendation Notifications
            HealthNotification(
                title: "Health Recommendation",
                subtitle: "Vitamin D Supplement",
                message: "Based on your recent lab work, consider adding Vitamin D3 supplements to your routine.",
                category: .recommendation,
                priority: .normal,
                timestamp: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now,
                isRead: false,
                actionType: .acceptRecommendation,
                metadata: NotificationMetadata(
                    recommendationId: "REC-2024-VIT-D",
                    deepLinkPath: "/recommendations/vitamin-d",
                    badgeCount: 1,
                    expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: now)
                )
            ),
            
            // Health Alert Notifications
            HealthNotification(
                title: "Health Alert",
                subtitle: "Blood Pressure Monitoring",
                message: "Your recent readings show elevated blood pressure. Please monitor closely and consult your physician.",
                category: .alert,
                priority: .urgent,
                timestamp: Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now,
                isRead: true,
                actionType: .dismissAlert,
                metadata: NotificationMetadata(
                    alertId: "ALT-2024-BP-001",
                    deepLinkPath: "/alerts/blood-pressure",
                    badgeCount: 1
                )
            ),
            
            // System Notifications
            HealthNotification(
                title: "App Update Available",
                subtitle: "Version 2.1.0",
                message: "New features include enhanced health tracking and improved AI insights.",
                category: .system,
                priority: .low,
                timestamp: Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now,
                isRead: false,
                actionType: .openSettings,
                metadata: NotificationMetadata(
                    deepLinkPath: "/settings/updates"
                )
            ),
            
            // Additional Lab Report
            HealthNotification(
                title: "Processing Complete",
                subtitle: "Metabolic Panel Analysis",
                message: "AI analysis of your metabolic panel is complete. Review your personalized health insights.",
                category: .labReport,
                priority: .normal,
                timestamp: Calendar.current.date(byAdding: .day, value: -5, to: now) ?? now,
                isRead: true,
                actionType: .viewReport,
                metadata: NotificationMetadata(
                    reportId: "RPT-2024-002",
                    insightId: "INS-2024-MET-001",
                    deepLinkPath: "/reports/RPT-2024-002"
                )
            )
        ]
    }
    
    /// Generate unread notification count
    static func unreadCount(from notifications: [HealthNotification]) -> Int {
        return notifications.filter { !$0.isRead }.count
    }
    
    /// Filter notifications by category
    static func filterNotifications(
        _ notifications: [HealthNotification], 
        by filter: NotificationFilter
    ) -> [HealthNotification] {
        switch filter {
        case .all:
            return notifications
        case .unread:
            return notifications.filter { !$0.isRead }
        default:
            if let category = filter.category {
                return notifications.filter { $0.category == category }
            }
            return notifications
        }
    }
}