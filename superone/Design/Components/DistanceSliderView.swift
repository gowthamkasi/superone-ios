//
//  DistanceSliderView.swift
//  SuperOne
//
//  Modern distance range slider for lab facility filtering
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Modern distance slider component with hotel booking app styling
struct DistanceSliderView: View {
    @Binding var distanceValue: Double
    let maxDistance: Double = 25.0
    let minDistance: Double = 0.5
    
    @State private var isDragging = false
    @State private var lastHapticValue: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Header with current selection
            HStack {
                Text("Distance")
                    .font(HealthTypography.headline)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                Text("Within \(formattedDistance(distanceValue))")
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primary)
                    .padding(.horizontal, HealthSpacing.md)
                    .padding(.vertical, HealthSpacing.xs)
                    .background(HealthColors.primary.opacity(0.1))
                    .cornerRadius(HealthCornerRadius.lg)
            }
            
            // Custom slider with enhanced visuals
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 3)
                    .fill(HealthColors.secondaryBackground)
                    .frame(height: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(HealthColors.border, lineWidth: 0.5)
                    )
                
                // Active track
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [HealthColors.primary, HealthColors.emerald],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: sliderWidth, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: distanceValue)
                
                // Slider thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? 28 : 24, height: isDragging ? 28 : 24)
                    .shadow(color: HealthColors.primary.opacity(0.3), radius: isDragging ? 8 : 4, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .stroke(HealthColors.primary, lineWidth: isDragging ? 3 : 2)
                    )
                    .offset(x: sliderWidth - (isDragging ? 14 : 12))
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: distanceValue)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    HapticFeedback.light()
                                }
                                updateSliderValue(from: value.location.x)
                                
                                // Haptic feedback at intervals
                                let hapticInterval: Double = 2.0
                                if abs(distanceValue - lastHapticValue) >= hapticInterval {
                                    HapticFeedback.soft()
                                    lastHapticValue = distanceValue
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                HapticFeedback.soft()
                            }
                    )
            }
            .frame(height: 24)
            
            // Distance markers
            HStack {
                Text(formattedDistance(minDistance))
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                
                Spacer()
                
                Text("10 km")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .opacity(0.7)
                
                Spacer()
                
                Text(formattedDistance(maxDistance))
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
        }
        .onAppear {
            lastHapticValue = distanceValue
        }
    }
    
    // MARK: - Private Methods
    
    private var sliderWidth: CGFloat {
        let totalWidth = UIScreen.main.bounds.width - (HealthSpacing.screenPadding * 2) - 24
        let progress = (distanceValue - minDistance) / (maxDistance - minDistance)
        return max(0, min(totalWidth, totalWidth * progress))
    }
    
    private func updateSliderValue(from xPosition: CGFloat) {
        let totalWidth = UIScreen.main.bounds.width - (HealthSpacing.screenPadding * 2) - 24
        let progress = max(0, min(1, xPosition / totalWidth))
        let newValue = minDistance + (maxDistance - minDistance) * progress
        
        // Snap to common intervals
        let snapIntervals: [Double] = [0.5, 1.0, 2.0, 5.0, 10.0, 15.0, 20.0, 25.0]
        let snappedValue = snapIntervals.min { abs($0 - newValue) < abs($1 - newValue) } ?? newValue
        
        distanceValue = snappedValue
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
#Preview {
    VStack(spacing: HealthSpacing.xl) {
        DistanceSliderView(distanceValue: .constant(10.0))
            .padding(.horizontal, HealthSpacing.screenPadding)
        
        DistanceSliderView(distanceValue: .constant(2.5))
            .padding(.horizontal, HealthSpacing.screenPadding)
        
        DistanceSliderView(distanceValue: .constant(25.0))
            .padding(.horizontal, HealthSpacing.screenPadding)
    }
    .padding(.vertical, HealthSpacing.xl)
    .background(HealthColors.background)
}