import SwiftUI

/// HealthKit permissions request view with clear privacy explanations
struct HealthKitPermissionsView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @State private var animateContent = false
    @State private var showDetailedPermissions = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                HealthColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: HealthSpacing.formGroupSpacing) {
                        // Header Section
                        headerSection
                        
                        // Progress Indicator
                        ProgressView(value: viewModel.progressValue)
                            .progressViewStyle(HealthProgressViewStyle())
                            .padding(.horizontal, HealthSpacing.screenPadding)
                        
                        // Permission Explanation
                        permissionExplanationSection
                        
                        // Benefits Section
                        benefitsSection
                        
                        // Privacy Section
                        privacySection
                        
                        // Bottom spacing for content separation
                        Spacer(minLength: HealthSpacing.xxl)
                    }
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: animateContent)
            }
        }
        .safeAreaInset(edge: .bottom) {
            OnboardingBottomButtonBar(
                configuration: .triple(
                    leftTitle: "Back",
                    leftHandler: {
                        viewModel.previousStep()
                    },
                    centerTitle: "Skip",
                    centerHandler: {
                        viewModel.nextStep()
                    },
                    rightTitle: "Allow Health Access",
                    rightIsLoading: viewModel.isLoading,
                    rightHandler: {
                        Task.detached(priority: .userInitiated) {
                            await MainActor.run {
                                guard !viewModel.isLoading else { return }
                            }
                            await viewModel.requestHealthKitPermissions()
                        }
                    }
                )
            )
        }
        .onAppear {
            animateContent = true
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showDetailedPermissions) {
            DetailedPermissionsView()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: HealthSpacing.md) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(HealthColors.primary)
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("Health Data Access")
                    .healthTextStyle(.title1, color: HealthColors.primaryText, alignment: .center)
                
                Text("Securely sync your health data")
                    .healthTextStyle(.body, color: HealthColors.secondaryText, alignment: .center)
            }
        }
        .padding(.top, HealthSpacing.xxl)
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Permission Explanation Section
    
    private var permissionExplanationSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            // HealthKit Integration Card
            VStack(spacing: HealthSpacing.md) {
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(HealthColors.primary)
                    
                    VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                        Text("Apple Health Integration")
                            .healthTextStyle(.headline, color: HealthColors.primaryText)
                        
                        Text("Connect with Apple Health to automatically sync your health metrics")
                            .healthTextStyle(.body, color: HealthColors.secondaryText)
                    }
                    
                    Spacer()
                }
                
                Button("View Detailed Permissions") {
                    showDetailedPermissions = true
                }
                .buttonStyle(HealthSmallButtonStyle(.secondary))
            }
            .padding(HealthSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                    .fill(HealthColors.accent.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                            .strokeBorder(HealthColors.accent.opacity(0.3), lineWidth: 1)
                    )
            )
            .screenPadding()
            
            // Quick Permission Preview
            quickPermissionPreview
        }
    }
    
    // MARK: - Quick Permission Preview
    
    private var quickPermissionPreview: some View {
        VStack(spacing: HealthSpacing.md) {
            HStack {
                Text("We'll request access to:")
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            VStack(spacing: HealthSpacing.sm) {
                ForEach(Array(primaryPermissions.enumerated()), id: \.offset) { index, permission in
                    PermissionPreviewRow(permission: permission)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(x: animateContent ? 0 : -20)
                        .animation(.easeOut(duration: 0.4).delay(0.8 + Double(index) * 0.1), value: animateContent)
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            HStack {
                Text("Benefits of Health Data Sync")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            VStack(spacing: HealthSpacing.md) {
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Comprehensive Analysis",
                    description: "Get deeper insights by combining lab results with daily health metrics"
                )
                
                BenefitRow(
                    icon: "clock.arrow.2.circlepath",
                    title: "Automatic Updates",
                    description: "Your health data stays current without manual entry"
                )
                
                BenefitRow(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "Personalized Recommendations",
                    description: "Receive tailored advice based on your complete health picture"
                )
                
                BenefitRow(
                    icon: "bell.badge",
                    title: "Smart Notifications",
                    description: "Get alerted about important changes in your health trends"
                )
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        VStack(spacing: HealthSpacing.lg) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.primary)
                
                Text("Your Privacy is Protected")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            VStack(spacing: HealthSpacing.md) {
                PrivacyFeatureRow(
                    icon: "lock.fill",
                    title: "End-to-End Encryption",
                    description: "Your health data is encrypted on your device and in transit"
                )
                
                PrivacyFeatureRow(
                    icon: "person.badge.shield.checkmark.fill",
                    title: "You Control Your Data",
                    description: "You can revoke access or delete your data at any time"
                )
                
                PrivacyFeatureRow(
                    icon: "eye.slash.fill",
                    title: "Never Shared",
                    description: "We never sell or share your health data with third parties"
                )
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
    }
    
    
    // MARK: - Computed Properties
    
    private var primaryPermissions: [HealthKitPermissionType] {
        [
            .readHeight,
            .readWeight,
            .readHeartRate,
            .readBloodPressure,
            .readSteps
        ]
    }
}

// MARK: - Supporting Components

struct PermissionPreviewRow: View {
    let permission: HealthKitPermissionType
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Image(systemName: permission.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(HealthColors.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(permission.displayName)
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                
                Text(permission.description)
                    .healthTextStyle(.caption1, color: HealthColors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(HealthColors.healthGood)
        }
        .padding(HealthSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                .fill(HealthColors.secondaryBackground)
        )
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            ZStack {
                Circle()
                    .fill(HealthColors.accent.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.primary)
            }
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(title)
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                
                Text(description)
                    .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct PrivacyFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(HealthColors.healthGood)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(title)
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                
                Text(description)
                    .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Detailed Permissions Sheet

struct DetailedPermissionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HealthSpacing.lg) {
                    Text("Super One will request access to the following health data types:")
                        .healthTextStyle(.body, color: HealthColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HealthSpacing.screenPadding)
                    
                    VStack(spacing: HealthSpacing.sm) {
                        ForEach(HealthKitPermissionType.allCases, id: \.rawValue) { permission in
                            DetailedPermissionRow(permission: permission)
                        }
                    }
                    .padding(.horizontal, HealthSpacing.screenPadding)
                    
                    VStack(spacing: HealthSpacing.md) {
                        Text("Important Notes")
                            .healthTextStyle(.headline, color: HealthColors.primaryText)
                        
                        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                            Text("• You can choose which data to share when prompted")
                            Text("• You can revoke access at any time in Settings")
                            Text("• Data is encrypted and never shared with third parties")
                            Text("• All permissions are optional for basic app functionality")
                        }
                        .healthTextStyle(.body, color: HealthColors.secondaryText)
                    }
                    .padding(HealthSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                            .fill(HealthColors.accent.opacity(0.08))
                    )
                    .padding(.horizontal, HealthSpacing.screenPadding)
                }
                .padding(.vertical, HealthSpacing.lg)
            }
            .navigationTitle("Health Data Access")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailedPermissionRow: View {
    let permission: HealthKitPermissionType
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Image(systemName: permission.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(HealthColors.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(permission.displayName)
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                
                Text(permission.description)
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(HealthSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                .fill(HealthColors.secondaryBackground)
        )
    }
}

// MARK: - Preview

#Preview("HealthKit Permissions View") {
    HealthKitPermissionsView()
        .environment(OnboardingViewModel())
}

#Preview("Detailed Permissions View") {
    DetailedPermissionsView()
}
