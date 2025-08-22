import SwiftUI
import HealthKit
import Combine

@main
struct SuperOneApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var healthStore = HealthDataStore()
    @State private var authManager = AuthenticationManager()
    @State private var scenePhaseManager: ScenePhaseManager
    @State private var onboardingViewModel = OnboardingViewModel()
    @State private var flowManager = AppFlowManager.shared
    
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        // Initialize scene phase manager with the same auth manager instance
        let authManager = AuthenticationManager()
        _authManager = State(initialValue: authManager)
        _scenePhaseManager = State(initialValue: ScenePhaseManager(authManager: authManager))
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(healthStore)
                    .environment(scenePhaseManager)
                    .environment(authManager)
                    .environment(onboardingViewModel)
                    .environment(flowManager)
                    .onAppear {
                        // Simple app initialization with native iOS 18 behavior
                        appState.loadUserPreferences()
                        
                        // CRITICAL: Check authentication status first to enable automatic token refresh
                        authManager.checkInitialAuthenticationStatus()
                        
                        // Then detect initial app flow state
                        Task {
                            await flowManager.detectInitialFlow()
                        }
                    }
                
                // Security overlay views
                BlurOverlayView(isVisible: scenePhaseManager.showBlurOverlay)
                
                BiometricReauthView(
                    isVisible: scenePhaseManager.requiresBiometricAuth,
                    onSuccess: {
                        scenePhaseManager.handleBiometricAuthSuccess()
                    },
                    onFailure: {
                        scenePhaseManager.handleBiometricAuthFailure()
                    },
                    onCancel: {
                        Task { 
                            do {
                                try await authManager.signOut()
                            } catch {
                                // Log error but still clear biometric auth state
                                print("Error during sign out: \(error.localizedDescription)")
                            }
                        }
                        scenePhaseManager.requiresBiometricAuth = false
                        scenePhaseManager.showBlurOverlay = false
                    }
                )
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
        }
    }
    
    // MARK: - Scene Phase Management
    
    @MainActor
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background, .inactive:
            // App going to background - activate security measures
            scenePhaseManager.handleAppGoingToBackground()
            
        case .active:
            // App becoming active - check if re-authentication needed
            scenePhaseManager.handleAppBecomingActive()
            
        @unknown default:
            break
        }
    }
}

// MARK: - App State Management
@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var healthScore: Int = 78
    @Published var isProcessingReport: Bool = false
    @AppStorage(AppConfiguration.UserDefaultsKeys.onboardingComplete) var isOnboardingComplete: Bool = false
    
    func initialize() async {
        // Only do immediate synchronous operations for app launch
        loadUserPreferences()
        checkOnboardingStatus()
    }
    
    func loadUserPreferences() {
        // Preferences are now handled by @AppStorage automatically
    }
    
    func checkOnboardingStatus() {
        // Check if user has completed onboarding flow
        if !isOnboardingComplete {
            selectedTab = -1 // Show onboarding instead of main tabs
        }
    }
    
}

// MARK: - Health Data Store
@MainActor
class HealthDataStore: ObservableObject {
    @Published var healthMetrics: [HealthMetric] = []
    @Published var isAuthorized: Bool = false
    
    private let healthKitService = HealthKitService()
    
    func requestAuthorization() async {
        // Only request authorization when user actually needs health features
        // This prevents blocking the app startup with permission dialogs
        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            return
        }
        
        do {
            let authorized = try await healthKitService.requestAuthorization()
            isAuthorized = authorized
            
            if authorized {
                await loadHealthData()
            }
        } catch {
            // Essential error logging for HealthKit authorization failures
            isAuthorized = false
        }
    }
    
    func loadHealthData() async {
        guard isAuthorized else { return }
        
        // For now, create sample data since we removed the conflicting models
        // This can be replaced with real HealthKit integration later
        healthMetrics = []
    }
}

// Note: AuthenticationManager is now consolidated in core/Authentication/AuthenticationManager.swift




