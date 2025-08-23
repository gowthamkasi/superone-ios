import SwiftUI

/// Service options grid showing 4 main service types with smooth animations
struct ServiceOptionsGrid: View {
    let onOnlineBookingTap: () -> Void
    let onHomeCollectionTap: () -> Void
    let onTestPackagesTap: () -> Void
    let onQuickTestsTap: () -> Void
    
    @State private var isVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Section Header
            HStack {
                Text("Services")
                    .font(HealthTypography.headline)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            // Horizontal Service Options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HealthSpacing.lg) {
                    ForEach(Array(serviceOptions.enumerated()), id: \.element.id) { index, option in
                        ServiceOptionButton(
                            serviceOption: option,
                            animationDelay: Double(index) * 0.1,
                            isVisible: isVisible
                        ) {
                            handleServiceOptionTap(option.type)
                        }
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .frame(maxHeight: 100)
            }
            .scrollTargetBehavior(.viewAligned)
            .frame(maxHeight: 100)
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var serviceOptions: [ServiceOption] {
        [
            ServiceOption(
                id: "online_booking",
                icon: "calendar.badge.plus",
                title: "Online Booking",
                description: "Schedule lab visits",
                type: .onlineBooking,
                color: HealthColors.primary
            ),
            ServiceOption(
                id: "home_collection",
                icon: "house.fill",
                title: "Home Collection",
                description: "Sample collection at home",
                type: .homeCollection,
                color: HealthColors.secondary
            ),
            ServiceOption(
                id: "test_packages",
                icon: "shippingbox.fill",
                title: "Test Packages",
                description: "Health check bundles",
                type: .testPackages,
                color: HealthColors.emerald
            ),
            ServiceOption(
                id: "quick_tests",
                icon: "clock.fill",
                title: "Quick Tests",
                description: "Walk-in available",
                type: .quickTests,
                color: HealthColors.forest
            )
        ]
    }
    
    // MARK: - Private Methods
    
    private func handleServiceOptionTap(_ type: ServiceOptionType) {
        switch type {
        case .onlineBooking:
            onOnlineBookingTap()
        case .homeCollection:
            onHomeCollectionTap()
        case .testPackages:
            onTestPackagesTap()
        case .quickTests:
            onQuickTestsTap()
        }
    }
}

// MARK: - Service Option Models

struct ServiceOption: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let type: ServiceOptionType
    let color: Color
}

enum ServiceOptionType {
    case onlineBooking
    case homeCollection
    case testPackages
    case quickTests
}

// MARK: - Service Option Button (Compact Horizontal Style)

struct ServiceOptionButton: View {
    let serviceOption: ServiceOption
    let animationDelay: Double
    let isVisible: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            onTap()
        }) {
            VStack(spacing: HealthSpacing.sm) {
                // Circular icon background
                ZStack {
                    Circle()
                        .fill(serviceOption.color.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .animation(.spring(duration: 0.5, bounce: 0.3).delay(animationDelay), value: isVisible)
                    
                    Image(systemName: serviceOption.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(serviceOption.color)
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .animation(.spring(duration: 0.6, bounce: 0.4).delay(animationDelay + 0.1), value: isVisible)
                }
                
                // Title
                Text(serviceOption.title)
                    .font(HealthTypography.caption1)
                    .foregroundColor(HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4).delay(animationDelay + 0.2), value: isVisible)
            }
            .frame(width: 80, height: 80)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

// MARK: - Service Option Card

struct ServiceOptionCard: View {
    let serviceOption: ServiceOption
    let animationDelay: Double
    let isVisible: Bool
    let onTap: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            onTap()
        }) {
            VStack(spacing: HealthSpacing.sm) {
                // Icon section
                HStack {
                    ZStack {
                        // Icon background with themed color
                        Circle()
                            .fill(serviceOption.color.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .scaleEffect(isVisible ? 1.0 : 0.8)
                            .animation(.spring(duration: 0.5, bounce: 0.3).delay(animationDelay + 0.2), value: isVisible)
                        
                        Image(systemName: serviceOption.icon)
                            .font(.system(size: HealthSpacing.iconSize, weight: .semibold))
                            .foregroundColor(serviceOption.color)
                            .scaleEffect(isVisible ? 1.0 : 0.8)
                            .animation(.spring(duration: 0.6, bounce: 0.4).delay(animationDelay + 0.3), value: isVisible)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Content section
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(serviceOption.title)
                        .font(HealthTypography.headline)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 10)
                        .animation(.easeInOut(duration: 0.4).delay(animationDelay + 0.4), value: isVisible)
                    
                    Text(serviceOption.description)
                        .font(HealthTypography.caption1)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 10)
                        .animation(.easeInOut(duration: 0.4).delay(animationDelay + 0.5), value: isVisible)
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
            .animation(.spring(duration: 0.6, bounce: 0.2).delay(animationDelay), value: isVisible)
        }
        .buttonStyle(ServiceOptionCardButtonStyle())
        .simultaneousGesture(
            // Long press gesture for additional context
            LongPressGesture(minimumDuration: 0.8)
                .onEnded { _ in
                    HapticFeedback.heavy()
                    // Could trigger service info or quick actions
                }
        )
        .accessibilityLabel("\(serviceOption.title): \(serviceOption.description)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to access \(serviceOption.title.lowercased())")
    }
    
    // MARK: - Private Properties
    
    private var cardBackgroundColor: Color {
        return Color(.secondarySystemBackground)
    }
    
    private var borderColor: Color {
        return serviceOption.color.opacity(0.2)
    }
}

// MARK: - Custom Button Style

struct ServiceOptionCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: configuration.isPressed)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.xl)
                    .fill(Color.clear)
                    .contentShape(Rectangle())
            )
    }
}


// MARK: - Preview

#Preview("Service Options Grid") {
    ServiceOptionsGrid(
        onOnlineBookingTap: { print("Online Booking tapped") },
        onHomeCollectionTap: { print("Home Collection tapped") },
        onTestPackagesTap: { print("Test Packages tapped") },
        onQuickTestsTap: { print("Quick Tests tapped") }
    )
    .padding()
    .background(HealthColors.background)
}

#Preview("Service Options Grid - Dark Mode") {
    ServiceOptionsGrid(
        onOnlineBookingTap: { print("Online Booking tapped") },
        onHomeCollectionTap: { print("Home Collection tapped") },
        onTestPackagesTap: { print("Test Packages tapped") },
        onQuickTestsTap: { print("Quick Tests tapped") }
    )
    .padding()
    .background(HealthColors.background)
    .environment(\.colorScheme, .dark)
}

#Preview("Single Service Card") {
    ServiceOptionCard(
        serviceOption: ServiceOption(
            id: "online_booking",
            icon: "calendar.badge.plus",
            title: "Online Booking",
            description: "Schedule lab visits",
            type: .onlineBooking,
            color: HealthColors.primary
        ),
        animationDelay: 0.1,
        isVisible: true
    ) {
        print("Service option tapped")
    }
    .padding()
    .background(HealthColors.background)
}