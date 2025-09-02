//
//  SkeletonComponents.swift
//  SuperOne
//
//  Created by Claude Code on 1/30/25.
//  Comprehensive skeleton loading system for professional loading states
//

import SwiftUI

// MARK: - Base Skeleton System

/// Professional shimmer-based skeleton view for loading states
struct HealthSkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var isAnimating = false
    
    init(
        width: CGFloat? = nil,
        height: CGFloat = 16,
        cornerRadius: CGFloat = HealthCornerRadius.xs
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(HealthColors.secondaryBackground)
            .frame(width: width, height: height)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                HealthColors.background.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 300 : -300)
                    .animation(
                        Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .cornerRadius(cornerRadius)
            .onAppear {
                isAnimating = true
            }
            .clipped()
    }
}

// MARK: - Specialized Skeleton Components

/// Skeleton for list item rows with icon, title, and subtitle
struct ListItemSkeleton: View {
    let showIcon: Bool
    let showSubtitle: Bool
    let showTrailing: Bool
    
    init(
        showIcon: Bool = true,
        showSubtitle: Bool = true,
        showTrailing: Bool = false
    ) {
        self.showIcon = showIcon
        self.showSubtitle = showSubtitle
        self.showTrailing = showTrailing
    }
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            // Leading icon
            if showIcon {
                HealthSkeletonView(
                    width: HealthSpacing.iconSize,
                    height: HealthSpacing.iconSize,
                    cornerRadius: HealthCornerRadius.sm
                )
            }
            
            // Content area
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                // Title line - varying width for realistic appearance
                HealthSkeletonView(
                    width: .random(in: 120...200),
                    height: 16
                )
                
                // Subtitle line
                if showSubtitle {
                    HealthSkeletonView(
                        width: .random(in: 80...150),
                        height: 14
                    )
                }
            }
            
            Spacer()
            
            // Trailing element (chevron, toggle, etc.)
            if showTrailing {
                HealthSkeletonView(
                    width: 20,
                    height: 14,
                    cornerRadius: HealthCornerRadius.xs
                )
            }
        }
        .padding(.vertical, HealthSpacing.sm)
    }
}

/// Skeleton for card-based content with header and body
struct CardSkeleton: View {
    let showImage: Bool
    let imageSize: CGSize
    let contentLines: Int
    
    init(
        showImage: Bool = false,
        imageSize: CGSize = CGSize(width: 60, height: 60),
        contentLines: Int = 3
    ) {
        self.showImage = showImage
        self.imageSize = imageSize
        self.contentLines = contentLines
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Header area
            HStack(spacing: HealthSpacing.md) {
                // Optional image/icon
                if showImage {
                    HealthSkeletonView(
                        width: imageSize.width,
                        height: imageSize.height,
                        cornerRadius: HealthCornerRadius.md
                    )
                }
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    // Title
                    HealthSkeletonView(
                        width: .random(in: 140...220),
                        height: 18
                    )
                    
                    // Subtitle
                    HealthSkeletonView(
                        width: .random(in: 100...180),
                        height: 14
                    )
                }
                
                Spacer()
            }
            
            // Content lines
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                ForEach(0..<contentLines, id: \.self) { index in
                    HealthSkeletonView(
                        width: index == contentLines - 1 ? .random(in: 100...180) : nil,
                        height: 14
                    )
                }
            }
        }
        .padding(HealthSpacing.cardPadding)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

/// Skeleton for detail view sections
struct DetailsSkeleton: View {
    let sectionCount: Int
    let itemsPerSection: Int
    
    init(sectionCount: Int = 2, itemsPerSection: Int = 3) {
        self.sectionCount = sectionCount
        self.itemsPerSection = itemsPerSection
    }
    
    var body: some View {
        VStack(spacing: HealthSpacing.xl) {
            ForEach(0..<sectionCount, id: \.self) { sectionIndex in
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    // Section header
                    HStack {
                        HealthSkeletonView(
                            width: 24,
                            height: 24,
                            cornerRadius: HealthCornerRadius.sm
                        )
                        
                        HealthSkeletonView(
                            width: .random(in: 100...160),
                            height: 20
                        )
                        
                        Spacer()
                    }
                    
                    // Section content
                    VStack(spacing: HealthSpacing.md) {
                        ForEach(0..<itemsPerSection, id: \.self) { _ in
                            ListItemSkeleton(showTrailing: true)
                        }
                    }
                    .padding(HealthSpacing.lg)
                    .background(HealthColors.secondaryBackground)
                    .cornerRadius(HealthCornerRadius.card)
                }
            }
        }
    }
}

/// Skeleton for grid-based layouts
struct GridItemSkeleton: View {
    let imageAspectRatio: CGFloat
    let showTitle: Bool
    let showSubtitle: Bool
    
