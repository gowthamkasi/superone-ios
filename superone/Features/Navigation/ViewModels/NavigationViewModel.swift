import SwiftUI

/// Navigation state management and deep linking for the Super One Health app
@MainActor
@Observable
class NavigationViewModel {
    // MARK: - Observable Properties
    var selectedTab: Int = 0
    var isPresentingUpload: Bool = false
    var navigationPath = NavigationPath()
    var isTabBarHidden: Bool = false
    
    // MARK: - Private Properties
    var appState: AppState
    
    // MARK: - Tab Configuration
    struct TabItem {
        let id: Int
        let title: String
        let icon: String
        let selectedIcon: String
        let type: TabType
        
        enum TabType {
            case normal, upload, navigation
        }
    }
    
    let tabs: [TabItem] = [
        TabItem(id: 0, title: "Home", icon: "house", selectedIcon: "house.fill", type: .normal),
        TabItem(id: 1, title: "Appointments", icon: "calendar", selectedIcon: "calendar", type: .normal),
        TabItem(id: 2, title: "", icon: "plus.circle.fill", selectedIcon: "plus.circle.fill", type: .upload),
        TabItem(id: 3, title: "Reports", icon: "doc.text", selectedIcon: "doc.text.fill", type: .normal),
        TabItem(id: 4, title: "Profile", icon: "person.circle", selectedIcon: "person.circle.fill", type: .normal)
    ]
    
    /// Computed property to filter tabs based on feature flags
    var availableTabs: [TabItem] {
        return tabs.filter { tab in
            if tab.type == .upload {
                return AppConfiguration.current.isFeatureEnabled(.ocrUpload)
            }
            return true
        }
    }
    
    // MARK: - Initialization
    init(appState: AppState) {
        self.appState = appState
        // Removed Combine-based observers - direct synchronization for better performance
        self.selectedTab = appState.selectedTab
    }
    
    // MARK: - Public Methods
    
    /// Handle tab selection with special logic for upload tab
    func selectTab(_ tabIndex: Int) {
        if tabIndex == 2 { // Upload tab
            // Add feature flag check
            if AppConfiguration.current.isFeatureEnabled(.ocrUpload) {
                presentUploadFlow()
            }
            // If disabled, do nothing (no crash, no action)
        } else {
            selectedTab = tabIndex
            appState.selectedTab = tabIndex
            handleTabSelection(tabIndex)
        }
    }
    
    /// Present the upload flow
    func presentUploadFlow() {
        isPresentingUpload = true
        
        // Haptic feedback for upload action
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    /// Dismiss upload flow
    func dismissUploadFlow() {
        isPresentingUpload = false
    }
    
    /// Navigate to specific screen with deep linking
    func navigateToScreen(_ screen: DeepLinkDestination) {
        switch screen {
        case .dashboard:
            selectedTab = 0
        case .appointments:
            selectedTab = 1
        case .reports:
            selectedTab = 3
        case .profile:
            selectedTab = 4
        case .upload:
            presentUploadFlow()
        case .healthScore:
            selectedTab = 0
            // Could push to health score detail view here
        case .notifications:
            selectedTab = 0
            // Could push to notifications view here
        }
    }
    
    /// Hide/show tab bar with animation
    func setTabBarHidden(_ hidden: Bool, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                isTabBarHidden = hidden
            }
        } else {
            isTabBarHidden = hidden
        }
    }
    
    /// Reset navigation to root
    func resetToRoot() {
        selectedTab = 0
        navigationPath = NavigationPath()
        isTabBarHidden = false
        isPresentingUpload = false
    }
    
    // MARK: - Private Methods
    private func handleTabSelection(_ tabIndex: Int) {
        // Handle side effects of tab selection
        switch tabIndex {
        case 0: // Dashboard
            // Could trigger dashboard refresh here
            break
        case 1: // Appointments
            // Could trigger appointments refresh here
            break
        case 3: // Reports
            // Could trigger reports refresh here
            break
        case 4: // Profile
            // Could trigger profile refresh here
            break
        default:
            break
        }
    }
}

// MARK: - Deep Link Destinations
enum DeepLinkDestination {
    case dashboard
    case appointments
    case reports
    case profile
    case upload
    case healthScore
    case notifications
}

// MARK: - Navigation Extensions
extension NavigationViewModel {
    
    /// Get appropriate haptic feedback for tab
    func hapticFeedbackForTab(_ tabIndex: Int) -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch tabIndex {
        case 2: // Upload tab
            return .heavy
        default:
            return .light
        }
    }
    
    /// Check if tab should be highlighted
    func shouldHighlightTab(_ tabIndex: Int) -> Bool {
        return selectedTab == tabIndex && tabIndex != 2
    }
    
    /// Get accessibility label for tab
    func accessibilityLabel(for tab: TabItem) -> String {
        switch tab.type {
        case .upload:
            return "Upload lab report"
        case .normal:
            return tab.title
        default:
            return tab.title
        }
    }
    
    /// Get accessibility hint for tab
    func accessibilityHint(for tab: TabItem) -> String {
        switch tab.id {
        case 0:
            return "View your health dashboard and scores"
        case 1:
            return "Manage your appointments"
        case 2:
            return "Upload a new lab report for analysis"
        case 3:
            return "View your lab reports and results"
        case 4:
            return "Access your profile and settings"
        default:
            return ""
        }
    }
}