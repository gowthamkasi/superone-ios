//
//  ResponseValidationView.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Advanced response validation view with detailed mismatch detection and analysis
//

import SwiftUI

/// Advanced response validation view with detailed analysis
struct ResponseValidationView: View {
    let validationResult: APIValidationResult
    let endpoint: APIEndpoint
    let showDetailedAnalysis: Bool
    
    @State private var selectedTab = 0
    @State private var expandedSections: Set<ValidationSection> = []
    
    init(
        validationResult: APIValidationResult,
        endpoint: APIEndpoint,
        showDetailedAnalysis: Bool = true
    ) {
        self.validationResult = validationResult
        self.endpoint = endpoint
        self.showDetailedAnalysis = showDetailedAnalysis
    }
    
    enum ValidationSection: String, CaseIterable {
        case overview = "Overview"
        case errors = "Errors"
        case mismatches = "Mismatches"
        case warnings = "Warnings"
        case suggestions = "Suggestions"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Validation header
            validationHeader
            
            if showDetailedAnalysis {
                // Detailed analysis tabs
                detailedAnalysisView
            } else {
                // Quick summary view
                quickSummaryView
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
    
    // MARK: - Validation Header
    
    private var validationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text("Response Validation")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("Analysis for \(endpoint.displayName)")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
            
            // Overall validation status
            ValidationStatusIndicator(result: validationResult)
        }
    }
    
    // MARK: - Quick Summary View
    
    private var quickSummaryView: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            if validationResult.isValid {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(HealthColors.healthGood)
                    
                    Text("Response is valid")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.healthGood)
                    
                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(HealthColors.healthCritical)
                        
                        Text("Validation failed")
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(HealthColors.healthCritical)
                        
