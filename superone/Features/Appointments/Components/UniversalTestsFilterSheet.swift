//
//  UniversalTestsFilterSheet.swift
//  SuperOne
//
//  Tests filter implementation using the Universal Filter Sheet component
//  Replaces the basic TestsFilterSheet with consistent universal architecture
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Tests filter sheet using the universal filter component architecture
struct UniversalTestsFilterSheet: View {
    @Bindable var viewModel: AppointmentsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var hasChanges = false
    
    // Test filter state (this would typically be in the view model)
    @State private var selectedTestCategories: Set<FilterTestCategory> = []
    @State private var selectedPriceRanges: Set<PriceRange> = []
    @State private var selectedRequirements: Set<TestRequirement> = []
    
    var body: some View {
        UniversalFilterSheet.withResetConfirmation(
            title: "Filter Tests",
            hasActiveFilters: hasActiveTestFilters,
            hasChanges: hasChanges,
            canReset: hasActiveTestFilters,
            activeFiltersContent: hasActiveTestFilters ? {
                AnyView(
                    UniversalActiveFiltersSummary(
                        title: "Active Filters",
                        activeFilterCount: activeTestFilterCount,
                        filtersContent: {
                            // Category filter chips
                            ForEach(Array(selectedTestCategories), id: \.self) { category in
                                UniversalActiveFilterChip(
                                    title: category.displayName,
                                    icon: category.icon
                                )
                            }
                            
                            // Price range filter chips
                            ForEach(Array(selectedPriceRanges), id: \.self) { priceRange in
                                UniversalActiveFilterChip(
                                    title: priceRange.displayName,
                                    icon: "indianrupeesign"
                                )
                            }
                            
                            // Requirement filter chips
                            ForEach(Array(selectedRequirements), id: \.self) { requirement in
                                UniversalActiveFilterChip(
                                    title: requirement.displayName,
                                    icon: requirement.icon
                                )
                            }
                        }
                    )
                )
            } : nil,
            filterContent: {
                VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                    // Test Categories Section
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        UniversalFilterSectionHeader(
                            "Test Categories",
                            subtitle: "Select the types of tests you're interested in"
                        )
                        
                        UniversalFilterChipsContainer(columns: 2) {
                            ForEach(FilterTestCategory.allCases, id: \.self) { category in
                                TestCategoryFilterChip(
                                    category: category,
                                    isSelected: selectedTestCategories.contains(category)
                                ) {
                                    toggleTestCategory(category)
                                }
                            }
                        }
                    }
                    
                    // Divider
                    Divider()
                        .background(HealthColors.border)
                    
                    // Price Range Section
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        UniversalFilterSectionHeader(
                            "Price Range",
                            subtitle: "Choose your preferred price range"
                        )
                        
                        UniversalVerticalFilterChips {
                            ForEach(PriceRange.allCases, id: \.self) { priceRange in
                                PriceRangeFilterChip(
                                    priceRange: priceRange,
                                    isSelected: selectedPriceRanges.contains(priceRange)
                                ) {
                                    togglePriceRange(priceRange)
                                }
                            }
                        }
                    }
                    
                    // Divider
                    Divider()
                        .background(HealthColors.border)
                    
                    // Test Requirements Section
                    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
                        UniversalFilterSectionHeader(
                            "Test Requirements",
                            subtitle: "Special requirements or preferences"
                        )
                        
                        UniversalVerticalFilterChips {
                            ForEach(TestRequirement.allCases, id: \.self) { requirement in
                                TestRequirementFilterChip(
                                    requirement: requirement,
                                    isSelected: selectedRequirements.contains(requirement)
                                ) {
                                    toggleTestRequirement(requirement)
                                }
                            }
                        }
                    }
                }
            },
            onResetConfirmed: {
                resetAllTestFilters()
                hasChanges = true
            },
            onApply: {
                if hasChanges {
                    applyTestFilters()
                    HapticFeedback.success()
                }
                dismiss()
            },
            resetConfirmationMessage: "This will clear all test filter selections and show all available tests."
        )
    }
    
    // MARK: - Helper Methods
    
    private func toggleTestCategory(_ category: FilterTestCategory) {
        if selectedTestCategories.contains(category) {
            selectedTestCategories.remove(category)
        } else {
            selectedTestCategories.insert(category)
        }
        hasChanges = true
        HapticFeedback.soft()
    }
    
    private func togglePriceRange(_ priceRange: PriceRange) {
        if selectedPriceRanges.contains(priceRange) {
            selectedPriceRanges.remove(priceRange)
        } else {
            selectedPriceRanges.insert(priceRange)
        }
        hasChanges = true
        HapticFeedback.soft()
    }
    
    private func toggleTestRequirement(_ requirement: TestRequirement) {
        if selectedRequirements.contains(requirement) {
            selectedRequirements.remove(requirement)
        } else {
            selectedRequirements.insert(requirement)
        }
        hasChanges = true
        HapticFeedback.soft()
    }
    
    private func resetAllTestFilters() {
        selectedTestCategories.removeAll()
        selectedPriceRanges.removeAll()
        selectedRequirements.removeAll()
    }
    
    private func applyTestFilters() {
        // Apply filters to the view model
        // This would typically be implemented in the view model
    }
    
    // MARK: - Computed Properties
    
    private var hasActiveTestFilters: Bool {
        !selectedTestCategories.isEmpty || !selectedPriceRanges.isEmpty || !selectedRequirements.isEmpty
    }
    
    private var activeTestFilterCount: Int {
        selectedTestCategories.count + selectedPriceRanges.count + selectedRequirements.count
    }
}

