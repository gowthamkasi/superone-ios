//
//  ThemeManager.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI
import Combine

/// App theme options
enum AppTheme: String, CaseIterable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    /// Display name for the theme
    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    /// Description for the theme
    var description: String {
        switch self {
        case .system:
            return "Follow system appearance"
        case .light:
            return "Always use light mode"
        case .dark:
            return "Always use dark mode"
        }
    }
    
    /// SF Symbol icon for the theme
    var icon: String {
        switch self {
        case .system:
            return "gearshape.fill"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
    
    /// Convert to SwiftUI ColorScheme for preferredColorScheme modifier
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil // Let system decide
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

/// Centralized theme management for the app
@MainActor
final class ThemeManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Current selected theme, persisted in UserDefaults
    @Published var currentTheme: AppTheme = .system {
        didSet {
            // Persist the change to UserDefaults
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme_preference")
            
            // Provide haptic feedback when theme changes
            HapticFeedback.light()
        }
    }
    
    /// Whether the app is currently in dark mode (computed property)
    var isDarkMode: Bool {
        switch currentTheme {
        case .system:
            // Check system appearance
            return UITraitCollection.current.userInterfaceStyle == .dark
        case .light:
            return false
        case .dark:
            return true
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load persisted theme from UserDefaults
        if let savedThemeString = UserDefaults.standard.string(forKey: "app_theme_preference"),
           let savedTheme = AppTheme(rawValue: savedThemeString) {
            _currentTheme = Published(initialValue: savedTheme)
        } else {
            _currentTheme = Published(initialValue: .system)
        }
    }
    
    // MARK: - Public Methods
    
    /// Set the app theme
    func setTheme(_ theme: AppTheme) {
        guard theme != currentTheme else { return }
        
        // Theme changing from \(currentTheme.displayName) to \(theme.displayName)
        currentTheme = theme
        
        // Post notification for any observers
        NotificationCenter.default.post(
            name: .themeDidChange,
            object: nil,
            userInfo: ["newTheme": theme]
        )
    }
    
    /// Toggle between light and dark mode (excludes system)
    func toggleTheme() {
        switch currentTheme {
        case .system, .light:
            setTheme(.dark)
        case .dark:
            setTheme(.light)
        }
    }
    
    /// Reset to system theme
    func resetToSystemTheme() {
        setTheme(.system)
    }
    
    /// Get appropriate color for current theme context
    func adaptiveColor(light: Color, dark: Color) -> Color {
        switch currentTheme {
        case .system:
            return Color.dynamic(light: light, dark: dark)
        case .light:
            return light
        case .dark:
            return dark
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    /// Posted when app theme changes
    static let themeDidChange = Notification.Name("ThemeDidChange")
}

