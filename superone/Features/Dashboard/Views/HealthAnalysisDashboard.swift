//
//  HealthAnalysisDashboard.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI

/// Main dashboard view for displaying health analysis data and insights
struct HealthAnalysisDashboard: View {
    
    @State private var viewModel = HealthAnalysisViewModel()
    @State private var selectedTimeRange: HealthTrendTimeRange = .last3Months
    @State private var showingInsightDetail = false
    @State private var selectedInsight: HealthInsight?
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel
        NavigationView {
            ScrollView {
                LazyVStack(spacing: HealthSpacing.xl) {
                    // Health Score Overview
                    healthScoreSection
                    
                    // Critical Alerts (if any)
                    if viewModel.hasCriticalAlerts {
                        criticalAlertsSection
                    }
                    
                    // Category Assessments
                    categoryAssessmentsSection
                    
                    // Key Insights
                    keyInsightsSection
                    
                    // Biomarker Trends
                    biomarkerTrendsSection
                    
                    // Last Updated Info
                    lastUpdatedSection
                }
                .padding(HealthSpacing.lg)
            }
            .navigationTitle("Health Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
            .refreshable {
                await viewModel.refreshAnalysisData()
            }
            .alert("Health Analysis Error", isPresented: $bindableViewModel.showErrorAlert) {
                Button("OK") {
                    viewModel.showErrorAlert = false
                }
                Button("Retry") {
                    Task {
                        await viewModel.loadAnalysisData()
                    }
                }
            } message: {
                Text(viewModel.analysisError?.localizedDescription ?? "Unknown error occurred")
            }
            .sheet(item: $selectedInsight) { insight in
                HealthInsightDetailView(insight: insight)
            }
        }
    }
    
    // MARK: - Health Score Section
    
    private var healthScoreSection: some View {
        HealthAnalysisScoreCard(
            score: viewModel.overallHealthScore,
            scoreDescription: viewModel.healthScoreDescription,
            scoreColor: viewModel.healthScoreColor,
            trend: viewModel.healthScoreTrend,
            trendIcon: viewModel.trendIcon,
            trendColor: viewModel.trendColor,
            totalBiomarkers: viewModel.totalBiomarkersCount,
            optimalPercentage: viewModel.optimalBiomarkersPercentage,
            isLoading: viewModel.isLoadingAnalysis
        )
    }
    
    // MARK: - Critical Alerts Section
    
    private var criticalAlertsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Critical Alerts")
                .font(HealthTypography.headingMedium)
                .foregroundColor(HealthColors.primaryText)
            
            ForEach(viewModel.criticalAlerts) { alert in
                CriticalAlertCard(alert: alert)
            }
        }
    }
    
    // MARK: - Category Assessments Section
    
    private var categoryAssessmentsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Health Categories")
                .font(HealthTypography.headingMedium)
                .foregroundColor(HealthColors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: HealthSpacing.md) {
                ForEach(Array(viewModel.categoryAssessments.keys), id: \.self) { category in
                    if let assessment = viewModel.categoryAssessments[category] {
                        CategoryAssessmentCard(
                            category: category,
                            assessment: assessment
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Key Insights Section
    
    private var keyInsightsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Text("Key Insights")
                    .font(HealthTypography.headingMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                if viewModel.keyInsights.count > 3 {
                    Button("View All") {
                        // Navigate to full insights view
                    }
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                }
            }
            
            ForEach(viewModel.priorityInsights) { insight in
                InsightCard(insight: insight) {
                    selectedInsight = insight
                    showingInsightDetail = true
                }
            }
        }
    }
    
    // MARK: - Biomarker Trends Section
    
    private var biomarkerTrendsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Text("Biomarker Trends")
                    .font(HealthTypography.headingMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(HealthTrendTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            
            if viewModel.isLoadingTrends {
                ProgressView("Loading trends...")
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                BiomarkerTrendsChart(
                    trends: viewModel.recentBiomarkers,
                    timeRange: selectedTimeRange
                )
                .frame(height: 200)
            }
        }
        .onChange(of: selectedTimeRange) { oldValue, newValue in
            Task {
                await viewModel.loadBiomarkerTrends(for: newValue)
            }
        }
    }
    
    // MARK: - Last Updated Section
    
    private var lastUpdatedSection: some View {
        VStack(spacing: HealthSpacing.sm) {
            if let lastUpdated = viewModel.lastUpdated {
                Text("Last updated \(lastUpdated, style: .relative)")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            if viewModel.isDataStale {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(HealthColors.healthWarning)
                    Text("Data may be outdated. Pull to refresh.")
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.healthWarning)
                }
            }
        }
    }
    
    // MARK: - Refresh Button
    
    private var refreshButton: some View {
        Button {
            Task {
                await viewModel.refreshAnalysisData()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .foregroundColor(HealthColors.primary)
        }
        .disabled(viewModel.isRefreshing || viewModel.isLoadingAnalysis)
    }
}

// MARK: - Supporting Views

struct HealthAnalysisScoreCard: View {
    let score: Int
    let scoreDescription: String
    let scoreColor: Color
    let trend: TrendDirection
    let trendIcon: String
    let trendColor: Color
    let totalBiomarkers: Int
    let optimalPercentage: Double
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: HealthSpacing.lg) {
            if isLoading {
                ProgressView("Loading health score...")
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
            } else {
                // Main score display
                HStack {
                    VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                        Text("Health Score")
                            .font(HealthTypography.headingSmall)
                            .foregroundColor(HealthColors.secondaryText)
                        
                        HStack(alignment: .bottom, spacing: HealthSpacing.sm) {
                            Text("\(score)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(scoreColor)
                            
                            Text("/100")
                                .font(HealthTypography.headingMedium)
                                .foregroundColor(HealthColors.secondaryText)
                                .offset(y: -8)
                        }
                        
                        Text(scoreDescription)
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(scoreColor)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: HealthSpacing.sm) {
                        // Trend indicator
                        HStack {
                            Image(systemName: trendIcon)
                                .foregroundColor(trendColor)
                            Text(trend.displayText)
                                .font(HealthTypography.captionMedium)
                                .foregroundColor(trendColor)
                        }
                        
                        // Circular progress
                        HealthCircularProgressView(
                            progress: Double(score) / 100.0,
                            color: scoreColor,
                            size: 60
                        )
                    }
                }
                
                // Stats row
                HStack {
                    StatItem(
                        icon: "checkmark.circle.fill",
                        value: "\(Int(optimalPercentage * 100))%",
                        label: "Optimal",
                        color: HealthColors.healthGood
                    )
                    
                    Spacer()
                    
                    StatItem(
                        icon: "chart.line.uptrend.xyaxis",
                        value: "\(totalBiomarkers)",
                        label: "Biomarkers",
                        color: HealthColors.primary
                    )
                }
            }
        }
        .padding(HealthSpacing.xl)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.lg)
        .healthCardShadow()
    }
}

