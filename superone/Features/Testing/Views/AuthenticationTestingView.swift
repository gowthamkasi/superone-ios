//
//  AuthenticationTestingView.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Comprehensive testing interface for all authentication endpoints
//

import SwiftUI

/// Testing interface for all authentication endpoints
struct AuthenticationTestingView: View {
    
    @EnvironmentObject var testingService: APITestingService
    @State private var selectedEndpoint = 0
    @State private var testParameters: [String: TestParameterValue] = [:]
    @State private var showingResults = false
    @State private var currentTestResult: APITestResult?
    @State private var isRunningTest = false
    
    // Authentication endpoints
    private let endpoints: [APIEndpoint] = [
        APIEndpoint(
            name: "register",
            displayName: "Register User",
            method: APIHTTPMethod.POST,
            path: "/api/v1/auth/register",
            category: APICategory.authentication,
            description: "Register a new user account",
            requiredParameters: [
                ParameterDefinition(name: "email", type: .email, description: "User's email address"),
                ParameterDefinition(name: "password", type: .password, description: "User's password"),
                ParameterDefinition(name: "name", type: .string, description: "User's full name")
            ],
            optionalParameters: [
                ParameterDefinition(name: "dateOfBirth", type: .date, description: "User's date of birth"),
                ParameterDefinition(name: "gender", type: .string, description: "User's gender (male, female, other)")
            ],
            expectedResponseType: "AuthResponse",
            requiresAuthentication: false
        ),
        
        APIEndpoint(
            name: "login",
            displayName: "Login User",
            method: APIHTTPMethod.POST,
            path: "/api/v1/auth/login",
            category: APICategory.authentication,
            description: "Authenticate user and return tokens",
            requiredParameters: [
                ParameterDefinition(name: "email", type: .email, description: "User's email address"),
                ParameterDefinition(name: "password", type: .password, description: "User's password")
            ],
            optionalParameters: [],
            expectedResponseType: "AuthResponse",
            requiresAuthentication: false
        ),
        
        APIEndpoint(
            name: "logout",
            displayName: "Logout User",
            method: APIHTTPMethod.POST,
            path: "/api/v1/auth/logout",
            category: APICategory.authentication,
            description: "Logout user and invalidate tokens",
            requiredParameters: [],
            optionalParameters: [
                ParameterDefinition(name: "currentDeviceOnly", type: .boolean, description: "Logout from current device only", defaultValue: true)
            ],
            expectedResponseType: "LogoutResponse",
            requiresAuthentication: true
        ),
        
        APIEndpoint(
            name: "refreshToken",
            displayName: "Refresh Token",
            method: APIHTTPMethod.POST,
            path: "/api/v1/auth/refresh",
            category: APICategory.authentication,
            description: "Refresh authentication token",
            requiredParameters: [],
            optionalParameters: [],
            expectedResponseType: "TokenResponse",
            requiresAuthentication: false
        ),
        
        APIEndpoint(
            name: "forgotPassword",
            displayName: "Forgot Password",
            method: APIHTTPMethod.POST,
            path: "/api/v1/auth/forgot-password",
            category: APICategory.authentication,
            description: "Send password reset email",
            requiredParameters: [
                ParameterDefinition(name: "email", type: .email, description: "User's email address")
            ],
            optionalParameters: [],
            expectedResponseType: "PasswordResetResponse",
            requiresAuthentication: false
        ),
        
        APIEndpoint(
            name: "getCurrentUser",
            displayName: "Get Current User",
            method: APIHTTPMethod.GET,
            path: "/api/v1/mobile/users/me",
            category: APICategory.authentication,
            description: "Get current authenticated user information",
            requiredParameters: [],
            optionalParameters: [],
            expectedResponseType: "User",
            requiresAuthentication: true
        ),
        
        APIEndpoint(
            name: "validateToken",
            displayName: "Validate Token",
            method: APIHTTPMethod.GET,
            path: "/token/validate",
            category: APICategory.authentication,
            description: "Check if current token is valid",
            requiredParameters: [],
            optionalParameters: [],
            expectedResponseType: "Boolean",
            requiresAuthentication: true
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: HealthSpacing.lg) {
                // Header
                headerSection
                
                // Endpoint Selection
                endpointSelectorSection
                
                // Current Endpoint Details
                endpointDetailsSection
                
                // Parameters Input
                parametersInputSection
                
                // Test Actions
                testActionsSection
                
                // Test Results
                if let result = currentTestResult {
                    testResultsSection(result: result)
                }
                
                // Recent Tests History
                recentTestsSection
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.bottom, HealthSpacing.xl)
        }
        .background(HealthColors.background.ignoresSafeArea())
        .onAppear {
            initializeDefaultParameters()
        }
        .onChange(of: selectedEndpoint) { _, _ in
            updateParametersForSelectedEndpoint()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            HStack {
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundColor(HealthColors.primary)
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text("Authentication Testing")
                        .font(HealthTypography.headingMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text("Test all authentication endpoints with detailed response validation")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                Spacer()
            }
            
            // Quick stats for auth endpoints
            HStack(spacing: HealthSpacing.lg) {
                StatBadge(title: "Endpoints", value: "\(endpoints.count)", color: HealthColors.primary)
                StatBadge(title: "Requires Auth", value: "\(endpoints.filter { $0.requiresAuthentication }.count)", color: HealthColors.healthWarning)
                StatBadge(title: "Public", value: "\(endpoints.filter { !$0.requiresAuthentication }.count)", color: HealthColors.healthGood)
                Spacer()
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
    
    // MARK: - Endpoint Selector
    
    private var endpointSelectorSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Select Endpoint")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HealthSpacing.sm) {
                    ForEach(endpoints.indices, id: \.self) { index in
                        EndpointButton(
                            endpoint: endpoints[index],
                            isSelected: selectedEndpoint == index,
                            action: { selectedEndpoint = index }
                        )
                    }
                }
                .padding(.horizontal, HealthSpacing.sm)
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
    
    // MARK: - Endpoint Details
    
    private var endpointDetailsSection: some View {
        let endpoint = endpoints[selectedEndpoint]
        
        return VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                HTTPMethodBadge(method: endpoint.method)
                
                Text(endpoint.displayName)
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                if endpoint.requiresAuthentication {
                    Image(systemName: "lock.fill")
                        .foregroundColor(HealthColors.healthWarning)
                        .font(.caption)
                }
            }
            
            Text(endpoint.description)
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
            
            HStack {
                Text("Path:")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.secondaryText)
                
                Text(endpoint.path)
                    .font(HealthTypography.captionRegular.monospaced())
                    .foregroundColor(HealthColors.primaryText)
                    .padding(.horizontal, HealthSpacing.xs)
                    .padding(.vertical, 2)
                    .background(HealthColors.background)
                    .cornerRadius(4)
                
                Spacer()
            }
            
            HStack {
                Text("Expected Response:")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.secondaryText)
                
                Text(endpoint.expectedResponseType)
                    .font(HealthTypography.captionRegular.monospaced())
                    .foregroundColor(HealthColors.primary)
                    .padding(.horizontal, HealthSpacing.xs)
                    .padding(.vertical, 2)
                    .background(HealthColors.primary.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
    
    // MARK: - Parameters Input
    
    private var parametersInputSection: some View {
        let endpoint = endpoints[selectedEndpoint]
        let hasParameters = !endpoint.requiredParameters.isEmpty || !endpoint.optionalParameters.isEmpty
        
        return VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Parameters")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            if hasParameters {
                VStack(spacing: HealthSpacing.lg) {
                    // Required Parameters
                    if !endpoint.requiredParameters.isEmpty {
                        ParameterGroupView(
                            title: "Required",
                            parameters: endpoint.requiredParameters,
                            values: $testParameters
                        )
                    }
                    
                    // Optional Parameters
                    if !endpoint.optionalParameters.isEmpty {
                        ParameterGroupView(
                            title: "Optional",
                            parameters: endpoint.optionalParameters,
                            values: $testParameters
                        )
                    }
                }
            } else {
                VStack(spacing: HealthSpacing.md) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundColor(HealthColors.healthGood)
                    
                    Text("No parameters required")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(HealthSpacing.xl)
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
    
    // MARK: - Test Actions
    
    private var testActionsSection: some View {
        VStack(spacing: HealthSpacing.md) {
            // Run Test Button
            Button(action: runTest) {
                HStack {
                    if isRunningTest {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                    }
                    
                    Text(isRunningTest ? "Testing..." : "Run Test")
                        .font(HealthTypography.bodyMedium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(HealthSpacing.md)
                .background(isRunningTest ? HealthColors.secondaryText : HealthColors.primary)
                .cornerRadius(HealthCornerRadius.button)
            }
            .disabled(isRunningTest)
            
            // Secondary Actions
            HStack(spacing: HealthSpacing.md) {
                Button("Clear Parameters") {
                    clearParameters()
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primary)
                .padding(.horizontal, HealthSpacing.lg)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.primary.opacity(0.1))
                .cornerRadius(HealthCornerRadius.button)
                
                Button("Load Defaults") {
                    loadDefaultParameters()
                }
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primary)
                .padding(.horizontal, HealthSpacing.lg)
                .padding(.vertical, HealthSpacing.sm)
                .background(HealthColors.primary.opacity(0.1))
                .cornerRadius(HealthCornerRadius.button)
                
                Spacer()
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
    
    // MARK: - Test Results Section
    
    private func testResultsSection(result: APITestResult) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Text("Test Result")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                TestStatusBadge(status: result.status)
            }
            
            // Result Details
            TestResultDetailView(result: result)
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
    
    // MARK: - Recent Tests Section
    
    private var recentTestsSection: some View {
        let authTests = testingService.testResults.filter { $0.endpoint.category == .authentication }
        
        return VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Text("Recent Authentication Tests")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                Button("View All") {
                    showingResults = true
                }
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primary)
            }
            
            if authTests.isEmpty {
                VStack(spacing: HealthSpacing.md) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(HealthColors.secondaryText)
                    
                    Text("No tests run yet")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(HealthSpacing.xl)
            } else {
                LazyVStack(spacing: HealthSpacing.sm) {
                    ForEach(authTests.prefix(5), id: \.id) { result in
                        TestResultRowView(result: result) {
                            currentTestResult = result
                        }
                    }
                }
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
    
    // MARK: - Actions
    
    private func runTest() {
        let endpoint = endpoints[selectedEndpoint]
        isRunningTest = true
        currentTestResult = nil
        
        Task {
            do {
                let parameters = testParameters.reduce(into: [String: Any]()) { result, item in
                    result[item.key] = item.value.actualValue
                }
                
                let result = try await testingService.executeTest(
                    endpoint: endpoint,
                    parameters: parameters
                )
                
                await MainActor.run {
                    currentTestResult = result
                    isRunningTest = false
                }
            } catch {
                await MainActor.run {
                    // Create error result
                    let errorResult = APITestResult(
                        endpoint: endpoint,
                        parameters: testParameters.reduce(into: [String: Any]()) { result, item in
                            result[item.key] = item.value.actualValue
                        },
                        responseTime: 0,
                        status: .failed,
                        error: error
                    )
                    currentTestResult = errorResult
                    isRunningTest = false
                }
            }
        }
    }
    
    private func initializeDefaultParameters() {
        loadDefaultParametersForEndpoint(endpoints[selectedEndpoint])
    }
    
    private func updateParametersForSelectedEndpoint() {
        testParameters.removeAll()
        loadDefaultParametersForEndpoint(endpoints[selectedEndpoint])
    }
    
    private func loadDefaultParametersForEndpoint(_ endpoint: APIEndpoint) {
        // Load default values for testing
        switch endpoint.name {
        case "register":
            testParameters["email"] = .string("test@example.com")
            testParameters["password"] = .string("TestPass123!")
            testParameters["name"] = .string("Test User")
            testParameters["gender"] = .string("male")
            
        case "login":
            testParameters["email"] = .string("test@example.com")
            testParameters["password"] = .string("TestPass123!")
            
        case "forgotPassword":
            testParameters["email"] = .string("test@example.com")
            
        case "logout":
            testParameters["currentDeviceOnly"] = .boolean(true)
            
        default:
            break
        }
    }
    
    private func clearParameters() {
        testParameters.removeAll()
    }
    
    private func loadDefaultParameters() {
        loadDefaultParametersForEndpoint(endpoints[selectedEndpoint])
    }
}

// MARK: - Supporting Views will be implemented in the next files