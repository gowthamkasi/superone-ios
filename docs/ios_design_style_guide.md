# iOS Health Analysis App - Design Style Guide

## 🎨 Color Palette & Theme System

### Primary Color Palette
Based on the provided green color scheme optimized for health and medical applications:

```swift
struct HealthColors {
    // Primary Green Palette (from provided image)
    static let sage = Color(hex: "#A8D5BA")      // Lightest green
    static let emerald = Color(hex: "#6BBF8A")   // Light-medium green  
    static let forest = Color(hex: "#4B9B6E")    // Medium green
    static let pine = Color(hex: "#2E7D5C")      // Dark green
    static let deepForest = Color(hex: "#1B5E3A") // Darkest green
    
    // Semantic Colors
    static let primary = forest                   // Main brand color
    static let secondary = emerald               // Secondary actions
    static let accent = sage                     // Highlights and backgrounds
    
    // System Colors (iOS 18 compatible)
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    // Text Colors
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    
    // Health Status Colors
    static let healthGood = emerald
    static let healthWarning = Color(.systemOrange)
    static let healthCritical = Color(.systemRed)
    static let healthNeutral = Color(.systemGray)
}

// Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

### Dark Mode Support

```swift
struct HealthColorsDark {
    static let sage = Color(hex: "#6B8F7A")      // Darker sage
    static let emerald = Color(hex: "#4A8F6A")   // Darker emerald
    static let forest = Color(hex: "#3A7B5E")    // Darker forest
    static let pine = Color(hex: "#256D4C")      // Darker pine
    static let deepForest = Color(hex: "#1A4E3A") // Darkest (unchanged)
}

// Dynamic Color System
extension Color {
    static let dynamicPrimary = Color.dynamic(
        light: HealthColors.forest,
        dark: HealthColorsDark.forest
    )
    
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
```

## 🔤 Typography System

### iOS-Optimized Font Hierarchy

```swift
struct HealthTypography {
    // Large Titles (iOS 18 optimized)
    static let largeTitle = Font.custom("SF Pro Display", size: 34)
        .weight(.bold)
    
    // Navigation & Screen Titles
    static let title1 = Font.custom("SF Pro Display", size: 28)
        .weight(.bold)
    
    static let title2 = Font.custom("SF Pro Display", size: 22)
        .weight(.bold)
    
    static let title3 = Font.custom("SF Pro Display", size: 20)
        .weight(.semibold)
    
    // Headlines & Section Headers
    static let headline = Font.custom("SF Pro Text", size: 17)
        .weight(.semibold)
    
    // Body Text
    static let body = Font.custom("SF Pro Text", size: 17)
        .weight(.regular)
    
    static let bodyEmphasized = Font.custom("SF Pro Text", size: 17)
        .weight(.medium)
    
    // Supporting Text
    static let callout = Font.custom("SF Pro Text", size: 16)
        .weight(.regular)
    
    static let subheadline = Font.custom("SF Pro Text", size: 15)
        .weight(.regular)
    
    static let footnote = Font.custom("SF Pro Text", size: 13)
        .weight(.regular)
    
    // Labels & Captions
    static let caption1 = Font.custom("SF Pro Text", size: 12)
        .weight(.regular)
    
    static let caption2 = Font.custom("SF Pro Text", size: 11)
        .weight(.regular)
    
    // Health-Specific Typography
    static let healthMetricValue = Font.custom("SF Pro Display", size: 36)
        .weight(.bold)
        .monospacedDigit()
    
    static let healthMetricUnit = Font.custom("SF Pro Text", size: 14)
        .weight(.medium)
}

// Dynamic Type Support
extension Font {
    static func scaledFont(_ font: Font) -> Font {
        return font.with(.scaled(relativeTo: .body))
    }
}
```

### Text Styles Implementation

```swift
struct HealthTextStyle: ViewModifier {
    let style: HealthTypography.Style
    let color: Color
    let alignment: TextAlignment
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(color)
            .multilineTextAlignment(alignment)
            .lineLimit(nil)
    }
}

