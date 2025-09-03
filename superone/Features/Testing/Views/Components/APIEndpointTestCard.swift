//
//  APIEndpointTestCard.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Reusable component for displaying and testing API endpoints
//

import SwiftUI

// MARK: - Supporting Components for API Testing

/// Badge for displaying HTTP methods with color coding
struct HTTPMethodBadge: View {
    let method: APIHTTPMethod
    
    var body: some View {
        Text(method.rawValue)
            .font(HealthTypography.captionMedium.monospaced())
            .foregroundColor(.white)
            .padding(.horizontal, HealthSpacing.sm)
            .padding(.vertical, 4)
            .background(method.color)
            .cornerRadius(HealthCornerRadius.sm)
    }
}

/// Badge for displaying test status
struct TestStatusBadge: View {
    let status: APITestStatus
    
    var body: some View {
        HStack(spacing: HealthSpacing.xs) {
            Image(systemName: status.icon)
                .font(.caption)
            
            Text(status.displayName)
                .font(HealthTypography.captionMedium)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, HealthSpacing.sm)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(HealthCornerRadius.sm)
    }
}

/// Button for selecting endpoints
struct EndpointButton: View {
    let endpoint: APIEndpoint
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                HStack {
                    HTTPMethodBadge(method: endpoint.method)
                    
                    if endpoint.requiresAuthentication {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(HealthColors.healthWarning)
                    }
                    
                    Spacer()
                }
                
                Text(endpoint.displayName)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(endpoint.path)
                    .font(HealthTypography.captionRegular.monospaced())
                    .foregroundColor(HealthColors.secondaryText)
                    .lineLimit(1)
            }
            .padding(HealthSpacing.sm)
            .frame(width: 160, height: 80, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .fill(isSelected ? HealthColors.primary.opacity(0.1) : HealthColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .strokeBorder(
                                isSelected ? HealthColors.primary : HealthColors.border,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Stat badge for displaying quick statistics
struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(HealthTypography.captionMedium)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(HealthColors.secondaryText)
        }
    }
}

/// Group view for displaying parameters with input fields
struct ParameterGroupView: View {
    let title: String
    let parameters: [ParameterDefinition]
    @Binding var values: [String: TestParameterValue]
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Text(title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("(\(parameters.count))")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                
                Spacer()
            }
            
            VStack(spacing: HealthSpacing.sm) {
                ForEach(parameters, id: \.id) { parameter in
                    ParameterInputView(
                        parameter: parameter,
                        value: Binding(
                            get: { values[parameter.name] },
                            set: { values[parameter.name] = $0 }
                        )
                    )
                }
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.background)
        .cornerRadius(HealthCornerRadius.sm)
    }
}

/// Individual parameter input view
struct ParameterInputView: View {
    let parameter: ParameterDefinition
    @Binding var value: TestParameterValue?
    
