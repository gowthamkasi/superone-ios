//
//  UniversalFilterSheet.swift
//  SuperOne
//
//  Universal filter sheet component for consistent filter experiences across the entire app
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Universal filter sheet component that can be reused across the entire app for consistent filter experiences.
/// Based on the successful ModernLabsFilterSheet design with flexible content injection.
struct UniversalFilterSheet<Content: View>: View {
    // MARK: - Properties
    
    /// Title displayed in the navigation bar
    let title: String
    
    /// Whether there are currently active filters
    let hasActiveFilters: Bool
    
    /// Whether changes have been made since opening the sheet
    let hasChanges: Bool
    
    /// Whether the reset button should be enabled
    let canReset: Bool
    
    /// Optional content for displaying active filters at the top
    let activeFiltersContent: (() -> AnyView)?
    
    /// Main filter content builder
    @ViewBuilder let filterContent: () -> Content
    
    /// Callback when reset is requested
    let onReset: () -> Void
    
    /// Callback when apply is requested
    let onApply: () -> Void
    
    // MARK: - State
    
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                    
                    // Active Filters Section (conditional - shown at top for better UX)
                    if hasActiveFilters, let activeFiltersContent = activeFiltersContent {
                        activeFiltersContent()
                        
                        // Divider (only shown when active filters are present)
                        Divider()
                            .background(HealthColors.border)
                    }
                    
                    // Custom Filter Content
                    filterContent()
                    
                    // Bottom spacing for sheet
                    Spacer(minLength: HealthSpacing.xl)
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .padding(.top, HealthSpacing.lg)
                .padding(.bottom, HealthSpacing.xl)
            }
            .background(HealthColors.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        onReset()
                    }
                    .font(HealthTypography.buttonSecondary)
                    .foregroundColor(canReset ? HealthColors.healthCritical : HealthColors.secondaryText)
                    .disabled(!canReset)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                    }
                    .font(hasChanges ? HealthTypography.buttonPrimary : HealthTypography.buttonSecondary)
                    .foregroundColor(HealthColors.primary)
                }
            }
        }
    }
}

// MARK: - Universal Active Filter Components

/// Universal active filters summary component that can be customized for different filter types
struct UniversalActiveFiltersSummary<Content: View>: View {
    let title: String
    let activeFilterCount: Int
    @ViewBuilder let filtersContent: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Text(title)
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
                    filtersContent()
                }
                .padding(.horizontal, 1) // Prevent clipping
            }
        }
    }
}

/// Universal active filter chip component
struct UniversalActiveFilterChip: View {
    let title: String
    let icon: String
    let onRemove: (() -> Void)?
    
    init(title: String, icon: String, onRemove: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.onRemove = onRemove
    }
    
    var body: some View {
        HStack(spacing: HealthSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(HealthColors.primary)
            
            Text(title)
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.primary)
            
            // Optional remove button
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(HealthColors.primary)
                }
                .padding(.leading, HealthSpacing.xs)
            }
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

// MARK: - Universal Filter Section Components

/// Universal section header for filter categories
struct UniversalFilterSectionHeader: View {
    let title: String
    let subtitle: String?
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.xs) {
            Text(title)
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
        }
    }
}

/// Universal filter chips container with flexible layout
struct UniversalFilterChipsContainer<Content: View>: View {
    let columns: Int
    @ViewBuilder let content: () -> Content
    
    init(columns: Int = 2, @ViewBuilder content: @escaping () -> Content) {
        self.columns = columns
        self.content = content
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: columns),
            spacing: HealthSpacing.md
        ) {
            content()
        }
    }
}

/// Universal vertical filter chips container
struct UniversalVerticalFilterChips<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: HealthSpacing.sm) {
            content()
        }
    }
}

// MARK: - Convenience Extensions

