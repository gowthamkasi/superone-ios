//
//  BiomarkerTrendsChart.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI
import Charts

/// Chart view for displaying biomarker trends over time
struct BiomarkerTrendsChart: View {
    let trends: [String: [BiomarkerTrendData]]
    let timeRange: HealthTrendTimeRange
    
    @State private var selectedBiomarker: String?
    @State private var showingBiomarkerSelection = false
    
    var body: some View {
        VStack(spacing: HealthSpacing.md) {
            // Chart header with biomarker selector
            chartHeader
            
            // Main chart content
            if trends.isEmpty {
                emptyStateView
            } else if let selectedData = selectedTrendData {
                trendChart(for: selectedData)
            } else {
                emptyStateView
            }
        }
        .onAppear {
            // Select first biomarker by default
            if selectedBiomarker == nil, let firstBiomarker = trends.keys.first {
                selectedBiomarker = firstBiomarker
            }
        }
    }
    
    // MARK: - Chart Header
    
    private var chartHeader: some View {
        HStack {
            Text("Trends")
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
            
            if !trends.isEmpty {
                Button(selectedBiomarker ?? "Select Biomarker") {
                    showingBiomarkerSelection = true
                }
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primary)
                .actionSheet(isPresented: $showingBiomarkerSelection) {
                    biomarkerSelectionSheet
                }
            }
        }
    }
    
    // MARK: - Chart Content
    
    private func trendChart(for data: [BiomarkerTrendData]) -> some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .foregroundStyle(trendLineColor(for: point))
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [trendLineColor(for: point).opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            PointMark(
                x: .value("Date", point.date),
                y: .value("Value", point.value)
            )
            .foregroundStyle(trendLineColor(for: point))
            .symbolSize(30)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: chartXAxisStride)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 150)
        .padding(.horizontal, HealthSpacing.md)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: HealthSpacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(HealthColors.secondaryText)
            
            Text("No Trend Data Available")
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.secondaryText)
            
            Text("Upload more lab reports to see biomarker trends")
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
    }
    
    // MARK: - Biomarker Selection
    
    private var biomarkerSelectionSheet: ActionSheet {
        let buttons = trends.keys.map { biomarkerName in
            ActionSheet.Button.default(Text(biomarkerName)) {
                selectedBiomarker = biomarkerName
            }
        }
        
        return ActionSheet(
            title: Text("Select Biomarker"),
            buttons: buttons + [ActionSheet.Button.cancel()]
        )
    }
    
    // MARK: - Helper Properties
    
    private var selectedTrendData: [BiomarkerTrendData]? {
        guard let selectedBiomarker = selectedBiomarker else { return nil }
        return trends[selectedBiomarker]
    }
    
    private var chartXAxisStride: Int {
        switch timeRange {
        case .lastMonth:
            return 7 // Weekly marks
        case .last3Months:
            return 14 // Bi-weekly marks
        case .last6Months:
            return 30 // Monthly marks
        case .lastYear:
            return 60 // Bi-monthly marks
        }
    }
    
    private func trendLineColor(for point: BiomarkerTrendData) -> Color {
        switch point.status {
        case .optimal:
            return HealthColors.healthExcellent
        case .normal:
            return HealthColors.healthGood
        case .borderline:
            return HealthColors.healthWarning
        case .abnormal:
            return HealthColors.healthCritical
        case .high:
            return HealthColors.healthWarning
        case .low:
            return HealthColors.healthWarning
        case .critical:
            return Color.red
        case .unknown:
            return HealthColors.healthNeutral
        }
    }
}

// MARK: - Trend Summary Card

