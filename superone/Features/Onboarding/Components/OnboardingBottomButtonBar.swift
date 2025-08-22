import SwiftUI

/// Standardized bottom button bar for onboarding views with consistent positioning and layout
struct OnboardingBottomButtonBar: View {
    let configuration: ButtonConfiguration
    
    var body: some View {
        VStack(spacing: 0) {
            // Top border for visual separation
            Rectangle()
                .fill(HealthColors.accent.opacity(0.2))
                .frame(height: 1)
            
            // Button content with background
            buttonContent
                .background(
                    HealthColors.background
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                )
        }
    }
    
    // MARK: - Button Content
    
    @ViewBuilder
    private var buttonContent: some View {
        VStack(spacing: HealthSpacing.md) {
            switch configuration.layout {
            case .single(let action):
                singleButtonLayout(action: action)
                
            case .dual(let leftAction, let rightAction):
                dualButtonLayout(leftAction: leftAction, rightAction: rightAction)
                
            case .triple(let leftAction, let centerAction, let rightAction):
                tripleButtonLayout(leftAction: leftAction, centerAction: centerAction, rightAction: rightAction)
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
        .padding(.top, HealthSpacing.md)
//        .safeAreaPadding(.bottom)@todo add more spacing at bottom uncomment this
    }
    
    // MARK: - Layout Variations
    
    private func singleButtonLayout(action: ButtonAction) -> some View {
        buttonView(for: action)
    }
    
    private func dualButtonLayout(leftAction: ButtonAction, rightAction: ButtonAction) -> some View {
        HStack(spacing: HealthSpacing.md) {
            buttonView(for: leftAction)
            buttonView(for: rightAction)
        }
    }
    
    private func tripleButtonLayout(leftAction: ButtonAction, centerAction: ButtonAction, rightAction: ButtonAction) -> some View {
        VStack(spacing: HealthSpacing.md) {
            // Primary action (full width)
            buttonView(for: rightAction)
            
            // Secondary actions (equal width, side by side)
            HStack(spacing: HealthSpacing.md) {
                buttonView(for: leftAction)
                    .frame(maxWidth: .infinity)
                buttonView(for: centerAction)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Button View Builder
    
    @ViewBuilder
    private func buttonView(for action: ButtonAction) -> some View {
        switch action.style {
        case .primary:
            HealthPrimaryButton(action.title, isLoading: action.isLoading) {
                // HapticFeedback now handles async execution internally
                HapticFeedback.medium()
                action.handler()
            }
            .disabled(action.isDisabled)
            
        case .secondary:
            HealthSecondaryButton(action.title) {
                // HapticFeedback now handles async execution internally
                HapticFeedback.light()
                action.handler()
            }
            .disabled(action.isDisabled)
            
        }
    }
    
}

// MARK: - Configuration Models

struct ButtonConfiguration {
    let layout: ButtonLayout
    
    enum ButtonLayout {
        case single(ButtonAction)
        case dual(left: ButtonAction, right: ButtonAction)
        case triple(left: ButtonAction, center: ButtonAction, right: ButtonAction)
    }
}

struct ButtonAction {
    let title: String
    let style: ButtonStyle
    let isLoading: Bool
    let isDisabled: Bool
    let handler: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
    }
    
    init(
        title: String,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.handler = handler
    }
}

// MARK: - Convenience Initializers

extension ButtonConfiguration {
    /// Single button configuration (typically for primary actions)
    static func single(
        title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        handler: @escaping () -> Void
    ) -> ButtonConfiguration {
        ButtonConfiguration(
            layout: .single(
                ButtonAction(
                    title: title,
                    style: .primary,
                    isLoading: isLoading,
                    isDisabled: isDisabled,
                    handler: handler
                )
            )
        )
    }
    
    /// Dual button configuration (back + continue pattern)
    static func dual(
        leftTitle: String,
        leftStyle: ButtonAction.ButtonStyle = .secondary,
        leftHandler: @escaping () -> Void,
        rightTitle: String,
        rightStyle: ButtonAction.ButtonStyle = .primary,
        rightIsLoading: Bool = false,
        rightIsDisabled: Bool = false,
        rightHandler: @escaping () -> Void
    ) -> ButtonConfiguration {
        ButtonConfiguration(
            layout: .dual(
                left: ButtonAction(
                    title: leftTitle,
                    style: leftStyle,
                    handler: leftHandler
                ),
                right: ButtonAction(
                    title: rightTitle,
                    style: rightStyle,
                    isLoading: rightIsLoading,
                    isDisabled: rightIsDisabled,
                    handler: rightHandler
                )
            )
        )
    }
    
    /// Triple button configuration (back + skip/secondary + primary)
    static func triple(
        leftTitle: String,
        leftHandler: @escaping () -> Void,
        centerTitle: String,
        centerHandler: @escaping () -> Void,
        rightTitle: String,
        rightIsLoading: Bool = false,
        rightHandler: @escaping () -> Void
    ) -> ButtonConfiguration {
        ButtonConfiguration(
            layout: .triple(
                left: ButtonAction(
                    title: leftTitle,
                    style: .secondary,
                    handler: leftHandler
                ),
                center: ButtonAction(
                    title: centerTitle,
                    style: .secondary,
                    handler: centerHandler
                ),
                right: ButtonAction(
                    title: rightTitle,
                    style: .primary,
                    isLoading: rightIsLoading,
                    handler: rightHandler
                )
            )
        )
    }
}

// MARK: - Preview

#Preview("Single Button") {
    OnboardingBottomButtonBar(
        configuration: .single(
            title: "Get Started",
            handler: {}
        )
    )
}

#Preview("Dual Buttons") {
    OnboardingBottomButtonBar(
        configuration: .dual(
            leftTitle: "Back",
            leftHandler: {},
            rightTitle: "Continue",
            rightHandler: {}
        )
    )
}

#Preview("Triple Buttons") {
    OnboardingBottomButtonBar(
        configuration: .triple(
            leftTitle: "Back",
            leftHandler: {},
            centerTitle: "Skip",
            centerHandler: {},
            rightTitle: "Allow Access",
            rightHandler: {}
        )
    )
}
