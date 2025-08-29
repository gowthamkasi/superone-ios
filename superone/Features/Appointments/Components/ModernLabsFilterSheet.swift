//
//  ModernLabsFilterSheet.swift
//  SuperOne
//
//  Modern hotel booking-style filter interface for lab facilities
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Modern labs filter sheet with hotel booking app styling
struct ModernLabsFilterSheet: View {
    @Bindable var viewModel: AppointmentsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var hasChanges = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                    
                    // Distance Section with Slider
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        DistanceSliderView(distanceValue: $viewModel.distanceSliderValue)
                            .onChange(of: viewModel.distanceSliderValue) { _, _ in
                                hasChanges = true
                            }
                    }
                    
                    // Divider
                    Divider()
                        .background(HealthColors.border)
                    
                    // Lab Features - Grouped Chips
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        ModernFilterChipGrid(
                            selectedFeatures: viewModel.selectedLabFeatures,
                            onFeatureToggle: { feature in
                                viewModel.toggleLabFeature(feature)
                                hasChanges = true
                                HapticFeedback.soft()
                            }
                        )
                    }
                    
                    // Divider
                    Divider()
                        .background(HealthColors.border)
                    
                    // Rating Section with Stars
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        StarRatingSelector(selectedRating: $viewModel.selectedMinimumRating)
                            .onChange(of: viewModel.selectedMinimumRating) { _, _ in
                                hasChanges = true
                            }
                    }
                    
                    // Active Filters Summary (if any)
                    if viewModel.hasActiveFilters {
                        // Divider
                        Divider()
                            .background(HealthColors.border)
                        
                        ActiveFiltersSummary(viewModel: viewModel)
                    }
                    
                    // Bottom spacing for sheet
                    Spacer(minLength: HealthSpacing.xl)
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .padding(.top, HealthSpacing.lg)
                .padding(.bottom, HealthSpacing.xl)
            }
            .background(HealthColors.background)
            .navigationTitle("Filter Labs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        if viewModel.hasActiveFilters {
                            showResetConfirmation = true
                        }
                    }
                    .font(HealthTypography.buttonSecondary)
                    .foregroundColor(viewModel.hasActiveFilters ? HealthColors.healthCritical : HealthColors.secondaryText)
                    .disabled(!viewModel.hasActiveFilters)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        if hasChanges {
                            viewModel.applyLabFilters()
                            HapticFeedback.success()
                        }
                        dismiss()
                    }
                    .font(hasChanges ? HealthTypography.buttonPrimary : HealthTypography.buttonSecondary)
                    .foregroundColor(HealthColors.primary)
                }
            }
            .confirmationDialog(
                "Reset all filters?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset All Filters", role: .destructive) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.resetLabFilters()
                        hasChanges = true
                    }
                    HapticFeedback.light()
                }
                
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear all active filter selections and show all available labs.")
            }
        }
    }
}

/// Active filters summary component
struct ActiveFiltersSummary: View {
    let viewModel: AppointmentsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Text("Active Filters")
                    .font(HealthTypography.headline)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                Text("\(activeFilterCount) active")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                    .padding(.horizontal, HealthSpacing.sm)
                    .padding(.vertical, HealthSpacing.xs)
                    .background(HealthColors.primary.opacity(0.1))
                    .cornerRadius(HealthCornerRadius.sm)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HealthSpacing.sm) {
                    // Distance filter summary
                    if viewModel.selectedDistanceFilter != .any {
                        ActiveFilterChip(
                            title: "Within \(formattedDistance(viewModel.distanceSliderValue))",
                            icon: "location"
                        )
                    }
                    
                    // Feature filters summary
                    ForEach(Array(viewModel.selectedLabFeatures), id: \.self) { feature in
                        ActiveFilterChip(
                            title: feature.shortDisplayName,
                            icon: feature.icon
                        )
                    }
                    
                    // Rating filter summary
                    if viewModel.selectedMinimumRating != .any {
                        ActiveFilterChip(
                            title: viewModel.selectedMinimumRating.shortDisplayText,
                            icon: "star.fill"
                        )
                    }
                }
                .padding(.horizontal, 1) // Prevent clipping
            }
        }
    }
    
    // MARK: - Private Computed Properties
    
    private var activeFilterCount: Int {
        var count = 0
        
        if viewModel.selectedDistanceFilter != .any {
            count += 1
        }
        
        count += viewModel.selectedLabFeatures.count
        
        if viewModel.selectedMinimumRating != .any {
            count += 1
        }
        
        return count
    }
    
    private func formattedDistance(_ distance: Double) -> String {
        if distance < 1.0 {
            return "\(Int(distance * 1000)) m"
        } else if distance == floor(distance) {
            return "\(Int(distance)) km"
        } else {
            return String(format: "%.1f km", distance)
        }
    }
}

/// Individual active filter chip
struct ActiveFilterChip: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: HealthSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(HealthColors.primary)
            
            Text(title)
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.primary)
        }
        .padding(.horizontal, HealthSpacing.sm)
        .padding(.vertical, HealthSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                .fill(HealthColors.primary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                        .strokeBorder(HealthColors.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview("Modern Labs Filter") {
    ModernLabsFilterSheet(viewModel: AppointmentsViewModel())
}

#Preview("Modern Labs Filter - With Filters") {
    let viewModel = AppointmentsViewModel()
    viewModel.distanceSliderValue = 10.0
    viewModel.selectedLabFeatures = [.walkInsAccepted, .digitalReports]
    viewModel.selectedMinimumRating = .fourPointZeroPlus
    
    return ModernLabsFilterSheet(viewModel: viewModel)
}