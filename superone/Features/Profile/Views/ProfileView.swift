//
//  ProfileView.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Main profile screen with user information and settings
struct ProfileView: View {
    
    @State private var viewModel = ProfileViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: HealthSpacing.xl) {
                    // Profile header
                    profileHeaderSection
                    
                    // Health data section
                    healthDataSection
                    
                    // Settings sections
                    settingsSection
                    
                    // Appearance section
                    appearanceSection
                    
                    // Data & Privacy section
                    dataPrivacySection
                    
                    // Support section
                    supportSection
                    
                    #if DEBUG
                    // Developer Test APIs section (development only)
                    testApisSection
                    #endif
                    
                    // Account section
                    accountSection
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .padding(.bottom, HealthSpacing.xl)
            }
            .background(HealthColors.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Only load profile when view appears, not during ViewModel init
                viewModel.loadUserProfile()
            }
            .refreshable {
                viewModel.retryLoadUserProfile() // Use retry method for pull-to-refresh
            }
            .sheet(isPresented: $viewModel.showEditProfile) {
                EditProfileSheet(
                    profile: viewModel.userProfile,
                    onSave: { profile in
                        viewModel.updateProfile(profile)
                    }
                )
            }
            .sheet(isPresented: $viewModel.showDataExport) {
                DataExportSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showAbout) {
                AboutSheet()
            }
            .sheet(isPresented: $viewModel.showSupport) {
                SupportSheet()
            }
            .alert("Sign Out", isPresented: $viewModel.showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await viewModel.signOut(using: authManager)
                    }
                }
                .disabled(viewModel.isSigningOut)
            } message: {
                if viewModel.isSigningOut {
                    Text("Signing out...")
                } else {
                    Text("Are you sure you want to sign out?")
                }
            }
            .alert("Delete Account", isPresented: $viewModel.showDeleteAccount) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteAccount()
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
                Button("Retry") {
                    viewModel.retryLoadUserProfile()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .alert("Sign Out Error", isPresented: $viewModel.showSignOutError) {
                Button("OK") {
                    viewModel.showSignOutError = false
                }
            } message: {
                Text(viewModel.signOutErrorMessage ?? "An error occurred while signing out.")
            }
            // Loading overlay for sign out process
            .loadingOverlay(
                isLoading: viewModel.isSigningOut,
                message: "Signing out..."
            )
            // Biometric lifecycle methods removed for now
        }
    }
    
    // MARK: - Profile Header Section
    
    private var profileHeaderSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Profile avatar and basic info
            HStack(spacing: HealthSpacing.lg) {
                // Profile image
                AsyncImage(url: URL(string: viewModel.userProfile?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(HealthColors.primary)
                        .font(.system(size: HealthSpacing.avatarSizeLarge))
                }
                .frame(width: HealthSpacing.avatarSizeLarge, height: HealthSpacing.avatarSizeLarge)
                .clipShape(Circle())
                
                // User info
                VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                    if let profile = viewModel.userProfile {
                        Text(profile.name)
                            .font(HealthTypography.headingMedium)
                            .foregroundColor(HealthColors.primaryText)
                        
                        Text(profile.email)
                            .font(HealthTypography.body)
                            .foregroundColor(HealthColors.secondaryText)
                        
                        if let dateOfBirth = profile.dateOfBirth {
                            let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
                            Text("\(age) years old")
                                .font(HealthTypography.captionMedium)
                                .foregroundColor(HealthColors.secondaryText)
                        }
                    } else if viewModel.isLoadingProfile {
                        VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                            SkeletonView()
                                .frame(width: 120, height: 20)
                            SkeletonView()
                                .frame(width: 180, height: 16)
                            SkeletonView()
                                .frame(width: 80, height: 14)
                        }
                    } else {
                        Text("Unable to load profile")
                            .font(HealthTypography.body)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            
            // Edit profile button
            Button(action: { viewModel.showEditProfile = true }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primary)
                .padding(.horizontal, HealthSpacing.lg)
                .padding(.vertical, HealthSpacing.md)
                .background(HealthColors.primary.opacity(0.1))
                .cornerRadius(HealthCornerRadius.button)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
    
    // MARK: - Health Data Section
    
    private var healthDataSection: some View {
        ProfileSection(title: "Health Data", icon: "heart.fill") {
            VStack(spacing: HealthSpacing.md) {
                ProfileRow(
                    icon: "figure.mixed.cardio",
                    title: "HealthKit Sync",
                    subtitle: "Sync data with Apple Health",
                    trailing: {
                        Toggle("", isOn: Binding(
                            get: { viewModel.healthKitSyncEnabled },
                            set: { viewModel.toggleHealthKitSync($0) }
                        ))
                        .tint(HealthColors.primary)
                    }
                )
                
                Divider()
                
                ProfileRow(
                    icon: "chart.bar.fill",
                    title: "Health Reports",
                    subtitle: "\(viewModel.storageUsage.reportsCount) reports stored",
                    action: {
                        // Navigation to reports will be implemented
                    }
                )
                
                Divider()
                
                ProfileRow(
                    icon: "photo.fill",
                    title: "Images",
                    subtitle: "\(viewModel.storageUsage.imagesCount) images stored",
                    action: {
                        // Navigation to images will be implemented
                    }
                )
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        ProfileSection(title: "Settings", icon: "gear") {
            VStack(spacing: HealthSpacing.md) {
                ProfileRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Health reminders and updates",
                    trailing: {
                        Toggle("", isOn: Binding(
                            get: { viewModel.notificationsEnabled },
                            set: { viewModel.toggleNotifications($0) }
                        ))
                        .tint(HealthColors.primary)
                    }
                )
                
                Divider()
                
                // Biometric Authentication settings removed for now - will be added back later
            }
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        ProfileSection(title: "Appearance", icon: "paintbrush.fill") {
            VStack(spacing: HealthSpacing.md) {
                ProfileRow(
                    icon: themeManager.currentTheme.icon,
                    title: "Theme",
                    subtitle: themeManager.currentTheme.description,
                    trailing: {
                        Menu {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Button {
                                    themeManager.setTheme(theme)
                                } label: {
                                    HStack {
                                        Image(systemName: theme.icon)
                                        Text(theme.displayName)
                                        if theme == themeManager.currentTheme {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: HealthSpacing.xs) {
                                Text(themeManager.currentTheme.displayName)
                                    .font(HealthTypography.captionMedium)
                                    .foregroundColor(HealthColors.primary)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(HealthColors.secondaryText)
                            }
                            .padding(.horizontal, HealthSpacing.sm)
                            .padding(.vertical, HealthSpacing.xs)
                            .background(HealthColors.primary.opacity(0.1))
                            .cornerRadius(HealthCornerRadius.sm)
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Data & Privacy Section
    
    private var dataPrivacySection: some View {
        ProfileSection(title: "Data & Privacy", icon: "lock.shield") {
            VStack(spacing: HealthSpacing.md) {
                ProfileRow(
                    icon: "square.and.arrow.up",
                    title: "Export Data",
                    subtitle: "Download your health data",
                    action: {
                        viewModel.showDataExport = true
                    }
                )
                
                Divider()
                
                ProfileRow(
                    icon: "internaldrive",
                    title: "Storage",
                    subtitle: "\(viewModel.storageUsage.displayTotalUsed) used",
                    action: {
                        // Storage details view will be implemented
                    }
                )
                
                Divider()
                
                ProfileRow(
                    icon: "trash",
                    title: "Clear Cache",
                    subtitle: "\(viewModel.storageUsage.displayCacheSize) cached data",
                    action: {
                        viewModel.clearCache()
                    }
                )
                
                Divider()
                
                ProfileRow(
                    icon: "chart.pie",
                    title: "Analytics",
                    subtitle: "Help improve the app",
                    trailing: {
                        Toggle("", isOn: $viewModel.analyticsEnabled)
                            .tint(HealthColors.primary)
                    }
                )
            }
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        ProfileSection(title: "Support", icon: "questionmark.circle") {
            VStack(spacing: HealthSpacing.md) {
                ProfileRow(
                    icon: "envelope",
                    title: "Contact Support",
                    subtitle: "Get help with the app",
                    action: {
                        viewModel.contactSupport()
                    }
                )
                
                Divider()
                
                ProfileRow(
                    icon: "star",
                    title: "Rate App",
                    subtitle: "Share your feedback",
                    action: {
                        viewModel.rateApp()
                    }
                )
                
                Divider()
                
                ProfileRow(
                    icon: "square.and.arrow.up",
                    title: "Share App",
                    subtitle: "Tell others about SuperOne",
                    action: {
                        viewModel.shareApp()
                    }
                )
                
                Divider()
                
                ProfileRow(
                    icon: "info.circle",
                    title: "About",
                    subtitle: "App version and info",
                    action: {
                        viewModel.showAboutScreen()
                    }
                )
            }
        }
    }
    
    #if DEBUG
    // MARK: - Test APIs Section (Development Only)
    
    private var testApisSection: some View {
        ProfileSection(title: "Test APIs", icon: "wrench.and.screwdriver") {
            VStack(spacing: HealthSpacing.md) {
                NavigationLink(destination: ManualAPITestingView()) {
                    HStack(spacing: HealthSpacing.md) {
                        Image(systemName: "terminal")
                            .foregroundColor(HealthColors.primary)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                            Text("Manual API Testing Console")
                                .font(HealthTypography.bodyMedium)
                                .foregroundColor(HealthColors.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Comprehensive testing for all Super One endpoints")
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(HealthColors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(HealthColors.secondaryText)
                            .font(.system(size: 14))
                    }
                    .padding(.vertical, HealthSpacing.xs)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    #endif
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        ProfileSection(title: "Account", icon: "person") {
            VStack(spacing: HealthSpacing.md) {
                ProfileRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    subtitle: viewModel.isSigningOut ? "Signing out..." : "Sign out of your account",
                    titleColor: viewModel.isSigningOut ? HealthColors.secondaryText : HealthColors.healthWarning,
                    action: viewModel.isSigningOut ? nil : {
                        viewModel.showLogoutAlert = true
                    },
                    trailing: {
                        if viewModel.isSigningOut {
                            HStack(spacing: HealthSpacing.xs) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(HealthColors.primary)
                            }
                        } else {
                            EmptyView()
                        }
                    }
                )
                
                Divider()
                
                ProfileRow(
                    icon: "trash.circle",
                    title: "Delete Account",
                    subtitle: "Permanently delete your account",
                    titleColor: HealthColors.healthCritical,
                    action: {
                        viewModel.showDeleteAccount = true
                    }
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct ProfileSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 20)
                
                Text(title)
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                content
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
        }
        .healthCardShadow()
    }
}

struct ProfileRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let titleColor: Color
    let action: (() -> Void)?
    @ViewBuilder let trailing: Trailing
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        titleColor: Color = HealthColors.primaryText,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.action = action
        self.trailing = trailing()
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: HealthSpacing.md) {
                Image(systemName: icon)
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(titleColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                if trailing is EmptyView {
                    if action != nil {
                        Image(systemName: "chevron.right")
                            .foregroundColor(HealthColors.secondaryText)
                            .font(.system(size: 14))
                    }
                } else {
                    trailing
                }
            }
            .padding(.vertical, HealthSpacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil && trailing is EmptyView)
    }
}

struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(HealthColors.secondaryText.opacity(0.3))
            .cornerRadius(4)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                HealthColors.background.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                    .offset(x: isAnimating ? 200 : -200)
                    .animation(
                        Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .onAppear {
                isAnimating = true
            }
            .clipped()
    }
}

// MARK: - Preview

#Preview("Profile View") {
    ProfileView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}

#Preview("Profile View - Loading") {
    ProfileView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}