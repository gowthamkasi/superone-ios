import SwiftUI

/// Health-focused color system based on medical-grade green palette
struct HealthColors {
    // MARK: - Primary Green Palette
    static let sage = Color(hex: "#A8D5BA")       // Lightest green
    static let emerald = Color(hex: "#6BBF8A")    // Light-medium green  
    static let forest = Color(hex: "#4B9B6E")     // Medium green
    static let pine = Color(hex: "#2E7D5C")       // Dark green
    static let deepForest = Color(hex: "#1B5E3A") // Darkest green
    
    // MARK: - Semantic Colors
    static let primary = forest                    // Main brand color
    static let secondary = emerald                // Secondary actions
    static let accent = sage                      // Highlights and backgrounds
    
    // MARK: - System Colors (iOS compatible)
    static let background = Color(.systemBackground)
    static let primaryBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    // MARK: - Text Colors
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    
    // MARK: - UI Element Colors
    static let border = Color(.separator)
    
    // MARK: - Health Status Colors
    static let healthExcellent = emerald
    static let healthGood = forest
    static let healthNormal = sage
    static let healthFair = Color(.systemYellow)
    static let healthModerate = Color(.systemYellow)
    static let healthWarning = Color(.systemOrange)
    static let healthCritical = Color(.systemRed)
    static let healthNeutral = Color(.systemGray)
    
    // MARK: - Dark Mode Support
    struct Dark {
        static let sage = Color(hex: "#6B8F7A")
        static let emerald = Color(hex: "#4A8F6A")
        static let forest = Color(hex: "#3A7B5E")
        static let pine = Color(hex: "#256D4C")
        static let deepForest = Color(hex: "#1A4E3A")
    }
    
    // MARK: - Dynamic Colors
    static let dynamicPrimary = Color.dynamic(
        light: forest,
        dark: Dark.forest
    )
    
    static let dynamicSecondary = Color.dynamic(
        light: emerald,
        dark: Dark.emerald
    )
    
    static let dynamicAccent = Color.dynamic(
        light: sage,
        dark: Dark.sage
    )
}

// MARK: - Color Extensions
extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Create dynamic color for light/dark mode
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Health Status Color Extensions
extension HealthColors {
    /// Get color for health status
    static func statusColor(for status: HealthStatus) -> Color {
        switch status {
        case .excellent:
            return healthExcellent
        case .good:
            return healthGood
        case .normal:
            return healthNormal
        case .fair:
            return healthFair
        case .monitor:
            return healthWarning
        case .needsAttention:
            return healthCritical
        case .poor:
            return healthCritical
        case .critical:
            return healthCritical
        }
    }
    
    /// Get background color for health status
    static func statusBackgroundColor(for status: HealthStatus) -> Color {
        switch status {
        case .excellent, .good, .normal:
            return accent.opacity(0.1)
        case .fair:
            return healthFair.opacity(0.1)
        case .monitor:
            return healthWarning.opacity(0.1)
        case .needsAttention, .poor, .critical:
            return healthCritical.opacity(0.1)
        }
    }
}

// MARK: - Health Status Colors
// HealthStatus enum is now defined in BackendModels.swift to avoid duplication
// Use the consolidated version with proper Sendable conformance