    init(
        imageAspectRatio: CGFloat = 1.0,
        showTitle: Bool = true,
        showSubtitle: Bool = true
    ) {
        self.imageAspectRatio = imageAspectRatio
        self.showTitle = showTitle
        self.showSubtitle = showSubtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            // Image placeholder
            HealthSkeletonView(
                height: 120 / imageAspectRatio,
                cornerRadius: HealthCornerRadius.md
            )
            
            if showTitle || showSubtitle {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    // Title
                    if showTitle {
                        HealthSkeletonView(
                            width: .random(in: 80...120),
                            height: 16
                        )
                    }
                    
                    // Subtitle
                    if showSubtitle {
                        HealthSkeletonView(
                            width: .random(in: 60...100),
                            height: 14
                        )
                    }
                }
                .padding(.horizontal, HealthSpacing.sm)
            }
        }
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

/// Skeleton for headers and navigation elements
struct HeaderSkeleton: View {
    let showAvatar: Bool
    let showActions: Bool
    
    init(showAvatar: Bool = false, showActions: Bool = true) {
        self.showAvatar = showAvatar
        self.showActions = showActions
    }
    
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            // Avatar
            if showAvatar {
                HealthSkeletonView(
                    width: HealthSpacing.avatarSize,
                    height: HealthSpacing.avatarSize,
                    cornerRadius: HealthSpacing.avatarSize / 2
                )
            }
            
            // Title area
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                HealthSkeletonView(
                    width: .random(in: 150...250),
                    height: 24
                )
                
                HealthSkeletonView(
                    width: .random(in: 100...180),
                    height: 16
                )
            }
            
            Spacer()
            
            // Action buttons
            if showActions {
                HStack(spacing: HealthSpacing.sm) {
                    HealthSkeletonView(
                        width: 32,
                        height: 32,
                        cornerRadius: HealthCornerRadius.sm
                    )
                    
                    HealthSkeletonView(
                        width: 32,
                        height: 32,
                        cornerRadius: HealthCornerRadius.sm
                    )
                }
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
}

// MARK: - Specialized Health App Skeletons

/// Skeleton for test cards in TestsListView
struct TestCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.md) {
                // Test icon
                HealthSkeletonView(
                    width: 40,
                    height: 40,
                    cornerRadius: HealthCornerRadius.sm
                )
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    // Test name
                    HealthSkeletonView(
                        width: .random(in: 160...240),
                        height: 18
                    )
                    
                    // Test category
                    HealthSkeletonView(
                        width: .random(in: 100...150),
                        height: 14
                    )
                }
                
                Spacer()
                
                // Price/action area
                VStack(alignment: .trailing, spacing: HealthSpacing.xs) {
                    HealthSkeletonView(
                        width: 60,
                        height: 16
                    )
                    
                    HealthSkeletonView(
                        width: 40,
                        height: 14
                    )
                }
            }
            
            // Description area
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                HealthSkeletonView(height: 14)
                HealthSkeletonView(
                    width: .random(in: 200...280),
                    height: 14
                )
            }
            
            // Tags/attributes
            HStack(spacing: HealthSpacing.sm) {
                HealthSkeletonView(
                    width: 60,
                    height: 24,
                    cornerRadius: HealthCornerRadius.round
                )
                
                HealthSkeletonView(
                    width: 80,
                    height: 24,
                    cornerRadius: HealthCornerRadius.round
                )
                
                Spacer()
            }
        }
        .padding(HealthSpacing.cardPadding)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

/// Skeleton for appointment cards
struct AppointmentCardSkeleton: View {
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            // Date/time area
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                HealthSkeletonView(
                    width: 40,
                    height: 20
                )
                
                HealthSkeletonView(
                    width: 60,
                    height: 16
                )
            }
            
            Rectangle()
                .fill(HealthColors.primary.opacity(0.3))
                .frame(width: 2, height: 60)
            
            // Appointment details
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                HealthSkeletonView(
                    width: .random(in: 120...200),
                    height: 18
                )
                
                HealthSkeletonView(
                    width: .random(in: 100...160),
                    height: 14
                )
                
                HealthSkeletonView(
                    width: .random(in: 80...140),
                    height: 14
                )
            }
            
            Spacer()
            
            // Status indicator
            HealthSkeletonView(
                width: 24,
                height: 24,
                cornerRadius: 12
            )
        }
        .padding(HealthSpacing.cardPadding)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

/// Skeleton for lab facility cards
struct LabFacilitySkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Facility image
            HealthSkeletonView(
                height: 80,
                cornerRadius: HealthCornerRadius.md
            )
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                // Facility name
                HealthSkeletonView(
                    width: .random(in: 100...140),
                    height: 16
                )
                
                // Location
                HealthSkeletonView(
                    width: .random(in: 80...120),
                    height: 14
                )
                
                // Rating/distance
                HStack(spacing: HealthSpacing.sm) {
                    HealthSkeletonView(
                        width: 50,
                        height: 12
                    )
                    
                    HealthSkeletonView(
                        width: 40,
                        height: 12
                    )
                    
                    Spacer()
                }
            }
            .padding(.horizontal, HealthSpacing.sm)
        }
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