    @State private var stringValue: String = ""
    @State private var intValue: Int = 0
    @State private var doubleValue: Double = 0.0
    @State private var boolValue: Bool = false
    @State private var dateValue: Date = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.xs) {
            // Parameter header
            HStack {
                HStack(spacing: HealthSpacing.xs) {
                    Image(systemName: parameter.type.icon)
                        .font(.caption)
                        .foregroundColor(HealthColors.primary)
                    
                    Text(parameter.displayName)
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primaryText)
                }
                
                Spacer()
                
                Text(parameter.type.displayName)
                    .font(.caption2)
                    .foregroundColor(HealthColors.secondaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(HealthColors.secondaryText.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Parameter description
            if !parameter.description.isEmpty {
                Text(parameter.description)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            // Input field based on parameter type
            inputField
                .onAppear {
                    loadDefaultValue()
                }
        }
    }
    
    @ViewBuilder
    private var inputField: some View {
        switch parameter.type {
        case .string, .email, .url:
            TextField("Enter \(parameter.displayName.lowercased())", text: $stringValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(parameter.type == .email ? .emailAddress : .default)
                .autocapitalization(parameter.type == .email ? .none : .words)
                .onChange(of: stringValue) { _, newValue in
                    value = .string(newValue)
                }
                
        case .password:
            SecureField("Enter password", text: $stringValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: stringValue) { _, newValue in
                    value = .string(newValue)
                }
                
        case .integer:
            TextField("Enter number", value: $intValue, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .onChange(of: intValue) { _, newValue in
                    value = .integer(newValue)
                }
                
        case .double:
            TextField("Enter number", value: $doubleValue, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .onChange(of: doubleValue) { _, newValue in
                    value = .double(newValue)
                }
                
        case .boolean:
            Toggle(isOn: $boolValue) {
                Text("Enable")
                    .font(HealthTypography.captionRegular)
            }
            .tint(HealthColors.primary)
            .onChange(of: boolValue) { _, newValue in
                value = .boolean(newValue)
            }
            
        case .date:
            DatePicker(
                "Select date",
                selection: $dateValue,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .onChange(of: dateValue) { _, newValue in
                value = .date(newValue)
            }
            
        case .array:
            TextField("Enter comma-separated values", text: $stringValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: stringValue) { _, newValue in
                    let array = newValue.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    value = .array(array)
                }
                
        case .object, .file:
            Text("Not implemented yet")
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.secondaryText)
                .italic()
        }
    }
    
    private func loadDefaultValue() {
        if value == nil, let defaultValue = parameter.defaultValue {
            switch parameter.type {
            case .string, .email, .password, .url:
                if let stringDefault = defaultValue as? String {
                    stringValue = stringDefault
                    value = .string(stringDefault)
                }
            case .integer:
                if let intDefault = defaultValue as? Int {
                    intValue = intDefault
                    value = .integer(intDefault)
                }
            case .double:
                if let doubleDefault = defaultValue as? Double {
                    doubleValue = doubleDefault
                    value = .double(doubleDefault)
                }
            case .boolean:
                if let boolDefault = defaultValue as? Bool {
                    boolValue = boolDefault
                    value = .boolean(boolDefault)
                }
            case .date:
                if let dateDefault = defaultValue as? Date {
                    dateValue = dateDefault
                    value = .date(dateDefault)
                }
            default:
                break
            }
        }
    }
}

/// Detailed test result view
struct TestResultDetailView: View {
    let result: APITestResult
    @State private var selectedTab = 0
    
    private let tabs = ["Response", "Expected", "Validation", "Request", "Timing"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Tab selection
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { index in
                    Button(tabs[index]) {
                        selectedTab = index
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(selectedTab == index ? HealthColors.primary : HealthColors.secondaryText)
                    .padding(.horizontal, HealthSpacing.md)
                    .padding(.vertical, HealthSpacing.sm)
                    .background(
                        selectedTab == index ? HealthColors.primary.opacity(0.1) : Color.clear
                    )
                    .cornerRadius(HealthCornerRadius.sm)
                }
                
                Spacer()
            }
            
            // Content based on selected tab
            Group {
                switch selectedTab {
                case 0:
                    responseTab
                case 1:
                    expectedResponseTab
                case 2:
                    validationTab
                case 3:
                    requestTab
                case 4:
                    timingTab
                default:
                    EmptyView()
                }
            }
            .frame(minHeight: 100)
        }
    }
    
    private var responseTab: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            if let response = result.response {
                ScrollView {
                    PayloadInspectorView(data: response, title: "Response", isExpectedResponse: false)
                }
                .frame(maxHeight: 300)
            } else if let error = result.error {
                VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                    Text("Error:")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.healthCritical)
                    
                    Text(error.localizedDescription)
                        .font(HealthTypography.captionRegular.monospaced())
                        .foregroundColor(HealthColors.primaryText)
                        .padding(HealthSpacing.sm)
                        .background(HealthColors.healthCritical.opacity(0.1))
                        .cornerRadius(HealthCornerRadius.sm)
                }
            } else {
                Text("No response data available")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .italic()
            }
        }
    }
    
    private var expectedResponseTab: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            // Get expected response based on endpoint
            let expectedResponse = getExpectedResponse(for: result.endpoint)
            
            ScrollView {
                PayloadInspectorView(data: expectedResponse, title: "Expected Response", isExpectedResponse: true)
            }
            .frame(maxHeight: 300)
        }
    }
    
    private var validationTab: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            if let validation = result.validationResult {
                if validation.isValid {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(HealthColors.healthGood)
                        Text("Response is valid")
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.healthGood)
                    }
                } else {
                    VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(HealthColors.healthCritical)
                            Text("Validation failed")
                                .font(HealthTypography.captionMedium)
                                .foregroundColor(HealthColors.healthCritical)
                        }
                        
                        if !validation.errors.isEmpty {
                            ValidationIssuesView(title: "Errors", issues: validation.errors, color: HealthColors.healthCritical)
                        }
                        
                        if !validation.mismatches.isEmpty {
                            ValidationMismatchesView(mismatches: validation.mismatches)
                        }
                        
                        if !validation.warnings.isEmpty {
                            ValidationIssuesView(title: "Warnings", issues: validation.warnings, color: HealthColors.healthWarning)
                        }
                    }
                }
            } else {
                Text("No validation performed")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .italic()
            }
        }
    }
    
    private var requestTab: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            Text("Request Parameters:")
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primaryText)
            
            if result.parameters.isEmpty {
                Text("No parameters sent")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .italic()
            } else {
                ScrollView {
                    PayloadInspectorView(data: result.parameters, title: "Parameters", isExpectedResponse: false)
                }
                .frame(maxHeight: 200)
            }
        }
    }
    
    private var timingTab: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            HStack {
                Text("Response Time:")
                    .font(HealthTypography.captionMedium)
                
                Text(result.formattedResponseTime)
                    .font(HealthTypography.captionMedium.monospaced())
                    .foregroundColor(result.responseTime < 1000 ? HealthColors.healthGood : HealthColors.healthWarning)
                
                Spacer()
            }
            
            HStack {
                Text("Timestamp:")
                    .font(HealthTypography.captionMedium)
                
                Text(result.formattedTimestamp)
                    .font(HealthTypography.captionRegular.monospaced())
                    .foregroundColor(HealthColors.secondaryText)
                
                Spacer()
            }
        }
    }
    
    /// Get expected response structure for an endpoint
    private func getExpectedResponse(for endpoint: APIEndpoint) -> [String: Any] {
        switch endpoint.name {
        case "login":
            return [
                "success": true,
                "message": "Login successful",
                "data": [
                    "user": [
                        "_id": "68a4b68d895feeda983294b7",
                        "email": "user@test.local",
                        "name": "Sample",
                        "first_name": "Sample",
                        "last_name": "User",
                        "profile_image_url": "https://example.com/avatar.jpg",
                        "phone_number": "+1555000000",
                        "date_of_birth": "1990-01-15T00:00:00.000Z",
                        "gender": "male",
                        "height": 175.0,
                        "weight": 70.0,
                        "activity_level": "moderately_active",
                        "health_goals": ["fitness", "weight_management"],
                        "medical_conditions": [],
                        "medications": [],
                        "allergies": [],
                        "labloop_patient_id": "68a4b68d895feeda983294b7",
                        "created_at": "2024-01-01T00:00:00.000Z",
                        "updated_at": "2025-01-15T10:30:00.000Z",
                        "email_verified": true,
                        "phone_verified": false,
                        "two_factor_enabled": false,
                        "profile": [
                            "date_of_birth": "1990-01-15T00:00:00.000Z",
                            "gender": "male",
                            "height": 175.0,
                            "weight": 70.0,
                            "activity_level": "moderately_active",
                            "health_goals": ["fitness", "weight_management"],
                            "medical_conditions": [],
                            "medications": [],
                            "allergies": [],
                            "emergency_contact": [
                                "name": "Jane Doe",
                                "phone": "+1234567891",
                                "relationship": "spouse"
                            ],
                            "profile_image_url": "https://example.com/avatar.jpg",
                            "labloop_patient_id": "68a4b68d895feeda983294b7"
                        ],
                        "preferences": [
                            "notifications": [
                                "appointment_reminders": true,
                                "email_enabled": true,
                                "health_alerts": true,
                                "monthly_report": true,
                                "push_enabled": true,
                                "quiet_hours": [
                                    "enabled": true,
                                    "start_time": "22:00",
                                    "end_time": "08:00"
                                ],
                                "recommendations": true,
                                "report_ready": true,
                                "sms_enabled": false,
                                "weekly_digest": false
                            ],
                            "privacy": [
                                "allow_analytics": true,
                                "allow_marketing": false,
                                "data_retention_period": 365,
                                "share_data_for_research": false,
                                "share_data_with_providers": true
                            ],
                            "theme": "system",
                            "units": [
                                "date_format": "yyyy-MM-dd",
                                "height_unit": "cm",
                                "temperature_unit": "celsius",
                                "weight_unit": "kg"
                            ]
                        ]
                    ],
                    "tokens": [
                        "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                        "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                        "tokenType": "Bearer",
                        "expiresIn": 900
                    ]
                ],
                "timestamp": "2025-01-29T12:00:00.000Z"
            ]
        case "register":
            return [
                "success": true,
                "message": "Registration successful",
                "data": [
                    "user": [
                        "_id": "new_user_id_456",
                        "email": "newuser@test.local",
                        "name": "Jane",
                        "first_name": "Jane",
                        "last_name": "Smith",
                        "profile_image_url": NSNull(),
                        "phone_number": NSNull(),
                        "date_of_birth": "1992-05-20T00:00:00.000Z",
                        "gender": "female",
                        "height": 165.0,
                        "weight": 65.0,
                        "activity_level": "lightly_active",
                        "health_goals": [],
                        "medical_conditions": [],
                        "medications": [],
                        "allergies": [],
                        "labloop_patient_id": "new_user_id_456",
                        "created_at": "2025-01-29T12:00:00.000Z",
                        "updated_at": "2025-01-29T12:00:00.000Z",
                        "email_verified": false,
                        "phone_verified": false,
                        "two_factor_enabled": false,
                        "profile": NSNull(),
                        "preferences": NSNull()
                    ],
                    "tokens": [
                        "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                        "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                        "tokenType": "Bearer",
                        "expiresIn": 900
                    ]
                ],
                "timestamp": "2025-01-29T12:00:00.000Z"
            ]
        case "logout":
            return [
                "success": true,
                "message": "Logout successful",
                "timestamp": "2025-01-29T12:00:00.000Z"
            ]
        case "refreshToken":
            return [
                "success": true,
                "message": "Token refreshed successfully",
                "data": [
                    "accessToken": "new_jwt_token_string",
                    "refreshToken": "new_refresh_token_string",
                    "tokenType": "Bearer",
                    "expiresIn": 900
                ],
                "timestamp": "2025-01-29T12:00:00.000Z"
            ]
        case "forgotPassword":
            return [
                "success": true,
                "message": "Password reset email sent",
                "timestamp": "2025-01-29T12:00:00.000Z"
            ]
        case "getCurrentUser":
            return [
                "success": true,
                "message": "User retrieved successfully",
                "data": [
                    "_id": "user_id_123",
                    "email": "user@test.local",
                    "name": "Sample User",
                    "profile_image_url": "https://example.com/avatar.jpg",
                    "phone_number": "+1555000000",
                    "date_of_birth": "1990-01-01T00:00:00.000Z",
                    "gender": "male",
                    "created_at": "2024-01-01T00:00:00.000Z",
                    "updated_at": "2024-01-15T10:30:00.000Z",
                    "email_verified": true,
                    "phone_verified": false,
                    "two_factor_enabled": false,
                    "profile": [
                        "date_of_birth": "1990-01-01T00:00:00.000Z",
                        "gender": "male",
                        "height": 175.0,
                        "weight": 70.5,
                        "activity_level": "moderately_active",
                        "health_goals": ["cardiovascular_health", "weight_loss"],
                        "medical_conditions": ["hypertension"],
                        "medications": ["lisinopril"],
                        "allergies": ["peanuts"],
                        "emergency_contact": [
                            "name": "Jane Doe",
                            "relationship": "spouse",
                            "phone_number": "+1234567891",
                            "email": "jane@test.local"
                        ],
                        "profile_image_url": "https://example.com/avatar.jpg",
                        "labloop_patient_id": "ll_patient_123"
                    ],
                    "preferences": [
                        "notifications": [
                            "health_alerts": true,
                            "appointment_reminders": true,
                            "report_ready": true,
                            "recommendations": true,
                            "weekly_digest": false,
                            "monthly_report": true,
                            "push_enabled": true,
                            "email_enabled": true,
                            "sms_enabled": false,
                            "quiet_hours": [
                                "enabled": true,
                                "start_time": "22:00",
                                "end_time": "08:00"
                            ]
                        ],
                        "privacy": [
                            "share_data_with_providers": true,
                            "share_data_for_research": false,
                            "allow_analytics": true,
                            "allow_marketing": false,
                            "data_retention_period": 365
                        ],
                        "units": [
                            "weight_unit": "kg",
                            "height_unit": "cm",
                            "temperature_unit": "celsius",
                            "date_format": "yyyy-MM-dd"
                        ],
                        "theme": "system"
                    ]
                ],
                "timestamp": "2024-01-15T10:30:00.000Z",
                "meta": [
                    "requestedAt": "2024-01-15T10:30:00.000Z",
                    "processingTime": 0.125,
                    "version": "1.0.0",
                    "requestId": "req_12345"
                ]
            ]
        case "validateToken":
            return [
                "valid": true,
                "expiresAt": "2025-01-29T12:15:00.000Z"
            ]
        default:
            return [
                "success": true,
                "message": "Expected response structure not defined for this endpoint",
                "data": "Response will vary based on endpoint implementation"
            ]
        }
    }
}

