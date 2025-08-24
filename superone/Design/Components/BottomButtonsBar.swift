import SwiftUI
import UIKit

/// Reusable bottom buttons bar component for internal pages
/// Supports primary/secondary button combinations with consistent styling and accessibility
@MainActor
struct BottomButtonsBar: View {
    
    // MARK: - Properties
    let primaryAction: BottomButtonAction
    let secondaryAction: BottomButtonAction?
    let isLoading: Bool
    let safeAreaBottomPadding: CGFloat
    
    // MARK: - Initialization
    init(
        primaryAction: BottomButtonAction,
        secondaryAction: BottomButtonAction? = nil,
        isLoading: Bool = false,
        safeAreaBottomPadding: CGFloat = 34
    ) {
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.isLoading = isLoading
        self.safeAreaBottomPadding = safeAreaBottomPadding
    }
    
    // MARK: - Body
    var body: some View {
        BlurView(style: .systemMaterial)
            .frame(height: contentHeight)
            .overlay {
                buttonContent
            }
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    // MARK: - Content Height
    private var contentHeight: CGFloat {
        let buttonHeight: CGFloat = 50
        let topPadding: CGFloat = 16
        let bottomPadding = safeAreaBottomPadding
        let buttonSpacing: CGFloat = secondaryAction != nil ? HealthSpacing.md : 0
        
        return buttonHeight + topPadding + bottomPadding + buttonSpacing
    }
    
    // MARK: - Button Content
    private var buttonContent: some View {
        VStack(spacing: secondaryAction != nil ? HealthSpacing.md : 0) {
            if let secondaryAction = secondaryAction {
                // Two button layout
                HStack(spacing: HealthSpacing.md) {
                    // Secondary button
                    secondaryButtonView(action: secondaryAction)
                    
                    // Primary button
                    primaryButtonView(action: primaryAction)
                }
            } else {
                // Single button layout
                primaryButtonView(action: primaryAction)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
        .padding(.top, 16)
        .padding(.bottom, safeAreaBottomPadding)
    }
    
    // MARK: - Primary Button View
    private func primaryButtonView(action: BottomButtonAction) -> some View {
        Button(action: action.action) {
            HStack(spacing: HealthSpacing.sm) {
                if isLoading && action.showLoadingState {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: action.style.textColor))
                } else {
                    if let icon = action.icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(action.title)
                        .healthTextStyle(.buttonPrimary, color: action.style.textColor)
                }
            }
            .foregroundColor(action.style.textColor)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(action.style.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .stroke(action.style.borderColor, lineWidth: action.style.borderWidth)
            )
        }
        .disabled(action.isDisabled || (isLoading && action.showLoadingState))
        .opacity(action.isDisabled ? 0.6 : 1.0)
        .accessibilityLabel(action.accessibilityLabel ?? action.title)
        .accessibilityHint(action.accessibilityHint ?? "")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Secondary Button View
    private func secondaryButtonView(action: BottomButtonAction) -> some View {
        Button(action: action.action) {
            HStack(spacing: HealthSpacing.sm) {
                if let icon = action.icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(action.title)
                    .healthTextStyle(.buttonSecondary, color: action.style.textColor)
            }
            .foregroundColor(action.style.textColor)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(action.style.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                    .stroke(action.style.borderColor, lineWidth: action.style.borderWidth)
            )
        }
        .disabled(action.isDisabled)
        .opacity(action.isDisabled ? 0.6 : 1.0)
        .accessibilityLabel(action.accessibilityLabel ?? action.title)
        .accessibilityHint(action.accessibilityHint ?? "")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Bottom Button Action
struct BottomButtonAction: Sendable {
    let title: String
    let icon: String?
    let style: BottomButtonStyleType
    let action: @Sendable () -> Void
    let isDisabled: Bool
    let showLoadingState: Bool
    let accessibilityLabel: String?
    let accessibilityHint: String?
    
    init(
        title: String,
        icon: String? = nil,
        style: BottomButtonStyleType = .primary,
        isDisabled: Bool = false,
        showLoadingState: Bool = true,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        action: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isDisabled = isDisabled
        self.showLoadingState = showLoadingState
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
}

// MARK: - Bottom Button Style
enum BottomButtonStyleType {
    case primary
    case secondary
    case outline
    case destructive
    case custom(backgroundColor: Color, textColor: Color, borderColor: Color, borderWidth: CGFloat)
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return HealthColors.primary
        case .secondary:
            return HealthColors.primary.opacity(0.1)
        case .outline:
            return Color.clear
        case .destructive:
            return Color.red
        case .custom(let backgroundColor, _, _, _):
            return backgroundColor
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary, .destructive:
            return .white
        case .secondary, .outline:
            return HealthColors.primary
        case .custom(_, let textColor, _, _):
            return textColor
        }
    }
    
    var borderColor: Color {
        switch self {
        case .primary, .secondary, .destructive:
            return Color.clear
        case .outline:
            return HealthColors.primary
        case .custom(_, _, let borderColor, _):
            return borderColor
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .primary, .secondary, .destructive:
            return 0
        case .outline:
            return 1
        case .custom(_, _, _, let borderWidth):
            return borderWidth
        }
    }
}

// MARK: - Common Button Actions
extension BottomButtonAction {
    static func book(action: @escaping @Sendable () -> Void) -> BottomButtonAction {
        BottomButtonAction(
            title: "Book Test",
            icon: "calendar.badge.plus",
            style: .primary,
            accessibilityLabel: "Book test appointment",
            accessibilityHint: "Double tap to proceed with booking this test",
            action: action
        )
    }
    
    static func addToCart(action: @escaping @Sendable () -> Void) -> BottomButtonAction {
        BottomButtonAction(
            title: "Add to Cart",
            icon: "cart.badge.plus",
            style: .secondary,
            showLoadingState: false,
            accessibilityLabel: "Add to cart",
            accessibilityHint: "Double tap to add this test to your cart",
            action: action
        )
    }
    
    static func save(action: @escaping @Sendable () -> Void) -> BottomButtonAction {
        BottomButtonAction(
            title: "Save",
            icon: "heart",
            style: .outline,
            showLoadingState: false,
            accessibilityLabel: "Save test",
            accessibilityHint: "Double tap to save this test for later",
            action: action
        )
    }
    
    static func share(action: @escaping @Sendable () -> Void) -> BottomButtonAction {
        BottomButtonAction(
            title: "Share",
            icon: "square.and.arrow.up",
            style: .outline,
            showLoadingState: false,
            accessibilityLabel: "Share test",
            accessibilityHint: "Double tap to share this test information",
            action: action
        )
    }
    
    static func cancel(action: @escaping @Sendable () -> Void) -> BottomButtonAction {
        BottomButtonAction(
            title: "Cancel",
            style: .outline,
            showLoadingState: false,
            accessibilityLabel: "Cancel",
            accessibilityHint: "Double tap to cancel and go back",
            action: action
        )
    }
}

// MARK: - Blur View Helper
private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Preview
// Preview removed to avoid compilation issues