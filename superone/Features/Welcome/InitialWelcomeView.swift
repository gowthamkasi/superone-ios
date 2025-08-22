//
//  InitialWelcomeView.swift
//  SuperOne
//
//  Created by Claude Code on 1/30/25.
//  Initial welcome screen for path selection between new and existing users
//

import SwiftUI

/// Initial welcome screen that helps users choose their path
struct InitialWelcomeView: View {
    @Environment(AppFlowManager.self) private var flowManager
    @State private var animateContent = false
    @State private var showReinstallHint = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        HealthColors.accent.opacity(0.1),
                        HealthColors.background,
                        HealthColors.sage.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: HealthSpacing.xl) {
                        
                        // Top spacing for design
                        Spacer()
                            .frame(height: geometry.size.height * 0.1)
                        
                        // Logo and Brand Section
                        VStack(spacing: HealthSpacing.lg) {
                            // App Icon with animation
                            ZStack {
                                Circle()
                                    .fill(HealthColors.primary)
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 60, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(animateContent ? 1.0 : 0.8)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                            
                            VStack(spacing: HealthSpacing.sm) {
                                Text("Super One Health")
                                    .healthTextStyle(.largeTitle, color: HealthColors.primary)
                                    .multilineTextAlignment(.center)
                                
                                Text("Your personal health analysis companion")
                                    .healthTextStyle(.title3, color: HealthColors.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                        }
                        
                        // Key Benefits Section
                        VStack(spacing: HealthSpacing.md) {
                            benefitRow(
                                icon: "doc.text.magnifyingglass",
                                title: "AI Lab Analysis",
                                description: "Upload reports, get instant insights"
                            )
                            
                            benefitRow(
                                icon: "heart.text.square.fill",
                                title: "Health Tracking",
                                description: "Monitor your health metrics seamlessly"
                            )
                            
                            benefitRow(
                                icon: "shield.checkered",
                                title: "Secure & Private",
                                description: "Your data is encrypted and protected"
                            )
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
                        
                        // Reinstall hint (if applicable)
                        if flowManager.isPossibleReinstall {
                            reinstallHintSection
                        }
                        
                        // Spacer to push buttons down
                        Spacer()
                            .frame(minHeight: HealthSpacing.xl)
                    }
                    .padding(.horizontal, HealthSpacing.screenPadding)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            actionButtonsSection
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
            
            // Show reinstall hint after a delay if applicable
            if flowManager.isPossibleReinstall {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showReinstallHint = true
                    }
                }
            }
        }
    }
    
    // MARK: - Benefit Row
    
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: HealthSpacing.md) {
            ZStack {
                Circle()
                    .fill(HealthColors.accent)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(HealthColors.primary)
            }
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(title)
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                
                Text(description)
                    .healthTextStyle(.caption1, color: HealthColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, HealthSpacing.sm)
    }
    
    // MARK: - Reinstall Hint Section
    
    private var reinstallHintSection: some View {
        VStack(spacing: HealthSpacing.sm) {
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(HealthColors.emerald)
                
                Text("Welcome back!")
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                
                Spacer()
            }
            
            Text("It looks like you might have used Super One before. If you have an account, choose 'I Have an Account' to sign in.")
                .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(HealthSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                .fill(HealthColors.accent.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                        .stroke(HealthColors.emerald.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(showReinstallHint ? 1.0 : 0.0)
        .scaleEffect(showReinstallHint ? 1.0 : 0.95)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: HealthSpacing.md) {
            // Get Started Button (New User)
            Button(action: {
                HapticFeedback.light()
                flowManager.startOnboarding()
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Get Started")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.md)
                .background(HealthColors.primary)
                .foregroundColor(.white)
                .cornerRadius(HealthCornerRadius.button)
            }
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.6).delay(0.8), value: animateContent)
            
            // I Have Account Button (Existing User)
            Button(action: {
                HapticFeedback.light()
                flowManager.startAuthentication()
            }) {
                HStack {
                    Image(systemName: "person.circle")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("I Have an Account")
                        .font(.system(.body, design: .rounded, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.md)
                .background(HealthColors.accent)
                .foregroundColor(HealthColors.primary)
                .cornerRadius(HealthCornerRadius.button)
                .overlay(
                    RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                        .stroke(HealthColors.primary.opacity(0.3), lineWidth: 1)
                )
            }
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.6).delay(1.0), value: animateContent)
            
            // Smart email hint (if available)
            if let lastEmail = flowManager.lastKnownEmail {
                Text("Last used: \(lastEmail)")
                    .healthTextStyle(.caption2, color: HealthColors.tertiaryText)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(1.2), value: animateContent)
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
        .padding(.bottom, HealthSpacing.md)
        .background(
            Rectangle()
                .fill(HealthColors.background)
                .ignoresSafeArea()
        )
    }
}


// MARK: - Preview

#Preview("Initial Welcome") {
    InitialWelcomeView()
        .environment(AppFlowManager.shared)
}

#Preview("With Reinstall Hint") {
    InitialWelcomeView()
        .environment({
            let manager = AppFlowManager.shared
            // Simulate reinstall scenario
            UserDefaults.standard.set(true, forKey: "has_ever_had_account")
            UserDefaults.standard.set("user@example.com", forKey: "last_known_user_email")
            return manager
        }())
}