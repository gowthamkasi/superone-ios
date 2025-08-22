import Foundation

/// ViewModel for managing the onboarding flow and user data
@MainActor
@Observable
class OnboardingViewModel {
    
    // MARK: - Observable Properties
    var currentStep: OnboardingStep = .welcome
    var userProfile = OnboardingProfile()
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var healthKitPermissionStatus: HealthKitPermissionStatus = .notDetermined
    var biometricAuthenticationStatus: BiometricAuthenticationStatus = .skipped // Always skipped for now
    
    // MARK: - Private Properties  
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Dependencies
    private var healthKitService: HealthKitServiceProtocol
    private var keychainService: KeychainServiceProtocol
    private var authenticationManager: AuthenticationManager
    private var flowManager: AppFlowManager
    
    // MARK: - Initialization
    init(healthKitService: HealthKitServiceProtocol = HealthKitService(), keychainService: KeychainServiceProtocol = KeychainHelper.shared, authenticationManager: AuthenticationManager = AuthenticationManager(), flowManager: AppFlowManager = AppFlowManager.shared) {
        // Initialize all dependencies first
        self.healthKitService = healthKitService
        self.keychainService = keychainService
        self.authenticationManager = authenticationManager
        self.flowManager = flowManager
        
        // Load profile immediately - UserDefaults access is fast enough and won't block
        loadSavedProfile()
    }
    
    // MARK: - Public Methods
    
