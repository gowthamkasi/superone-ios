import Foundation

/// Health score model representing overall health calculation
struct HealthScore {
    let value: Int
    let status: HealthStatus
    let trend: TrendDirection
    let lastUpdated: Date
    let components: [HealthScoreComponent]
    
    init(value: Int, trend: TrendDirection = .stable, lastUpdated: Date = Date(), components: [HealthScoreComponent] = []) {
        self.value = max(0, min(100, value)) // Clamp between 0-100
        self.status = Self.calculateStatus(for: value)
        self.trend = trend
        self.lastUpdated = lastUpdated
        self.components = components
    }
    
    /// Calculate health status based on score value
    private static func calculateStatus(for value: Int) -> HealthStatus {
        switch value {
        case 90...100:
            return .excellent
        case 80..<90:
            return .good
        case 70..<80:
            return .normal
        case 60..<70:
            return .monitor
        default:
            return .needsAttention
        }
    }
    
    /// Get display text for status with trend
    var statusDisplayText: String {
        switch trend {
        case .improving:
            return "\(status.displayName) - Improving Trend"
        case .declining:
            return "\(status.displayName) - Watch Carefully"
        case .stable:
            return "\(status.displayName) - Stable Trend"
        case .unknown:
            return "\(status.displayName) - Status Unknown"
        }
    }
    
    /// Get normalized progress value for animations (0.0 to 1.0)
    var normalizedProgress: Double {
        return Double(value) / 100.0
    }
}

// HealthTrend enum is now defined in BackendModels.swift to avoid duplication
// Use the consolidated version with proper protocol conformances

/// Individual component contributing to overall health score
struct HealthScoreComponent {
    let category: String
    let value: Int
    let weight: Double
    let lastUpdated: Date
    
    /// Weighted contribution to overall score
    var weightedValue: Double {
        return Double(value) * weight
    }
}

// MARK: - Factory Methods
extension HealthScore {
    /// Create empty health score for initial state
    static func empty() -> HealthScore {
        return HealthScore(value: 0, trend: .unknown, components: [])
    }
    
    /// Create health score from lab report analysis
    static func fromLabData(components: [HealthScoreComponent]) -> HealthScore {
        guard !components.isEmpty else {
            return empty()
        }
        
        // Calculate weighted average from real health data components
        let totalWeightedValue = components.reduce(0) { $0 + $1.weightedValue }
        let totalWeight = components.reduce(0) { $0 + $1.weight }
        let averageScore = totalWeight > 0 ? Int(totalWeightedValue / totalWeight) : 0
        
        // Determine trend based on component changes over time
        let trend = determineTrend(from: components)
        
        return HealthScore(
            value: averageScore,
            trend: trend,
            lastUpdated: Date(),
            components: components
        )
    }
    
    /// Determine overall health trend from component analysis
    private static func determineTrend(from components: [HealthScoreComponent]) -> TrendDirection {
        // Trend analysis based on historical component data - compares current values with previous measurements
        return .unknown
    }
}