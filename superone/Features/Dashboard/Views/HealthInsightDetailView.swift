//
//  HealthInsightDetailView.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI

/// Detailed view for displaying health insights with actionable recommendations
struct HealthInsightDetailView: View {
    let insight: HealthInsight
    @Environment(\.dismiss) private var dismiss
    
    @State private var isBookmarkingInsight = false
    @State private var isBookmarked = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                    // Header section
                    insightHeader
                    
                    // Priority and category info
                    insightMetadata
                    
                    // Main content
                    insightContent
                    
                    // Related biomarkers
                    if !insight.relatedBiomarkers.isEmpty {
                        relatedBiomarkersSection
                    }
                    
                    // Action recommendations
                    if insight.actionRequired {
                        actionRecommendationsSection
                    }
                    
                    // Additional resources
                    additionalResourcesSection
                }
                .padding(HealthSpacing.lg)
            }
            .navigationTitle("Health Insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        bookmarkButton
                        shareButton
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                HealthInsightShareSheet(insight: insight)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var insightHeader: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                priorityIndicator
                
                Spacer()
                
                if insight.actionRequired {
                    actionableBadge
                }
            }
            
            Text(insight.title)
                .font(HealthTypography.headingLarge)
                .foregroundColor(HealthColors.primaryText)
                .multilineTextAlignment(.leading)
        }
    }
    
    // MARK: - Metadata Section
    
    private var insightMetadata: some View {
        HStack(spacing: HealthSpacing.lg) {
            // Category info
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: categoryIcon)
                    .foregroundColor(HealthColors.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Category")
                        .font(HealthTypography.captionSmall)
                        .foregroundColor(HealthColors.secondaryText)
                    
                    Text(insight.category.displayName)
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primaryText)
                }
            }
            
            Spacer()
            
            // Priority info
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "flag.fill")
                    .foregroundColor(priorityColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Priority")
                        .font(HealthTypography.captionSmall)
                        .foregroundColor(HealthColors.secondaryText)
                    
                    Text(insight.severity.rawValue.capitalized)
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(priorityColor)
                }
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
    
    // MARK: - Content Section
    
    private var insightContent: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.lg) {
            Text("Description")
                .font(HealthTypography.headingMedium)
                .foregroundColor(HealthColors.primaryText)
            
            Text(insight.description)
                .font(HealthTypography.bodyRegular)
                .foregroundColor(HealthColors.primaryText)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Related Biomarkers Section
    
    private var relatedBiomarkersSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Related Biomarkers")
                .font(HealthTypography.headingMedium)
                .foregroundColor(HealthColors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: HealthSpacing.sm) {
                ForEach(insight.relatedBiomarkers, id: \.self) { biomarkerName in
                    BiomarkerChip(name: biomarkerName)
                }
            }
        }
    }
    
    // MARK: - Action Recommendations Section
    
    private var actionRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Recommended Actions")
                .font(HealthTypography.headingMedium)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                ActionRecommendationCard(
                    icon: "calendar",
                    title: "Schedule Follow-up",
                    description: "Book an appointment with your healthcare provider to discuss these findings",
                    action: {
                        // Navigate to appointment booking
                    }
                )
                
                ActionRecommendationCard(
                    icon: "plus.circle",
                    title: "Upload New Lab Report",
                    description: "Upload recent lab results to track progress on this insight",
                    action: {
                        // Navigate to lab report upload
                    }
                )
                
                if insight.severity == .critical {
                    ActionRecommendationCard(
                        icon: "phone.fill",
                        title: "Contact Healthcare Provider",
                        description: "This insight requires immediate attention from your doctor",
                        action: {
                            // Open emergency contact
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Additional Resources Section
    
    private var additionalResourcesSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Learn More")
                .font(HealthTypography.headingMedium)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                ResourceLinkCard(
                    icon: "book.fill",
                    title: "Understanding \(insight.category.displayName) Health",
                    description: "Learn about factors that affect your \(insight.category.displayName.lowercased()) health",
                    url: "https://example.com/health-education"
                )
                
                ResourceLinkCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Normal Range Guidelines",
                    description: "View reference ranges for biomarkers in this category",
                    url: "https://example.com/reference-ranges"
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var priorityIndicator: some View {
        HStack(spacing: HealthSpacing.sm) {
            Circle()
                .fill(priorityColor)
                .frame(width: 12, height: 12)
            
            Text("\(insight.severity.rawValue.capitalized) Priority")
                .font(HealthTypography.captionMedium)
                .foregroundColor(priorityColor)
        }
    }
    
    private var actionableBadge: some View {
        Text("Actionable")
            .font(HealthTypography.captionSmall)
            .foregroundColor(HealthColors.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(HealthColors.primary.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var bookmarkButton: some View {
        Button {
            toggleBookmark()
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundColor(HealthColors.primary)
        }
        .disabled(isBookmarkingInsight)
    }
    
    private var shareButton: some View {
        Button {
            showingShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(HealthColors.primary)
        }
    }
    
    // MARK: - Helper Properties
    
    private var priorityColor: Color {
        switch insight.severity {
        case .critical: return HealthColors.healthCritical
        case .warning: return HealthColors.healthWarning
        case .info: return HealthColors.primary
        }
    }
    
    private var categoryIcon: String {
        switch insight.category {
        case .cardiovascular: return "heart.fill"
        case .metabolic: return "flame.fill"
        case .hematology: return "drop.fill"
        default: return "pills.fill"
        }
    }
    
    // MARK: - Actions
    
    private func toggleBookmark() {
        isBookmarkingInsight = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isBookmarked.toggle()
            isBookmarkingInsight = false
        }
    }
}

// MARK: - Supporting Views

struct BiomarkerChip: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(HealthTypography.captionMedium)
            .foregroundColor(HealthColors.primary)
            .padding(.horizontal, HealthSpacing.sm)
            .padding(.vertical, 6)
            .background(HealthColors.primary.opacity(0.1))
            .cornerRadius(16)
            .lineLimit(1)
    }
}

struct ActionRecommendationCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HealthSpacing.md) {
                Image(systemName: icon)
                    .foregroundColor(HealthColors.primary)
                    .font(.title2)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                    Text(title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(HealthColors.secondaryText)
                    .font(.caption)
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.primaryBackground)
            .cornerRadius(HealthCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .stroke(HealthColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ResourceLinkCard: View {
    let icon: String
    let title: String
    let description: String
    let url: String
    
    var body: some View {
        Button {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: HealthSpacing.md) {
                Image(systemName: icon)
                    .foregroundColor(HealthColors.secondary)
                    .font(.title3)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                    Text(title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .foregroundColor(HealthColors.secondary)
                    .font(.caption)
            }
            .padding(HealthSpacing.md)
            .background(HealthColors.secondary.opacity(0.05))
            .cornerRadius(HealthCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HealthInsightShareSheet: View {
    let insight: HealthInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: HealthSpacing.xl) {
                Text("Share Health Insight")
                    .font(HealthTypography.headingMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("Share this insight with your healthcare provider or save it for your records.")
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: HealthSpacing.md) {
                    ShareOptionButton(
                        icon: "square.and.arrow.up",
                        title: "Share via Messages/Email",
                        action: {
                            // Share via system share sheet
                            dismiss()
                        }
                    )
                    
                    ShareOptionButton(
                        icon: "doc.on.doc",
                        title: "Copy to Clipboard",
                        action: {
                            UIPasteboard.general.string = shareText
                            dismiss()
                        }
                    )
                    
                    ShareOptionButton(
                        icon: "square.and.arrow.down",
                        title: "Export as PDF",
                        action: {
                            // Export insight as PDF
                            dismiss()
                        }
                    )
                }
                
                Spacer()
            }
            .padding(HealthSpacing.xl)
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
    
    private var shareText: String {
        """
        Health Insight: \(insight.title)
        
        Category: \(insight.category.displayName)
        Priority: \(insight.severity.rawValue.capitalized)
        
        \(insight.description)
        
        Related Biomarkers: \(insight.relatedBiomarkers.joined(separator: ", "))
        
        Generated by Super One Health App
        """
    }
}

struct ShareOptionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(HealthColors.primary)
                    .font(.title2)
                    .frame(width: 40)
                
                Text(title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.primaryBackground)
            .cornerRadius(HealthCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .stroke(HealthColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    let mockInsight = HealthInsight(
        id: "mock-insight-1",
        category: .cardiovascular,
        title: "Cholesterol Levels Need Attention",
        description: "Your recent lab results show elevated LDL cholesterol levels that exceed the recommended range. High LDL cholesterol is a significant risk factor for cardiovascular disease and should be addressed through dietary changes, exercise, and possibly medication. Consider reducing saturated fat intake and increasing fiber consumption.",
        severity: .warning,
        actionRequired: true,
        relatedBiomarkers: ["Total Cholesterol", "LDL Cholesterol", "HDL Cholesterol", "Triglycerides"]
    )
    
    HealthInsightDetailView(insight: mockInsight)
}