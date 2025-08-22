import SwiftUI
import Foundation

// MARK: - Dashboard Configuration

/// Comprehensive dashboard configuration for iOS 18+ environment integration
/// Uses @Entry macro for clean environment access and dynamic feature management
struct DashboardConfiguration {
    let features: DashboardFeatures
    let layout: DashboardLayout
    let refreshSettings: RefreshSettings
    let healthCategories: [HealthCategoryConfig]
    let notifications: DashboardNotificationSettings
    let analytics: DashboardAnalyticsSettings
    let accessibility: DashboardAccessibilitySettings
    
    /// Default dashboard configuration
    static let `default` = DashboardConfiguration(
        features: DashboardFeatures(),
        layout: DashboardLayout(),
        refreshSettings: RefreshSettings(),
        healthCategories: HealthCategoryConfig.defaultCategories,
        notifications: DashboardNotificationSettings(),
        analytics: DashboardAnalyticsSettings(),
        accessibility: DashboardAccessibilitySettings()
    )
}

// MARK: - Dashboard Features

/// Feature flags and toggles for dashboard functionality
struct DashboardFeatures {
    let enableHealthScore: Bool
    let enableQuickStats: Bool
    let enableRecentActivity: Bool
    let enableHealthCategories: Bool
    let enableNotifications: Bool
    let enableTrends: Bool
    let enableRecommendations: Bool
    let enableExport: Bool
    let enableComparison: Bool
    let enableGoals: Bool
    let enableReminders: Bool
    let enableSocialSharing: Bool
    
    init(
        enableHealthScore: Bool = true,
        enableQuickStats: Bool = true,
        enableRecentActivity: Bool = true,
        enableHealthCategories: Bool = true,
        enableNotifications: Bool = true,
        enableTrends: Bool = true,
        enableRecommendations: Bool = true,
        enableExport: Bool = false,
        enableComparison: Bool = false,
        enableGoals: Bool = false,
        enableReminders: Bool = true,
        enableSocialSharing: Bool = false
    ) {
        self.enableHealthScore = enableHealthScore
        self.enableQuickStats = enableQuickStats
        self.enableRecentActivity = enableRecentActivity
        self.enableHealthCategories = enableHealthCategories
        self.enableNotifications = enableNotifications
        self.enableTrends = enableTrends
        self.enableRecommendations = enableRecommendations
        self.enableExport = enableExport
        self.enableComparison = enableComparison
        self.enableGoals = enableGoals
        self.enableReminders = enableReminders
        self.enableSocialSharing = enableSocialSharing
    }
}

// MARK: - Dashboard Layout

/// Layout configuration for dashboard components
struct DashboardLayout {
    let sectionOrder: [DashboardSection]
    let quickStatsLayout: QuickStatsLayout
    let healthScorePosition: HealthScorePosition
    let compactMode: Bool
    let maxSectionsVisible: Int
    let animationsEnabled: Bool
    
    init(
        sectionOrder: [DashboardSection] = DashboardSection.defaultOrder,
        quickStatsLayout: QuickStatsLayout = .grid,
        healthScorePosition: HealthScorePosition = .top,
        compactMode: Bool = false,
        maxSectionsVisible: Int = 10,
        animationsEnabled: Bool = true
    ) {
        self.sectionOrder = sectionOrder
        self.quickStatsLayout = quickStatsLayout
        self.healthScorePosition = healthScorePosition
        self.compactMode = compactMode
        self.maxSectionsVisible = maxSectionsVisible
        self.animationsEnabled = animationsEnabled
    }
}

// MARK: - Dashboard Sections

