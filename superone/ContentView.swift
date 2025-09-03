import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(OnboardingViewModel.self) var onboardingViewModel
    @Environment(AppFlowManager.self) private var flowManager
    
    var body: some View {
        Group {
            if flowManager.isLoading {
                // Show loading state while detecting initial flow
                LoadingView()
                    .onAppear {
                    }
            } else {
                switch flowManager.currentFlow {
                case .initialWelcome:
                    InitialWelcomeView()
                        .onAppear {
                        }
                
                case .onboarding:
                    OnboardingView()
                        .onAppear {
                        }
                
                case .authentication:
                    LoginView()
                        .onAppear {
                        }
                
                case .authenticated:
                    MainTabView()
                        .onAppear {
                        }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: flowManager.currentFlow)
        .onAppear {
            // Immediate check for state mismatch on appear
            if authManager.isAuthenticated && flowManager.currentFlow != .authenticated {
                flowManager.completeAuthentication(email: authManager.currentUser?.email ?? "")
            }
        }
        .onChange(of: appState.isOnboardingComplete) { oldValue, newValue in
        }
        .onChange(of: flowManager.currentFlow) { oldValue, newValue in
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            if newValue {
                // User authenticated, update flow manager
                flowManager.completeAuthentication(email: authManager.currentUser?.email ?? "")
            } else if oldValue == true && newValue == false {
                // User logged out, flow manager should already be updated by signOut()
            }
        }
    }
}




