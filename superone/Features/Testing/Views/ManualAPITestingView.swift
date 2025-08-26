//
//  ManualAPITestingView.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Comprehensive manual API testing interface for the Super One iOS app
//

import SwiftUI

/// Main manual API testing interface with full-page navigation
struct ManualAPITestingView: View {
    
    @State private var selectedTab = 0
    @StateObject private var testingService = APITestingService()
    @Environment(\.dismiss) private var dismiss
    
    private let tabs = [
        APITestingTab(id: 0, title: "Auth", icon: "key.fill", color: HealthColors.primary),
        APITestingTab(id: 1, title: "LabLoop", icon: "building.2.fill", color: HealthColors.healthGood),
        APITestingTab(id: 2, title: "Health", icon: "heart.fill", color: HealthColors.healthExcellent),
        APITestingTab(id: 3, title: "Reports", icon: "doc.text.fill", color: HealthColors.healthWarning),
        APITestingTab(id: 4, title: "Upload", icon: "arrow.up.circle.fill", color: HealthColors.healthCritical)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with title and status
                headerSection
                
                // Tab Navigation
                tabSelectionView
                
                // Content Area
                contentArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(HealthColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(HealthColors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Clear All Results") {
                            testingService.clearAllResults()
                        }
                        
                        Button("Export Test Results") {
                            testingService.exportResults()
                        }
                        
                        Button("Import Test Configuration") {
                            testingService.importConfiguration()
                        }
                        
                        Divider()
                        
                        Button("Reset to Defaults") {
                            testingService.resetToDefaults()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(HealthColors.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: HealthSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text("API Testing Console")
                        .font(HealthTypography.headingLarge)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text("Manual testing for all Super One endpoints")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                Spacer()
                
                // Status indicator
                statusIndicator
            }
            
            // Quick stats bar
            quickStatsBar
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
        .padding(.vertical, HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
    }
    
    private var statusIndicator: some View {
        VStack(alignment: .trailing, spacing: HealthSpacing.xs) {
            HStack(spacing: HealthSpacing.xs) {
                Circle()
                    .fill(testingService.isConnected ? HealthColors.healthGood : HealthColors.healthCritical)
                    .frame(width: 8, height: 8)
                
                Text(testingService.isConnected ? "Connected" : "Offline")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(testingService.isConnected ? HealthColors.healthGood : HealthColors.healthCritical)
            }
            
            Text("v\(testingService.apiVersion)")
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.secondaryText)
        }
    }
    
    private var quickStatsBar: some View {
        HStack(spacing: HealthSpacing.lg) {
            APIStatItem(
                title: "Tests Run",
                value: "\(testingService.totalTestsRun)",
                color: HealthColors.primary
            )
            
            APIStatItem(
                title: "Success",
                value: "\(testingService.successfulTests)",
                color: HealthColors.healthGood
            )
            
            APIStatItem(
                title: "Failed",
                value: "\(testingService.failedTests)",
                color: HealthColors.healthCritical
            )
            
            Spacer()
            
            APIStatItem(
                title: "Avg Response",
                value: "\(Int(testingService.averageResponseTime))ms",
                color: HealthColors.secondaryText
            )
        }
    }
    
    // MARK: - Tab Selection
    
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HealthSpacing.sm) {
                ForEach(tabs, id: \.id) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab.id,
                        action: { selectedTab = tab.id }
                    )
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
        .padding(.vertical, HealthSpacing.md)
        .background(HealthColors.background)
    }
    
    // MARK: - Content Area
    
    private var contentArea: some View {
        TabView(selection: $selectedTab) {
            // Authentication Testing Tab
            AuthenticationTestingView()
                .environmentObject(testingService)
                .tag(0)
            
            // LabLoop Testing Tab  
            LabLoopTestingView()
                .environmentObject(testingService)
                .tag(1)
            
            // Health Analysis Testing Tab
            HealthAnalysisTestingView()
                .environmentObject(testingService)
                .tag(2)
            
            // Lab Reports Testing Tab
            LabReportsTestingView()
                .environmentObject(testingService)
                .tag(3)
            
            // Upload Testing Tab
            UploadTestingView()
                .environmentObject(testingService)
                .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
}

// MARK: - Supporting Views

struct APITestingTab {
    let id: Int
    let title: String
    let icon: String
    let color: Color
}

struct TabButton: View {
    let tab: APITestingTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: HealthSpacing.xs) {
                Image(systemName: tab.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? tab.color : HealthColors.secondaryText)
                
                Text(tab.title)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(isSelected ? tab.color : HealthColors.secondaryText)
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .fill(isSelected ? tab.color.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .strokeBorder(
                        isSelected ? tab.color : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct APIStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: HealthSpacing.xs) {
            Text(value)
                .font(HealthTypography.headingSmall)
                .foregroundColor(color)
            
            Text(title)
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.secondaryText)
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

struct LabLoopTestingView: View {
    @EnvironmentObject var testingService: APITestingService
    
    var body: some View {
        VStack {
            Text("LabLoop Testing")
                .font(HealthTypography.headingMedium)
            Text("Coming Soon - Phase 2")
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HealthColors.background)
    }
}

struct HealthAnalysisTestingView: View {
    @EnvironmentObject var testingService: APITestingService
    
    var body: some View {
        VStack {
            Text("Health Analysis Testing")
                .font(HealthTypography.headingMedium)
            Text("Coming Soon - Phase 3")
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HealthColors.background)
    }
}

struct LabReportsTestingView: View {
    @EnvironmentObject var testingService: APITestingService
    
    var body: some View {
        VStack {
            Text("Lab Reports Testing")
                .font(HealthTypography.headingMedium)
            Text("Coming Soon - Phase 3")
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HealthColors.background)
    }
}

struct UploadTestingView: View {
    @EnvironmentObject var testingService: APITestingService
    
    var body: some View {
        VStack {
            Text("Upload Testing")
                .font(HealthTypography.headingMedium)
            Text("Coming Soon - Phase 3")
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HealthColors.background)
    }
}

// MARK: - Preview

#Preview("Manual API Testing") {
    ManualAPITestingView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
}