extension UniversalFilterSheet {
    /// Convenience initializer for sheets with reset confirmation dialog
    static func withResetConfirmation(
        title: String,
        hasActiveFilters: Bool,
        hasChanges: Bool,
        canReset: Bool,
        activeFiltersContent: (() -> AnyView)? = nil,
        @ViewBuilder filterContent: @escaping () -> Content,
        onResetConfirmed: @escaping () -> Void,
        onApply: @escaping () -> Void,
        resetConfirmationTitle: String = "Reset all filters?",
        resetConfirmationMessage: String = "This will clear all active filter selections."
    ) -> some View {
        UniversalFilterSheetWithConfirmation(
            title: title,
            hasActiveFilters: hasActiveFilters,
            hasChanges: hasChanges,
            canReset: canReset,
            activeFiltersContent: activeFiltersContent,
            filterContent: filterContent,
            onResetConfirmed: onResetConfirmed,
            onApply: onApply,
            resetConfirmationTitle: resetConfirmationTitle,
            resetConfirmationMessage: resetConfirmationMessage
        )
    }
}

/// Universal filter sheet with built-in reset confirmation dialog
struct UniversalFilterSheetWithConfirmation<Content: View>: View {
    let title: String
    let hasActiveFilters: Bool
    let hasChanges: Bool
    let canReset: Bool
    let activeFiltersContent: (() -> AnyView)?
    @ViewBuilder let filterContent: () -> Content
    let onResetConfirmed: () -> Void
    let onApply: () -> Void
    let resetConfirmationTitle: String
    let resetConfirmationMessage: String
    
    @State private var showResetConfirmation = false
    
    var body: some View {
        UniversalFilterSheet(
            title: title,
            hasActiveFilters: hasActiveFilters,
            hasChanges: hasChanges,
            canReset: canReset,
            activeFiltersContent: activeFiltersContent,
            filterContent: filterContent,
            onReset: {
                if hasActiveFilters {
                    showResetConfirmation = true
                }
            },
            onApply: onApply
        )
        .confirmationDialog(
            resetConfirmationTitle,
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset All Filters", role: .destructive) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    onResetConfirmed()
                }
                HapticFeedback.light()
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(resetConfirmationMessage)
        }
    }
}

// MARK: - Preview

#Preview("Universal Filter Sheet - Empty") {
    UniversalFilterSheet(
        title: "Filter Example",
        hasActiveFilters: false,
        hasChanges: false,
        canReset: false,
        activeFiltersContent: nil,
        filterContent: {
            VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                UniversalFilterSectionHeader("Categories")
                
                UniversalFilterChipsContainer(columns: 2) {
                    ForEach(["Option 1", "Option 2", "Option 3", "Option 4"], id: \.self) { option in
                        Button(option) { }
                            .padding()
                            .background(HealthColors.background)
                            .cornerRadius(HealthCornerRadius.md)
                    }
                }
            }
        },
        onReset: { },
        onApply: { }
    )
}

#Preview("Universal Filter Sheet - With Active Filters") {
    UniversalFilterSheet(
        title: "Filter Example",
        hasActiveFilters: true,
        hasChanges: true,
        canReset: true,
        activeFiltersContent: {
            AnyView(
                UniversalActiveFiltersSummary(
                    title: "Active Filters",
                    activeFilterCount: 3,
                    filtersContent: {
                        UniversalActiveFilterChip(title: "Category 1", icon: "tag")
                        UniversalActiveFilterChip(title: "Within 5km", icon: "location")
                        UniversalActiveFilterChip(title: "4+ Rating", icon: "star.fill")
                    }
                )
            )
        },
        filterContent: {
            VStack(alignment: .leading, spacing: HealthSpacing.xl) {
                UniversalFilterSectionHeader("Categories", subtitle: "Select your preferred categories")
                
                UniversalFilterChipsContainer(columns: 2) {
                    ForEach(["Selected 1", "Selected 2", "Option 3", "Option 4"], id: \.self) { option in
                        Button(option) { }
                            .padding()
                            .background(option.contains("Selected") ? HealthColors.primary.opacity(0.1) : HealthColors.background)
                            .cornerRadius(HealthCornerRadius.md)
                    }
                }
                
                Divider().background(HealthColors.border)
                
                UniversalFilterSectionHeader("Price Range")
                
                UniversalVerticalFilterChips {
                    ForEach(["Under ₹500", "₹500 - ₹1000", "₹1000+"], id: \.self) { range in
                        Button(range) { }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(HealthColors.background)
                            .cornerRadius(HealthCornerRadius.md)
                    }
                }
            }
        },
        onReset: { },
        onApply: { }
    )
}