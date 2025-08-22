//
//  OCRSettingsView.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI

/// View for configuring OCR processing preferences and monitoring performance
struct OCRSettingsView: View {
    
    @StateObject private var smartOCRService = SmartOCRService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var preferBackendOCR = true
    @State private var allowFallback = true
    @State private var fallbackTimeout: Double = 30.0
    @State private var qualityThreshold: Double = 0.8
    @State private var showingPerformanceAnalytics = false
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                    // Current OCR method status
                    currentStatusSection
                    
                    // OCR method preferences
                    ocrPreferencesSection
                    
                    // Advanced settings
                    advancedSettingsSection
                    
                    // Performance analytics
                    performanceSection
                    
                    // Actions
                    actionsSection
                }
                .padding(HealthSpacing.lg)
            }
            .navigationTitle("OCR Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingPerformanceAnalytics) {
                OCRPerformanceAnalyticsView()
            }
            .alert("Reset Performance Data", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    smartOCRService.resetPerformanceTracking()
                }
            } message: {
                Text("This will clear all OCR performance tracking data. This action cannot be undone.")
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // MARK: - Current Status Section
    
    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Current OCR Method")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            CurrentOCRMethodCard(method: smartOCRService.currentOCRMethod)
        }
    }
    
    // MARK: - OCR Preferences Section
    
    private var ocrPreferencesSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("OCR Preferences")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                // Backend preference toggle
                SettingToggleCard(
                    title: "Prefer Cloud OCR",
                    subtitle: "Use AWS Textract for higher accuracy when available",
                    icon: "cloud.fill",
                    isOn: $preferBackendOCR
                )
                
                // Fallback toggle
                SettingToggleCard(
                    title: "Enable Local Fallback",
                    subtitle: "Use on-device Vision framework if cloud OCR fails",
                    icon: "iphone",
                    isOn: $allowFallback
                )
            }
        }
    }
    
    // MARK: - Advanced Settings Section
    
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Advanced Settings")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.lg) {
                // Fallback timeout
                SettingSliderCard(
                    title: "Fallback Timeout",
                    subtitle: "Time to wait before falling back to local OCR",
                    value: $fallbackTimeout,
                    range: 10...60,
                    unit: "seconds",
                    icon: "clock.fill"
                )
                
                // Quality threshold
                SettingSliderCard(
                    title: "Quality Threshold",
                    subtitle: "Minimum quality score to accept OCR results",
                    value: $qualityThreshold,
                    range: 0.5...1.0,
                    unit: "",
                    icon: "checkmark.seal.fill",
                    formatter: { String(format: "%.1f", $0) }
                )
            }
        }
    }
    
    // MARK: - Performance Section
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Performance")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            let analytics = smartOCRService.getPerformanceAnalytics()
            
            VStack(spacing: HealthSpacing.md) {
                OCRPerformanceSummaryCard(analytics: analytics)
                
                Button {
                    showingPerformanceAnalytics = true
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("View Detailed Analytics")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(HealthColors.primary)
                    .padding(HealthSpacing.md)
                    .background(HealthColors.secondaryBackground)
                    .cornerRadius(HealthCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Actions")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                // Test OCR methods
                Button {
                    testOCRMethods()
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(HealthColors.primary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Test OCR Methods")
                                .font(HealthTypography.bodyMedium)
                                .foregroundColor(HealthColors.primaryText)
                            
                            Text("Run a quick test to compare performance")
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(HealthColors.secondaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(HealthSpacing.md)
                    .background(HealthColors.primaryBackground)
                    .cornerRadius(HealthCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Reset performance data
                Button {
                    showingResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(HealthColors.healthWarning)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset Performance Data")
                                .font(HealthTypography.bodyMedium)
                                .foregroundColor(HealthColors.primaryText)
                            
                            Text("Clear all performance tracking data")
                                .font(HealthTypography.captionRegular)
                                .foregroundColor(HealthColors.secondaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(HealthSpacing.md)
                    .background(HealthColors.primaryBackground)
                    .cornerRadius(HealthCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentSettings() {
        // Load current settings from SmartOCRService
        preferBackendOCR = UserDefaults.standard.object(forKey: "preferBackendOCR") as? Bool ?? true
        allowFallback = UserDefaults.standard.object(forKey: "allowFallbackToLocal") as? Bool ?? true
        fallbackTimeout = UserDefaults.standard.object(forKey: "fallbackTimeout") as? Double ?? 30.0
        qualityThreshold = UserDefaults.standard.object(forKey: "qualityThreshold") as? Double ?? 0.8
    }
    
    private func saveSettings() {
        smartOCRService.configureOCRRouting(
            preferBackend: preferBackendOCR,
            allowFallback: allowFallback,
            timeout: fallbackTimeout,
            qualityThreshold: qualityThreshold
        )
        
        dismiss()
    }
    
    private func testOCRMethods() {
        // This would run a test with sample documents
    }
}

// MARK: - Supporting Views

struct CurrentOCRMethodCard: View {
    let method: OCRMethod
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .cornerRadius(HealthCornerRadius.sm)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(method.displayName)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .fontWeight(.semibold)
                
                Text(method.description)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.lg)
        .healthCardShadow()
    }
    
    private var iconName: String {
        switch method {
        case .awsTextract: return "cloud.fill"
        case .visionFramework: return "iphone"
        case .hybrid: return "arrow.triangle.merge"
        case .automatic: return "brain.head.profile"
        case .backend: return "cloud.fill"
        case .local: return "iphone"
        case .cloud: return "cloud.fill"
        }
    }
    
    private var iconColor: Color {
        switch method {
        case .awsTextract: return HealthColors.primary
        case .visionFramework: return HealthColors.secondary
        case .hybrid: return HealthColors.healthGood
        case .automatic: return HealthColors.healthExcellent
        case .backend: return HealthColors.primary
        case .local: return HealthColors.secondary
        case .cloud: return HealthColors.primary
        }
    }
}

struct SettingToggleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(HealthColors.primary)
                .font(.title3)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(subtitle)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(HealthColors.primary)
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.lg)
    }
}

struct SettingSliderCard: View {
    let title: String
    let subtitle: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let icon: String
    let formatter: ((Double) -> String)?
    
    init(
        title: String,
        subtitle: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        unit: String,
        icon: String,
        formatter: ((Double) -> String)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self._value = value
        self.range = range
        self.unit = unit
        self.icon = icon
        self.formatter = formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.md) {
                Image(systemName: icon)
                    .foregroundColor(HealthColors.primary)
                    .font(.title3)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text(subtitle)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(formattedValue)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primary)
                    .fontWeight(.semibold)
            }
            
            Slider(value: $value, in: range, step: range == 0.5...1.0 ? 0.1 : 1.0)
                .tint(HealthColors.primary)
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.lg)
    }
    
    private var formattedValue: String {
        if let formatter = formatter {
            return formatter(value) + (unit.isEmpty ? "" : " \(unit)")
        } else {
            return String(format: "%.0f", value) + (unit.isEmpty ? "" : " \(unit)")
        }
    }
}

struct OCRPerformanceSummaryCard: View {
    let analytics: OCRPerformanceAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Text("Performance Summary")
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(analytics.totalOperations) operations")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            HStack(spacing: HealthSpacing.lg) {
                PerformanceMetricItem(
                    title: "Cloud OCR",
                    successRate: analytics.backendSuccessRate,
                    avgTime: analytics.averageBackendTime,
                    color: HealthColors.primary
                )
                
                PerformanceMetricItem(
                    title: "Local OCR",
                    successRate: analytics.localSuccessRate,
                    avgTime: analytics.averageLocalTime,
                    color: HealthColors.secondary
                )
            }
            
            if analytics.recommendedMethod != .automatic {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(HealthColors.healthExcellent)
                        .font(.caption)
                    
                    Text("Recommended: \(analytics.recommendedMethod.displayName)")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.healthExcellent)
                }
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.lg)
    }
}

