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
    @State private var dateOfBirth: Date?
    @State private var selectedGender: Gender?
    @State private var heightCm: String = ""
    @State private var weightKg: String = ""
    @State private var showingDatePicker = false
    
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
                    .disabled(!isValidForm)
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
    }
    
    private func loadProfile() {
        guard let profile = profile else { return }
        
        // Extract name parts from the full name
        let nameParts = profile.name.components(separatedBy: " ")
        firstName = nameParts.first ?? ""
        lastName = nameParts.dropFirst().joined(separator: " ")
        
        email = profile.email
        dateOfBirth = profile.dateOfBirth
        selectedGender = profile.gender
        
        // Load health profile data if available
        if let healthProfile = profile.profile {
            heightCm = healthProfile.height.map { String(Int($0)) } ?? ""
            weightKg = healthProfile.weight.map { String(format: "%.1f", $0) } ?? ""
        }
    }
    
    private func saveProfile() {
        guard let profile = profile else { return }
        
        // Create updated health profile
        let updatedHealthProfile = UserProfile(
            height: Double(heightCm),
            weight: Double(weightKg),
            activityLevel: profile.profile?.activityLevel,
            healthGoals: profile.profile?.healthGoals ?? [],
            medicalConditions: profile.profile?.medicalConditions ?? [],
            medications: profile.profile?.medications ?? [],
            allergies: profile.profile?.allergies ?? [],
            emergencyContact: profile.profile?.emergencyContact,
            labloopPatientId: profile.profile?.labloopPatientId
        )
        
        // Create updated user
        let updatedUser = User(
            id: profile.id,
            email: email,
            name: "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces),
            profileImageURL: profile.profileImageURL,
            phoneNumber: profile.phoneNumber,
            dateOfBirth: dateOfBirth,
            gender: selectedGender,
            createdAt: profile.createdAt,
            updatedAt: Date(),
            emailVerified: profile.emailVerified,
            phoneVerified: profile.phoneVerified,
            twoFactorEnabled: profile.twoFactorEnabled,
            profile: updatedHealthProfile,
            preferences: profile.preferences
        )
        
        onSave(updatedUser)
        dismiss()
    }
    
    private var isValidForm: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty
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

#Preview {
    EditProfileSheet(
        profile: User(
            id: "preview-user-id",
            email: "preview@example.com",
            name: "Sample User",
            profileImageURL: nil,
            phoneNumber: nil,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date()),
            gender: .male,
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