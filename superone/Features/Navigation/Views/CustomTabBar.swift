import SwiftUI

/// Custom tab bar with health-focused design and enhanced animations
struct CustomTabBar: View {
    @Bindable var viewModel: NavigationViewModel
    
    // MARK: - Animation Properties
    @State private var tabBarOffset: CGFloat = 0
    @State private var isVisible = true
    @Namespace private var tabBarNamespace
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar Content with safe area aware padding
            HStack(spacing: 0) {
                ForEach(viewModel.availableTabs, id: \.id) { tab in
                    TabBarItem(
                        tab: tab,
                        isSelected: viewModel.selectedTab == tab.id,
                        namespace: tabBarNamespace,
                        viewModel: viewModel,
                        onTap: {
                            handleTabTap(tab)
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, HealthSpacing.md)
            .padding(.top, HealthSpacing.sm)
            .padding(.bottom, HealthSpacing.sm)
            .background(
                // Full-screen extending background
                HealthTabBarBackground()
                    .ignoresSafeArea(.all, edges: .bottom)
            )
            .overlay(
                // Top border for visual separation
                Rectangle()
                    .fill(HealthColors.accent.opacity(0.2))
                    .frame(height: 0.5)
                    .frame(maxHeight: .infinity, alignment: .top)
            )
        }
        .offset(y: viewModel.isTabBarHidden ? HealthSpacing.tabBarHeight : 0)
        .animation(.spring(duration: 0.4, bounce: 0.2), value: viewModel.isTabBarHidden)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
    
    // MARK: - iOS 18+ Enhanced Tab Tap Handling
    private func handleTabTap(_ tab: NavigationViewModel.TabItem) {
        // iOS 18+ contextual haptic feedback based on tab type
        switch tab.type {
        case .upload:
            HapticFeedback.success() // Upload action deserves success feedback
        case .normal:
            HapticFeedback.medium() // Primary navigation
        default:
            HapticFeedback.light() // Secondary navigation
        }
        
        // Handle selection with enhanced animations
        withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
            viewModel.selectTab(tab.id)
        }
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let tab: NavigationViewModel.TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let viewModel: NavigationViewModel
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var bounceAnimation = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HealthSpacing.xs) {
                // Icon with special handling for upload tab
                if tab.type == .upload {
                    UploadTabIcon(isPressed: isPressed)
                } else {
                    RegularTabIcon(
                        tab: tab,
                        isSelected: isSelected,
                        namespace: namespace
                    )
                }
                
                // Tab title (hidden for upload tab)
                if !tab.title.isEmpty {
                    Text(tab.title)
                        .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
            }
            .frame(height: 49) // Standard tab bar item height
            .contentShape(Rectangle()) // Expand touch area
        }
        .buttonStyle(TabButtonStyle(isPressed: $isPressed))
        .scaleEffect(bounceAnimation ? 1.1 : 1.0)
        .animation(.spring(duration: 0.3, bounce: 0.4), value: bounceAnimation)
        .accessibilityLabel(viewModel.accessibilityLabel(for: tab))
        .accessibilityHint(viewModel.accessibilityHint(for: tab))
        .onChange(of: isSelected) { selected in
            if selected {
                withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                    bounceAnimation = true
                }
                
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await MainActor.run {
                        withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                            bounceAnimation = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Upload Tab Icon
struct UploadTabIcon: View {
    let isPressed: Bool
    
    @State private var rotationAnimation: Double = 0
    @State private var scaleAnimation: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [HealthColors.primary, HealthColors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .scaleEffect(isPressed ? 0.9 : scaleAnimation)
                .animation(.spring(duration: 0.3, bounce: 0.3), value: isPressed)
            
            // Plus icon
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(rotationAnimation))
        }
        .floatingButtonShadow()
        .onAppear {
            // Subtle pulsing animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                scaleAnimation = 1.05
            }
        }
    }
}

// MARK: - Regular Tab Icon
struct RegularTabIcon: View {
    let tab: NavigationViewModel.TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    
    var body: some View {
        ZStack {
            // Selection indicator background
            if isSelected {
                Capsule()
                    .fill(HealthColors.accent.opacity(0.2))
                    .frame(width: 40, height: 28)
                    .matchedGeometryEffect(id: "selectedTab", in: namespace)
                    .animation(.spring(duration: 0.4, bounce: 0.3), value: isSelected)
            }
            
            // Icon
            Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                .animation(.none, value: isSelected) // Prevent icon transition animation
        }
    }
}

// MARK: - Tab Button Style
// MARK: - iOS 18+ Enhanced Tab Button Style
struct TabButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                // iOS 18+ enhanced interaction area
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(minHeight: 44) // iOS minimum touch target
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.5), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
                if pressed {
                    // iOS 18+ haptic feedback for tab selection
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
}

// MARK: - Tab Bar Background
struct HealthTabBarBackground: View {
    var body: some View {
        ZStack {
            // Main background with blur effect
            Rectangle()
                .fill(.regularMaterial)
                .background(HealthColors.background.opacity(0.95))
            
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    HealthColors.accent.opacity(0.02),
                    HealthColors.primary.opacity(0.01)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Preview
#Preview("Custom Tab Bar") {
    VStack {
        Spacer()
        
        CustomTabBar(viewModel: NavigationViewModel(appState: AppState()))
    }
    .background(HealthColors.background)
}

#Preview("Tab Bar States") {
    VStack {
        Spacer()
        
        // Normal state
        CustomTabBar(viewModel: NavigationViewModel(appState: AppState()))
        
        Spacer()
        
        // Different selected tab
        CustomTabBar(viewModel: {
            let vm = NavigationViewModel(appState: AppState())
            vm.selectedTab = 3
            return vm
        }())
    }
    .background(HealthColors.background)
}