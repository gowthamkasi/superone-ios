//
//  SupportSheet.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI
import MessageUI

/// Sheet for contacting support and getting help
struct SupportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: SupportCategory = .general
    @State private var message: String = ""
    @State private var userEmail: String = ""
    @State private var showingMailCompose = false
    @State private var showingCopyAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: HealthSpacing.xl) {
                    // Header
                    VStack(spacing: HealthSpacing.md) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(HealthColors.primary)
                        
                        Text("How can we help?")
                            .font(HealthTypography.headingMedium)
                            .foregroundColor(HealthColors.primaryText)
                        
                        Text("Get support, report issues, or share feedback")
                            .font(HealthTypography.body)
                            .foregroundColor(HealthColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Quick help options
                    VStack(spacing: HealthSpacing.md) {
                        SupportOptionCard(
                            icon: "book.fill",
                            title: "FAQ & Guides",
                            subtitle: "Find answers to common questions",
                            action: {
                                // FAQ section will be implemented
                            }
                        )
                        
                        SupportOptionCard(
                            icon: "video.fill",
                            title: "Video Tutorials",
                            subtitle: "Learn how to use SuperOne",
                            action: {
                                // Video tutorials will be implemented
                            }
                        )
                        
                        SupportOptionCard(
                            icon: "message.fill",
                            title: "Community Forum",
                            subtitle: "Connect with other users",
                            action: {
                                // Community forum will be implemented
                            }
                        )
                    }
                    
                    // Contact form
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        Text("Contact Support")
                            .font(HealthTypography.headingSmall)
                            .foregroundColor(HealthColors.primaryText)
                        
                        VStack(spacing: HealthSpacing.md) {
                            // Category selection
                            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                                Text("Category")
                                    .font(HealthTypography.bodyMedium)
                                    .foregroundColor(HealthColors.primaryText)
                                
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(SupportCategory.allCases, id: \.self) { category in
                                        Text(category.displayName).tag(category)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                                Text("Your Email")
                                    .font(HealthTypography.bodyMedium)
                                    .foregroundColor(HealthColors.primaryText)
                                
                                TextField("Enter your email", text: $userEmail)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                            }
                            
                            // Message field
                            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                                Text("Message")
                                    .font(HealthTypography.bodyMedium)
                                    .foregroundColor(HealthColors.primaryText)
                                
                                TextEditor(text: $message)
                                    .frame(minHeight: 100)
                                    .padding(HealthSpacing.sm)
                                    .background(HealthColors.secondaryBackground)
                                    .cornerRadius(HealthCornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                                            .stroke(HealthColors.secondaryText.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(HealthSpacing.lg)
                        .background(HealthColors.secondaryBackground)
                        .cornerRadius(HealthCornerRadius.card)
                    }
                    
                    // Submit button
                    Button(action: sendSupportMessage) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Message")
                        }
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HealthSpacing.md)
                        .background(isFormValid ? HealthColors.primary : HealthColors.secondaryText)
                        .cornerRadius(HealthCornerRadius.button)
                    }
                    .disabled(!isFormValid)
                    
                    // Alternative contact methods
                    VStack(spacing: HealthSpacing.md) {
                        Text("Other ways to reach us")
                            .font(HealthTypography.headingSmall)
                            .foregroundColor(HealthColors.primaryText)
                        
                        VStack(spacing: HealthSpacing.sm) {
                            ContactMethodRow(
                                icon: "envelope.fill",
                                title: "Email",
                                value: "support@superonehealth.com",
                                action: {
                                    copyToClipboard("support@superonehealth.com")
                                }
                            )
                            
                            ContactMethodRow(
                                icon: "globe",
                                title: "Website",
                                value: "superonehealth.com/support",
                                action: {
                                    // Website navigation will be implemented
                                }
                            )
                            
                            ContactMethodRow(
                                icon: "person.2.fill",
                                title: "Live Chat",
                                value: "Available 9 AM - 6 PM PST",
                                action: {
                                    // Live chat will be implemented
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .padding(.bottom, HealthSpacing.xl)
            }
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Copied!", isPresented: $showingCopyAlert) {
                Button("OK") { }
            } message: {
                Text("Email address copied to clipboard")
            }
        }
    }
    
    private var isFormValid: Bool {
        !userEmail.isEmpty && !message.isEmpty && userEmail.contains("@")
    }
    
    private func sendSupportMessage() {
        // Support message sending will be implemented
        
        // Reset form
        message = ""
        userEmail = ""
        selectedCategory = .general
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        showingCopyAlert = true
    }
}

// MARK: - Supporting Views

struct SupportOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HealthSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(HealthColors.secondaryText)
                    .font(.system(size: 14))
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .healthCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContactMethodRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HealthSpacing.md) {
                Image(systemName: icon)
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(value)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Image(systemName: "doc.on.doc")
                    .foregroundColor(HealthColors.secondaryText)
                    .font(.system(size: 14))
            }
            .padding(.vertical, HealthSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Types

enum SupportCategory: String, CaseIterable {
    case general = "general"
    case technical = "technical"
    case billing = "billing"
    case feedback = "feedback"
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .technical: return "Technical"
        case .billing: return "Billing"
        case .feedback: return "Feedback"
        }
    }
}

#Preview {
    SupportSheet()
}