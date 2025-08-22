import SwiftUI

/// Main tab view with custom navigation and health-focused design
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigationViewModel: NavigationViewModel
    
    // Create navigation view model with proper AppState injection
    init() {
        // Initialize with a placeholder that will be properly configured in onAppear
        self._navigationViewModel = State(initialValue: NavigationViewModel(appState: AppState()))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area - full screen background
            TabContentView(
                selectedTab: navigationViewModel.selectedTab,
                navigationViewModel: navigationViewModel
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all, edges: .bottom)
            
            // Custom tab bar - overlays content at bottom
            CustomTabBar(viewModel: navigationViewModel)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        // iOS 18+ keyboard handling is handled automatically
        .sheet(isPresented: $navigationViewModel.isPresentingUpload) {
            LabReportUploadView()
                .onDisappear {
                    navigationViewModel.dismissUploadFlow()
                }
        }
        .onAppear {
            // Efficiently update navigation view model with the actual app state from environment
            if navigationViewModel.appState !== appState {
                navigationViewModel.appState = appState
                navigationViewModel.selectedTab = appState.selectedTab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // PERFORMANCE FIX: Comprehensive input session cleanup when app goes background
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .environment(navigationViewModel)
    }
}

// MARK: - Tab Content View  
struct TabContentView: View {
    let selectedTab: Int
    @Bindable var navigationViewModel: NavigationViewModel
    
    // Cache views to prevent recreation
    @State private var cachedViews: [Int: AnyView] = [:]
    
    var body: some View {
        ZStack {
            // Pre-load and cache tab views for instant switching
            ForEach([0, 1, 3, 4], id: \.self) { tabIndex in
                getCachedView(for: tabIndex)
                    .opacity(selectedTab == tabIndex ? 1 : 0)
                    .allowsHitTesting(selectedTab == tabIndex)
                    .safeAreaInset(edge: .bottom) {
                        // Reserve space for overlaying tab bar
                        Color.clear
                            .frame(height: HealthSpacing.tabBarHeight + HealthSpacing.sm)
                    }
            }
        }
        .onAppear {
            setupNavigationAppearance()
            preloadViews()
        }
    }
    
    private func getCachedView(for tabIndex: Int) -> AnyView {
        if let cached = cachedViews[tabIndex] {
            return cached
        }
        
        let view = createView(for: tabIndex)
        cachedViews[tabIndex] = view
        return view
    }
    
    private func createView(for tabIndex: Int) -> AnyView {
        switch tabIndex {
        case 0:
            return AnyView(DashboardView())
        case 1:
            return AnyView(AppointmentsView())
        case 3:
            return AnyView(ReportsView())
        case 4:
            return AnyView(ProfileView())
        default:
            return AnyView(DashboardView())
        }
    }
    
    private func preloadViews() {
        // Pre-cache dashboard view for instant access
        _ = getCachedView(for: 0)
    }
    
    private func setupNavigationAppearance() {
        // Modern SwiftUI navigation styling is handled via view modifiers
        // This function is kept for compatibility but can be removed
    }
}

// MARK: - Optimized Tab Views (No NavigationView nesting)
struct OptimizedDashboardView: View {
    var body: some View {
        DashboardView()
            .toolbarBackground(HealthColors.background, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
    }
}

struct OptimizedAppointmentsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: HealthSpacing.sectionSpacing) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Appointments")
                            .font(HealthTypography.title1)
                            .foregroundColor(HealthColors.primaryText)
                        
                        Text("Manage your health appointments")
                            .font(HealthTypography.subheadline)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                
                // Coming soon placeholder
                VStack(spacing: HealthSpacing.lg) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(HealthColors.primary)
                    
                    Text("Appointments Coming Soon")
                        .font(HealthTypography.headline)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text("Schedule and manage your lab appointments and health consultations.")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HealthSpacing.xl)
                }
                .padding(.top, HealthSpacing.xxxl)
                
                Spacer()
            }
        }
        .background(HealthColors.background.ignoresSafeArea())
        .toolbarBackground(HealthColors.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationTitle("Appointments")
    }
}

struct OptimizedReportsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: HealthSpacing.sectionSpacing) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Lab Reports")
                            .font(HealthTypography.title1)
                            .foregroundColor(HealthColors.primaryText)
                        
                        Text("View and manage your health reports")
                            .font(HealthTypography.subheadline)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                
                // Coming soon placeholder
                VStack(spacing: HealthSpacing.lg) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(HealthColors.primary)
                    
                    Text("Reports Coming Soon")
                        .font(HealthTypography.headline)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text("Access your lab reports, analysis results, and health insights all in one place.")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HealthSpacing.xl)
                }
                .padding(.top, HealthSpacing.xxxl)
                
                Spacer()
            }
        }
        .background(HealthColors.background.ignoresSafeArea())
        .toolbarBackground(HealthColors.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationTitle("Lab Reports")
    }
}

struct OptimizedProfileView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: HealthSpacing.sectionSpacing) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Profile")
                            .font(HealthTypography.title1)
                            .foregroundColor(HealthColors.primaryText)
                        
                        Text("Manage your account and preferences")
                            .font(HealthTypography.subheadline)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                
                // Coming soon placeholder
                VStack(spacing: HealthSpacing.lg) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 60))
                        .foregroundColor(HealthColors.primary)
                    
                    Text("Profile Settings Coming Soon")
                        .font(HealthTypography.headline)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text("Customize your health profile, manage preferences, and control your data.")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HealthSpacing.xl)
                }
                .padding(.top, HealthSpacing.xxxl)
                
                Spacer()
            }
        }
        .background(HealthColors.background.ignoresSafeArea())
        .toolbarBackground(HealthColors.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationTitle("Profile")
    }
}

// MARK: - Lab Report Upload Integration
// The LabReportUploadView is now integrated as the main upload interface
// replacing the previous placeholder UploadFlowView

// MARK: - Preview
#Preview("Main Tab View") {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(HealthDataStore())
}

#Preview("Different Tab Selected") {
    MainTabView()
        .environmentObject({
            let state = AppState()
            state.selectedTab = 3
            return state
        }())
        .environmentObject(HealthDataStore())
}