//
//  AboutSheet.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Sheet showing app information and version details
struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: HealthSpacing.xl) {
                    // App icon and title
                    VStack(spacing: HealthSpacing.lg) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 80))
                            .foregroundColor(HealthColors.primary)
                        
                        VStack(spacing: HealthSpacing.sm) {
                            Text("SuperOne Health")
                                .font(HealthTypography.headingMedium)
                                .foregroundColor(HealthColors.primaryText)
                            
                            Text("AI-Powered Health Analysis")
                                .font(HealthTypography.bodyMedium)
                                .foregroundColor(HealthColors.secondaryText)
                        }
                    }
                    
                    // Version information
                    VStack(spacing: HealthSpacing.md) {
                        InfoRow(title: "Version", value: appVersion)
                        InfoRow(title: "Build", value: buildNumber)
                        InfoRow(title: "Platform", value: "iOS \(UIDevice.current.systemVersion)")
                    }
                    .padding(HealthSpacing.lg)
                    .background(HealthColors.secondaryBackground)
                    .cornerRadius(HealthCornerRadius.card)
                    
                    // App description
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        Text("About SuperOne")
                            .font(HealthTypography.headingSmall)
                            .foregroundColor(HealthColors.primaryText)
                        
                        Text("SuperOne Health is your personal AI-powered health analysis companion. Upload your lab reports and get instant insights, trends analysis, and personalized health recommendations.")
                            .font(HealthTypography.body)
                            .foregroundColor(HealthColors.primaryText)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(HealthSpacing.lg)
                    .background(HealthColors.secondaryBackground)
                    .cornerRadius(HealthCornerRadius.card)
                    
                    // Features
                    VStack(alignment: .leading, spacing: HealthSpacing.md) {
                        Text("Key Features")
                            .font(HealthTypography.headingSmall)
                            .foregroundColor(HealthColors.primaryText)
                        
                        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                            FeatureRow(icon: "doc.text.magnifyingglass", text: "AI-powered document analysis")
                            FeatureRow(icon: "heart.text.square", text: "Biomarker extraction and tracking")
                            FeatureRow(icon: "brain.head.profile", text: "Personalized health insights")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Health trends monitoring")
                            FeatureRow(icon: "figure.mixed.cardio", text: "HealthKit integration")
                            FeatureRow(icon: "lock.shield", text: "End-to-end encryption")
                        }
                    }
                    .padding(HealthSpacing.lg)
                    .background(HealthColors.secondaryBackground)
                    .cornerRadius(HealthCornerRadius.card)
                    
                    // Legal and credits
                    VStack(spacing: HealthSpacing.md) {
                        Button("Privacy Policy") {
                            // Privacy policy view will be implemented
                        }
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primary)
                        
                        Button("Terms of Service") {
                            // Terms of service view will be implemented
                        }
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primary)
                        
                        Button("Open Source Licenses") {
                            // Open source licenses view will be implemented
                        }
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primary)
                    }
                    
                    // Copyright
                    VStack(spacing: HealthSpacing.sm) {
                        Text("© 2025 SuperOne Health")
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.secondaryText)
                        
                        Text("Made with ❤️ for better health")
                            .font(HealthTypography.captionRegular)
                            .foregroundColor(HealthColors.secondaryText)
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .padding(.bottom, HealthSpacing.xl)
            }
            .navigationTitle("About")
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

// MARK: - Supporting Views

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(HealthColors.primary)
                .frame(width: 20)
            
            Text(text)
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
        }
    }
}

#Preview {
    AboutSheet()
}