                        Spacer()
                    }
                    
                    // Quick stats
                    ValidationStatsBar(result: validationResult)
                }
            }
        }
    }
    
    // MARK: - Detailed Analysis View
    
    private var detailedAnalysisView: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Tab selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HealthSpacing.sm) {
                    ForEach(ValidationSection.allCases, id: \.self) { section in
                        ValidationTabButton(
                            section: section,
                            isSelected: selectedTab == ValidationSection.allCases.firstIndex(of: section) ?? 0,
                            count: sectionItemCount(section),
                            action: {
                                selectedTab = ValidationSection.allCases.firstIndex(of: section) ?? 0
                            }
                        )
                    }
                }
                .padding(.horizontal, HealthSpacing.sm)
            }
            
            // Content for selected tab
            selectedTabContent
                .frame(minHeight: 150)
        }
    }
    
    @ViewBuilder
    private var selectedTabContent: some View {
        let section = ValidationSection.allCases[selectedTab]
        
        switch section {
        case .overview:
            overviewSection
        case .errors:
            errorsSection
        case .mismatches:
            mismatchesSection
        case .warnings:
            warningsSection
        case .suggestions:
            suggestionsSection
        }
    }
    
    // MARK: - Individual Sections
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Overall status
            HStack {
                Text("Overall Status:")
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(validationResult.isValid ? "Valid" : "Invalid")
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(validationResult.isValid ? HealthColors.healthGood : HealthColors.healthCritical)
                
                Spacer()
            }
            
            Divider()
            
            // Statistics
            ValidationStatsGrid(result: validationResult)
            
            if !validationResult.isValid {
                Divider()
                
                // Quick issue summary
                ValidationIssueSummary(result: validationResult)
            }
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.background)
        .cornerRadius(HealthCornerRadius.sm)
    }
    
    private var errorsSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HealthSpacing.sm) {
                if validationResult.errors.isEmpty {
                    NoIssuesView(
                        icon: "checkmark.circle.fill",
                        title: "No Errors",
                        description: "Response validation passed without any errors",
                        color: HealthColors.healthGood
                    )
                } else {
                    ForEach(validationResult.errors.indices, id: \.self) { index in
                        ErrorItemView(
                            error: validationResult.errors[index],
                            index: index + 1
                        )
                    }
                }
            }
            .padding(HealthSpacing.sm)
        }
        .background(HealthColors.background)
        .cornerRadius(HealthCornerRadius.sm)
    }
    
    private var mismatchesSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HealthSpacing.sm) {
                if validationResult.mismatches.isEmpty {
                    NoIssuesView(
                        icon: "checkmark.circle.fill",
                        title: "No Mismatches",
                        description: "Response structure matches expected format",
                        color: HealthColors.healthGood
                    )
                } else {
                    ForEach(validationResult.mismatches, id: \.id) { mismatch in
                        MismatchItemView(mismatch: mismatch)
                    }
                }
            }
            .padding(HealthSpacing.sm)
        }
        .background(HealthColors.background)
        .cornerRadius(HealthCornerRadius.sm)
    }
    
    private var warningsSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HealthSpacing.sm) {
                if validationResult.warnings.isEmpty {
                    NoIssuesView(
                        icon: "checkmark.circle.fill",
                        title: "No Warnings",
                        description: "No potential issues detected in response",
                        color: HealthColors.healthGood
                    )
                } else {
                    ForEach(validationResult.warnings.indices, id: \.self) { index in
                        WarningItemView(
                            warning: validationResult.warnings[index],
                            index: index + 1
                        )
                    }
                }
            }
            .padding(HealthSpacing.sm)
        }
        .background(HealthColors.background)
        .cornerRadius(HealthCornerRadius.sm)
    }
    
    private var suggestionsSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HealthSpacing.md) {
                // Generate suggestions based on validation results
                if validationResult.isValid {
                    SuggestionCard(
                        icon: "checkmark.circle.fill",
                        title: "Response is Valid",
                        description: "The API response matches the expected format and contains no errors.",
                        color: HealthColors.healthGood
                    )
                } else {
                    // Suggestions for improvement
                    if !validationResult.errors.isEmpty {
                        SuggestionCard(
                            icon: "exclamationmark.triangle.fill",
                            title: "Fix Critical Errors",
                            description: "Address the \(validationResult.errors.count) critical error(s) that prevent proper response processing.",
                            color: HealthColors.healthCritical
                        )
                    }
                    
                    if !validationResult.mismatches.isEmpty {
                        SuggestionCard(
                            icon: "info.circle.fill",
                            title: "Review Schema Mismatches",
                            description: "Check the \(validationResult.mismatches.count) field(s) that don't match expected format.",
                            color: HealthColors.primary
                        )
                    }
                    
                    if !validationResult.warnings.isEmpty {
                        SuggestionCard(
                            icon: "exclamationmark.circle.fill",
                            title: "Consider Warning Messages",
                            description: "Review \(validationResult.warnings.count) warning(s) that might affect response quality.",
                            color: HealthColors.healthWarning
                        )
                    }
                }
                
                // Endpoint-specific suggestions
                endpointSpecificSuggestions
            }
            .padding(HealthSpacing.sm)
        }
        .background(HealthColors.background)
        .cornerRadius(HealthCornerRadius.sm)
    }
    
    @ViewBuilder
    private var endpointSpecificSuggestions: some View {
        switch endpoint.category {
        case .authentication:
            authenticationSuggestions
        case .labLoop:
            labLoopSuggestions
        case .health:
            healthSuggestions
        case .reports:
            reportsSuggestions
        case .upload:
            uploadSuggestions
        }
    }
    
    private var authenticationSuggestions: some View {
        Group {
            if endpoint.name == "register" || endpoint.name == "login" {
                SuggestionCard(
                    icon: "key.fill",
                    title: "Security Validation",
                    description: "Ensure tokens are properly formatted and contain all required claims.",
                    color: HealthColors.primary
                )
            }
            
            if endpoint.requiresAuthentication {
                SuggestionCard(
                    icon: "lock.fill",
                    title: "Token Validation",
                    description: "Verify that authentication tokens are valid and not expired.",
                    color: HealthColors.healthWarning
                )
            }
        }
    }
    
    private var labLoopSuggestions: some View {
        SuggestionCard(
            icon: "building.2.fill",
            title: "LabLoop Integration",
            description: "Ensure facility and appointment data includes all required fields for proper integration.",
            color: HealthColors.healthGood
        )
    }
    
    private var healthSuggestions: some View {
        SuggestionCard(
            icon: "heart.fill",
            title: "Health Data Validation",
            description: "Verify health metrics are within expected ranges and properly formatted.",
            color: HealthColors.healthExcellent
        )
    }
    
    private var reportsSuggestions: some View {
        SuggestionCard(
            icon: "doc.text.fill",
            title: "Report Processing",
            description: "Check that report data includes proper metadata and processing status.",
            color: HealthColors.healthWarning
        )
    }
    
    private var uploadSuggestions: some View {
        SuggestionCard(
            icon: "arrow.up.circle.fill",
            title: "Upload Validation",
            description: "Ensure upload responses include progress tracking and error handling information.",
            color: HealthColors.healthCritical
        )
    }
    
    // MARK: - Helper Functions
    
    private func sectionItemCount(_ section: ValidationSection) -> Int {
        switch section {
        case .overview:
            return validationResult.hasIssues ? validationResult.issueCount : 0
        case .errors:
            return validationResult.errors.count
        case .mismatches:
            return validationResult.mismatches.count
        case .warnings:
            return validationResult.warnings.count
        case .suggestions:
            return validationResult.hasIssues ? 3 : 1
        }
    }
}