enum DashboardSection: String, CaseIterable, Identifiable {
    case header = "header"
    case healthScore = "health_score"
    case quickStats = "quick_stats"
    case healthCategories = "health_categories"
    case recentActivity = "recent_activity"
    case trends = "trends"
    case recommendations = "recommendations"
    case goals = "goals"
    case reminders = "reminders"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .header: return "Header"
        case .healthScore: return "Health Score"
        case .quickStats: return "Quick Stats"
        case .healthCategories: return "Health Categories"
        case .recentActivity: return "Recent Activity"
        case .trends: return "Health Trends"
        case .recommendations: return "Recommendations"
        case .goals: return "Health Goals"
        case .reminders: return "Reminders"
        }
    }
    
    var icon: String {
        switch self {
        case .header: return "person.crop.circle"
        case .healthScore: return "heart.circle"
        case .quickStats: return "square.grid.2x2"
        case .healthCategories: return "list.bullet.clipboard"
        case .recentActivity: return "clock.arrow.circlepath"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .recommendations: return "lightbulb"
        case .goals: return "target"
        case .reminders: return "bell"
        }
    }
    
    static let defaultOrder: [DashboardSection] = [
        .header,
        .healthScore,
        .quickStats,
        .healthCategories,
        .recentActivity,
        .trends,
        .recommendations
    ]
}

// MARK: - Layout Enums

enum QuickStatsLayout: String, CaseIterable {
    case grid = "grid"
    case list = "list"
    case carousel = "carousel"
    
    var displayName: String {
        switch self {
        case .grid: return "Grid"
        case .list: return "List"
        case .carousel: return "Carousel"
        }
    }
}

enum HealthScorePosition: String, CaseIterable {
    case top = "top"
    case center = "center"
    case bottom = "bottom"
    case hidden = "hidden"
    
    var displayName: String {
        switch self {
        case .top: return "Top"
        case .center: return "Center"
        case .bottom: return "Bottom"
        case .hidden: return "Hidden"
        }
    }
}

// MARK: - Refresh Settings

/// Settings for dashboard data refresh behavior
struct RefreshSettings {
    let autoRefreshEnabled: Bool
    let refreshInterval: TimeInterval
    let pullToRefreshEnabled: Bool
    let backgroundRefreshEnabled: Bool
    let refreshOnAppLaunch: Bool
    let refreshOnForeground: Bool
    let staleDataThreshold: TimeInterval
    
    init(
        autoRefreshEnabled: Bool = true,
        refreshInterval: TimeInterval = 300, // 5 minutes
        pullToRefreshEnabled: Bool = true,
        backgroundRefreshEnabled: Bool = false,
        refreshOnAppLaunch: Bool = true,
        refreshOnForeground: Bool = true,
        staleDataThreshold: TimeInterval = 120 // 2 minutes
    ) {
        self.autoRefreshEnabled = autoRefreshEnabled
        self.refreshInterval = refreshInterval
        self.pullToRefreshEnabled = pullToRefreshEnabled
        self.backgroundRefreshEnabled = backgroundRefreshEnabled
        self.refreshOnAppLaunch = refreshOnAppLaunch
        self.refreshOnForeground = refreshOnForeground
        self.staleDataThreshold = staleDataThreshold
    }
}

// MARK: - Health Category Configuration

/// Configuration for individual health categories on dashboard
struct HealthCategoryConfig: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let enabled: Bool
    let priority: Int
    let showOnDashboard: Bool
    let alertsEnabled: Bool
    
    static let defaultCategories: [HealthCategoryConfig] = [
        HealthCategoryConfig(
            id: "cardiovascular",
            name: "Cardiovascular",
            icon: "heart.fill",
            color: "#FF6B6B",
            enabled: true,
            priority: 1,
            showOnDashboard: true,
            alertsEnabled: true
        ),
        HealthCategoryConfig(
            id: "metabolic",
            name: "Metabolic",
            icon: "drop.fill",
            color: "#4ECDC4",
            enabled: true,
            priority: 2,
            showOnDashboard: true,
            alertsEnabled: true
        ),
        HealthCategoryConfig(
            id: "hematology",
            name: "Blood Work",
            icon: "drop.circle.fill",
            color: "#45B7D1",
            enabled: true,
            priority: 3,
            showOnDashboard: true,
            alertsEnabled: true
        ),
        HealthCategoryConfig(
            id: "liver",
            name: "Liver Function",
            icon: "leaf.fill",
            color: "#96CEB4",
            enabled: true,
            priority: 4,
            showOnDashboard: false,
            alertsEnabled: true
        ),
        HealthCategoryConfig(
            id: "kidney",
            name: "Kidney Function",
            icon: "drop.triangle.fill",
            color: "#FFEAA7",
            enabled: true,
            priority: 5,
            showOnDashboard: false,
            alertsEnabled: true
        )
    ]
}

