import SwiftUI

// MARK: - Quick Action Model
struct QuickAction {
    let id = UUID()
    let title: String
    let icon: String
    let isPrimary: Bool
    let action: () -> Void
    
    init(title: String, icon: String, isPrimary: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isPrimary = isPrimary
        self.action = action
    }
}

// MARK: - Quick Actions Bar Component
struct QuickActionsBar: View {
    let onBookNow: () -> Void
    let onFindLabs: () -> Void
    let onViewPackages: () -> Void
    let onTrackSample: () -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    
    init(
        onBookNow: @escaping () -> Void,
        onFindLabs: @escaping () -> Void,
        onViewPackages: @escaping () -> Void,
        onTrackSample: @escaping () -> Void
    ) {
        self.onBookNow = onBookNow
        self.onFindLabs = onFindLabs
        self.onViewPackages = onViewPackages
        self.onTrackSample = onTrackSample
    }
    
    private var actions: [QuickAction] {
        [
            QuickAction(
                title: "Book Now",
                icon: "calendar.badge.plus",
                isPrimary: true,
                action: {
                    hapticImpact.impactOccurred()
                    onBookNow()
                }
            ),
            QuickAction(
                title: "Find Labs Near Me",
                icon: "location.magnifyingglass",
                action: {
                    hapticImpact.impactOccurred()
                    onFindLabs()
                }
            ),
            QuickAction(
                title: "View Packages",
                icon: "list.bullet.rectangle",
                action: {
                    hapticImpact.impactOccurred()
                    onViewPackages()
                }
            ),
            QuickAction(
                title: "Track Sample",
                icon: "shippingbox.and.arrow.backward",
                action: {
                    hapticImpact.impactOccurred()
                    onTrackSample()
                }
            )
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Section Header
            HStack {
                Text("Quick Actions")
                    .font(HealthTypography.headline)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            // 2x2 Grid Layout
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: HealthSpacing.md), count: 2),
                spacing: HealthSpacing.md
            ) {
                ForEach(actions, id: \.id) { action in
                    QuickActionCard(action: action)
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
    }
}

// MARK: - Quick Action Card Component (Detailed Grid Style)
private struct QuickActionCard: View {
    let action: QuickAction
    
    @State private var isVisible: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action.action()
        }) {
            VStack(spacing: HealthSpacing.sm) {
                // Icon section
                HStack {
                    ZStack {
                        // Icon background
                        Circle()
                            .fill(iconBackgroundColor)
                            .frame(width: 44, height: 44)
                            .scaleEffect(isVisible ? 1.0 : 0.8)
                            .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.2), value: isVisible)
                        
                        Image(systemName: action.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(iconColor)
                            .scaleEffect(isVisible ? 1.0 : 0.8)
                            .animation(.spring(duration: 0.6, bounce: 0.4).delay(0.3), value: isVisible)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Content section
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(action.title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 10)
                        .animation(.easeInOut(duration: 0.4).delay(0.4), value: isVisible)
                    
                    Text(actionDescription)
                        .font(HealthTypography.caption1)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 10)
                        .animation(.easeInOut(duration: 0.4).delay(0.5), value: isVisible)
                }
            }
            .padding(HealthSpacing.lg)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                    .fill(cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .healthCardShadow()
            )
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .animation(.spring(duration: 0.6, bounce: 0.2), value: isVisible)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var actionDescription: String {
        switch action.title {
        case "Book Now":
            return "Quick appointment booking"
        case "Find Labs Near Me":
            return "Locate nearby facilities"
        case "View Packages":
            return "Browse health packages"
        case "Track Sample":
            return "Track sample status"
        default:
            return "Quick action"
        }
    }
    
    private var iconBackgroundColor: Color {
        if action.isPrimary {
            return HealthColors.primary.opacity(0.1)
        } else {
            return HealthColors.secondary.opacity(0.1)
        }
    }
    
    private var iconColor: Color {
        if action.isPrimary {
            return HealthColors.primary
        } else {
            return HealthColors.secondary
        }
    }
    
    private var cardBackgroundColor: Color {
        if action.isPrimary {
            return HealthColors.primary.opacity(0.05)
        } else {
            return Color(.secondarySystemBackground)
        }
    }
    
    private var borderColor: Color {
        if action.isPrimary {
            return HealthColors.primary.opacity(0.2)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Previews
#Preview("Quick Actions Bar") {
    VStack(spacing: HealthSpacing.xxl) {
        QuickActionsBar(
            onBookNow: { print("Book Now tapped") },
            onFindLabs: { print("Find Labs tapped") },
            onViewPackages: { print("View Packages tapped") },
            onTrackSample: { print("Track Sample tapped") }
        )
        
        Spacer()
    }
    .background(HealthColors.background)
}

#Preview("Quick Actions Bar - Dark Mode") {
    VStack(spacing: HealthSpacing.xxl) {
        QuickActionsBar(
            onBookNow: { print("Book Now tapped") },
            onFindLabs: { print("Find Labs tapped") },
            onViewPackages: { print("View Packages tapped") },
            onTrackSample: { print("Track Sample tapped") }
        )
        
        Spacer()
    }
    .background(HealthColors.background)
    .preferredColorScheme(.dark)
}

#Preview("Quick Actions Bar - iPad") {
    VStack(spacing: HealthSpacing.xxl) {
        QuickActionsBar(
            onBookNow: { print("Book Now tapped") },
            onFindLabs: { print("Find Labs tapped") },
            onViewPackages: { print("View Packages tapped") },
            onTrackSample: { print("Track Sample tapped") }
        )
        
        Spacer()
    }
    .background(HealthColors.background)
    .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}