// MARK: - Filter Data Models

enum FilterTestCategory: String, CaseIterable {
    case bloodTests = "blood_tests"
    case heartHealth = "heart_health"
    case diabetes = "diabetes"
    case thyroid = "thyroid"
    case liverFunction = "liver_function"
    case kidneyFunction = "kidney_function"
    case vitamins = "vitamins"
    case hormones = "hormones"
    
    var displayName: String {
        switch self {
        case .bloodTests: return "Blood Tests"
        case .heartHealth: return "Heart Health"
        case .diabetes: return "Diabetes"
        case .thyroid: return "Thyroid"
        case .liverFunction: return "Liver Function"
        case .kidneyFunction: return "Kidney Function"
        case .vitamins: return "Vitamins"
        case .hormones: return "Hormones"
        }
    }
    
    var icon: String {
        switch self {
        case .bloodTests: return "drop.fill"
        case .heartHealth: return "heart.fill"
        case .diabetes: return "cross.fill"
        case .thyroid: return "lungs.fill"
        case .liverFunction: return "oval.fill"
        case .kidneyFunction: return "kidney.fill"
        case .vitamins: return "pills.fill"
        case .hormones: return "brain.filled"
        }
    }
}

enum PriceRange: String, CaseIterable {
    case under500 = "under_500"
    case range500to1000 = "500_to_1000"
    case range1000to2000 = "1000_to_2000"
    case above2000 = "above_2000"
    
    var displayName: String {
        switch self {
        case .under500: return "Under ₹500"
        case .range500to1000: return "₹500 - ₹1000"
        case .range1000to2000: return "₹1000 - ₹2000"
        case .above2000: return "Above ₹2000"
        }
    }
}

enum TestRequirement: String, CaseIterable {
    case noFasting = "no_fasting"
    case fastingRequired = "fasting_required"
    case sameDayResults = "same_day_results"
    case homeCollection = "home_collection"
    
    var displayName: String {
        switch self {
        case .noFasting: return "No Fasting Required"
        case .fastingRequired: return "Fasting Required"
        case .sameDayResults: return "Same Day Results"
        case .homeCollection: return "Home Collection Available"
        }
    }
    
    var icon: String {
        switch self {
        case .noFasting: return "clock.badge.xmark"
        case .fastingRequired: return "clock.badge.checkmark"
        case .sameDayResults: return "timer"
        case .homeCollection: return "house.fill"
        }
    }
}

// MARK: - Filter Chip Components

struct TestCategoryFilterChip: View {
    let category: FilterTestCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                
                Text(category.displayName)
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .fill(isSelected ? HealthColors.primary.opacity(0.1) : HealthColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                            .strokeBorder(
                                isSelected ? HealthColors.primary.opacity(0.3) : HealthColors.border,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PriceRangeFilterChip: View {
    let priceRange: PriceRange
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "indianrupeesign")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                
                Text(priceRange.displayName)
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .fill(isSelected ? HealthColors.primary.opacity(0.1) : HealthColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                            .strokeBorder(
                                isSelected ? HealthColors.primary.opacity(0.3) : HealthColors.border,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TestRequirementFilterChip: View {
    let requirement: TestRequirement
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: requirement.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                
                Text(requirement.displayName)
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .fill(isSelected ? HealthColors.primary.opacity(0.1) : HealthColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                            .strokeBorder(
                                isSelected ? HealthColors.primary.opacity(0.3) : HealthColors.border,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Universal Tests Filter - Empty") {
    UniversalTestsFilterSheet(viewModel: AppointmentsViewModel())
}

#Preview("Universal Tests Filter - With Selections") {
    UniversalTestsFilterSheet(viewModel: AppointmentsViewModel())
}