// MARK: - Dashboard Notification Settings

struct DashboardNotificationSettings {
    let enableHealthAlerts: Bool
    let enableRecommendationNotifications: Bool
    let enableTrendNotifications: Bool
    let enableGoalNotifications: Bool
    let enableReminderNotifications: Bool
    let quietHoursEnabled: Bool
    let quietHoursStart: Date
    let quietHoursEnd: Date
    let criticalAlertsOnly: Bool
    
    init(
        enableHealthAlerts: Bool = true,
        enableRecommendationNotifications: Bool = true,
        enableTrendNotifications: Bool = false,
        enableGoalNotifications: Bool = true,
        enableReminderNotifications: Bool = true,
        quietHoursEnabled: Bool = false,
        quietHoursStart: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
        quietHoursEnd: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
        criticalAlertsOnly: Bool = false
    ) {
        self.enableHealthAlerts = enableHealthAlerts
        self.enableRecommendationNotifications = enableRecommendationNotifications
        self.enableTrendNotifications = enableTrendNotifications
        self.enableGoalNotifications = enableGoalNotifications
        self.enableReminderNotifications = enableReminderNotifications
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.criticalAlertsOnly = criticalAlertsOnly
    }
}

// MARK: - Dashboard Analytics Settings

struct DashboardAnalyticsSettings {
    let trackUserInteractions: Bool
    let trackViewDuration: Bool
    let trackScrollBehavior: Bool
    let trackFeatureUsage: Bool
    let anonymizeData: Bool
    let shareAnalytics: Bool
    
    init(
        trackUserInteractions: Bool = true,
        trackViewDuration: Bool = false,
        trackScrollBehavior: Bool = false,
        trackFeatureUsage: Bool = true,
        anonymizeData: Bool = true,
        shareAnalytics: Bool = false
    ) {
        self.trackUserInteractions = trackUserInteractions
        self.trackViewDuration = trackViewDuration
        self.trackScrollBehavior = trackScrollBehavior
        self.trackFeatureUsage = trackFeatureUsage
        self.anonymizeData = anonymizeData
        self.shareAnalytics = shareAnalytics
    }
}

// MARK: - Dashboard Accessibility Settings

struct DashboardAccessibilitySettings {
    let enableVoiceOver: Bool
    let enableHighContrast: Bool
    let enableLargeText: Bool
    let enableReducedMotion: Bool
    let enableHapticFeedback: Bool
    let simplifiedLayout: Bool
    let extendedTouchTargets: Bool
    
    init(
        enableVoiceOver: Bool = true,
        enableHighContrast: Bool = false,
        enableLargeText: Bool = true,
        enableReducedMotion: Bool = false,
        enableHapticFeedback: Bool = true,
        simplifiedLayout: Bool = false,
        extendedTouchTargets: Bool = false
    ) {
        self.enableVoiceOver = enableVoiceOver
        self.enableHighContrast = enableHighContrast
        self.enableLargeText = enableLargeText
        self.enableReducedMotion = enableReducedMotion
        self.enableHapticFeedback = enableHapticFeedback
        self.simplifiedLayout = simplifiedLayout
        self.extendedTouchTargets = extendedTouchTargets
    }
}

// MARK: - Dashboard Actions

/// Actions available for dashboard interactions
struct DashboardActions {
    let refreshData: () async -> Void
    let navigateToSection: (DashboardSection) -> Void
    let toggleSection: (DashboardSection) -> Void
    let customizeLayout: () -> Void
    let exportData: () async -> Void
    let shareData: () -> Void
    let showSettings: () -> Void
    let markNotificationRead: (String) -> Void
    let dismissRecommendation: (String) -> Void
    let trackInteraction: (String, [String: Any]) -> Void
    
