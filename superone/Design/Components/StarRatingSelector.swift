//
//  StarRatingSelector.swift
//  SuperOne
//
//  Interactive star rating selector for lab facility filtering
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Interactive star rating selector with visual star display
struct StarRatingSelector: View {
    @Binding var selectedRating: MinimumRating
    
    @State private var hoveredRating: MinimumRating?
    @State private var animationOffset: CGFloat = 0
    
    // Rating options in ascending order for better UX
    private let ratingOptions: [MinimumRating] = [
        .any, .threePointFivePlus, .fourPointZeroPlus, .fourPointFivePlus
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Header with current selection
            HStack {
                Text("Minimum Rating")
                    .font(HealthTypography.headline)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                if selectedRating != .any {
                    Text(selectedRating.displayText)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primary)
                        .padding(.horizontal, HealthSpacing.md)
                        .padding(.vertical, HealthSpacing.xs)
                        .background(HealthColors.primary.opacity(0.1))
                        .cornerRadius(HealthCornerRadius.lg)
                }
            }
            
            // Interactive star rating buttons
            VStack(spacing: HealthSpacing.sm) {
                ForEach(ratingOptions, id: \.self) { rating in
                    RatingOptionRow(
                        rating: rating,
                        isSelected: selectedRating == rating,
                        isHovered: hoveredRating == rating,
                        onTap: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedRating = rating
                            }
                            HapticFeedback.soft()
                        },
                        onHover: { hovering in
                            hoveredRating = hovering ? rating : nil
                        }
                    )
                }
            }
        }
    }
}

/// Individual rating option row with stars
struct RatingOptionRow: View {
    let rating: MinimumRating
    let isSelected: Bool
    let isHovered: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Star display or "Any" text
                HStack(spacing: HealthSpacing.xs) {
                    if rating == .any {
                        Text("Any Rating")
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(isSelected ? .white : HealthColors.primaryText)
                    } else {
                        // Star display
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { index in
                                Image(systemName: starIcon(for: index, rating: rating))
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(starColor(for: index, rating: rating, isSelected: isSelected))
                            }
                        }
                        
                        // Rating text
                        Text(rating.shortDisplayText)
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(isSelected ? .white : HealthColors.primaryText)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                } else if rating != .any {
                    // Show number of stars for non-selected options
                    Text(rating.numberDisplayText)
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            .padding(.horizontal, HealthSpacing.lg)
            .padding(.vertical, HealthSpacing.md)
            .frame(minHeight: 52) // Slightly taller for stars
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
                                colors: [
                                    isHovered ? HealthColors.primary.opacity(0.05) : HealthColors.secondaryBackground,
                                    isHovered ? HealthColors.primary.opacity(0.05) : HealthColors.secondaryBackground
                                ],
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
                            : (isHovered ? HealthColors.primary.opacity(0.3) : HealthColors.border),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
            onHover(pressing)
        } perform: { }
    }
    
    // MARK: - Star Display Logic
    
    private func starIcon(for index: Int, rating: MinimumRating) -> String {
        guard let minimumValue = rating.minimumValue else { return "star" }
        
        let starValue = Double(index + 1)
        
        if starValue <= minimumValue {
            return "star.fill"
        } else if starValue - 0.5 <= minimumValue {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
    
    private func starColor(for index: Int, rating: MinimumRating, isSelected: Bool) -> Color {
        guard let minimumValue = rating.minimumValue else {
            return isSelected ? .white : HealthColors.secondaryText
        }
        
        let starValue = Double(index + 1)
        
        if starValue <= minimumValue {
            return isSelected ? .white : HealthColors.healthWarning
        } else if starValue - 0.5 <= minimumValue {
            return isSelected ? .white : HealthColors.healthWarning
        } else {
            return isSelected ? HealthColors.primary.opacity(0.3) : HealthColors.secondaryText.opacity(0.3)
        }
    }
}

// MARK: - MinimumRating Extensions

extension MinimumRating {
    /// Display text with star indication
    var displayText: String {
        switch self {
        case .fourPointFivePlus:
            return "4.5+ Stars"
        case .fourPointZeroPlus:
            return "4.0+ Stars"
        case .threePointFivePlus:
            return "3.5+ Stars"
        case .any:
            return "Any Rating"
        }
    }
    
    /// Short display text for inline use
    var shortDisplayText: String {
        switch self {
        case .fourPointFivePlus:
            return "4.5+"
        case .fourPointZeroPlus:
            return "4.0+"
        case .threePointFivePlus:
            return "3.5+"
        case .any:
            return "Any"
        }
    }
    
    /// Number-only display text
    var numberDisplayText: String {
        switch self {
        case .fourPointFivePlus:
            return "4.5+"
        case .fourPointZeroPlus:
            return "4.0+"
        case .threePointFivePlus:
            return "3.5+"
        case .any:
            return ""
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: HealthSpacing.xl) {
            Text("Star Rating Selector")
                .font(HealthTypography.title2)
                .foregroundColor(HealthColors.primaryText)
            
            StarRatingSelector(selectedRating: .constant(.fourPointZeroPlus))
            
            Divider()
            
            StarRatingSelector(selectedRating: .constant(.any))
            
            Spacer(minLength: HealthSpacing.xl)
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
        .padding(.vertical, HealthSpacing.xl)
    }
    .background(HealthColors.background)
}