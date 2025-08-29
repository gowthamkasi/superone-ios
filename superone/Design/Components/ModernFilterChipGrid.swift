//
//  ModernFilterChipGrid.swift
//  SuperOne
//
//  Modern filter chip grid with hotel booking app styling and smart grouping
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Modern filter chip grid component with grouped categories
struct ModernFilterChipGrid: View {
    let selectedFeatures: Set<LabFeature>
    let onFeatureToggle: (LabFeature) -> Void
    
    // Grouped features for better organization
    private let featureGroups: [(title: String, features: [LabFeature])] = [
        ("Convenience", [.walkInsAccepted, .freeParking, .twentyFourHours]),
        ("Services", [.homeCollection, .sameDayReports, .digitalReports])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.xl) {
            ForEach(Array(featureGroups.enumerated()), id: \.offset) { index, group in
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    // Group title
                    Text(group.title)
                        .font(HealthTypography.headline)
                        .foregroundColor(HealthColors.primaryText)
                    
                    // Feature chips in flexible grid
                    FlexibleChipGrid(
                        features: group.features,
                        selectedFeatures: selectedFeatures,
                        onFeatureToggle: onFeatureToggle
                    )
                }
            }
        }
    }
}

/// Flexible chip grid that wraps chips to multiple rows as needed
struct FlexibleChipGrid: View {
    let features: [LabFeature]
    let selectedFeatures: Set<LabFeature>
    let onFeatureToggle: (LabFeature) -> Void
    
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: HealthSpacing.sm),
                GridItem(.flexible(), spacing: HealthSpacing.sm)
            ],
            spacing: HealthSpacing.sm
        ) {
            ForEach(features, id: \.self) { feature in
                ModernFilterChip(
                    feature: feature,
                    isSelected: selectedFeatures.contains(feature),
                    onTap: { onFeatureToggle(feature) }
                )
            }
        }
    }
}

/// Modern filter chip with enhanced visual design
struct ModernFilterChip: View {
    let feature: LabFeature
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.soft()
            onTap()
        }) {
            HStack(spacing: HealthSpacing.xs) {
                // Feature icon
                Image(systemName: feature.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : HealthColors.primary)
                
                // Feature name
                Text(feature.shortDisplayName)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(isSelected ? .white : HealthColors.primaryText)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.vertical, HealthSpacing.sm)
            .frame(minHeight: 44) // Accessibility touch target
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .fill(
                        isSelected 
                            ? LinearGradient(
                                colors: [HealthColors.primary, HealthColors.emerald],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [HealthColors.secondaryBackground, HealthColors.secondaryBackground],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .strokeBorder(
                        isSelected 
                            ? HealthColors.primary.opacity(0.3)
                            : HealthColors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: { }
    }
}

// MARK: - LabFeature Extensions

extension LabFeature {
    /// Icon for each lab feature
    var icon: String {
        switch self {
        case .walkInsAccepted:
            return "figure.walk"
        case .homeCollection:
            return "house.fill"
        case .sameDayReports:
            return "clock.fill"
        case .digitalReports:
            return "doc.text"
        case .freeParking:
            return "car.fill"
        case .twentyFourHours:
            return "24.circle.fill"
        }
    }
    
    /// Shorter display name for chips
    var shortDisplayName: String {
        switch self {
        case .walkInsAccepted:
            return "Walk-ins"
        case .homeCollection:
            return "Home Collect"
        case .sameDayReports:
            return "Same Day"
        case .digitalReports:
            return "Digital Rep"
        case .freeParking:
            return "Free Parking"
        case .twentyFourHours:
            return "24 Hours"
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: HealthSpacing.xl) {
            Text("Filter Chips")
                .font(HealthTypography.title2)
                .foregroundColor(HealthColors.primaryText)
            
            ModernFilterChipGrid(
                selectedFeatures: [.walkInsAccepted, .digitalReports],
                onFeatureToggle: { _ in }
            )
            
            Spacer(minLength: HealthSpacing.xl)
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
        .padding(.vertical, HealthSpacing.xl)
    }
    .background(HealthColors.background)
}