struct PerformanceMetricItem: View {
    let title: String
    let successRate: Double
    let avgTime: TimeInterval
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(HealthTypography.captionMedium)
                .foregroundColor(color)
                .fontWeight(.semibold)
            
            Text("\(Int(successRate * 100))% success")
                .font(HealthTypography.captionSmall)
                .foregroundColor(HealthColors.primaryText)
            
            Text(formatTime(avgTime))
                .font(HealthTypography.captionSmall)
                .foregroundColor(HealthColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        if time < 1 {
            return String(format: "%.1fs avg", time)
        } else {
            return String(format: "%.0fs avg", time)
        }
    }
}

// MARK: - OCR Performance Analytics View

struct OCRPerformanceAnalyticsView: View {
    @StateObject private var smartOCRService = SmartOCRService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: HealthSpacing.xl) {
                    let analytics = smartOCRService.getPerformanceAnalytics()
                    
                    // Overview cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: HealthSpacing.lg) {
                        AnalyticsCard(
                            title: "Total Operations",
                            value: "\(analytics.totalOperations)",
                            icon: "doc.text.fill",
                            color: HealthColors.primary
                        )
                        
                        AnalyticsCard(
                            title: "Cloud Operations",
                            value: "\(analytics.backendOperations)",
                            icon: "cloud.fill",
                            color: HealthColors.secondary
                        )
                        
                        AnalyticsCard(
                            title: "Local Operations",
                            value: "\(analytics.localOperations)",
                            icon: "iphone",
                            color: HealthColors.healthGood
                        )
                        
                        AnalyticsCard(
                            title: "Recommended",
                            value: analytics.recommendedMethod.displayName.components(separatedBy: " ").first ?? "",
                            icon: "star.fill",
                            color: HealthColors.healthExcellent
                        )
                    }
                    
                    // Detailed comparison
                    OCRComparisonChart(analytics: analytics)
                }
                .padding(HealthSpacing.lg)
            }
            .navigationTitle("OCR Analytics")
            .navigationBarTitleDisplayMode(.large)
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

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: HealthSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(HealthTypography.headingMedium)
                .foregroundColor(HealthColors.primaryText)
                .fontWeight(.bold)
            
            Text(title)
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(HealthSpacing.lg)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.lg)
    }
}

