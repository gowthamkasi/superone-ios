# Universal Filter Sheet Usage Guide

This guide demonstrates how to use the `UniversalFilterSheet` component for creating consistent filter experiences across the entire app.

## Overview

The Universal Filter Sheet provides a standardized architecture for all filtering interfaces in the app, ensuring:
- **Consistent UX**: Same navigation patterns, animations, and interactions
- **Reduced Code Duplication**: Single source of truth for filter sheet behavior
- **Flexible Content**: Support for any type of filter content via ViewBuilder
- **Active Filter Summary**: Built-in active filters display at the top
- **Reset Confirmation**: Optional confirmation dialogs for destructive actions

## Basic Usage

### Simple Filter Sheet

```swift
UniversalFilterSheet(
    title: "Filter Items",
    hasActiveFilters: viewModel.hasActiveFilters,
    hasChanges: hasChanges,
    canReset: viewModel.hasActiveFilters,
    activeFiltersContent: nil, // No active filters display
    filterContent: {
        // Your custom filter content here
        VStack {
            Text("Filter options go here")
        }
    },
    onReset: {
        // Handle reset action
        viewModel.resetFilters()
    },
    onApply: {
        // Handle apply action
        if hasChanges {
            viewModel.applyFilters()
        }
        dismiss()
    }
)
```

### Filter Sheet with Active Filters Display

```swift
UniversalFilterSheet(
    title: "Filter Labs",
    hasActiveFilters: viewModel.hasActiveFilters,
    hasChanges: hasChanges,
    canReset: viewModel.hasActiveFilters,
    activeFiltersContent: viewModel.hasActiveFilters ? {
        AnyView(
            UniversalActiveFiltersSummary(
                title: "Active Filters",
                activeFilterCount: 3,
                filtersContent: {
                    UniversalActiveFilterChip(title: "Within 5km", icon: "location")
                    UniversalActiveFilterChip(title: "4+ Rating", icon: "star.fill")
                    UniversalActiveFilterChip(title: "Digital Reports", icon: "doc.text")
                }
            )
        )
    } : nil,
    filterContent: {
        // Your filter sections here
    },
    onReset: { /* reset logic */ },
    onApply: { /* apply logic */ }
)
```

### Filter Sheet with Reset Confirmation

For sheets that should show a confirmation dialog before resetting:

```swift
UniversalFilterSheet.withResetConfirmation(
    title: "Filter Reports",
    hasActiveFilters: hasActiveFilters,
    hasChanges: hasChanges,
    canReset: hasActiveFilters,
    activeFiltersContent: /* active filters content */,
    filterContent: { /* filter content */ },
    onResetConfirmed: {
        // This only runs after user confirms reset
        resetAllFilters()
        hasChanges = true
    },
    onApply: { /* apply logic */ },
    resetConfirmationMessage: "This will clear all filter selections."
)
```

## Content Components

### Section Headers

Use `UniversalFilterSectionHeader` for consistent section titles:

```swift
UniversalFilterSectionHeader(
    "Categories",
    subtitle: "Select your preferred categories" // Optional
)
```

### Filter Chip Containers

#### Grid Layout (for categories, tags, etc.)
```swift
UniversalFilterChipsContainer(columns: 2) {
    ForEach(categories, id: \.self) { category in
        CategoryFilterChip(category: category, isSelected: isSelected(category)) {
            toggle(category)
        }
    }
}
```

#### Vertical Layout (for lists, ranges, etc.)
```swift
UniversalVerticalFilterChips {
    ForEach(priceRanges, id: \.self) { range in
        PriceRangeFilterChip(range: range, isSelected: isSelected(range)) {
            select(range)
        }
    }
}
```

### Active Filter Chips

#### Basic Chip
```swift
UniversalActiveFilterChip(
    title: "Within 5km",
    icon: "location"
)
```

#### Removable Chip
```swift
UniversalActiveFilterChip(
    title: "Search: \"keyword\"",
    icon: "magnifyingglass",
    onRemove: {
        clearSearchFilter()
        hasChanges = true
    }
)
```

## Common Patterns

### Standard Section Layout

```swift
VStack(alignment: .leading, spacing: HealthSpacing.xl) {
    // Section 1
    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
        UniversalFilterSectionHeader("Categories")
        
        UniversalFilterChipsContainer(columns: 2) {
            // Filter chips
        }
    }
    
    // Divider
    Divider().background(HealthColors.border)
    
    // Section 2
    VStack(alignment: .leading, spacing: HealthSpacing.lg) {
        UniversalFilterSectionHeader("Price Range")
        
        UniversalVerticalFilterChips {
            // Price range chips
        }
    }
}
```

### Search Filter Section

