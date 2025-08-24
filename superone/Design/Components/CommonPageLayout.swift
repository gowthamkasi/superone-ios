import SwiftUI
import UIKit

/// Common layout component for internal pages with consistent structure
/// Provides header, scrollable content area, and optional bottom actions
@MainActor
struct CommonPageLayout<Content: View, BottomContent: View>: View {
    
    // MARK: - Properties
    let content: Content
    let bottomContent: BottomContent?
    
    // MARK: - Animation Properties
    @State private var headerOffset: CGFloat = 0
    @State private var showFloatingHeader = false
    
    // MARK: - Initializers
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottomContent: () -> BottomContent
    ) {
        self.content = content()
        self.bottomContent = bottomContent()
    }
    
    init(
        @ViewBuilder content: () -> Content
    ) where BottomContent == EmptyView {
        self.content = content()
        self.bottomContent = nil
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main scrollable content
            mainScrollView
            
            // Fixed bottom content if provided
            if let bottomContent = bottomContent {
                bottomContent
            }
        }
        .navigationBarHidden(true)
        .background(HealthColors.secondaryBackground.ignoresSafeArea())
    }
    
    // MARK: - Main Scroll View
    private var mainScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                content
                
                // Bottom spacing for floating action bar
                if bottomContent != nil {
                    Spacer()
                        .frame(height: 120)
                }
            }
        }
        .coordinateSpace(name: "scroll")
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            headerOffset = value
            withAnimation(.easeInOut(duration: 0.25)) {
                showFloatingHeader = value < -100
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
// Preview removed to avoid compilation issues

// MARK: - Blur View Helper
private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}