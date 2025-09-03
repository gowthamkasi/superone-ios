import XCTest
import SwiftUI
@testable import superone

/// Unit tests for onboarding functionality
@MainActor
final class OnboardingViewTests: XCTestCase {
    
    var viewModel: OnboardingViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = OnboardingViewModel()
        
        // Clear any existing user defaults
        UserDefaults.standard.removeObject(forKey: "onboarding_user_profile")
        UserDefaults.standard.removeObject(forKey: "onboarding_completion_status")
        UserDefaults.standard.removeObject(forKey: "has_completed_onboarding")
    }
    
    override func tearDown() {
        viewModel = nil
        
        // Clean up user defaults
        UserDefaults.standard.removeObject(forKey: "onboarding_user_profile")
        UserDefaults.standard.removeObject(forKey: "onboarding_completion_status")
        UserDefaults.standard.removeObject(forKey: "has_completed_onboarding")
        
        super.tearDown()
    }
    
    // MARK: - OnboardingViewModel Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.healthKitPermissionStatus, .notDetermined)
        XCTAssertEqual(viewModel.biometricAuthenticationStatus, .notDetermined)
        XCTAssertFalse(viewModel.userProfile.hasCompletedOnboarding)
    }
    
    func testStepNavigation() {
        // Test moving forward
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .profileSetup)
        
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .healthGoals)
        
        // Test moving backward
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .profileSetup)
        
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }
    
    func testGoToSpecificStep() {
        viewModel.goToStep(.healthKitPermissions)
        XCTAssertEqual(viewModel.currentStep, .healthKitPermissions)
        
        viewModel.goToStep(.welcome)
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }
    
    func testProgressValue() {
        XCTAssertEqual(viewModel.progressValue, 0.0) // Welcome step
        
        viewModel.goToStep(.profileSetup)
        XCTAssertEqual(viewModel.progressValue, 0.2) // Step 1 of 5
        
        viewModel.goToStep(.completion)
        XCTAssertEqual(viewModel.progressValue, 1.0) // Final step
    }
    
    func testProfileUpdate() {
        let firstName = "Sample"
        let lastName = "User"
        let dateOfBirth = Date()
        let biologicalSex = BiologicalSex.male
        let height = 180.0
        let weight = 75.0
        
        viewModel.updateProfile(
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSex,
            height: height,
            weight: weight
        )
        
        XCTAssertEqual(viewModel.userProfile.firstName, firstName)
        XCTAssertEqual(viewModel.userProfile.lastName, lastName)
        XCTAssertEqual(viewModel.userProfile.dateOfBirth, dateOfBirth)
        XCTAssertEqual(viewModel.userProfile.biologicalSex, biologicalSex)
        XCTAssertEqual(viewModel.userProfile.height, height)
        XCTAssertEqual(viewModel.userProfile.weight, weight)
    }
    
    func testHealthGoalToggle() {
        let goal = HealthGoal.weightManagement
        
        // Initially not selected
        XCTAssertFalse(viewModel.isHealthGoalSelected(goal))
        XCTAssertFalse(viewModel.userProfile.selectedGoals.contains(goal))
        
        // Toggle on
        viewModel.toggleHealthGoal(goal)
        XCTAssertTrue(viewModel.isHealthGoalSelected(goal))
        XCTAssertTrue(viewModel.userProfile.selectedGoals.contains(goal))
        
        // Toggle off
        viewModel.toggleHealthGoal(goal)
        XCTAssertFalse(viewModel.isHealthGoalSelected(goal))
        XCTAssertFalse(viewModel.userProfile.selectedGoals.contains(goal))
    }
    
    func testCanProceedValidation() {
        // Welcome step - can always proceed
        viewModel.goToStep(.welcome)
        XCTAssertTrue(viewModel.canProceedFromCurrentStep)
        
        // Profile setup - requires basic info
        viewModel.goToStep(.profileSetup)
        XCTAssertFalse(viewModel.canProceedFromCurrentStep)
        
        viewModel.updateProfile(
            firstName: "Sample",
            lastName: "User",
            dateOfBirth: Date(),
            biologicalSex: .male
        )
        XCTAssertTrue(viewModel.canProceedFromCurrentStep)
        
        // Health goals - requires at least one goal
        viewModel.goToStep(.healthGoals)
        XCTAssertFalse(viewModel.canProceedFromCurrentStep)
        
        viewModel.toggleHealthGoal(.generalWellness)
        XCTAssertTrue(viewModel.canProceedFromCurrentStep)
    }
    
    func testHealthKitPermissionRequest() async {
        viewModel.goToStep(.healthKitPermissions)
        XCTAssertEqual(viewModel.healthKitPermissionStatus, .notDetermined)
        
        await viewModel.requestHealthKitPermissions()
        
        // Should move to next step after permission request
        XCTAssertEqual(viewModel.currentStep, .biometricSetup)
        XCTAssertEqual(viewModel.healthKitPermissionStatus, .authorized)
    }
    
    func testBiometricSetup() async {
        viewModel.goToStep(.biometricSetup)
        XCTAssertEqual(viewModel.biometricAuthenticationStatus, .notDetermined)
        
        await viewModel.setupBiometricAuthentication()
        
        // Should move to next step after biometric setup
        XCTAssertEqual(viewModel.currentStep, .completion)
        XCTAssertEqual(viewModel.biometricAuthenticationStatus, .available)
    }
    
    func testSkipBiometricSetup() {
        viewModel.goToStep(.biometricSetup)
        
        viewModel.skipBiometricSetup()
        
        XCTAssertEqual(viewModel.currentStep, .completion)
        XCTAssertEqual(viewModel.biometricAuthenticationStatus, .skipped)
    }
    
    func testCompleteOnboarding() async {
        // Set up complete profile
        viewModel.updateProfile(
            firstName: "Sample",
            lastName: "User",
            dateOfBirth: Date(),
            biologicalSex: .male
        )
        viewModel.toggleHealthGoal(.generalWellness)
        
        viewModel.goToStep(.completion)
        
        await viewModel.completeOnboarding()
        
        XCTAssertTrue(viewModel.userProfile.hasCompletedOnboarding)
    }
    
    func testResetOnboarding() {
        // Set up some state
        viewModel.updateProfile(firstName: "Sample", lastName: "User")
        viewModel.toggleHealthGoal(.weightManagement)
        viewModel.goToStep(.profileSetup)
        
        viewModel.resetOnboarding()
        
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertTrue(viewModel.userProfile.firstName.isEmpty)
        XCTAssertTrue(viewModel.userProfile.selectedGoals.isEmpty)
        XCTAssertEqual(viewModel.healthKitPermissionStatus, .notDetermined)
        XCTAssertEqual(viewModel.biometricAuthenticationStatus, .notDetermined)
    }
    
    // MARK: - OnboardingProfile Tests
    
    func testOnboardingProfileAge() {
        var profile = OnboardingProfile()
        
        // No date of birth
        XCTAssertNil(profile.age)
        
        // Set date of birth 25 years ago
        let calendar = Calendar.current
        profile.dateOfBirth = calendar.date(byAdding: .year, value: -25, to: Date())
        
        XCTAssertEqual(profile.age, 25)
    }
    
    func testOnboardingProfileFullName() {
        var profile = OnboardingProfile()
        
        // Empty names
        XCTAssertTrue(profile.fullName.isEmpty)
        
        profile.firstName = "Sample"
        profile.lastName = "User"
        
        XCTAssertEqual(profile.fullName, "Sample User")
    }
    
    func testOnboardingProfileCompletion() {
        var profile = OnboardingProfile()
        
        // Initially incomplete
        XCTAssertFalse(profile.isProfileComplete)
        
        // Add required fields
        profile.firstName = "Sample"
        profile.lastName = "User"
        profile.dateOfBirth = Date()
        profile.biologicalSex = .male
        profile.selectedGoals.insert(.generalWellness)
        
        XCTAssertTrue(profile.isProfileComplete)
    }
    
    func testHeightDisplayText() {
        var profile = OnboardingProfile()
        
        // No height
        XCTAssertNil(profile.heightDisplayText)
        
        // Set height to 180 cm (5'11")
        profile.height = 180.0
        XCTAssertEqual(profile.heightDisplayText, "5' 11\"")
        
        // Set height to 170 cm (5'7")
        profile.height = 170.0
        XCTAssertEqual(profile.heightDisplayText, "5' 7\"")
    }
    
    func testWeightDisplayText() {
        var profile = OnboardingProfile()
        
        // No weight
        XCTAssertNil(profile.weightDisplayText)
        
        // Set weight to 70 kg (~154 lbs)
        profile.weight = 70.0
        XCTAssertEqual(profile.weightDisplayText, "154 lbs")
        
        // Set weight to 80 kg (~176 lbs)
        profile.weight = 80.0
        XCTAssertEqual(profile.weightDisplayText, "176 lbs")
    }
    
    // MARK: - HealthGoal Tests
    
    func testHealthGoalProperties() {
        let goal = HealthGoal.weightManagement
        
        XCTAssertEqual(goal.displayName, "Weight Management")
        XCTAssertEqual(goal.icon, "scalemass.fill")
        XCTAssertEqual(goal.color, HealthColors.forest)
        XCTAssertFalse(goal.description.isEmpty)
    }
    
    func testAllHealthGoalsHaveProperties() {
        for goal in HealthGoal.allCases {
            XCTAssertFalse(goal.displayName.isEmpty, "Goal \(goal) should have a display name")
            XCTAssertFalse(goal.icon.isEmpty, "Goal \(goal) should have an icon")
            XCTAssertFalse(goal.description.isEmpty, "Goal \(goal) should have a description")
        }
    }
    
    // MARK: - BiologicalSex Tests
    
    func testBiologicalSexDisplayNames() {
        XCTAssertEqual(BiologicalSex.male.displayName, "Male")
        XCTAssertEqual(BiologicalSex.female.displayName, "Female")
        XCTAssertEqual(BiologicalSex.other.displayName, "Other")
        XCTAssertEqual(BiologicalSex.notSet.displayName, "Prefer not to say")
    }
    
    // MARK: - OnboardingStep Tests
    
    func testOnboardingStepProperties() {
        let step = OnboardingStep.profileSetup
        
        XCTAssertEqual(step.title, "Set Up Your Profile")
        XCTAssertEqual(step.subtitle, "Help us personalize your experience")
        XCTAssertEqual(step.icon, "person.fill")
        XCTAssertEqual(step.progressValue, 0.2) // Step 1 of 5
    }
    
    func testAllOnboardingStepsHaveProperties() {
        for step in OnboardingStep.allCases {
            XCTAssertFalse(step.title.isEmpty, "Step \(step) should have a title")
            XCTAssertFalse(step.subtitle.isEmpty, "Step \(step) should have a subtitle")
            XCTAssertFalse(step.icon.isEmpty, "Step \(step) should have an icon")
            XCTAssertGreaterThanOrEqual(step.progressValue, 0.0, "Step \(step) should have valid progress")
            XCTAssertLessThanOrEqual(step.progressValue, 1.0, "Step \(step) should have valid progress")
        }
    }
    
    // MARK: - WelcomeFeature Tests
    
    func testWelcomeFeatures() {
        let features = WelcomeFeature.features
        
        XCTAssertEqual(features.count, 4)
        XCTAssertFalse(features.isEmpty)
        
        for feature in features {
            XCTAssertFalse(feature.title.isEmpty)
            XCTAssertFalse(feature.description.isEmpty)
            XCTAssertFalse(feature.icon.isEmpty)
        }
    }
    
    // MARK: - HealthKitPermissionType Tests
    
    func testHealthKitPermissionTypes() {
        let permission = HealthKitPermissionType.readHeartRate
        
        XCTAssertEqual(permission.displayName, "Heart Rate")
        XCTAssertEqual(permission.icon, "heart.fill")
        XCTAssertFalse(permission.description.isEmpty)
    }
    
    func testAllHealthKitPermissionTypesHaveProperties() {
        for permission in HealthKitPermissionType.allCases {
            XCTAssertFalse(permission.displayName.isEmpty, "Permission \(permission) should have a display name")
            XCTAssertFalse(permission.icon.isEmpty, "Permission \(permission) should have an icon")
            XCTAssertFalse(permission.description.isEmpty, "Permission \(permission) should have a description")
        }
    }
    
    // MARK: - Performance Tests
    
    func testOnboardingViewModelPerformance() {
        measure {
            let viewModel = OnboardingViewModel()
            
            // Simulate typical onboarding flow
            viewModel.updateProfile(
                firstName: "Sample",
                lastName: "User",
                dateOfBirth: Date(),
                biologicalSex: .male,
                height: 180.0,
                weight: 75.0
            )
            
            for goal in [HealthGoal.generalWellness, .weightManagement, .fitnessTracking] {
                viewModel.toggleHealthGoal(goal)
            }
            
            for step in OnboardingStep.allCases {
                viewModel.goToStep(step)
            }
        }
    }
}

// MARK: - Mock Data Helpers

extension OnboardingViewTests {
    
    func createCompleteProfile() -> OnboardingProfile {
        var profile = OnboardingProfile()
        profile.firstName = "Sample"
        profile.lastName = "User"
        profile.dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())
        profile.biologicalSex = .male
        profile.height = 180.0
        profile.weight = 75.0
        profile.selectedGoals = [.generalWellness, .weightManagement]
        return profile
    }
    
    func createIncompleteProfile() -> OnboardingProfile {
        var profile = OnboardingProfile()
        profile.firstName = "Sample"
        // Missing required fields
        return profile
    }
}