```swift
VStack(alignment: .leading, spacing: HealthSpacing.md) {
    UniversalFilterSectionHeader("Search", subtitle: "Search by keywords")
    
    HStack {
        Image(systemName: "magnifyingglass")
            .foregroundColor(HealthColors.secondaryText)
        
        TextField("Search...", text: $searchText)
            .font(HealthTypography.bodyRegular)
            .onChange(of: searchText) { _, _ in
                hasChanges = true
            }
    }
    .padding(.horizontal, HealthSpacing.md)
    .padding(.vertical, HealthSpacing.sm)
    .background(HealthColors.cardBackground)
    .overlay(
        RoundedRectangle(cornerRadius: HealthCornerRadius.md)
            .strokeBorder(HealthColors.border, lineWidth: 1)
    )
    .cornerRadius(HealthCornerRadius.md)
}
```

## State Management

### Required State Variables

```swift
struct YourFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasChanges = false
    
    // Your filter state
    @State private var selectedCategories: Set<Category> = []
    @State private var selectedPriceRange: PriceRange? = nil
    @State private var searchText: String = ""
    
    // Computed properties
    private var hasActiveFilters: Bool {
        !selectedCategories.isEmpty || selectedPriceRange != nil || !searchText.isEmpty
    }
    
    private var activeFilterCount: Int {
        var count = selectedCategories.count
        if selectedPriceRange != nil { count += 1 }
        if !searchText.isEmpty { count += 1 }
        return count
    }
}
```

### Change Tracking

Always set `hasChanges = true` when filters are modified:

```swift
private func toggleCategory(_ category: Category) {
    if selectedCategories.contains(category) {
        selectedCategories.remove(category)
    } else {
        selectedCategories.insert(category)
    }
    hasChanges = true
    HapticFeedback.soft() // Optional haptic feedback
}
```

## Custom Filter Chip Components

### Basic Filter Chip Template

```swift
struct YourCustomFilterChip: View {
    let item: YourItemType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                
                Text(item.displayName)
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(HealthColors.primary)
                }
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .fill(isSelected ? HealthColors.primary.opacity(0.1) : HealthColors.cardBackground)
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
```

## Integration Examples

### Integration with Existing View Model

```swift
// In your view model
class YourViewModel: ObservableObject {
    // Filter state
    @Published var selectedCategories: Set<Category> = []
    @Published var selectedPriceRange: PriceRange? = nil
    
    // Computed properties
    var hasActiveFilters: Bool {
        !selectedCategories.isEmpty || selectedPriceRange != nil
    }
    
    // Filter actions
    func resetFilters() {
        selectedCategories.removeAll()
        selectedPriceRange = nil
    }
    
    func applyFilters() {
        // Apply the current filter state
        loadFilteredData()
    }
}

// In your view
struct YourView: View {
    @StateObject private var viewModel = YourViewModel()
    @State private var showFilterSheet = false
    
    var body: some View {
        // Your main view content
        .sheet(isPresented: $showFilterSheet) {
            YourFilterSheet(viewModel: viewModel)
        }
    }
}
```

## Best Practices

### 1. Consistent Spacing
Always use `HealthSpacing.xl` between major sections and `HealthSpacing.lg` within sections.

### 2. Proper Dividers
Use `Divider().background(HealthColors.border)` between sections.

### 3. Haptic Feedback
Include haptic feedback for filter interactions:
```swift
HapticFeedback.soft() // For toggles
HapticFeedback.success() // For apply actions
HapticFeedback.light() // For resets
```

### 4. Accessibility
Ensure all interactive elements have proper accessibility labels and touch targets.

### 5. State Management
- Always track changes with `hasChanges` state
- Only enable reset button when there are active filters
- Highlight apply button when changes are pending

### 6. Performance
For large filter sets, consider lazy loading or virtualization:
```swift
LazyVGrid(columns: columns, spacing: HealthSpacing.md) {
    // Large sets of filter chips
}
```

## Migration from Existing Filters

### Step 1: Extract Content
Move your existing filter content into the `filterContent` builder.

### Step 2: Create Active Filters Summary
Convert your active filter display to use `UniversalActiveFiltersSummary`.

### Step 3: Update State Management
Ensure you have proper `hasActiveFilters`, `hasChanges`, and `canReset` logic.

### Step 4: Replace Navigation
Remove custom navigation bar setup and rely on the universal component.

### Step 5: Test and Refine
Verify the filter experience matches your existing UX before removing old components.

## Examples in the Codebase

- **Labs Filter**: `UniversalLabsFilterSheet.swift` - Demonstrates migration from existing modern filter
- **Tests Filter**: `UniversalTestsFilterSheet.swift` - Shows multiple section types
- **Reports Filter**: `UniversalReportsFilterSheet.swift` - Advanced usage with search and complex filtering

This universal approach ensures consistent filter experiences across all app features while maintaining the flexibility to customize content for specific needs.