    /// Move to the next onboarding step
    func nextStep() {
        // CRITICAL: Direct synchronous navigation - SwiftUI requires immediate response to button taps
        if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        }
    }
    
    /// Move to the previous onboarding step
    func previousStep() {
        // CRITICAL: Direct synchronous navigation - SwiftUI requires immediate response to button taps
        if let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            currentStep = previousStep
        }
    }
    
    /// Jump to a specific onboarding step
    func goToStep(_ step: OnboardingStep) {
        // CRITICAL: Direct synchronous navigation - SwiftUI requires immediate response to button taps
        currentStep = step
    }
    
    /// Update user profile information
    func updateProfile(firstName: String? = nil, 
                      lastName: String? = nil, 
                      dateOfBirth: Date? = nil, 
                      biologicalSex: BiologicalSex? = nil, 
                      height: Double? = nil, 
                      weight: Double? = nil) {
        if let firstName = firstName {
            userProfile.firstName = firstName
        }
        if let lastName = lastName {
            userProfile.lastName = lastName
        }
        if let dateOfBirth = dateOfBirth {
            userProfile.dateOfBirth = dateOfBirth
        }
        if let biologicalSex = biologicalSex {
            userProfile.biologicalSex = biologicalSex
        }
        if let height = height {
            userProfile.height = height
        }
        if let weight = weight {
            userProfile.weight = weight
        }
        
        saveProfile()
    }
    
    /// Toggle health goal selection
    func toggleHealthGoal(_ goal: OnboardingHealthGoal) {
        if userProfile.selectedGoals.contains(goal) {
            userProfile.selectedGoals.remove(goal)
        } else {
            userProfile.selectedGoals.insert(goal)
        }
        saveProfile()
    }
    
    /// Check if a health goal is selected
    func isHealthGoalSelected(_ goal: OnboardingHealthGoal) -> Bool {
        return userProfile.selectedGoals.contains(goal)
    }
    
    /// Request HealthKit permissions
    func requestHealthKitPermissions() async {
        guard healthKitPermissionStatus != .authorized else {
            nextStep()
            return
        }
        
        // Ensure loading state is set on main actor
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Request HealthKit authorization - keep on main queue for proper actor isolation
            let authorized = try await healthKitService.requestAuthorization()
            
            await MainActor.run {
                if authorized {
                    self.healthKitPermissionStatus = .authorized
                    // Move to next step after successful permission
                    self.nextStep()
                } else {
                    self.healthKitPermissionStatus = .denied
                    self.showErrorMessage("HealthKit permission was denied. You can enable it later in Settings.")
                }
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.healthKitPermissionStatus = .denied
                self.showErrorMessage("Failed to request HealthKit permissions: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
    
    /// Set up biometric authentication (simplified - always skip for now)
    func setupBiometricAuthentication() async {
        // For now, we skip biometric setup - this can be re-enabled later
        biometricAuthenticationStatus = .skipped
        nextStep()
    }
    
    /// Skip biometric authentication setup
    func skipBiometricSetup() {
        biometricAuthenticationStatus = .skipped
        nextStep()
    }
    
    /// Create account and complete onboarding (called from AccountSetupView)
    func createAccountAndCompleteOnboarding() async {
        await Task.yield()
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            showError = false
        }
        
        do {
            // Validate full profile completion including account setup
            guard userProfile.isFullOnboardingComplete else {
                throw OnboardingError.incompleteProfile
            }
            
            
            // Create the user profile for API request
            let mappedGender = mapBiologicalSexToGender(userProfile.biologicalSex)
            
            let profile = UserProfile(
                dateOfBirth: userProfile.dateOfBirth,
                gender: mappedGender,
                height: userProfile.height,
                weight: userProfile.weight,
                activityLevel: nil, // Can be enhanced later
                healthGoals: mapOnboardingHealthGoalsToBackend(userProfile.selectedGoals),
                medicalConditions: nil,
                medications: nil,
                allergies: nil,
                emergencyContact: nil,
                profileImageURL: nil
            )
            
            
            // Use AuthenticationManager to register the account
            
            // Profile data ready for registration
            
            
            // Call the registration method with the user data
            
            await authenticationManager.registerUser(
                name: userProfile.fullName,
                email: userProfile.email,
                password: userProfile.password,
                dateOfBirth: userProfile.dateOfBirth,
                profile: profile
            )
            
            
            // Check if registration was successful
            if authenticationManager.isAuthenticated {
                // Registration successful, complete onboarding
                await Task.yield()
                await MainActor.run {
                    userProfile.hasCompletedOnboarding = true
                    saveOnboardingCompletion()
                    
                    // Notify flow manager
                    flowManager.completeOnboarding()
                    
                    // Move to completion step
                    nextStep()
                    
                    isLoading = false
                }
            } else {
                // Registration failed, show error with enhanced timeout handling
                await MainActor.run {
                    var errorMessage = authenticationManager.errorMessage ?? "Failed to create account. Please try again."
                    
                    // Provide more specific guidance for common issues
                    if errorMessage.contains("timed out") || errorMessage.contains("timeout") {
                        errorMessage = "The server is taking too long to respond. Please check your internet connection and try again. If the problem persists, please try again later."
                    } else if errorMessage.contains("network") || errorMessage.contains("connection") {
                        errorMessage = "Unable to connect to the server. Please check your internet connection and try again."
                    } else if errorMessage.contains("No internet connection") {
                        errorMessage = "No internet connection available. Please check your network settings and try again."
                    }
                    
                    showErrorMessage(errorMessage)
                    isLoading = false
                }
            }
            
        } catch {
            await MainActor.run {
                showErrorMessage("Failed to create account: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    
    /// Complete the onboarding process
    func completeOnboarding() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Validate profile completion
            guard userProfile.isProfileComplete else {
                throw OnboardingError.incompleteProfile
            }
            
            // Mark onboarding as completed
            userProfile.hasCompletedOnboarding = true
            
            // Save completion state
            saveOnboardingCompletion()
            
            await MainActor.run {
                // Don't call nextStep() - we're already at completion
                // The navigation will be handled by the parent view listening to hasCompletedOnboarding
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.showErrorMessage("Failed to complete onboarding: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
    
    /// Cancel ongoing network requests
    func cancelActiveRequests() {
        // Cancel any active requests - simplified for now
        // authenticationManager.cancelActiveRequests()
        isLoading = false
        errorMessage = nil
        showError = false
    }
    
    /// Reset onboarding to start over
    func resetOnboarding() {
        // Cancel any active requests first
        cancelActiveRequests()
        
        currentStep = .welcome
        userProfile = OnboardingProfile()
        healthKitPermissionStatus = .notDetermined
        biometricAuthenticationStatus = .skipped
        clearSavedData()
    }
    
    // MARK: - Computed Properties
    
    var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .profileSetup:
            return !userProfile.firstName.isEmpty && 
                   !userProfile.lastName.isEmpty && 
                   userProfile.dateOfBirth != nil && 
                   userProfile.biologicalSex != .notSet &&
                   isValidAge
        case .healthGoals:
            return !userProfile.selectedGoals.isEmpty
        case .healthKitPermissions:
            return healthKitPermissionStatus == .authorized || healthKitPermissionStatus == .denied
        case .biometricSetup:
            return true // Always considered complete since we skip biometric setup
        case .accountSetup:
            return userProfile.isAccountSetupComplete
        case .completion:
            return true
        }
    }
    
    var progressValue: Double {
        return currentStep.progressValue
    }
    
    var isFirstStep: Bool {
        return currentStep == .welcome
    }
    
    var isLastStep: Bool {
        return currentStep == .completion
    }
    
    /// Validate that user is at least 18 years old
    var isValidAge: Bool {
        guard let dateOfBirth = userProfile.dateOfBirth else { return false }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
        guard let age = ageComponents.year else { return false }
        return age >= 18
    }
    
    // MARK: - Private Methods
    
    // REMOVED: setupSubscriptions() - no longer needed with @Observable pattern
    // Manual saveProfile() calls are more performant than Combine publishers
    
    private func showErrorMessage(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
    
    /// Maps BiologicalSex to backend Gender enum
    private func mapBiologicalSexToGender(_ biologicalSex: BiologicalSex) -> Gender? {
        
        let mappedGender: Gender?
        switch biologicalSex {
        case .male:
            mappedGender = .male
        case .female:
            mappedGender = .female
        case .other:
            mappedGender = .other
        case .notSet:
            mappedGender = .notSpecified // Map to backend's notSpecified instead of nil
        }
        
        
        return mappedGender
    }
    
    /// Maps OnboardingHealthGoal to backend HealthGoal enum
    private func mapOnboardingHealthGoalsToBackend(_ onboardingGoals: Set<OnboardingHealthGoal>) -> [HealthGoal] {
        return onboardingGoals.compactMap { onboardingGoal in
            switch onboardingGoal {
            case .weightManagement:
                return .general // Map to general wellness for weight management
            case .fitnessTracking:
                return .cardiovascularHealth
            case .chronicCondition:
                return .general
            case .preventiveHealth:
                return .general
            case .nutritionOptimization:
                return .general
            case .stressManagement:
                return .general
            case .sleepImprovement:
                return .sleep
            case .heartHealth:
                return .cardiovascularHealth
            case .bloodSugarControl:
                return .diabetes
            case .generalWellness:
                return .general
            }
        }
    }
    
    private func saveProfile() {
        // Keep it simple and synchronous - UserDefaults access is already fast enough
        
        do {
            let data = try JSONEncoder().encode(userProfile)
            let jsonString = String(data: data, encoding: .utf8) ?? "Could not convert to string"
            
            userDefaults.set(data, forKey: OnboardingKeys.userProfile)
            
            // Verify immediately by trying to load it back
            if let savedData = userDefaults.data(forKey: OnboardingKeys.userProfile) {
                let verificationString = String(data: savedData, encoding: .utf8) ?? "Could not convert"
            } else {
            }
        } catch {
        }
    }
    
    
    private func loadSavedProfile() {
        // Keep it simple and synchronous for initialization
        
        guard let data = userDefaults.data(forKey: OnboardingKeys.userProfile) else { 
            return 
        }
        
        let jsonString = String(data: data, encoding: .utf8) ?? "Could not convert to string"
        
        do {
            let loadedProfile = try JSONDecoder().decode(OnboardingProfile.self, from: data)
            
            userProfile = loadedProfile
            
        } catch {
        }
    }
    
    private func saveOnboardingCompletion() {
        // Keep it simple and synchronous
        let completion = OnboardingCompletion()
        do {
            let data = try JSONEncoder().encode(completion)
            userDefaults.set(data, forKey: OnboardingKeys.completionStatus)
            userDefaults.set(true, forKey: OnboardingKeys.hasCompletedOnboarding)
        } catch {
        }
    }
    
    private func clearSavedData() {
        userDefaults.removeObject(forKey: OnboardingKeys.userProfile)
        userDefaults.removeObject(forKey: OnboardingKeys.completionStatus)
        userDefaults.removeObject(forKey: OnboardingKeys.hasCompletedOnboarding)
    }
}

// MARK: - Supporting Types

enum HealthKitPermissionStatus {
    case notDetermined
    case denied
    case authorized
    case restricted
}

enum BiometricAuthenticationStatus {
    case notDetermined
    case available
    case notAvailable
    case skipped
}

enum OnboardingError: @preconcurrency LocalizedError {
    case incompleteProfile
    case healthKitPermissionDenied
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .incompleteProfile:
            return "Please complete all required profile information"
        case .healthKitPermissionDenied:
            return "HealthKit permission is required for full functionality"
        case .networkError:
            return "Network error occurred. Please try again."
        }
    }
}

// MARK: - UserDefaults Keys
private struct OnboardingKeys {
    static let userProfile = "onboarding_user_profile"
    static let completionStatus = "onboarding_completion_status"
    static let hasCompletedOnboarding = "has_completed_onboarding"
}

