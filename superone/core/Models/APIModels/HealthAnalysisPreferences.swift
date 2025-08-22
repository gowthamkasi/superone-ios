//
//  HealthAnalysisPreferences.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import Foundation

/// User preferences for health analysis processing and customization
struct HealthAnalysisPreferences: Codable, Sendable {
    
    // MARK: - Analysis Preferences
    
    /// Include historical trend analysis
    var includeHistoricalTrends: Bool = true
    
    /// Include predictive health insights
    var includePredictiveInsights: Bool = true
    
    /// Include personalized recommendations
    var includeRecommendations: Bool = true
    
    /// Include risk assessments
    var includeRiskAssessments: Bool = true
    
    /// Include risk assessment (alias for includeRiskAssessments)
    var includeRiskAssessment: Bool {
        get { includeRiskAssessments }
        set { includeRiskAssessments = newValue }
    }
    
    /// Include personalized recommendations
    var includePersonalizedRecommendations: Bool = true
    
    // MARK: - User Context
    
    /// Dietary restrictions for personalized recommendations
    var dietaryRestrictions: String?
    
    /// Exercise preferences for lifestyle recommendations
    var exercisePreferences: String?
    
    /// Lifestyle constraints that should be considered
    var lifestyleConstraints: String?
    
    /// Health goals for personalized analysis
    var healthGoals: String?
    
    /// Current medical conditions
    var medicalConditions: [String]?
    
    /// Current medications
    var medications: [String]?
    
    /// User age for age-specific analysis
    var userAge: Int?
    
    /// User height in centimeters
    var userHeight: Double?
    
    /// User weight in kilograms
    var userWeight: Double?
    
    // MARK: - Processing Preferences
    
    /// Preferred OCR method for document processing
    var preferredOCRMethod: String = "automatic"
    
    /// Analysis depth level (automatic, standard, detailed)
    var analysisDepth: String = "standard"
    
    /// Processing priority level
    var processingPriority: String = "standard"
    
    /// Quality vs speed balance preference
    var qualityVsSpeedBalance: String = "balanced"
    
    /// Focus areas for analysis
    var focusAreas: [String] = []
    
    // MARK: - Notification Preferences
    
    /// Notify when analysis is complete
    var notifyOnCompletion: Bool = true
    
    /// Notify when critical findings are detected
    var notifyOnCriticalFindings: Bool = true
    
    /// Send weekly health summary
    var sendWeeklySummary: Bool = false
    
    // MARK: - Initializer
    
    init(
        includeHistoricalTrends: Bool = true,
        includePredictiveInsights: Bool = true,
        includeRecommendations: Bool = true,
        includeRiskAssessments: Bool = true,
        includePersonalizedRecommendations: Bool = true,
        dietaryRestrictions: String? = nil,
        exercisePreferences: String? = nil,
        lifestyleConstraints: String? = nil,
        healthGoals: String? = nil,
        medicalConditions: [String]? = nil,
        medications: [String]? = nil,
        userAge: Int? = nil,
        userHeight: Double? = nil,
        userWeight: Double? = nil,
        preferredOCRMethod: String = "automatic",
        analysisDepth: String = "standard",
        processingPriority: String = "standard",
        qualityVsSpeedBalance: String = "balanced",
        focusAreas: [String] = [],
        notifyOnCompletion: Bool = true,
        notifyOnCriticalFindings: Bool = true,
        sendWeeklySummary: Bool = false
    ) {
        self.includeHistoricalTrends = includeHistoricalTrends
        self.includePredictiveInsights = includePredictiveInsights
        self.includeRecommendations = includeRecommendations
        self.includeRiskAssessments = includeRiskAssessments
        self.includePersonalizedRecommendations = includePersonalizedRecommendations
        self.dietaryRestrictions = dietaryRestrictions
        self.exercisePreferences = exercisePreferences
        self.lifestyleConstraints = lifestyleConstraints
        self.healthGoals = healthGoals
        self.medicalConditions = medicalConditions
        self.medications = medications
        self.userAge = userAge
        self.userHeight = userHeight
        self.userWeight = userWeight
        self.preferredOCRMethod = preferredOCRMethod
        self.analysisDepth = analysisDepth
        self.processingPriority = processingPriority
        self.qualityVsSpeedBalance = qualityVsSpeedBalance
        self.focusAreas = focusAreas
        self.notifyOnCompletion = notifyOnCompletion
        self.notifyOnCriticalFindings = notifyOnCriticalFindings
        self.sendWeeklySummary = sendWeeklySummary
    }
    
    // MARK: - Static Convenience Initializers
    
    
    /// Fast processing preferences
    static let fastProcessing = HealthAnalysisPreferences(
        preferredOCRMethod: "automatic",
        analysisDepth: "standard",
        qualityVsSpeedBalance: "speed"
    )
}