    /// Default actions (no-op implementations)
    static let `default` = DashboardActions(
        refreshData: { },
        navigateToSection: { _ in },
        toggleSection: { _ in },
        customizeLayout: { },
        exportData: { },
        shareData: { },
        showSettings: { },
        markNotificationRead: { _ in },
        dismissRecommendation: { _ in },
        trackInteraction: { _, _ in }
    )
}

// MARK: - Dashboard State

/// Current state of the dashboard
struct DashboardState {
    let isLoading: Bool
    let lastRefreshDate: Date?
    let errorMessage: String?
    let hasUnreadNotifications: Bool
    let visibleSections: Set<DashboardSection>
    let scrollPosition: CGFloat
    let selectedHealthCategory: String?
    
    /// Default dashboard state
    static let `default` = DashboardState(
        isLoading: false,
        lastRefreshDate: nil,
        errorMessage: nil,
        hasUnreadNotifications: false,
        visibleSections: Set(DashboardSection.defaultOrder),
        scrollPosition: 0,
        selectedHealthCategory: nil
    )
    
    /// Loading state
    static let loading = DashboardState(
        isLoading: true,
        lastRefreshDate: nil,
        errorMessage: nil,
        hasUnreadNotifications: false,
        visibleSections: Set(DashboardSection.defaultOrder),
        scrollPosition: 0,
        selectedHealthCategory: nil
    )
    
    /// Error state
    static func error(_ message: String) -> DashboardState {
        DashboardState(
            isLoading: false,
            lastRefreshDate: nil,
            errorMessage: message,
            hasUnreadNotifications: false,
            visibleSections: Set(DashboardSection.defaultOrder),
            scrollPosition: 0,
            selectedHealthCategory: nil
        )
    }
}

// MARK: - iOS 18+ Environment Integration with @Entry Macro

extension EnvironmentValues {
    /// Dashboard configuration environment value using iOS 18+ @Entry macro
    @Entry var dashboardConfiguration: DashboardConfiguration = .default
    
    /// Dashboard state environment value
    @Entry var dashboardState: DashboardState = .default
    
    /// Dashboard actions environment value
    @Entry var dashboardActions: DashboardActions = .default
}

// MARK: - Dashboard Environment Modifiers

extension View {
    /// Apply dashboard environment with configuration
    func dashboardEnvironment(
        configuration: DashboardConfiguration = .default,
        state: DashboardState = .default,
        actions: DashboardActions = .default
    ) -> some View {
        self
            .environment(\.dashboardConfiguration, configuration)
            .environment(\.dashboardState, state)
            .environment(\.dashboardActions, actions)
    }
    
    /// Apply compact dashboard environment
    func compactDashboardEnvironment() -> some View {
        var compactConfig = DashboardConfiguration.default
        compactConfig = DashboardConfiguration(
            features: compactConfig.features,
            layout: DashboardLayout(compactMode: true, maxSectionsVisible: 5),
            refreshSettings: compactConfig.refreshSettings,
            healthCategories: compactConfig.healthCategories,
            notifications: compactConfig.notifications,
            analytics: compactConfig.analytics,
            accessibility: compactConfig.accessibility
        )
        
        return self.dashboardEnvironment(configuration: compactConfig)
    }
    
    /// Apply accessibility-focused dashboard environment
    func accessibleDashboardEnvironment() -> some View {
        var accessibleConfig = DashboardConfiguration.default
        accessibleConfig = DashboardConfiguration(
            features: accessibleConfig.features,
            layout: DashboardLayout(maxSectionsVisible: 3, animationsEnabled: false),
            refreshSettings: accessibleConfig.refreshSettings,
            healthCategories: accessibleConfig.healthCategories,
            notifications: accessibleConfig.notifications,
            analytics: accessibleConfig.analytics,
            accessibility: DashboardAccessibilitySettings(
                enableReducedMotion: true,
                simplifiedLayout: true,
                extendedTouchTargets: true
            )
        )
        
        return self.dashboardEnvironment(configuration: accessibleConfig)
    }
}

// MARK: - Dashboard Configuration Helpers

