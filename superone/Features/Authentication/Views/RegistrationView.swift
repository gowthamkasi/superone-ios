import SwiftUI

/// Simplified registration view using consolidated AuthenticationManager
struct RegistrationView: View {
    
    // MARK: - Properties
    
    @Environment(AuthenticationManager.self) private var authManager
    @State private var currentStep: RegistrationStep = .basic
    @State private var showingDatePicker = false
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    // Local form state
    @State private var registrationForm = RegistrationFormData()
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Progress Indicator
                    progressIndicator
                        .padding(.top, 32)
                        .padding(.horizontal, 20)
                    
                    // Header Section
                    headerSection
                        .padding(.top, 48)
                    
                    // Form Section
                    formSection
                        .padding(.horizontal, 20)
                        .padding(.top, 48)
                    
                    // Actions Section
                    actionsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                    
                    // Footer
                    footerSection
                        .padding(.top, 48)
                        .padding(.bottom, 32)
                }
                .frame(minHeight: max(geometry.size.height * 0.9, 600))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back", action: previousStep)
            }
        }
        .alert("Registration Error", isPresented: .constant(false)) {
            Button("OK") { }
        } message: {
            Text("An error occurred during registration")
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
    }
    
    // MARK: - View Components
    
    private var progressIndicator: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(RegistrationStep.allCases, id: \.self) { step in
                    Rectangle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            
            HStack {
                Text("Step \(currentStep.rawValue + 1) of \(RegistrationStep.allCases.count)")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
                Spacer()
                Text(currentStep.title)
                    .font(.caption)
                    .foregroundColor(Color.primary)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(Color.blue)
            
            VStack(spacing: 4) {
                Text(currentStep.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primary)
                
                Text(currentStep.subtitle)
                    .font(.body)
                    .foregroundColor(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 24) {
            switch currentStep {
            case .basic:
                basicInfoForm
            case .credentials:
                credentialsForm
            case .terms:
                termsForm
            }
        }
    }
    
    private var basicInfoForm: some View {
        VStack(spacing: 24) {
            // Name Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Full Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary)
                
                TextField("Enter your full name", text: $registrationForm.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.name)
                    .autocorrectionDisabled()
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Email Address")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary)
                
                TextField("Enter your email", text: $registrationForm.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            // Phone Number Field (Optional)
            VStack(alignment: .leading, spacing: 4) {
                Text("Phone Number (Optional)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary)
                
                TextField("Enter your phone number", text: $registrationForm.phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
            
            // Date of Birth
            VStack(alignment: .leading, spacing: 4) {
                Text("Date of Birth")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary)
                
                Button(action: { showingDatePicker = true }) {
                    HStack {
                        if let dateOfBirth = registrationForm.dateOfBirth {
                            Text(DateFormatter.mediumDate.string(from: dateOfBirth))
                                .foregroundColor(Color.primary)
                        } else {
                            Text("Select your date of birth")
                                .foregroundColor(Color.secondary)
                        }
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundColor(Color.blue)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private var credentialsForm: some View {
        VStack(spacing: 24) {
            // Password Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary)
                
                HStack {
                    Group {
                        if isPasswordVisible {
                            TextField("Create a strong password", text: $registrationForm.password)
                        } else {
                            SecureField("Create a strong password", text: $registrationForm.password)
                        }
                    }
                    .textContentType(.newPassword)
                    .autocorrectionDisabled()
                    
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(Color.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                
                // Password strength indicator
                if !registrationForm.password.isEmpty {
                    HStack {
                        Text(passwordStrengthText(registrationForm.password))
                            .font(.caption)
                            .foregroundColor(passwordStrengthColor(registrationForm.password))
                        Spacer()
                    }
                }
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Confirm Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary)
                
                HStack {
                    Group {
                        if isConfirmPasswordVisible {
                            TextField("Confirm your password", text: $registrationForm.confirmPassword)
                        } else {
                            SecureField("Confirm your password", text: $registrationForm.confirmPassword)
                        }
                    }
                    .textContentType(.newPassword)
                    .autocorrectionDisabled()
                    
                    Button(action: { isConfirmPasswordVisible.toggle() }) {
                        Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(Color.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                
                // Password match indicator
                if !registrationForm.confirmPassword.isEmpty {
                    HStack {
                        Image(systemName: registrationForm.isConfirmPasswordValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(registrationForm.isConfirmPasswordValid ? .green : .red)
                        Text(registrationForm.isConfirmPasswordValid ? "Passwords match" : "Passwords don't match")
                            .font(.caption)
                            .foregroundColor(registrationForm.isConfirmPasswordValid ? .green : .red)
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var termsForm: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                // Terms of Service
                Button(action: {
                    registrationForm.acceptedTerms.toggle()
                }) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: registrationForm.acceptedTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(registrationForm.acceptedTerms ? Color.blue : Color.secondary)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I agree to the Terms of Service")
                                .font(.body)
                                .foregroundColor(Color.primary)
                            Text("Read and understand the terms")
                                .font(.caption)
                                .foregroundColor(Color.secondary)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Privacy Policy
                Button(action: {
                    registrationForm.acceptedPrivacy.toggle()
                }) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: registrationForm.acceptedPrivacy ? "checkmark.square.fill" : "square")
                            .foregroundColor(registrationForm.acceptedPrivacy ? Color.blue : Color.secondary)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I agree to the Privacy Policy")
                                .font(.body)
                                .foregroundColor(Color.primary)
                            Text("Understand how your data is used")
                                .font(.caption)
                                .foregroundColor(Color.secondary)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            // Primary Action Button
            Button(action: primaryAction) {
                HStack {
                    // Loading indicator removed for simplicity
                    
                    Text(currentStep == .terms ? "Create Account" : "Continue")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canProceed ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!canProceed)
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            Button("Already have an account? Sign In") {
                // Navigate back to login
            }
            .font(.body)
            .foregroundColor(Color.blue)
        }
    }
    
    private var datePickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Date of Birth",
                    selection: Binding(
                        get: { registrationForm.dateOfBirth ?? Date() },
                        set: { registrationForm.dateOfBirth = $0 }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Date of Birth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingDatePicker = false
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingDatePicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func primaryAction() {
        if currentStep == .terms {
            createAccount()
        } else {
            nextStep()
        }
    }
    
    private func nextStep() {
        guard canProceed else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .basic:
                currentStep = .credentials
            case .credentials:
                currentStep = .terms
            case .terms:
                break // Should not reach here
            }
        }
    }
    
    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .basic:
                // Navigate back to login or previous screen
                break
            case .credentials:
                currentStep = .basic
            case .terms:
                currentStep = .credentials
            }
        }
    }
    
    private func createAccount() {
        guard registrationForm.isFormValid else { return }
        
        Task {
            // Simplified registration - would need to access AuthenticationManager properly
        }
    }
    
    // MARK: - Computed Properties
    
    private var canProceed: Bool {
        switch currentStep {
        case .basic:
            return registrationForm.isNameValid && registrationForm.isEmailValid
        case .credentials:
            return registrationForm.isPasswordValid && registrationForm.isConfirmPasswordValid
        case .terms:
            return registrationForm.areTermsAccepted
        }
    }
    
    // MARK: - Helper Functions
    
    private func passwordStrengthText(_ password: String) -> String {
        let length = password.count
        if length < 6 { return "Too short" }
        if length < 8 { return "Weak" }
        if length >= 12 { return "Strong" }
        return "Medium"
    }
    
    private func passwordStrengthColor(_ password: String) -> Color {
        let length = password.count
        if length < 6 { return .red }
        if length < 8 { return .orange }
        if length >= 12 { return .green }
        return .yellow
    }
}

// MARK: - Supporting Types

enum RegistrationStep: Int, CaseIterable {
    case basic = 0
    case credentials = 1
    case terms = 2
    
    var title: String {
        switch self {
        case .basic: return "Basic Info"
        case .credentials: return "Create Password"
        case .terms: return "Terms & Privacy"
        }
    }
    
    var subtitle: String {
        switch self {
        case .basic: return "Tell us about yourself"
        case .credentials: return "Secure your account"
        case .terms: return "Review and accept"
        }
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let registrationMediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}