// MARK: - Supporting Views

struct ValidationStatusIndicator: View {
    let result: APIValidationResult
    
    var body: some View {
        HStack(spacing: HealthSpacing.xs) {
            Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(result.isValid ? HealthColors.healthGood : HealthColors.healthCritical)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(result.isValid ? "Valid" : "Invalid")
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(result.isValid ? HealthColors.healthGood : HealthColors.healthCritical)
                
                if result.hasIssues {
                    Text("\(result.issueCount) issue(s)")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
        }
    }
}

struct ValidationStatsBar: View {
    let result: APIValidationResult
    
    var body: some View {
        HStack(spacing: HealthSpacing.lg) {
            // Commented out StatItem due to parameter mismatch
            // StatItem(
            //     title: "Errors",
            //     value: "\(result.errors.count)",
            //     color: HealthColors.healthCritical
            // )
            
            Text("Errors: \(result.errors.count)")
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.healthCritical)
            
            Text("Mismatches: \(result.mismatches.count)")
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.healthWarning)
            
            Text("Warnings: \(result.warnings.count)")
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.healthModerate)
            
            Spacer()
        }
    }
}

struct ValidationStatsGrid: View {
    let result: APIValidationResult
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: HealthSpacing.md) {
            ValidationStatCard(title: "Errors", count: result.errors.count, color: HealthColors.healthCritical)
            ValidationStatCard(title: "Mismatches", count: result.mismatches.count, color: HealthColors.healthWarning)
            ValidationStatCard(title: "Warnings", count: result.warnings.count, color: HealthColors.healthModerate)
        }
    }
}

struct ValidationStatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: HealthSpacing.xs) {
            Text("\(count)")
                .font(HealthTypography.headingLarge)
                .foregroundColor(count > 0 ? color : HealthColors.healthGood)
            
            Text(title)
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.secondaryText)
        }
        .padding(HealthSpacing.sm)
        .background(count > 0 ? color.opacity(0.1) : HealthColors.healthGood.opacity(0.1))
        .cornerRadius(HealthCornerRadius.sm)
    }
}

struct ValidationTabButton: View {
    let section: ResponseValidationView.ValidationSection
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HealthSpacing.xs) {
                Text(section.rawValue)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                
                if count > 0 {
                    Text("\(count)")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(isSelected ? HealthColors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(HealthCornerRadius.button)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NoIssuesView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: HealthSpacing.md) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(title)
                .font(HealthTypography.bodyMedium)
                .foregroundColor(color)
            
            Text(description)
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(HealthSpacing.xl)
    }
}

struct ErrorItemView: View {
    let error: String
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: HealthSpacing.sm) {
            Text("\(index)")
                .font(HealthTypography.captionMedium)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(HealthColors.healthCritical)
                .clipShape(Circle())
            
            Text(error)
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
        }
        .padding(HealthSpacing.sm)
        .background(HealthColors.healthCritical.opacity(0.1))
        .cornerRadius(HealthCornerRadius.sm)
    }
}