extension DashboardConfiguration {
    /// Check if a specific feature is enabled
    func isFeatureEnabled(_ feature: DashboardFeatureType) -> Bool {
        switch feature {
        case .healthScore: return features.enableHealthScore
        case .quickStats: return features.enableQuickStats
        case .recentActivity: return features.enableRecentActivity
        case .healthCategories: return features.enableHealthCategories
        case .notifications: return features.enableNotifications
        case .trends: return features.enableTrends
        case .recommendations: return features.enableRecommendations
        case .export: return features.enableExport
        case .comparison: return features.enableComparison
        case .goals: return features.enableGoals
        case .reminders: return features.enableReminders
        case .socialSharing: return features.enableSocialSharing
        }
    }
    
    /// Get enabled health categories for dashboard display
    var enabledHealthCategories: [HealthCategoryConfig] {
        healthCategories.filter { $0.enabled && $0.showOnDashboard }
            .sorted { $0.priority < $1.priority }
    }
    
    /// Check if data is stale and needs refresh
    func isDataStale(lastUpdate: Date?) -> Bool {
        guard let lastUpdate = lastUpdate else { return true }
        return Date().timeIntervalSince(lastUpdate) > refreshSettings.staleDataThreshold
    }
}

// MARK: - Dashboard Feature Type

enum DashboardFeatureType {
    case healthScore
    case quickStats
    case recentActivity
    case healthCategories
    case notifications
    case trends
    case recommendations
    case export
    case comparison
    case goals
    case reminders
    case socialSharing
}

// MARK: - Dashboard Conditional View Helpers

extension View {
    /// Show this view only if dashboard feature is enabled
    @ViewBuilder
    func ifDashboardFeatureEnabled(_ feature: DashboardFeatureType) -> some View {
        DashboardFeatureGatedView(
            feature: feature,
            content: { self },
            fallback: { EmptyView() }
        )
    }
}

// MARK: - Dashboard Feature Gated View

struct DashboardFeatureGatedView<Content: View, Fallback: View>: View {
    @Environment(\.dashboardConfiguration) private var config
    let feature: DashboardFeatureType
    let content: () -> Content
    let fallback: () -> Fallback
    
    var body: some View {
        if config.isFeatureEnabled(feature) {
            content()
        } else {
            fallback()
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension DashboardConfiguration {
    /// Preview configuration with all features enabled
    static let previewFull = DashboardConfiguration(
        features: DashboardFeatures(
            enableHealthScore: true,
            enableQuickStats: true,
            enableRecentActivity: true,
            enableHealthCategories: true,
            enableNotifications: true,
            enableTrends: true,
            enableRecommendations: true,
            enableExport: true,
            enableComparison: true,
            enableGoals: true,
            enableReminders: true,
            enableSocialSharing: true
        ),
        layout: DashboardLayout(),
        refreshSettings: RefreshSettings(),
        healthCategories: HealthCategoryConfig.defaultCategories,
        notifications: DashboardNotificationSettings(),
        analytics: DashboardAnalyticsSettings(),
        accessibility: DashboardAccessibilitySettings()
    )
    
    /// Preview configuration with minimal features
    static let previewMinimal = DashboardConfiguration(
        features: DashboardFeatures(
            enableHealthScore: true,
            enableQuickStats: true,
            enableRecentActivity: false,
            enableHealthCategories: false,
            enableNotifications: false,
            enableTrends: false,
            enableRecommendations: false
        ),
        layout: DashboardLayout(compactMode: true),
        refreshSettings: RefreshSettings(),
        healthCategories: [],
        notifications: DashboardNotificationSettings(),
        analytics: DashboardAnalyticsSettings(),
        accessibility: DashboardAccessibilitySettings()
    )
}

extension DashboardState {
    /// Preview state with notifications
    static let previewWithNotifications = DashboardState(
        isLoading: false,
        lastRefreshDate: Date().addingTimeInterval(-300),
        errorMessage: nil,
        hasUnreadNotifications: true,
        visibleSections: Set(DashboardSection.defaultOrder),
        scrollPosition: 0,
        selectedHealthCategory: "cardiovascular"
    )
}
#endif