extension View {
    func healthTextStyle(
        _ style: HealthTypography.Style,
        color: Color = HealthColors.primaryText,
        alignment: TextAlignment = .leading
    ) -> some View {
        modifier(HealthTextStyle(style: style, color: color, alignment: alignment))
    }
}
```

## 🧩 Component Design System

### 1. Buttons

```swift
// Primary Action Button
struct HealthPrimaryButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HealthTypography.bodyEmphasized)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isEnabled ? HealthColors.primary : HealthColors.healthNeutral)
                )
        }
        .disabled(!isEnabled)
    }
}

// Secondary Button
struct HealthSecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HealthTypography.bodyEmphasized)
                .foregroundColor(HealthColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(HealthColors.primary, lineWidth: 1.5)
                )
        }
    }
}

// Icon Button
struct HealthIconButton: View {
    let icon: String
    let action: () -> Void
    let size: CGFloat = 44
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(HealthColors.primary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(HealthColors.accent.opacity(0.1))
                )
        }
    }
}
```

### 2. Cards & Containers

```swift
// Health Metric Card
struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: HealthTrend
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(HealthTypography.subheadline)
                    .foregroundColor(HealthColors.secondaryText)
                
                Spacer()
                
                TrendIndicator(trend: trend)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(HealthTypography.healthMetricValue)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(HealthTypography.healthMetricUnit)
                    .foregroundColor(HealthColors.tertiaryText)
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// Section Container
struct HealthSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
                .padding(.horizontal, 20)
            
            content
        }
    }
}