struct WarningItemView: View {
    let warning: String
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: HealthSpacing.sm) {
            Text("\(index)")
                .font(HealthTypography.captionMedium)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(HealthColors.healthWarning)
                .clipShape(Circle())
            
            Text(warning)
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
        }
        .padding(HealthSpacing.sm)
        .background(HealthColors.healthWarning.opacity(0.1))
        .cornerRadius(HealthCornerRadius.sm)
    }
}

struct MismatchItemView: View {
    let mismatch: APIValidationMismatch
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            HStack {
                Image(systemName: mismatch.severity.icon)
                    .foregroundColor(mismatch.severity.color)
                
                Text(mismatch.path)
                    .font(HealthTypography.captionMedium.monospaced())
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                Text(mismatch.severity.rawValue.uppercased())
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(mismatch.severity.color)
                    .cornerRadius(4)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Expected:")
                        .font(.caption2)
                        .foregroundColor(HealthColors.secondaryText)
                    
                    Text(mismatch.expected)
                        .font(.caption2.monospaced())
                        .foregroundColor(HealthColors.primaryText)
                        .padding(4)
                        .background(HealthColors.healthGood.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Actual:")
                        .font(.caption2)
                        .foregroundColor(HealthColors.secondaryText)
                    
                    Text(mismatch.actual)
                        .font(.caption2.monospaced())
                        .foregroundColor(HealthColors.primaryText)
                        .padding(4)
                        .background(HealthColors.healthCritical.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(HealthSpacing.sm)
        .background(mismatch.severity.color.opacity(0.1))
        .cornerRadius(HealthCornerRadius.sm)
    }
}

struct ValidationIssueSummary: View {
    let result: APIValidationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            Text("Issues Found:")
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primaryText)
            
            HStack {
                if !result.errors.isEmpty {
                    IssueTypeBadge(
                        type: "Errors",
                        count: result.errors.count,
                        color: HealthColors.healthCritical
                    )
                }
                
                if !result.mismatches.isEmpty {
                    IssueTypeBadge(
                        type: "Mismatches",
                        count: result.mismatches.count,
                        color: HealthColors.healthWarning
                    )
                }
                
                if !result.warnings.isEmpty {
                    IssueTypeBadge(
                        type: "Warnings",
                        count: result.warnings.count,
                        color: HealthColors.healthModerate
                    )
                }
                
                Spacer()
            }
        }
    }
}

struct IssueTypeBadge: View {
    let type: String
    let count: Int
    let color: Color
    
    var body: some View {
        Text("\(count) \(type)")
            .font(HealthTypography.captionMedium)
            .foregroundColor(.white)
            .padding(.horizontal, HealthSpacing.sm)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(HealthCornerRadius.sm)
    }
}

struct SuggestionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: HealthSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(description)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(HealthSpacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(HealthCornerRadius.sm)
    }
}

#Preview("Validation Success") {
    ResponseValidationView(
        validationResult: APIValidationResult(isValid: true),
        endpoint: APIEndpoint(
            name: "login",
            displayName: "Login User",
            method: .POST,
            path: "/api/v1/auth/login",
            category: .authentication,
            description: "Test endpoint",
            requiredParameters: [],
            optionalParameters: [],
            expectedResponseType: "AuthResponse",
            requiresAuthentication: false
        )
    )
}

#Preview("Validation Failed") {
    ResponseValidationView(
        validationResult: APIValidationResult(
            isValid: false,
            mismatches: [
                APIValidationMismatch(path: "data.tokens", expected: "object", actual: "null", severity: APIMismatchSeverity.error),
                APIValidationMismatch(path: "data.user.email", expected: "string", actual: "number", severity: APIMismatchSeverity.warning)
            ],
            errors: ["Missing required field: data.tokens", "Invalid token format"],
            warnings: ["Deprecated field detected: legacy_id"]
        ),
        endpoint: APIEndpoint(
            name: "login",
            displayName: "Login User",
            method: .POST,
            path: "/api/v1/auth/login",
            category: .authentication,
            description: "Test endpoint",
            requiredParameters: [],
            optionalParameters: [],
            expectedResponseType: "AuthResponse",
            requiresAuthentication: false
        )
    )
}