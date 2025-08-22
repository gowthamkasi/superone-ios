import SwiftUI

/// Modern profile setup view with iOS 18 native input fields following latest best practices
@MainActor
struct ProfileSetupView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    // Using ultra-minimal TextField approach for maximum performance
    
    // Local form state - no validation during typing to prevent performance issues
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedDate = Date()
    @State private var selectedHeight: Double = 170
    @State private var selectedWeight: Double = 70
    @State private var selectedSex: BiologicalSex = .notSet
    
    // Sheet presentation states
    @State private var showDatePicker = false
    @State private var showHeightPicker = false
    @State private var showWeightPicker = false
    
    // Animation state
    @State private var animateContent = false
    
    // Date restrictions (computed once)
    private var minimumBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -120, to: Date()) ?? Date()
    }
    
    private var maximumBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }
    
    // Validation for 18+ requirement
    private var isValidAge: Bool {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: selectedDate, to: now)
        guard let age = ageComponents.year else { return false }
        return age >= 18
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                HealthColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: HealthSpacing.formGroupSpacing) {
                        // Header
                        headerSection
                        
                        // Progress
                        progressSection
                        
                        // Form sections
                        VStack(spacing: HealthSpacing.formGroupSpacing) {
                            personalInfoSection
                            biometricsSection
                            biologicalSexSection
                        }
                        .screenPadding()
                        
                        // Bottom spacing
                        Spacer(minLength: HealthSpacing.xxl)
                    }
                }
                .opacity(animateContent ? 1.0 : 0.0)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .safeAreaInset(edge: .bottom) {
            bottomButtonBar
        }
        .onAppear {
            loadExistingProfile()
            animateContent = true
        }
        .onDisappear {
            // Ensure clean state when navigating away
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .sheet(isPresented: $showHeightPicker) {
            heightPickerSheet
        }
        .sheet(isPresented: $showWeightPicker) {
            weightPickerSheet
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: HealthSpacing.md) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(HealthColors.primary)
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: animateContent)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("Set Up Your Profile")
                    .healthTextStyle(.title1, color: HealthColors.primaryText, alignment: .center)
                
                Text("Help us personalize your health experience")
                    .healthTextStyle(.body, color: HealthColors.secondaryText, alignment: .center)
            }
            .opacity(animateContent ? 1.0 : 0.0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
        }
        .padding(.top, HealthSpacing.xxl)
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        ProgressView(value: viewModel.progressValue)
            .progressViewStyle(HealthProgressViewStyle())
            .padding(.horizontal, HealthSpacing.screenPadding)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.6).delay(0.5), value: animateContent)
    }
    
    // MARK: - Personal Info Section
    
    private var personalInfoSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            SectionHeader(title: "Personal Information", icon: "person.text.rectangle")
            
            VStack(spacing: HealthSpacing.formSpacing) {
                // First Name - Ultra minimal TextField with zero overhead
                MinimalTextField(
                    title: "First Name",
                    text: $firstName,
                    placeholder: "Enter your first name",
                    icon: "person",
                    isRequired: true
                )
                
                // Last Name - Ultra minimal TextField with zero overhead
                MinimalTextField(
                    title: "Last Name", 
                    text: $lastName,
                    placeholder: "Enter your last name",
                    icon: "person.badge.plus",
                    isRequired: true
                )
                
                // Date of Birth
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Button(action: { showDatePicker = true }) {
                        NativeFieldRow(
                            title: "Date of Birth",
                            value: formatBirthDate(),
                            placeholder: "Select your date of birth",
                            icon: "calendar",
                            isRequired: true,
                            hasValue: viewModel.userProfile.dateOfBirth != nil
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Age validation error
                    if let dateOfBirth = viewModel.userProfile.dateOfBirth, !isValidAge {
                        HStack(spacing: HealthSpacing.xs) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(HealthColors.healthCritical)
                            
                            Text("You must be at least 18 years old to use this app")
                                .healthTextStyle(.caption1, color: HealthColors.healthCritical)
                        }
                        .padding(.leading, HealthSpacing.sm)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6).delay(0.7), value: animateContent)
    }
    
    // MARK: - Biometrics Section
    
    private var biometricsSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            SectionHeader(title: "Biometric Information", icon: "ruler")
            
            Text("Optional: This helps us provide more accurate health insights")
                .healthTextStyle(.footnote, color: HealthColors.tertiaryText)
                .multilineTextAlignment(.center)
            
            HStack(spacing: HealthSpacing.md) {
                // Height
                Button(action: { showHeightPicker = true }) {
                    NativeFieldRow(
                        title: "Height",
                        value: formatHeight(),
                        placeholder: "Select height",
                        icon: "ruler.fill",
                        isRequired: false,
                        hasValue: viewModel.userProfile.height != nil
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Weight
                Button(action: { showWeightPicker = true }) {
                    NativeFieldRow(
                        title: "Weight",
                        value: formatWeight(),
                        placeholder: "Select weight",
                        icon: "scalemass.fill",
                        isRequired: false,
                        hasValue: viewModel.userProfile.weight != nil
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6).delay(0.9), value: animateContent)
    }
    
    // MARK: - Biological Sex Section
    
    private var biologicalSexSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            SectionHeader(title: "Biological Sex", icon: "person.2")
            
            Text("Used for accurate health reference ranges and analysis")
                .healthTextStyle(.footnote, color: HealthColors.tertiaryText)
                .multilineTextAlignment(.center)
            
            VStack(spacing: HealthSpacing.sm) {
                ForEach(BiologicalSex.allCases, id: \.self) { sex in
                    SexSelectionRow(
                        sex: sex,
                        isSelected: selectedSex == sex,
                        action: {
                            
                            selectedSex = sex
                            
                            
                            updateProfile()
                            
                        }
                    )
                }
            }
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6).delay(1.1), value: animateContent)
    }
    
    // MARK: - Bottom Button Bar
    
    private var bottomButtonBar: some View {
        OnboardingBottomButtonBar(
            configuration: .dual(
                leftTitle: "Back",
                leftHandler: {
                    viewModel.previousStep()
                },
                rightTitle: "Continue",
                rightIsLoading: viewModel.isLoading,
                rightIsDisabled: !canProceed,
                rightHandler: {
                    updateProfile()
                    viewModel.nextStep()
                }
            )
        )
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6).delay(1.3), value: animateContent)
    }
    
    // MARK: - Sheet Views
    
    private var datePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date of Birth",
                    selection: $selectedDate,
                    in: minimumBirthDate...maximumBirthDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
                
                HealthPrimaryButton("Done") {
                    viewModel.updateProfile(dateOfBirth: selectedDate)
                    showDatePicker = false
                }
                .padding()
            }
            .navigationTitle("Date of Birth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showDatePicker = false
                    }
                }
            }
        }
    }
    
    private var heightPickerSheet: some View {
        NavigationStack {
            VStack {
                Picker("Height", selection: $selectedHeight) {
                    ForEach(140...220, id: \.self) { height in
                        Text("\(height) cm (\(formatHeightInFeetInches(Double(height))))")
                            .tag(Double(height))
                    }
                }
                .pickerStyle(.wheel)
                
                Spacer()
                
                HealthPrimaryButton("Done") {
                    viewModel.updateProfile(height: selectedHeight)
                    showHeightPicker = false
                }
                .padding()
            }
            .navigationTitle("Height")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showHeightPicker = false
                    }
                }
            }
        }
    }
    
    private var weightPickerSheet: some View {
        NavigationStack {
            VStack {
                Picker("Weight", selection: $selectedWeight) {
                    ForEach(30...200, id: \.self) { weight in
                        Text("\(weight) kg (\(Int(Double(weight) * 2.20462)) lbs)")
                            .tag(Double(weight))
                    }
                }
                .pickerStyle(.wheel)
                
                Spacer()
                
                HealthPrimaryButton("Done") {
                    viewModel.updateProfile(weight: selectedWeight)
                    showWeightPicker = false
                }
                .padding()
            }
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showWeightPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadExistingProfile() {
        let profile = viewModel.userProfile
        firstName = profile.firstName
        lastName = profile.lastName
        selectedSex = profile.biologicalSex
        
        if let dateOfBirth = profile.dateOfBirth {
            selectedDate = dateOfBirth
        }
        
        if let height = profile.height {
            selectedHeight = height
        }
        
        if let weight = profile.weight {
            selectedWeight = weight
        }
    }
    
    private func updateProfile() {
        // PERFORMANCE: Only update profile when user interaction completes
        // No real-time validation to prevent main thread blocking
        
        viewModel.updateProfile(
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: viewModel.userProfile.dateOfBirth,
            biologicalSex: selectedSex,
            height: viewModel.userProfile.height,
            weight: viewModel.userProfile.weight
        )
        
    }
    
    private var canProceed: Bool {
        !firstName.isEmpty && 
        !lastName.isEmpty && 
        viewModel.userProfile.dateOfBirth != nil && 
        selectedSex != .notSet
    }
    
    private func formatBirthDate() -> String {
        guard let date = viewModel.userProfile.dateOfBirth else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formatHeight() -> String {
        guard let height = viewModel.userProfile.height else { return "" }
        return "\(Int(height)) cm (\(formatHeightInFeetInches(height)))"
    }
    
    private func formatWeight() -> String {
        guard let weight = viewModel.userProfile.weight else { return "" }
        return "\(Int(weight)) kg (\(Int(weight * 2.20462)) lbs)"
    }
    
    private func formatHeightInFeetInches(_ cm: Double) -> String {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return "\(feet)'\(inches)\""
    }
}

// MARK: - Ultra Minimal Components (Zero Overhead)

/// Ultra minimal TextField - absolute bare minimum implementation
struct MinimalTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    let isRequired: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Simple title
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                if isRequired {
                    Text("*").foregroundColor(.red)
                }
            }
            
            // Bare minimum TextField - no styling, no monitoring, no validation
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

/// Native field row for button-triggered selections
struct NativeFieldRow: View {
    let title: String
    let value: String
    let placeholder: String
    let icon: String
    let isRequired: Bool
    let hasValue: Bool
    
    var body: some View {
        VStack(spacing: HealthSpacing.sm) {
            // Title
            HStack {
                Text(title)
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(HealthColors.healthCritical)
                }
                
                Spacer()
            }
            
            // Field row
            HStack(spacing: HealthSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.secondaryText)
                    .frame(width: 20)
                
                Text(hasValue ? value : placeholder)
                    .font(HealthTypography.body)
                    .foregroundColor(hasValue ? HealthColors.primaryText : HealthColors.tertiaryText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(HealthColors.tertiaryText)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .fill(HealthColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                            .strokeBorder(HealthColors.accent.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

/// Section header component
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: HealthSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(HealthColors.primary)
            
            Text(title)
                .healthTextStyle(.headline, color: HealthColors.primaryText)
            
            Spacer()
        }
    }
}

/// Biological sex selection row
struct SexSelectionRow: View {
    let sex: BiologicalSex
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(sex.displayName)
                        .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                    
                    if sex == .other || sex == .notSet {
                        Text("For health calculations")
                            .healthTextStyle(.caption2, color: HealthColors.tertiaryText)
                    }
                }
                
                Spacer()
                
                // Radio button
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? HealthColors.primary : HealthColors.healthNeutral,
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(HealthColors.primary)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .fill(isSelected ? HealthColors.accent.opacity(0.1) : HealthColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                            .strokeBorder(
                                isSelected ? HealthColors.primary : HealthColors.accent.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Native progress view style
struct HealthProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: HealthCornerRadius.xs)
                    .fill(HealthColors.accent.opacity(0.3))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: HealthCornerRadius.xs)
                    .fill(HealthColors.primary)
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: 6)
                    .animation(.easeInOut(duration: 0.3), value: configuration.fractionCompleted)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Focus Field Enum (Removed)

// ProfileField enum removed - MinimalTextField uses simple SwiftUI binding

// MARK: - Preview

#Preview("Profile Setup View") {
    ProfileSetupView()
        .environment(OnboardingViewModel())
}