struct TrendSummaryCard: View {
    let biomarkerName: String
    let currentValue: Double
    let previousValue: Double?
    let unit: String
    let status: BiomarkerStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            Text(biomarkerName)
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.secondaryText)
            
            HStack(alignment: .bottom) {
                Text(String(format: "%.1f", currentValue))
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(statusColor)
                
                Text(unit)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                
                Spacer()
                
                if let previous = previousValue {
                    trendIndicator(current: currentValue, previous: previous)
                }
            }
            
            statusBadge
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.primaryBackground)
        .cornerRadius(HealthCornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: HealthCornerRadius.sm)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        switch status {
        case .optimal: return HealthColors.healthExcellent
        case .normal: return HealthColors.healthGood
        case .borderline: return HealthColors.healthWarning
        case .abnormal: return HealthColors.healthCritical
        case .high: return HealthColors.healthWarning
        case .low: return HealthColors.healthWarning
        case .critical: return Color.red
        case .unknown: return HealthColors.healthNeutral
        }
    }
    
    private var statusBadge: some View {
        Text(status.rawValue.capitalized)
            .font(HealthTypography.captionSmall)
            .foregroundColor(statusColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.1))
            .cornerRadius(4)
    }
    
    private func trendIndicator(current: Double, previous: Double) -> some View {
        let change = current - previous
        let changePercentage = (change / previous) * 100
        
        let isImproving = (status == .optimal || status == .normal) ? change >= 0 : change <= 0
        
        return HStack(spacing: 2) {
            Image(systemName: isImproving ? "arrow.up" : "arrow.down")
                .font(.caption2)
                .foregroundColor(isImproving ? HealthColors.healthGood : HealthColors.healthCritical)
            
            Text(String(format: "%.1f%%", abs(changePercentage)))
                .font(HealthTypography.captionSmall)
                .foregroundColor(isImproving ? HealthColors.healthGood : HealthColors.healthCritical)
        }
    }
}

// MARK: - Multiple Biomarkers Trend View

struct MultipleBiomarkersTrendView: View {
    let trends: [String: [BiomarkerTrendData]]
    let selectedBiomarkers: [String]
    
    var body: some View {
        Chart {
            ForEach(selectedBiomarkers, id: \.self) { biomarkerName in
                if let data = trends[biomarkerName] {
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value),
                            series: .value("Biomarker", biomarkerName)
                        )
                        .foregroundStyle(by: .value("Biomarker", biomarkerName))
                    }
                }
            }
        }
        .chartLegend(position: .bottom)
        .frame(height: 200)
    }
}

// MARK: - Preview

#Preview("Single Biomarker") {
    let mockTrends: [String: [BiomarkerTrendData]] = [
        "Hemoglobin": [
            BiomarkerTrendData(date: Date().addingTimeInterval(-86400 * 30), value: 13.5, status: .normal, isOptimal: true),
            BiomarkerTrendData(date: Date().addingTimeInterval(-86400 * 20), value: 14.2, status: .optimal, isOptimal: true),
            BiomarkerTrendData(date: Date().addingTimeInterval(-86400 * 10), value: 14.8, status: .optimal, isOptimal: true),
            BiomarkerTrendData(date: Date(), value: 15.1, status: .optimal, isOptimal: true)
        ],
        "Cholesterol": [
            BiomarkerTrendData(date: Date().addingTimeInterval(-86400 * 30), value: 220, status: .borderline, isOptimal: false),
            BiomarkerTrendData(date: Date().addingTimeInterval(-86400 * 20), value: 210, status: .normal, isOptimal: true),
            BiomarkerTrendData(date: Date().addingTimeInterval(-86400 * 10), value: 195, status: .optimal, isOptimal: true),
            BiomarkerTrendData(date: Date(), value: 185, status: .optimal, isOptimal: true)
        ]
    ]
    
    VStack {
        BiomarkerTrendsChart(
            trends: mockTrends,
            timeRange: .last3Months
        )
        
        TrendSummaryCard(
            biomarkerName: "Hemoglobin",
            currentValue: 15.1,
            previousValue: 14.8,
            unit: "g/dL",
            status: .optimal
        )
    }
    .padding()
    .background(HealthColors.secondaryBackground)
}