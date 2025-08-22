//
//  AccountSetupView.swift
//  SuperOne
//
//  Created by Claude Code on 1/30/25.
//  Account setup step during onboarding for email and password collection
//

import SwiftUI

/// Account setup view for collecting email and password during onboarding
struct AccountSetupView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(AppFlowManager.self) private var flowManager
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var showValidationErrors = false
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        return ValidationHelper.isValidEmail(viewModel.userProfile.email) &&
               isPasswordValid(viewModel.userProfile.password) &&
               viewModel.userProfile.password == viewModel.userProfile.confirmPassword &&
               !viewModel.userProfile.password.isEmpty &&
               !viewModel.userProfile.confirmPassword.isEmpty
    }
    
    private func isPasswordValid(_ password: String) -> Bool {
        let hasLetters = password.rangeOfCharacter(from: .letters) != nil
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        return password.count >= 8 && hasLetters && hasNumbers
    }
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: HealthSpacing.onboardingSpacing) {
                    
                    // Header Section
                    VStack(spacing: HealthSpacing.md) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(HealthColors.accent)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(HealthColors.primary)
                        }
                        
                        // Title and subtitle
                        VStack(spacing: HealthSpacing.sm) {
                            Text("Create Your Account")
                                .healthTextStyle(.title2, color: HealthColors.primaryText, alignment: .center)
                            
                            Text("Create your secure account to save your health data and access personalized insights")
                                .healthTextStyle(.body, color: HealthColors.secondaryText, alignment: .center)
                        }
                    }
                    
                    // Form Section
                    VStack(spacing: HealthSpacing.lg) {
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                            Text("Email Address")
                                .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                            
                            TextField("Enter your email", text: Binding(
                                get: { viewModel.userProfile.email },
                                set: { viewModel.userProfile.email = $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
                            ))
                            .textFieldStyle(HealthTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .overlay(
                                // Validation icon
                                HStack {
                                    Spacer()
                                    if !viewModel.userProfile.email.isEmpty {
                                        Image(systemName: ValidationHelper.isValidEmail(viewModel.userProfile.email) ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                            .foregroundColor(ValidationHelper.isValidEmail(viewModel.userProfile.email) ? HealthColors.healthExcellent : HealthColors.healthCritical)
                                            .font(.system(size: 16))
                                            .padding(.trailing, HealthSpacing.md)
                                    }
                                }
                            )
                            
                            if showValidationErrors && !viewModel.userProfile.email.isEmpty && !ValidationHelper.isValidEmail(viewModel.userProfile.email) {
                                Text("Please enter a valid email address")
                                    .healthTextStyle(.caption1, color: HealthColors.healthCritical)
                            }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                            Text("Password")
                                .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                            
                            HStack {
                                if isPasswordVisible {
                                    TextField("Create a password", text: $bindableViewModel.userProfile.password)
                                        .textFieldStyle(HealthTextFieldStyle())
                                } else {
                                    SecureField("Create a password", text: $bindableViewModel.userProfile.password)
                                        .textFieldStyle(HealthTextFieldStyle())
                                }
                                
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(HealthColors.tertiaryText)
                                        .font(.system(size: 16))
                                }
                                .padding(.trailing, HealthSpacing.sm)
                            }
                            
                            // Password requirements
                            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                                passwordRequirement("At least 8 characters", isValid: viewModel.userProfile.password.count >= 8)
                                passwordRequirement("Contains letters and numbers", isValid: isPasswordValid(viewModel.userProfile.password) && !viewModel.userProfile.password.isEmpty)
                            }
                            .padding(.top, HealthSpacing.xs)
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                            Text("Confirm Password")
                                .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                            
                            HStack {
                                if isConfirmPasswordVisible {
                                    TextField("Confirm your password", text: $bindableViewModel.userProfile.confirmPassword)
                                        .textFieldStyle(HealthTextFieldStyle())
                                } else {
                                    SecureField("Confirm your password", text: $bindableViewModel.userProfile.confirmPassword)
                                        .textFieldStyle(HealthTextFieldStyle())
                                }
                                
                                Button(action: {
                                    isConfirmPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(HealthColors.tertiaryText)
                                        .font(.system(size: 16))
                                }
                                .padding(.trailing, HealthSpacing.sm)
                            }
                            
                            if showValidationErrors && !viewModel.userProfile.confirmPassword.isEmpty && viewModel.userProfile.password != viewModel.userProfile.confirmPassword {
                                Text("Passwords do not match")
                                    .healthTextStyle(.caption1, color: HealthColors.healthCritical)
                            }
                        }
                        
                        // Already have account option
                        VStack(spacing: HealthSpacing.sm) {
                            HStack {
                                VStack { Divider() }
                                Text("OR")
                                    .healthTextStyle(.caption1, color: HealthColors.tertiaryText)
                                    .padding(.horizontal, HealthSpacing.sm)
                                VStack { Divider() }
                            }
                            
                            Button(action: {
                                flowManager.startAuthentication()
                            }) {
                                HStack {
                                    Image(systemName: "person.circle")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text("I already have an account")
                                        .font(.system(.body, design: .rounded, weight: .medium))
                                }
                                .foregroundColor(HealthColors.primary)
                            }
                        }
                        .padding(.top, HealthSpacing.md)
                    }
                    
                    // Privacy Notice
                    VStack(spacing: HealthSpacing.sm) {
                        Text("By creating an account, you agree to our")
                            .healthTextStyle(.caption1, color: HealthColors.tertiaryText, alignment: .center)
                        
                        HStack(spacing: HealthSpacing.xs) {
                            Button("Terms of Service") {
                                // Handle terms tap
                            }
                            .healthTextStyle(.caption1, color: HealthColors.primary)
                            
                            Text("and")
                                .healthTextStyle(.caption1, color: HealthColors.tertiaryText)
                            
                            Button("Privacy Policy") {
                                // Handle privacy tap
                            }
                            .healthTextStyle(.caption1, color: HealthColors.primary)
                        }
                    }
                    .padding(.top, HealthSpacing.lg)
                    
                    // Bottom spacing
                    Spacer()
                        .frame(height: HealthSpacing.xxl)
                }
                .screenPadding()
            }
        }
        .safeAreaInset(edge: .bottom) {
            OnboardingBottomButtonBar(
                configuration: .dual(
                    leftTitle: "Back",
                    leftHandler: {
                        viewModel.previousStep()
                    },
                    rightTitle: "Create Account",
                    rightIsLoading: viewModel.isLoading,
                    rightIsDisabled: !isFormValid,
                    rightHandler: {
                        showValidationErrors = true
                        if isFormValid {
                            Task {
                                await viewModel.createAccountAndCompleteOnboarding()
                            }
                        }
                    }
                )
            )
        }
        .alert("Account Creation Failed", isPresented: $bindableViewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "Failed to create account. Please try again.")
        }
    }
    
    // MARK: - Password Requirement Helper
    
    private func passwordRequirement(_ text: String, isValid: Bool) -> some View {
        HStack(spacing: HealthSpacing.xs) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isValid ? HealthColors.healthExcellent : HealthColors.tertiaryText)
            
            Text(text)
                .healthTextStyle(.caption1, color: isValid ? HealthColors.healthExcellent : HealthColors.tertiaryText)
            
            Spacer()
        }
    }
    
}

// MARK: - Health Text Field Style

private struct HealthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(HealthSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .fill(HealthColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                            .stroke(HealthColors.primary.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Preview

#Preview("Account Setup") {
    AccountSetupView()
        .environment(OnboardingViewModel())
        .environment(AppFlowManager.shared)
}