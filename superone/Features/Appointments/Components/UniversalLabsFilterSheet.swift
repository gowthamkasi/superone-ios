//
//  UniversalLabsFilterSheet.swift
//  SuperOne
//
//  Labs filter implementation using the Universal Filter Sheet component
//  Demonstrates the migration from ModernLabsFilterSheet to universal architecture
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Labs filter sheet using the universal filter component architecture
struct UniversalLabsFilterSheet: View {
    @Bindable var viewModel: AppointmentsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var hasChanges = false
    
    var body: some View {
        UniversalFilterSheet.withResetConfirmation(
            title: "Filter Labs",
            hasActiveFilters: viewModel.hasActiveFilters,
            hasChanges: hasChanges,
            canReset: viewModel.hasActiveFilters,
            activeFiltersContent: viewModel.hasActiveFilters ? {
                AnyView(
                    UniversalActiveFiltersSummary(
                        title: "Active Filters",
                        activeFilterCount: activeFilterCount,
                        filtersContent: {
                            // Distance filter chip
                            if viewModel.selectedDistanceFilter != .any {
                                UniversalActiveFilterChip(
                                    title: "Within \(formattedDistance(viewModel.distanceSliderValue))",
                                    icon: "location"
                                )
                            }
                            
                            // Feature filter chips
                            ForEach(Array(viewModel.selectedLabFeatures), id: \.self) { feature in
                                UniversalActiveFilterChip(
                                    title: feature.shortDisplayName,
                                    icon: feature.icon
                                )
                            }
                            
                            // Rating filter chip
                            if viewModel.selectedMinimumRating != .any {
                                UniversalActiveFilterChip(
                                    title: viewModel.selectedMinimumRating.shortDisplayText,
                                    icon: "star.fill"
                                )
                            }
                        }
                    )
                )
            } : nil,
            filterContent: {
                VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                    // Distance Section
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        DistanceSliderView(distanceValue: $viewModel.distanceSliderValue)
                            .onChange(of: viewModel.distanceSliderValue) { _, _ in
                                hasChanges = true
                            }
                    }
                    
                    // Divider
                    Divider()
                        .background(HealthColors.border)
                    
                    // Lab Features Section
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
                    
                    // Rating Section
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        StarRatingSelector(selectedRating: $viewModel.selectedMinimumRating)
                            .onChange(of: viewModel.selectedMinimumRating) { _, _ in
                                hasChanges = true
                            }
                    }
                }
            },
            onResetConfirmed: {
                viewModel.resetLabFilters()
                hasChanges = true
            },
            onApply: {
                if hasChanges {
                    viewModel.applyLabFilters()
                    HapticFeedback.success()
                }
                dismiss()
            },
            resetConfirmationMessage: "This will clear all active filter selections and show all available labs."
        )
    }
    
    // MARK: - Helper Computed Properties
    
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

// MARK: - Preview

#Preview("Universal Labs Filter") {
    UniversalLabsFilterSheet(viewModel: AppointmentsViewModel())
}

#Preview("Universal Labs Filter - With Filters") {
    let viewModel = AppointmentsViewModel()
    viewModel.distanceSliderValue = 10.0
    viewModel.selectedLabFeatures = [.walkInsAccepted, .digitalReports]
    viewModel.selectedMinimumRating = .fourPointZeroPlus
    
    return UniversalLabsFilterSheet(viewModel: viewModel)
}