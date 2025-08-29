//
//  ModernFilterButton.swift
//  SuperOne
//
//  Modern filter button with active filter count badge
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Modern filter button with badge showing active filter count
struct ModernFilterButton: View {
    let activeFilterCount: Int
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            onTap()
        }) {
            ZStack {
                // Main button
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .fill(
                        activeFilterCount > 0
                            ? LinearGradient(
                                colors: [HealthColors.primary, HealthColors.emerald],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [HealthColors.secondaryBackground, HealthColors.secondaryBackground],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .strokeBorder(
                                activeFilterCount > 0 
                                    ? HealthColors.primary.opacity(0.3)
                                    : HealthColors.border,
                                lineWidth: 1
                            )
                    )
                    .frame(width: 44, height: 44)
                
                // Filter icon
                Image(systemName: activeFilterCount > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20, weight: activeFilterCount > 0 ? .semibold : .medium))
                    .foregroundColor(activeFilterCount > 0 ? .white : HealthColors.primary)
                
                // Active filter count badge
                if activeFilterCount > 0 {
                    VStack {
                        HStack {
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(HealthColors.healthCritical)
                                    .frame(width: 20, height: 20)
                                
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                                
                                Text("\(min(activeFilterCount, 99))")
                                    .font(.system(size: activeFilterCount > 9 ? 10 : 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                            }
                            .offset(x: 8, y: -8)
                        }
                        
                        Spacer()
                    }
                    .frame(width: 44, height: 44)
                }
            }
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: activeFilterCount)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: { }
    }
}

// MARK: - Preview

#Preview("Filter Buttons") {
    VStack(spacing: HealthSpacing.xl) {
        HStack(spacing: HealthSpacing.lg) {
            ModernFilterButton(activeFilterCount: 0) { }
            ModernFilterButton(activeFilterCount: 1) { }
            ModernFilterButton(activeFilterCount: 3) { }
            ModernFilterButton(activeFilterCount: 15) { }
        }
        
        Text("Filter Button States")
            .font(HealthTypography.headline)
            .foregroundColor(HealthColors.primaryText)
    }
    .padding(HealthSpacing.xl)
    .background(HealthColors.background)
}