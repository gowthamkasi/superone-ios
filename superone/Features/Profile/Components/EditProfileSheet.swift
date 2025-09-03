//
//  EditProfileSheet.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Sheet for editing user profile information
struct EditProfileSheet: View {
    let profile: User?
    let onSave: (User) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var mobileNumber: String = "" // Added mobile number field
    @State private var dateOfBirth: Date?
    @State private var selectedGender: Gender?
    @State private var heightCm: String = ""
    @State private var weightKg: String = ""
    @State private var showingDatePicker = false
    
    // Profile update state
    @State private var isUpdating = false
    @State private var updateError: String?
    @State private var showUpdateError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    HStack {
                        Text("First Name")
                        Spacer()
                        TextField("Enter first name", text: $firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Last Name")
                        Spacer()
                        TextField("Enter last name", text: $lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        TextField("Enter email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    
                    HStack {
                        Text("Mobile Number")
                        Spacer()
                        TextField("Enter mobile number", text: $mobileNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                            .keyboardType(.phonePad)
                    }
                }
                
                Section("Demographics") {
                    HStack {
                        Text("Date of Birth")
                        Spacer()
                        if let dob = dateOfBirth {
                            Text(dob, style: .date)
                                .foregroundColor(HealthColors.primary)
                        } else {
                            Text("Not set")
                                .foregroundColor(HealthColors.secondaryText)
                        }
                    }
                    .onTapGesture {
                        showingDatePicker = true
                    }
                    
                    HStack {
                        Text("Gender")
                        Spacer()
                        Picker("Gender", selection: $selectedGender) {
                            Text("Not specified").tag(nil as Gender?)
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.rawValue).tag(gender as Gender?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("Physical Information") {
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("170", text: $heightCm)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("70.0", text: $weightKg)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!isValidForm || isUpdating)
                    .overlay(
                        isUpdating ? ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle(tint: HealthColors.primary))
                            : nil
                    )
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(
                    selectedDate: Binding(
                        get: { dateOfBirth ?? Date() },
                        set: { dateOfBirth = $0 }
                    )
                )
            }
        }
        .onAppear {
            loadProfile()
        }
        .alert("Update Error", isPresented: $showUpdateError) {
            Button("OK") {
                showUpdateError = false
            }
        } message: {
            Text(updateError ?? "An error occurred while updating your profile")
        }
    }
    
    private func loadProfile() {
        guard let profile = profile else { return }
        
        // Load firstName and lastName directly from structured fields
        firstName = profile.firstName ?? ""
        lastName = profile.lastName ?? ""
        
        // Debug logging to help identify data source issues
        print("🔍 EditProfileSheet.loadProfile():")
        print("   profile.firstName: '\(profile.firstName ?? "nil")'")
        print("   profile.lastName: '\(profile.lastName ?? "nil")'")
        print("   Loaded firstName: '\(firstName)'")
        print("   Loaded lastName: '\(lastName)'")
        
        email = profile.email
        mobileNumber = profile.mobileNumber ?? "" // Load mobile number
        dateOfBirth = profile.dateOfBirth
        selectedGender = profile.gender
        
        // Load health profile data if available
        if let healthProfile = profile.profile {
            heightCm = healthProfile.height.map { String(Int($0)) } ?? ""
            weightKg = healthProfile.weight.map { String(format: "%.1f", $0) } ?? ""
        } else {
            // Fallback: load from User level height/weight if available
            heightCm = profile.height.map { String(Int($0)) } ?? ""
            weightKg = profile.weight.map { String(format: "%.1f", $0) } ?? ""
        }
    }
    
    private func saveProfile() {
        guard let profile = profile else { return }
        
        isUpdating = true
        updateError = nil
        showUpdateError = false
        
        // Create updated health profile
        let updatedHealthProfile = UserProfile(
            height: heightCm.isEmpty ? nil : Double(heightCm), // Convert empty string to nil
            weight: weightKg.isEmpty ? nil : Double(weightKg), // Convert empty string to nil
            activityLevel: profile.profile?.activityLevel,
            healthGoals: profile.profile?.healthGoals ?? [],
            medicalConditions: profile.profile?.medicalConditions ?? [],
            medications: profile.profile?.medications ?? [],
            allergies: profile.profile?.allergies ?? [],
            emergencyContact: profile.profile?.emergencyContact,
            labloopPatientId: profile.profile?.labloopPatientId
        )
        
        // Create updated user with mobile number support
        let updatedUser = User(
            id: profile.id,
            email: email,
            name: "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces),
            firstName: firstName,
            lastName: lastName,
            profileImageURL: profile.profileImageURL,
            phoneNumber: mobileNumber.isEmpty ? profile.phoneNumber : mobileNumber, // Use mobile number as phone
            mobileNumber: mobileNumber.isEmpty ? nil : mobileNumber, // Store mobile number separately
            dateOfBirth: dateOfBirth,
            gender: selectedGender,
            height: heightCm.isEmpty ? nil : Double(heightCm), // Convert empty string to nil
            weight: weightKg.isEmpty ? nil : Double(weightKg), // Convert empty string to nil
            createdAt: profile.createdAt,
            updatedAt: Date(),
            emailVerified: profile.emailVerified,
            phoneVerified: profile.phoneVerified,
            twoFactorEnabled: profile.twoFactorEnabled,
            profile: updatedHealthProfile,
            preferences: profile.preferences
        )
        
        // Validate form before saving
        do {
            try validateForm()
            
            onSave(updatedUser)
            isUpdating = false
            dismiss()
            
        } catch {
            isUpdating = false
            updateError = error.localizedDescription
            showUpdateError = true
        }
    }
    
    /// Validate form inputs
    private func validateForm() throws {
        // Validate email format if not empty
        if !email.isEmpty && !isValidEmail(email) {
            throw ValidationError.invalidEmail
        }
        
        // Validate mobile number format if not empty
        if !mobileNumber.isEmpty && !isValidMobileNumber(mobileNumber) {
            throw ValidationError.invalidMobileNumber
        }
        
        // Validate height if provided
        if !heightCm.isEmpty, let height = Double(heightCm) {
            if height < 50 || height > 300 {
                throw ValidationError.invalidHeight
            }
        }
        
        // Validate weight if provided
        if !weightKg.isEmpty, let weight = Double(weightKg) {
            if weight < 20 || weight > 500 {
                throw ValidationError.invalidWeight
            }
        }
    }
    
    /// Validate email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validate mobile number format
    private func isValidMobileNumber(_ mobileNumber: String) -> Bool {
        let digitsOnly = mobileNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return digitsOnly.count >= 10 && digitsOnly.count <= 15
    }
    
    private var isValidForm: Bool {
        // Basic validation - at least first name, last name, and email are required
        let hasRequiredFields = !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty
        
        // Optional field validation - if provided, must be valid
        let emailValid = email.isEmpty || isValidEmail(email)
        let mobileValid = mobileNumber.isEmpty || isValidMobileNumber(mobileNumber)
        
        return hasRequiredFields && emailValid && mobileValid
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(WheelDatePickerStyle())
            .padding()
            .navigationTitle("Date of Birth")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Validation Errors
// ValidationError enum is defined in NetworkError.swift

#Preview {
    EditProfileSheet(
        profile: User(
            id: "preview-user-id",
            email: "preview@test.local",
            name: "Sample User",
            firstName: "Sample",
            lastName: "User",
            profileImageURL: nil,
            phoneNumber: "+1555000000",
            mobileNumber: "+1555000000", // Added mobile number for preview
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date()),
            gender: .male,
            height: 175.0,
            weight: 70.0,
            createdAt: Date(),
            updatedAt: Date(),
            emailVerified: true,
            phoneVerified: false,
            twoFactorEnabled: false,
            profile: UserProfile(
                height: 175.0,
                weight: 70.0,
                activityLevel: .moderatelyActive,
                healthGoals: [.general],
                medicalConditions: [],
                medications: [],
                allergies: [],
                emergencyContact: nil,
                labloopPatientId: nil
            ),
            preferences: nil
        ),
        onSave: { _ in }
    )
}