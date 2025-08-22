import Foundation
import SwiftUI

// MARK: - Onboarding Models

/// Represents the current onboarding step
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case profileSetup = 1
    case healthGoals = 2
    case healthKitPermissions = 3
    case biometricSetup = 4
    case accountSetup = 5
    case completion = 6
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Super One"
        case .profileSetup:
            return "Set Up Your Profile"
        case .healthGoals:
            return "Health Goals"
        case .healthKitPermissions:
            return "Health Data Access"
        case .biometricSetup:
            return "Secure Your Data"
        case .accountSetup:
            return "Create Your Account"
        case .completion:
            return "You're All Set!"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome:
            return "Your personal health analysis companion"
        case .profileSetup:
            return "Help us personalize your experience"
        case .healthGoals:
            return "What would you like to focus on?"
        case .healthKitPermissions:
            return "Securely sync your health data"
        case .biometricSetup:
            return "Keep your health data private"
        case .accountSetup:
            return "Create your secure account to save your health data"
        case .completion:
            return "Let's start your health journey"
        }
    }
    
    var icon: String {
        switch self {
        case .welcome:
            return "heart.fill"
        case .profileSetup:
            return "person.fill"
        case .healthGoals:
            return "target"
        case .healthKitPermissions:
            return "heart.text.square.fill"
        case .biometricSetup:
            return "faceid"
        case .accountSetup:
            return "person.crop.circle.badge.plus"
        case .completion:
            return "checkmark.circle.fill"
        }
    }
    
    var progressValue: Double {
        return Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}

/// User's biological sex for health calculations
enum BiologicalSex: String, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"
    case other = "other"
    case notSet = "not_set"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        case .other:
            return "Other"
        case .notSet:
            return "Prefer not to say"
        }
    }
}

/// Health goals that users can select during onboarding
enum OnboardingHealthGoal: String, CaseIterable, Identifiable {
    case weightManagement = "weight_management"
    case fitnessTracking = "fitness_tracking"
    case chronicCondition = "chronic_condition"
    case preventiveHealth = "preventive_health"
    case nutritionOptimization = "nutrition_optimization"
    case stressManagement = "stress_management"
    case sleepImprovement = "sleep_improvement"
    case heartHealth = "heart_health"
    case bloodSugarControl = "blood_sugar_control"
    case generalWellness = "general_wellness"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .weightManagement:
            return "Weight Management"
        case .fitnessTracking:
            return "Fitness Tracking"
        case .chronicCondition:
            return "Chronic Condition Management"
        case .preventiveHealth:
            return "Preventive Health"
        case .nutritionOptimization:
            return "Nutrition Optimization"
        case .stressManagement:
            return "Stress Management"
        case .sleepImprovement:
            return "Sleep Improvement"
        case .heartHealth:
            return "Heart Health"
        case .bloodSugarControl:
            return "Blood Sugar Control"
        case .generalWellness:
            return "General Wellness"
        }
    }
    
    var description: String {
        switch self {
        case .weightManagement:
            return "Monitor weight trends and receive personalized recommendations"
        case .fitnessTracking:
            return "Track exercise metrics and cardiovascular health"
        case .chronicCondition:
            return "Manage diabetes, hypertension, or other ongoing conditions"
        case .preventiveHealth:
            return "Stay ahead of potential health issues with early insights"
        case .nutritionOptimization:
            return "Optimize your diet based on lab results and health data"
        case .stressManagement:
            return "Monitor stress levels and their impact on your health"
        case .sleepImprovement:
            return "Understand how sleep affects your overall health"
        case .heartHealth:
            return "Focus on cardiovascular wellness and heart disease prevention"
        case .bloodSugarControl:
            return "Monitor glucose levels and metabolic health"
        case .generalWellness:
            return "Overall health optimization and wellness tracking"
        }
    }
    
    var icon: String {
        switch self {
        case .weightManagement:
            return "scalemass.fill"
        case .fitnessTracking:
            return "figure.run"
        case .chronicCondition:
            return "medical.thermometer.fill"
        case .preventiveHealth:
            return "shield.fill"
        case .nutritionOptimization:
            return "leaf.fill"
        case .stressManagement:
            return "brain.head.profile"
        case .sleepImprovement:
            return "bed.double.fill"
        case .heartHealth:
            return "heart.fill"
        case .bloodSugarControl:
            return "drop.fill"
        case .generalWellness:
            return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .weightManagement:
            return HealthColors.forest
        case .fitnessTracking:
            return HealthColors.emerald
        case .chronicCondition:
            return HealthColors.healthWarning
        case .preventiveHealth:
            return HealthColors.pine
        case .nutritionOptimization:
            return HealthColors.sage
        case .stressManagement:
            return Color.purple
        case .sleepImprovement:
            return Color.indigo
        case .heartHealth:
            return HealthColors.healthCritical
        case .bloodSugarControl:
            return Color.blue
        case .generalWellness:
            return HealthColors.primary
        }
    }
}

/// User profile data collected during onboarding
struct OnboardingProfile {
    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: Date?
    var biologicalSex: BiologicalSex = .notSet
    var height: Double? // in centimeters
    var weight: Double? // in kilograms
    var selectedGoals: Set<OnboardingHealthGoal> = []
    var hasCompletedOnboarding: Bool = false
    