/// Skeleton for health score cards
struct HealthScoreCardSkeleton: View {
    var body: some View {
        VStack(spacing: HealthSpacing.md) {
            // Score circle
            Circle()
                .fill(HealthColors.secondaryBackground)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(HealthColors.primary.opacity(0.3), lineWidth: 8)
                )
            
            VStack(spacing: HealthSpacing.xs) {
                // Category name
                HealthSkeletonView(
                    width: .random(in: 80...120),
                    height: 16
                )
                
                // Status text
                HealthSkeletonView(
                    width: .random(in: 60...100),
                    height: 14
                )
            }
        }
        .padding(HealthSpacing.cardPadding)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

/// Skeleton for report cards
struct ReportCardSkeleton: View {
    var body: some View {
        HStack(spacing: HealthSpacing.md) {
            // Report thumbnail
            HealthSkeletonView(
                width: 60,
                height: 80,
                cornerRadius: HealthCornerRadius.md
            )
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                // Report name
                HealthSkeletonView(
                    width: .random(in: 150...220),
                    height: 18
                )
                
                // Date
                HealthSkeletonView(
                    width: .random(in: 100...140),
                    height: 14
                )
                
                // Status/progress
                HealthSkeletonView(
                    width: .random(in: 80...120),
                    height: 14
                )
                
                // Analysis status
                HStack(spacing: HealthSpacing.sm) {
                    HealthSkeletonView(
                        width: 60,
                        height: 20,
                        cornerRadius: HealthCornerRadius.round
                    )
                    
                    HealthSkeletonView(
                        width: 40,
                        height: 20,
                        cornerRadius: HealthCornerRadius.round
                    )
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Action button
            HealthSkeletonView(
                width: 32,
                height: 32,
                cornerRadius: HealthCornerRadius.sm
            )
        }
        .padding(HealthSpacing.cardPadding)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

// MARK: - Container Views for Multiple Skeletons

/// Container for displaying multiple skeleton items with staggered animation
struct SkeletonList<Content: View>: View {
    let count: Int
    let spacing: CGFloat
    let staggerDelay: Double
    @ViewBuilder let skeletonContent: (Int) -> Content
    
    @State private var visibleItems: Set<Int> = []
    
    init(
        count: Int,
        spacing: CGFloat = HealthSpacing.md,
        staggerDelay: Double = 0.1,
        @ViewBuilder skeletonContent: @escaping (Int) -> Content
    ) {
        self.count = count
        self.spacing = spacing
        self.staggerDelay = staggerDelay
        self.skeletonContent = skeletonContent
    }
    
    var body: some View {
        LazyVStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { index in
                skeletonContent(index)
                    .opacity(visibleItems.contains(index) ? 1 : 0)
                    .scaleEffect(visibleItems.contains(index) ? 1 : 0.8)
                    .animation(
                        .easeOut(duration: 0.4).delay(Double(index) * staggerDelay),
                        value: visibleItems.contains(index)
                    )
            }
        }
        .onAppear {
            // Stagger the appearance of items
            for index in 0..<count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * staggerDelay) {
                    visibleItems.insert(index)
                }
            }
        }
    }
}

// MARK: - View Modifier for Easy Skeleton Loading

extension View {
    /// Apply skeleton loading state to any view
    func skeletonLoading<SkeletonContent: View>(
        isLoading: Bool,
        @ViewBuilder skeleton: () -> SkeletonContent
    ) -> some View {
        ZStack {
            if isLoading {
                skeleton()
                    .transition(.opacity)
            } else {
                self
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

// MARK: - Previews

#Preview("Health Skeleton View") {
    VStack(spacing: HealthSpacing.lg) {
        HealthSkeletonView(width: 200, height: 20)
        HealthSkeletonView(width: 150, height: 16)
        HealthSkeletonView(width: 100, height: 14)
    }
    .padding()
}

#Preview("List Item Skeleton") {
    VStack(spacing: HealthSpacing.md) {
        ListItemSkeleton()
        ListItemSkeleton(showSubtitle: false)
        ListItemSkeleton(showIcon: false, showTrailing: true)
    }
    .padding()
}

#Preview("Card Skeleton") {
    CardSkeleton(showImage: true, contentLines: 3)
        .padding()
}

#Preview("Test Card Skeleton") {
    VStack(spacing: HealthSpacing.md) {
        TestCardSkeleton()
        TestCardSkeleton()
    }
    .padding()
}

#Preview("Health Score Cards") {
    HStack(spacing: HealthSpacing.md) {
        HealthScoreCardSkeleton()
        HealthScoreCardSkeleton()
        HealthScoreCardSkeleton()
    }
    .padding()
}

#Preview("Staggered List") {
    SkeletonList(count: 5, staggerDelay: 0.15) { index in
        TestCardSkeleton()
    }
    .padding()
}