/// View for displaying validation issues
struct ValidationIssuesView: View {
    let title: String
    let issues: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.xs) {
            Text(title)
                .font(HealthTypography.captionMedium)
                .foregroundColor(color)
            
            ForEach(issues.indices, id: \.self) { index in
                Text("• \(issues[index])")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.primaryText)
            }
        }
        .padding(HealthSpacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(HealthCornerRadius.sm)
    }
}

/// View for displaying validation mismatches
struct ValidationMismatchesView: View {
    let mismatches: [APIValidationMismatch]
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.xs) {
            Text("Mismatches")
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.healthCritical)
            
            ForEach(mismatches, id: \.id) { mismatch in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: mismatch.severity.icon)
                            .font(.caption2)
                            .foregroundColor(mismatch.severity.color)
                        
                        Text(mismatch.path)
                            .font(HealthTypography.captionMedium.monospaced())
                            .foregroundColor(HealthColors.primaryText)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Expected:")
                            .font(.caption2)
                            .foregroundColor(HealthColors.secondaryText)
                        
                        Text(mismatch.expected)
                            .font(.caption2.monospaced())
                            .foregroundColor(HealthColors.primaryText)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Actual:")
                            .font(.caption2)
                            .foregroundColor(HealthColors.secondaryText)
                        
                        Text(mismatch.actual)
                            .font(.caption2.monospaced())
                            .foregroundColor(HealthColors.primaryText)
                        
                        Spacer()
                    }
                }
                .padding(HealthSpacing.xs)
                .background(mismatch.severity.color.opacity(0.05))
                .cornerRadius(4)
            }
        }
        .padding(HealthSpacing.sm)
        .background(HealthColors.healthCritical.opacity(0.1))
        .cornerRadius(HealthCornerRadius.sm)
    }
}

/// Row view for test results in lists
struct TestResultRowView: View {
    let result: APITestResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: HealthSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.endpoint.displayName)
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(1)
                    
                    Text(result.formattedTimestamp)
                        .font(.caption2)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                Spacer()
                
                Text(result.formattedResponseTime)
                    .font(HealthTypography.captionRegular.monospaced())
                    .foregroundColor(HealthColors.secondaryText)
                
                TestStatusBadge(status: result.status)
            }
            .padding(HealthSpacing.sm)
            .background(HealthColors.background)
            .cornerRadius(HealthCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}