//
//  BackendHealthCategory+Extensions.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI

// MARK: - Backend Health Category Extensions

extension BackendHealthCategory {
    
    /// Extended user-friendly display name for the health category
    var extendedDisplayName: String {
        switch self {
        case .cardiovascular:
            return "Cardiovascular Health"
        case .metabolic:
            return "Metabolic Health"
        case .hematology:
            return "Blood Work & Hematology"
        case .hepaticRenal:
            return "Liver & Kidney Function"
        case .nutritional:
            return "Nutritional Status"
        case .immune:
            return "Immune System"
        case .endocrine:
            return "Hormonal & Endocrine"
        case .cancerScreening:
            return "Cancer Screening"
        case .reproductiveHealth:
            return "Reproductive Health"
        case .mentalHealth:
            return "Mental Health Biomarkers"
        case .respiratory:
            return "Respiratory Function"
        case .geneticMarkers:
            return "Genetic Markers"
        }
    }
    
    /// Short description of what this category covers
    var description: String {
        switch self {
        case .cardiovascular:
            return "Heart health and circulation"
        case .metabolic:
            return "Metabolism and energy processing"
        case .hematology:
            return "Blood cells and blood disorders"
        case .hepaticRenal:
            return "Liver and kidney function"
        case .nutritional:
            return "Nutritional status and deficiencies"
        case .immune:
            return "Immune system function"
        case .endocrine:
            return "Hormonal balance and function"
        case .cancerScreening:
            return "Cancer screening and markers"
        case .reproductiveHealth:
            return "Reproductive health and fertility"
        case .mentalHealth:
            return "Mental health biomarkers"
        case .respiratory:
            return "Lung function and respiratory health"
        case .geneticMarkers:
            return "Genetic markers and predispositions"
        }
    }
    
    /// Icon name for displaying this category
    var iconName: String {
        switch self {
        case .cardiovascular:
            return "heart.fill"
        case .metabolic:
            return "flame.fill"
        case .hematology:
            return "drop.fill"
        case .hepaticRenal:
            return "cross.fill"
        case .nutritional:
            return "leaf.fill"
        case .immune:
            return "shield.fill"
        case .endocrine:
            return "testtube.2"
        case .cancerScreening:
            return "magnifyingglass.circle.fill"
        case .reproductiveHealth:
            return "figure.2.and.child.holdinghands"
        case .mentalHealth:
            return "brain.head.profile"
        case .respiratory:
            return "lungs.fill"
        case .geneticMarkers:
            return "dna"
        }
    }
    
    /// Primary color associated with this category
    var primaryColor: Color {
        switch self {
        case .cardiovascular:
            return HealthColors.healthCritical
        case .metabolic:
            return HealthColors.healthGood
        case .hematology:
            return HealthColors.healthExcellent
        case .hepaticRenal:
            return HealthColors.healthWarning
        case .nutritional:
            return HealthColors.healthNormal
        case .immune:
            return HealthColors.primary
        case .endocrine:
            return HealthColors.secondary
        case .cancerScreening:
            return HealthColors.accent
        case .reproductiveHealth:
            return Color(.systemPink)
        case .mentalHealth:
            return Color(.systemPurple)
        case .respiratory:
            return Color(.systemTeal)
        case .geneticMarkers:
            return Color(.systemIndigo)
        }
    }
    
    /// Priority level for this category (1 = highest, 5 = lowest)
    var priorityLevel: Int {
        switch self {
        case .cardiovascular, .cancerScreening:
            return 1 // Highest priority
        case .hepaticRenal, .hematology:
            return 2 // High priority
        case .metabolic, .endocrine:
            return 2 // High priority
        case .nutritional, .immune:
            return 3 // Medium priority
        case .respiratory, .reproductiveHealth:
            return 3 // Medium priority
        case .mentalHealth, .geneticMarkers:
            return 4 // Lower priority
        }
    }
}

// MARK: - Array Extensions

extension Array where Element == BackendHealthCategory {
    
    /// Sort categories by priority level
    var sortedByPriority: [BackendHealthCategory] {
        return self.sorted { $0.priorityLevel < $1.priorityLevel }
    }
    
    /// Filter categories by priority level
    func categoriesByPriority(_ priority: Int) -> [BackendHealthCategory] {
        return self.filter { $0.priorityLevel == priority }
    }
    
    /// Get high priority categories (priority 1-2)
    var highPriorityCategories: [BackendHealthCategory] {
        return self.filter { $0.priorityLevel <= 2 }
    }
    
    /// Get medium priority categories (priority 3)
    var mediumPriorityCategories: [BackendHealthCategory] {
        return self.filter { $0.priorityLevel == 3 }
    }
    
    /// Get low priority categories (priority 4-5)
    var lowPriorityCategories: [BackendHealthCategory] {
        return self.filter { $0.priorityLevel >= 4 }
    }
}