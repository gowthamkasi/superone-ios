import SwiftUI
import UIKit

/// Reusable header component for internal pages with consistent navigation and actions
/// Supports floating header that appears on scroll
@MainActor
struct CommonPageHeader: View {
    
    // MARK: - Properties
    let title: String
    let subtitle: String?
    let showFloatingHeader: Bool
    let rightActions: [HeaderAction]
    let onBackTap: () -> Void
    
    // MARK: - Initialization
    init(
        title: String,
        subtitle: String? = nil,
        showFloatingHeader: Bool = false,
        rightActions: [HeaderAction] = [
            .save { /* Default empty action */ },
            .share { /* Default empty action */ }
        ],
        onBackTap: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showFloatingHeader = showFloatingHeader
        self.rightActions = rightActions
        self.onBackTap = onBackTap
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background gradient
            headerBackground
            
            // Header content
            headerContent
            
            // Floating header overlay
            if showFloatingHeader {
                floatingHeader
            }
        }
    }
    
    // MARK: - Header Background
    private var headerBackground: some View {
        LinearGradient(
            colors: [
                HealthColors.primary.opacity(0.1),
                HealthColors.secondaryBackground
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: subtitle != nil ? 140 : 120)
    }
    
    // MARK: - Header Content
    private var headerContent: some View {
        VStack(spacing: 0) {
            // Status bar spacer
            Rectangle()
                .fill(Color.clear)
                .frame(height: 44)
            
            // Navigation and actions
            HStack(spacing: HealthSpacing.md) {
                // Back button
                backButton
                
                // Title content
                titleContent
                
                Spacer()
                
                // Right action buttons
                rightActionButtons
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            
            // Subtitle if provided
            if let subtitle = subtitle {
                HStack {
                    Text(subtitle)
                        .healthTextStyle(.subheadline, color: HealthColors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, HealthSpacing.screenPadding)
                    
                    Spacer()
                }
                .padding(.top, HealthSpacing.xs)
            }
        }
    }
    
    // MARK: - Back Button
    private var backButton: some View {
        Button(action: onBackTap) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(HealthColors.primaryText)
                .frame(width: 44, height: 44)
                .background(HealthColors.primaryBackground)
                .clipShape(Circle())
                .healthCardShadow()
        }
        .accessibilityLabel("Back")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Title Content
    private var titleContent: some View {
        Text(title)
            .healthTextStyle(.title3, color: HealthColors.primaryText)
            .lineLimit(1)
            .padding(.horizontal, HealthSpacing.md)
    }
    
    // MARK: - Right Action Buttons
    private var rightActionButtons: some View {
        HStack(spacing: HealthSpacing.md) {
            ForEach(rightActions, id: \.self) { action in
                actionButton(for: action)
            }
        }
    }
    
    // MARK: - Action Button
    private func actionButton(for action: HeaderAction) -> some View {
        Button(action: action.action) {
            Image(systemName: action.systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(action.color)
                .frame(width: 44, height: 44)
                .background(HealthColors.primaryBackground)
                .clipShape(Circle())
                .healthCardShadow()
        }
        .accessibilityLabel(action.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Floating Header
    private var floatingHeader: some View {
        BlurView(style: .systemMaterial)
            .frame(height: 94)
            .overlay {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 44)
                    
                    HStack(spacing: HealthSpacing.md) {
                        // Compact back button
                        Button(action: onBackTap) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(HealthColors.primaryText)
                        }
                        
                        // Compact title
                        Text(title)
                            .healthTextStyle(.headline, color: HealthColors.primaryText)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Compact right actions
                        HStack(spacing: HealthSpacing.sm) {
                            ForEach(rightActions, id: \.self) { action in
                                Button(action: action.action) {
                                    Image(systemName: action.systemImage)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(action.color)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, HealthSpacing.screenPadding)
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Header Action
struct HeaderAction: Hashable, Sendable {
    let id = UUID()
    let systemImage: String
    let color: Color
    let accessibilityLabel: String
    let action: @Sendable () -> Void
    
    init(
        systemImage: String,
        color: Color = HealthColors.secondaryText,
        accessibilityLabel: String,
        action: @escaping @Sendable () -> Void
    ) {
        self.systemImage = systemImage
        self.color = color
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: HeaderAction, rhs: HeaderAction) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Common Actions
    static func save(action: @escaping @Sendable () -> Void) -> HeaderAction {
        HeaderAction(
            systemImage: "heart",
            color: HealthColors.secondaryText,
            accessibilityLabel: "Save",
            action: action
        )
    }
    
    static func savedState(isSaved: Bool, action: @escaping @Sendable () -> Void) -> HeaderAction {
        HeaderAction(
            systemImage: isSaved ? "heart.fill" : "heart",
            color: isSaved ? .red : HealthColors.secondaryText,
            accessibilityLabel: isSaved ? "Remove from saved" : "Save",
            action: action
        )
    }
    
    static func share(action: @escaping @Sendable () -> Void) -> HeaderAction {
        HeaderAction(
            systemImage: "square.and.arrow.up",
            color: HealthColors.secondaryText,
            accessibilityLabel: "Share",
            action: action
        )
    }
    
    static func edit(action: @escaping @Sendable () -> Void) -> HeaderAction {
        HeaderAction(
            systemImage: "pencil",
            color: HealthColors.secondaryText,
            accessibilityLabel: "Edit",
            action: action
        )
    }
    
    static func more(action: @escaping @Sendable () -> Void) -> HeaderAction {
        HeaderAction(
            systemImage: "ellipsis",
            color: HealthColors.secondaryText,
            accessibilityLabel: "More options",
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