    // Account setup data
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    
    /// Computed age from date of birth
    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year
    }
    
    /// Full name computed property
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    /// Validation for profile completeness (excluding account setup)
    var isProfileComplete: Bool {
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               dateOfBirth != nil &&
               biologicalSex != .notSet &&
               !selectedGoals.isEmpty
    }
    
    /// Validation for account credentials
    var isAccountSetupComplete: Bool {
        return ValidationHelper.isValidEmail(email) &&
               isValidPassword(password) &&
               password == confirmPassword &&
               !password.isEmpty &&
               !confirmPassword.isEmpty
    }
    
    /// Password validation helper for onboarding
    private func isValidPassword(_ password: String) -> Bool {
        // More lenient validation for onboarding - just letters and numbers required
        let hasLetters = password.rangeOfCharacter(from: .letters) != nil
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        return password.count >= 8 && hasLetters && hasNumbers
    }
    
    /// Full onboarding completion including account setup
    var isFullOnboardingComplete: Bool {
        return isProfileComplete && isAccountSetupComplete
    }
    
    /// Height in feet and inches for display
    var heightDisplayText: String? {
        guard let height = height else { return nil }
        let totalInches = height / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return "\(feet)' \(inches)\""
    }
    
    /// Weight in pounds for display
    var weightDisplayText: String? {
        guard let weight = weight else { return nil }
        let pounds = Int(weight * 2.20462)
        return "\(pounds) lbs"
    }
}

// MARK: - Codable Conformance
extension OnboardingProfile: Codable {}
extension OnboardingProfile: Equatable {}
extension OnboardingCompletion: Codable {}
extension BiologicalSex: Codable {}
extension OnboardingHealthGoal: Codable {}

/// Welcome screen feature highlights
struct WelcomeFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

/// Static data for welcome screen features
extension WelcomeFeature {
    @MainActor static let features: [WelcomeFeature] = [
        WelcomeFeature(
            title: "Lab Report Analysis",
            description: "Upload your lab reports and get AI-powered insights about your health",
            icon: "doc.text.magnifyingglass",
            color: HealthColors.primary
        ),
        WelcomeFeature(
            title: "Health Tracking",
            description: "Monitor your health metrics with HealthKit integration",
            icon: "heart.text.square.fill",
            color: HealthColors.emerald
        ),
        WelcomeFeature(
            title: "Personalized Recommendations",
            description: "Get tailored health advice based on your unique profile",
            icon: "person.crop.circle.badge.checkmark",
            color: HealthColors.sage
        ),
        WelcomeFeature(
            title: "Secure & Private",
            description: "Your health data is encrypted and never shared without permission",
            icon: "lock.shield.fill",
            color: HealthColors.pine
        )
    ]
}

/// Onboarding completion state
struct OnboardingCompletion {
    let profileSetup: Bool
    let healthGoalsSelected: Bool
    let healthKitPermissionRequested: Bool
    let biometricSetupOffered: Bool
    let completedAt: Date
    
    init() {
        self.profileSetup = false
        self.healthGoalsSelected = false
        self.healthKitPermissionRequested = false
        self.biometricSetupOffered = false
        self.completedAt = Date()
    }
    
    var isComplete: Bool {
        return profileSetup && healthGoalsSelected && healthKitPermissionRequested
    }
}

/// HealthKit permission types relevant to onboarding
enum HealthKitPermissionType: String, CaseIterable {
    case readHeight = "height"
    case readWeight = "weight"
    case readHeartRate = "heart_rate"
    case readBloodPressure = "blood_pressure"
    case readBloodGlucose = "blood_glucose"
    case readSteps = "steps"
    case readSleep = "sleep"
    case readActiveEnergy = "active_energy"
    
    var displayName: String {
        switch self {
        case .readHeight:
            return "Height"
        case .readWeight:
            return "Weight"
        case .readHeartRate:
            return "Heart Rate"
        case .readBloodPressure:
            return "Blood Pressure"
        case .readBloodGlucose:
            return "Blood Glucose"
        case .readSteps:
            return "Steps"
        case .readSleep:
            return "Sleep Analysis"
        case .readActiveEnergy:
            return "Active Energy"
        }
    }
    
    var description: String {
        switch self {
        case .readHeight:
            return "Track height changes over time"
        case .readWeight:
            return "Monitor weight trends and fluctuations"
        case .readHeartRate:
            return "Analyze cardiovascular health patterns"
        case .readBloodPressure:
            return "Track blood pressure readings and trends"
        case .readBloodGlucose:
            return "Monitor blood sugar levels and patterns"
        case .readSteps:
            return "Track daily activity and movement"
        case .readSleep:
            return "Analyze sleep quality and duration"
        case .readActiveEnergy:
            return "Monitor calories burned during exercise"
        }
    }
    
    var icon: String {
        switch self {
        case .readHeight:
            return "ruler.fill"
        case .readWeight:
            return "scalemass.fill"
        case .readHeartRate:
            return "heart.fill"
        case .readBloodPressure:
            return "heart.circle.fill"
        case .readBloodGlucose:
            return "drop.fill"
        case .readSteps:
            return "figure.walk"
        case .readSleep:
            return "bed.double.fill"
        case .readActiveEnergy:
            return "flame.fill"
        }
    }
}

/// Biometric authentication setup options
enum BiometricSetupOption: String, CaseIterable {
    case enable = "enable"
    case skip = "skip"
    case later = "later"
    
    var displayName: String {
        switch self {
        case .enable:
            return "Enable Biometric Authentication"
        case .skip:
            return "Skip"
        case .later:
            return "Set Up Later"
        }
    }
    
    var description: String {
        switch self {
        case .enable:
            return "Use Face ID or Touch ID to securely access your health data"
        case .skip:
            return "Continue without biometric authentication"
        case .later:
            return "You can enable this feature later in Settings"
        }
    }
}
