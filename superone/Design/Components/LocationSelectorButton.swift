import SwiftUI

/// Reusable location selector button component for displaying current location with tap action
/// Used across Dashboard, Appointments, and other location-aware screens
struct LocationSelectorButton: View {
    let currentLocation: String
    let onLocationChange: () -> Void
    
    var body: some View {
        Button(action: onLocationChange) {
            HStack(spacing: HealthSpacing.xs) {
                Image(systemName: "location.fill")
                    .foregroundColor(HealthColors.primary)
                    .font(.system(size: 12))
                
                Text(currentLocation)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Image(systemName: "chevron.down")
                    .foregroundColor(HealthColors.primary)
                    .font(.system(size: 10, weight: .semibold))
            }
            .padding(.horizontal, HealthSpacing.sm)
            .padding(.vertical, HealthSpacing.xs)
            .background(HealthColors.primary.opacity(0.1))
            .cornerRadius(HealthCornerRadius.button)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Location Selector") {
    VStack(spacing: HealthSpacing.md) {
        LocationSelectorButton(
            currentLocation: "Baner, Pune",
            onLocationChange: {
                print("Location change tapped")
            }
        )
        
        LocationSelectorButton(
            currentLocation: "Getting location...",
            onLocationChange: {
                print("Location change tapped")
            }
        )
        
        LocationSelectorButton(
            currentLocation: "Downtown San Francisco, California",
            onLocationChange: {
                print("Location change tapped")
            }
        )
    }
    .padding()
    .background(HealthColors.background)
}

#Preview("Location Selector - Dark Mode") {
    LocationSelectorButton(
        currentLocation: "Baner, Pune",
        onLocationChange: {
            print("Location change tapped")
        }
    )
    .padding()
    .background(HealthColors.background)
    .environment(\.colorScheme, .dark)
}