struct CategoryAssessmentCard: View {
    let category: BackendHealthCategory
    let assessment: CategoryHealthAssessment
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
                    .font(.title2)
                
                Spacer()
                
                Text("\(assessment.score)")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(categoryColor)
            }
            
            Text(category.displayName)
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primaryText)
                .lineLimit(1)
            
            Text(assessment.status.rawValue.capitalized)
                .font(HealthTypography.captionMedium)
                .foregroundColor(categoryColor)
            
            ProgressView(value: Double(assessment.score) / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: categoryColor))
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.md)
        .healthCardShadow()
    }
    
    private var categoryIcon: String {
        switch category {
        case .cardiovascular: return "heart.fill"
        case .metabolic: return "flame.fill"
        case .hematology: return "drop.fill"
        default: return "pills.fill"
        }
    }
    
    private var categoryColor: Color {
        switch assessment.status {
        case .excellent: return HealthColors.healthExcellent
        case .good, .normal: return HealthColors.healthGood
        case .fair, .monitor: return HealthColors.healthWarning
        case .needsAttention, .poor, .critical: return HealthColors.healthCritical
        }
    }
}

struct InsightCard: View {
    let insight: HealthInsight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: HealthSpacing.md) {
                VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                    Text(insight.title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(insight.description)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack {
                    priorityIndicator
                    
                    if insight.actionRequired {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(HealthColors.primary)
                            .font(.caption)
                    }
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.primaryBackground)
            .cornerRadius(HealthCornerRadius.md)
            .healthCardShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityIndicator: some View {
        Circle()
            .fill(priorityColor)
            .frame(width: 8, height: 8)
    }
    
    private var priorityColor: Color {
        switch insight.severity {
        case .critical: return HealthColors.healthCritical
        case .warning: return HealthColors.healthWarning
        case .info: return HealthColors.primary
        }
    }
}

struct CriticalAlertCard: View {
    let alert: HealthAlert
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Image(systemName: alertIcon)
                .foregroundColor(alertColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: HealthSpacing.sm) {
                Text(alert.title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(alert.message)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if alert.actionRequired {
                Button("Action") {
                    // Handle alert action
                }
                .font(HealthTypography.captionMedium)
                .foregroundColor(alertColor)
            }
        }
        .padding(HealthSpacing.lg)
        .background(alertColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                .stroke(alertColor, lineWidth: 1)
        )
        .cornerRadius(HealthCornerRadius.md)
    }
    
    private var alertIcon: String {
        switch alert.severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private var alertColor: Color {
        switch alert.severity {
        case .critical: return HealthColors.healthCritical
        case .warning: return HealthColors.healthWarning
        case .info: return HealthColors.primary
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: HealthSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(label)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
        }
    }
}

struct HealthCircularProgressView: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
    }
}

// MARK: - Preview

#Preview {
    HealthAnalysisDashboard()
        .preferredColorScheme(.light)
}