//
//  UnifiedSearchBar.swift
//  SuperOne
//
//  Unified search bar component for consistent styling across Tests and Labs tabs
//  Created by Claude Code on 1/29/25.
//

import SwiftUI

/// Unified search bar component with integrated filter button for consistent UI
struct UnifiedSearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let hasActiveFilters: Bool
    let onFilterTap: () -> Void
    
    var body: some View {
        HStack {
            // Search icon
            Image(systemName: "magnifyingglass")
                .foregroundColor(HealthColors.secondaryText)
                .font(.system(size: 16, weight: .medium))
            
            // Search text field
            TextField(placeholder, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.primaryText)
                .accentColor(HealthColors.primary)
            
            // Clear button (when text is entered)
            if !searchText.isEmpty {
                Button(action: { 
                    searchText = ""
                    HapticFeedback.light()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(HealthColors.secondaryText)
                        .font(.system(size: 16, weight: .medium))
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: !searchText.isEmpty)
            }
            
            // Filter button (integrated in the same container)
            Button(action: {
                HapticFeedback.light()
                onFilterTap()
            }) {
                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .foregroundColor(hasActiveFilters ? HealthColors.emerald : HealthColors.primary)
                    .font(.system(size: 18, weight: hasActiveFilters ? .semibold : .medium))
                    .animation(.easeInOut(duration: 0.2), value: hasActiveFilters)
            }
        }
        .padding(.horizontal, HealthSpacing.lg)
        .padding(.vertical, HealthSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                .fill(HealthColors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                        .strokeBorder(
                            hasActiveFilters ? HealthColors.primary.opacity(0.3) : Color.clear,
                            lineWidth: hasActiveFilters ? 1 : 0
                        )
                        .animation(.easeInOut(duration: 0.2), value: hasActiveFilters)
                )
        )
        .healthCardShadow()
    }
}

// MARK: - Preview

#Preview("Unified Search Bars") {
    VStack(spacing: HealthSpacing.xl) {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Tests Tab Style")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            UnifiedSearchBar(
                searchText: .constant(""),
                placeholder: "Search tests or results...",
                hasActiveFilters: false,
                onFilterTap: { }
            )
        }
        
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Labs Tab Style (No Active Filters)")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            UnifiedSearchBar(
                searchText: .constant(""),
                placeholder: "Search labs, tests, or areas...",
                hasActiveFilters: false,
                onFilterTap: { }
            )
        }
        
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Labs Tab Style (With Active Filters)")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            UnifiedSearchBar(
                searchText: .constant("Blood test"),
                placeholder: "Search labs, tests, or areas...",
                hasActiveFilters: true,
                onFilterTap: { }
            )
        }
        
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("With Text Input")
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            UnifiedSearchBar(
                searchText: .constant("Complete Blood Count"),
                placeholder: "Search tests or results...",
                hasActiveFilters: false,
                onFilterTap: { }
            )
        }
    }
    .padding(HealthSpacing.screenPadding)
    .background(HealthColors.background)
}