struct OCRComparisonChart: View {
    let analytics: OCRPerformanceAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.lg) {
            Text("Performance Comparison")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                ComparisonRow(
                    title: "Success Rate",
                    cloudValue: analytics.backendSuccessRate,
                    localValue: analytics.localSuccessRate,
                    formatter: { String(format: "%.1f%%", $0 * 100) }
                )
                
                ComparisonRow(
                    title: "Average Time",
                    cloudValue: analytics.averageBackendTime,
                    localValue: analytics.averageLocalTime,
                    formatter: { String(format: "%.1fs", $0) }
                )
                
                ComparisonRow(
                    title: "Average Quality",
                    cloudValue: analytics.averageBackendQuality,
                    localValue: analytics.averageLocalQuality,
                    formatter: { String(format: "%.2f", $0) }
                )
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.lg)
    }
}

struct ComparisonRow: View {
    let title: String
    let cloudValue: Double
    let localValue: Double
    let formatter: (Double) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            Text(title)
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primaryText)
            
            HStack {
                // Cloud OCR
                HStack(spacing: HealthSpacing.sm) {
                    Image(systemName: "cloud.fill")
                        .foregroundColor(HealthColors.primary)
                        .font(.caption)
                    
                    Text(formatter(cloudValue))
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Local OCR
                HStack(spacing: HealthSpacing.sm) {
                    Image(systemName: "iphone")
                        .foregroundColor(HealthColors.secondary)
                        .font(.caption)
                    
                    Text(formatter(localValue))
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OCRSettingsView()
}