// Lab Report Card
struct LabReportCard: View {
    let report: LabReport
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Report Type Icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(HealthColors.accent)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 20))
                            .foregroundColor(HealthColors.primary)
                    )
                
                // Report Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.title)
                        .font(HealthTypography.bodyEmphasized)
                        .foregroundColor(HealthColors.primaryText)
                        .lineLimit(1)
                    
                    Text(report.date.formatted(date: .abbreviated, time: .omitted))
                        .font(HealthTypography.footnote)
                        .foregroundColor(HealthColors.secondaryText)
                    
                    StatusBadge(status: report.status)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(HealthColors.tertiaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### 3. Form Elements

```swift
// Health Input Field
struct HealthTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(HealthTypography.subheadline)
                .foregroundColor(HealthColors.primaryText)
            
            TextField(placeholder, text: $text)
                .font(HealthTypography.body)
                .textFieldStyle(HealthTextFieldStyle())
                .keyboardType(keyboardType)
        }
    }
}

struct HealthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(HealthColors.primary.opacity(0.3), lineWidth: 1)
            )
    }
}

// Health Picker
struct HealthPicker<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    let content: Content
    
    init(
        title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._selection = selection
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(HealthTypography.subheadline)
                .foregroundColor(HealthColors.primaryText)
            
            Picker(title, selection: $selection) {
                content
            }
            .pickerStyle(.menu)
            .tint(HealthColors.primary)
        }
    }
}
```

### 4. Navigation & Layout

```swift
// Health Navigation Bar
struct HealthNavigationBar: View {
    let title: String
    let backAction: (() -> Void)?
    let trailingAction: (() -> Void)?
    let trailingIcon: String?
    
    var body: some View {
        HStack {
            if let backAction = backAction {
                Button(action: backAction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(HealthColors.primary)
                }
            }
            
            Spacer()
            
            Text(title)
                .font(HealthTypography.headline)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
            
            if let trailingAction = trailingAction,
               let trailingIcon = trailingIcon {
                Button(action: trailingAction) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(HealthColors.primary)
                }
            } else {
                Spacer().frame(width: 44) // Balance the back button
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 44)
    }
}

// Tab Bar Styling
struct HealthTabBarStyle {
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.3)
        
        // Selected item
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(HealthColors.primary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(HealthColors.primary),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Normal item
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
```

## 📐 Spacing & Layout System

### Design Tokens

```swift
struct HealthSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    
    // Semantic Spacing
    static let cardPadding = lg
    static let sectionSpacing = xl
    static let screenPadding = xl
    static let buttonHeight: CGFloat = 50
    static let iconSize: CGFloat = 24
    static let avatarSize: CGFloat = 40
}

struct HealthCornerRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let round: CGFloat = 50
}

struct HealthShadows {
    static let light = Color.black.opacity(0.04)
    static let medium = Color.black.opacity(0.08)
    static let heavy = Color.black.opacity(0.12)
}
```

## 🎭 Animations & Transitions

### Smooth Micro-interactions

```swift
struct HealthAnimations {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
    
    // Health-specific animations
    static let heartbeat = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
    static let breathe = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
}

// Animated Progress Ring
struct HealthProgressRing: View {
    let progress: Double
    let color: Color
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(HealthAnimations.standard.delay(0.2)) {
                animatedProgress = progress
            }
        }
    }
}
```

## 🌓 Accessibility & Inclusive Design

### Accessibility Implementation

```swift
struct AccessibilityHelpers {
    static func dynamicSize(base: CGFloat, category: ContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall, .small, .medium:
            return base * 0.9
        case .large:
            return base
        case .extraLarge:
            return base * 1.1
        case .extraExtraLarge:
            return base * 1.2
        case .extraExtraExtraLarge:
            return base * 1.3
        case .accessibilityMedium:
            return base * 1.4
        case .accessibilityLarge:
            return base * 1.5
        case .accessibilityExtraLarge:
            return base * 1.6
        case .accessibilityExtraExtraLarge:
            return base * 1.7
        case .accessibilityExtraExtraExtraLarge:
            return base * 1.8
        @unknown default:
            return base
        }
    }
}

// Accessible Health Metric Card
extension HealthMetricCard {
    func accessibilityOptimized() -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title): \(value) \(unit)")
            .accessibilityHint("Health metric card. Double tap for details.")
            .accessibilityValue(trend.accessibilityDescription)
    }
}
```

## 📱 iOS 18+ Specific Features

### Control Center Integration

```swift
// Health Control Widget for iOS 18
struct HealthControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.healthtracker.controls") {
            ControlWidgetButton(action: QuickLogHealthDataIntent()) {
                Label("Log Health", systemImage: "heart.fill")
            }
            .tint(HealthColors.primary)
        }
        .displayName("Health Tracker")
        .description("Quickly log health data")
    }
}

// App Intent for Control Center
struct QuickLogHealthDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Health Data"
    
    func perform() async throws -> some IntentResult {
        // Implementation for quick health data logging
        return .result()
    }
}
```

### Live Activities Support

```swift
// Health Monitoring Live Activity
struct HealthMonitoringAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentReading: String
        var status: HealthStatus
        var timestamp: Date
    }
    
    var sessionName: String
}

// Live Activity View
struct HealthMonitoringLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HealthMonitoringAttributes.self) { context in
            // Live Activity expanded view
            HealthLiveActivityView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island implementation
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HealthIndicator(status: context.state.status)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.currentReading)
                        .font(HealthTypography.caption1)
                }
            } compactLeading: {
                Image(systemName: "heart.fill")
                    .foregroundColor(HealthColors.primary)
            } compactTrailing: {
                Text(context.state.currentReading)
                    .font(HealthTypography.caption2)
            } minimal: {
                Image(systemName: "heart.fill")
                    .foregroundColor(context.state.status.color)
            }
        }
    }
}
```

This comprehensive design style guide provides a medical-grade, accessible, and modern design system optimized for iOS 18+ health applications, incorporating the provided green color palette and following Apple's Human Interface Guidelines.