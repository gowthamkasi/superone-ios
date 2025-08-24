import SwiftUI

// MARK: - Primary Button Style
struct HealthPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: SwiftUI.ButtonStyle.Configuration) -> some View {
        configuration.label
            .font(HealthTypography.buttonPrimary)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: HealthSpacing.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .fill(isEnabled ? HealthColors.primary : HealthColors.healthNeutral)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.05), value: configuration.isPressed) // Faster animation to reduce conflicts
            .opacity(isEnabled ? 1.0 : 0.6)
            .defersSystemGestures(on: .bottom) // Defer system gestures for button area
    }
}

// MARK: - Secondary Button Style
struct HealthSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: SwiftUI.ButtonStyle.Configuration) -> some View {
        configuration.label
            .font(HealthTypography.buttonSecondary)
            .foregroundColor(isEnabled ? HealthColors.primary : HealthColors.healthNeutral)
            .frame(maxWidth: .infinity)
            .frame(height: HealthSpacing.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .strokeBorder(
                        isEnabled ? HealthColors.primary : HealthColors.healthNeutral,
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}


// MARK: - Icon Button Style
struct HealthIconButtonStyle: ButtonStyle {
    let size: CGFloat
    let backgroundColor: Color
    
    init(size: CGFloat = 44, backgroundColor: Color = HealthColors.accent.opacity(0.1)) {
        self.size = size
        self.backgroundColor = backgroundColor
    }
    
    func makeBody(configuration: SwiftUI.ButtonStyle.Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(HealthColors.primary)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(backgroundColor)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Floating Action Button Style (for central upload button)
struct HealthFloatingActionButtonStyle: ButtonStyle {
    func makeBody(configuration: SwiftUI.ButtonStyle.Configuration) -> some View {
        configuration.label
            .font(.system(size: 24, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(HealthColors.primary)
            )
            .floatingButtonShadow()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Small Button Style
struct HealthSmallButtonStyle: ButtonStyle {
    let variant: ButtonVariant
    
    enum ButtonVariant {
        case primary
        case secondary
    }
    
    init(_ variant: ButtonVariant = .primary) {
        self.variant = variant
    }
    
    func makeBody(configuration: SwiftUI.ButtonStyle.Configuration) -> some View {
        configuration.label
            .font(HealthTypography.buttonSmall)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, HealthSpacing.lg)
            .frame(height: HealthSpacing.buttonHeightSmall)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .strokeBorder(borderColor, lineWidth: borderWidth)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return .white
        case .secondary:
            return HealthColors.primary
        }
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return HealthColors.primary
        case .secondary:
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .primary:
            return Color.clear
        case .secondary:
            return HealthColors.primary
        }
    }
    
    private var borderWidth: CGFloat {
        switch variant {
        case .primary:
            return 0
        case .secondary:
            return 1.5
        }
    }
}

// MARK: - Destructive Button Style
struct HealthDestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: SwiftUI.ButtonStyle.Configuration) -> some View {
        configuration.label
            .font(HealthTypography.buttonPrimary)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: HealthSpacing.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .fill(isEnabled ? HealthColors.healthCritical : HealthColors.healthNeutral)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Button Components
struct HealthPrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    
    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                }
            }
        }
        .buttonStyle(HealthPrimaryButtonStyle())
        .disabled(isLoading)
    }
}

struct HealthSecondaryButton: View {
    let title: String
    let action: () -> Void
    
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(title, action: action)
            .buttonStyle(HealthSecondaryButtonStyle())
    }
}

struct HealthIconButton: View {
    let icon: String
    let action: () -> Void
    let size: CGFloat
    let backgroundColor: Color
    
    init(
        icon: String,
        size: CGFloat = 44,
        backgroundColor: Color = HealthColors.accent.opacity(0.1),
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
        }
        .buttonStyle(HealthIconButtonStyle(size: size, backgroundColor: backgroundColor))
    }
}

struct HealthFloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    init(icon: String = "plus", action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
        }
        .buttonStyle(HealthFloatingActionButtonStyle())
    }
}

// MARK: - Button Previews
#Preview("Button Styles") {
    VStack(spacing: HealthSpacing.lg) {
        HealthPrimaryButton("Primary Button") { }
        
        HealthSecondaryButton("Secondary Button") { }
        
        
        HStack(spacing: HealthSpacing.md) {
            Button("Small Primary") { }
                .buttonStyle(HealthSmallButtonStyle(.primary))
            
            Button("Small Secondary") { }
                .buttonStyle(HealthSmallButtonStyle(.secondary))
            
        }
        
        HStack(spacing: HealthSpacing.lg) {
            HealthIconButton(icon: "heart.fill") { }
            HealthIconButton(icon: "bell") { }
            HealthIconButton(icon: "gear") { }
        }
        
        HealthFloatingActionButton { }
        
        Button("Destructive Button") { }
            .buttonStyle(HealthDestructiveButtonStyle())
        
        HealthPrimaryButton("Loading Button", isLoading: true) { }
    }
    .padding(HealthSpacing.screenPadding)
}