# Super One Health - iOS App

A comprehensive health tracking and lab appointment booking app built with SwiftUI for iOS 18+.

## 🏥 Overview

Super One Health is a native iOS application that provides users with comprehensive health tracking, lab report analysis, and appointment booking capabilities. The app integrates with the Super One backend API to deliver AI-powered health insights and seamless appointment management.

## ✨ Features

### 🗓️ Appointment Management
- **Smart Scheduling**: Book appointments at nearby lab facilities
- **Today's Schedule**: Enhanced today view with preparation checklists
- **Appointment Tracking**: Real-time status updates and notifications
- **Flexible Rebooking**: Easy rescheduling and cancellation options

### 🧪 Lab Services
- **Walk-in Labs**: Discover nearby lab facilities with real-time wait times
- **Home Collection**: Schedule convenient at-home sample collection
- **Test Packages**: Browse curated health packages and individual tests
- **Smart Search**: Find labs, tests, and services by location or type

### 📍 Location Services
- **Automatic Detection**: Proactive location detection with iOS 18+ privacy features
- **Smart Caching**: Efficient location caching and reverse geocoding
- **Privacy-First**: Modern CLServiceSession implementation for enhanced privacy

### 🔬 Health Insights
- **Lab Report Processing**: OCR and AI analysis of medical reports
- **Health Trends**: Track biomarkers and health metrics over time
- **Personalized Recommendations**: AI-powered health guidance

### 🔐 Security & Privacy
- **Biometric Authentication**: Face ID/Touch ID support
- **Data Encryption**: End-to-end encryption for sensitive health data
- **HIPAA Compliance**: Healthcare-grade privacy and security

## 🛠️ Technical Stack

### Core Technologies
- **SwiftUI 6.0**: Modern declarative UI framework
- **Swift 6.0**: Latest Swift with strict concurrency
- **iOS 18.0+**: Target deployment version
- **Core Location**: Enhanced location services with CLServiceSession
- **HealthKit**: Comprehensive health data integration

### Architecture
- **MVVM Pattern**: Model-View-ViewModel architecture
- **Observable Pattern**: SwiftUI @Observable and @Bindable
- **Async/Await**: Modern Swift concurrency throughout
- **Clean Architecture**: Separation of concerns with services and utilities

### Dependencies (SPM)
```swift
dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire", from: "5.8.0"),
    .package(url: "https://github.com/KeychainAccess/KeychainAccess", from: "4.2.2"),
    .package(url: "https://github.com/danielgindi/Charts", from: "5.0.0"),
    .package(url: "https://github.com/onevcat/Kingfisher", from: "7.9.0")
]
```

## 🚀 Getting Started

### Prerequisites
- **Xcode 16.0 Beta** or later
- **macOS Sonoma 14.5+** with Apple Silicon Mac (16GB+ unified memory recommended)
- **iOS 18.0+** simulator or device for testing

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd "Super One/superone"
   ```

2. **Open in Xcode**
   ```bash
   open superone.xcodeproj
   ```

3. **Configure signing**
   - Select your development team in project settings
   - Configure App ID and provisioning profiles

4. **Set up permissions**
   - Ensure Info.plist includes required usage descriptions
   - Configure HealthKit entitlements

5. **Build and run**
   ```bash
   # Build the app
   xcodebuild -scheme superone -configuration Debug build
   
   # Run tests
   xcodebuild -scheme superone -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
   ```

## 📁 Project Structure

```
superone/
├── App/                          # App configuration and entry point
│   ├── superoneApp.swift         # Main app file
│   └── AppState.swift            # Global app state management
├── Features/                     # Feature-based modular architecture
│   ├── Appointments/             # Appointment booking and management
│   │   ├── Views/               # SwiftUI views
│   │   ├── ViewModels/          # Presentation logic
│   │   └── Components/          # Reusable UI components
│   ├── Dashboard/               # Main health overview
│   ├── LabReports/              # Lab report processing and analysis
│   ├── Profile/                 # User profile and settings
│   └── Location/                # Location services and UI
├── Core/                        # Shared business logic
│   ├── Services/                # Business services
│   │   ├── LocationManager.swift # Location services with iOS 18+ features
│   │   ├── HealthKitManager.swift # HealthKit integration
│   │   └── NetworkManager.swift  # API communication
│   ├── Models/                  # Data models and entities
│   └── Configuration/           # App configuration
├── Design/                      # Design system and components
│   ├── DesignSystem/            # Colors, typography, spacing
│   │   ├── HealthColors.swift   # Health-focused color palette
│   │   ├── HealthTypography.swift # Typography system
│   │   └── HealthSpacing.swift  # Spacing and layout constants
│   └── Components/              # Reusable UI components
└── Resources/                   # Assets and resources
    ├── Assets.xcassets          # Images and colors
    └── Info.plist               # App configuration
```

## 🎨 Design System

### Color Palette
- **Primary Green**: `#00C896` - Health-focused brand color
- **Health Status Colors**: Good (Green), Warning (Amber), Critical (Red)
- **Adaptive Colors**: Support for dark mode with semantic colors

### Typography
- **Headlines**: SF Pro Display - Bold, prominent headings
- **Body Text**: SF Pro Text - Readable body content
- **Captions**: SF Pro Text - Secondary information

### Spacing & Layout
- **Consistent Grid**: 8pt base grid system
- **Health Spacing**: Semantic spacing tokens (xs, sm, md, lg, xl)
- **Corner Radius**: Consistent radius system for cards and buttons

## 🔧 Configuration

### Environment Setup

1. **Backend API Configuration**
   ```swift
   // AppConfiguration.swift
   static let apiBaseURL = "https://api.superonehealth.com"
   static let apiVersion = "v1"
   ```

2. **Location Services**
   ```xml
   <!-- Info.plist -->
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>Find nearby labs and optimize your health journey</string>
   ```

3. **HealthKit Permissions**
   ```xml
   <key>NSHealthShareUsageDescription</key>
   <string>Access health data for personalized insights</string>
   ```

### Build Configurations

- **Debug**: Development builds with detailed logging
- **Release**: Production builds with optimizations
- **TestFlight**: Beta builds with analytics and crash reporting

## 🧪 Testing

### Test Coverage
- **Unit Tests**: Core business logic and services
- **Integration Tests**: API communication and data flow
- **UI Tests**: Critical user journeys and accessibility

### Running Tests
```bash
# Run all tests
xcodebuild test -scheme superone -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test suite
xcodebuild test -scheme superone -only-testing:superoneTests/LocationManagerTests

# Generate coverage report
xcodebuild test -scheme superone -enableCodeCoverage YES
```

## 🚀 Deployment

### App Store Preparation

1. **Archive the app**
   ```bash
   xcodebuild archive -scheme superone -configuration Release
   ```

2. **Upload to App Store Connect**
   - Use Xcode Organizer or Transporter app
   - Include release notes and metadata

3. **TestFlight Distribution**
   - Configure beta testing groups
   - Add testing instructions and feedback mechanisms

### Performance Targets
- **App Launch**: < 2 seconds cold start
- **Location Detection**: < 5 seconds with network
- **API Response**: < 3 seconds for standard requests
- **Memory Usage**: < 150MB peak usage

## 📊 Analytics & Monitoring

### Health Metrics
- App performance and crash reporting
- User journey analytics
- Location service efficiency
- API response times

### Privacy Compliance
- No personal health data in analytics
- Anonymized usage patterns only
- Full user consent for data collection

## 🤝 Contributing

### Development Guidelines

1. **Code Style**
   - Follow Swift API Design Guidelines
   - Use SwiftLint for consistent formatting
   - Include comprehensive documentation

2. **Feature Development**
   - Create feature branches from `main`
   - Include unit tests for new functionality
   - Update documentation and README

3. **Pull Request Process**
   - Ensure all tests pass
   - Include screenshots for UI changes
   - Request review from team members

### Commit Convention
```
feat: add location-based lab discovery
fix: resolve appointment cancellation bug
docs: update API integration guide
style: apply consistent spacing to cards
test: add coverage for LocationManager
```

## 📱 App Store Information

### App Store Listing
- **Name**: Super One Health
- **Category**: Health & Fitness
- **Age Rating**: 4+ (Medical/Treatment Information)
- **Privacy Label**: Health & Fitness data collection disclosed

### Keywords
health tracking, lab tests, medical appointments, health insights, lab reports, health analysis, medical records, appointment booking

## 🔗 Related Projects

- **[Super One Backend](../backend/)**: Node.js/Fastify health analysis API
- **[LabLoop B2B](../../labloop/)**: Lab management system for healthcare providers
- **[React Native App](../mobile-app/)**: Cross-platform health companion app

## 📄 License

This project is proprietary software. All rights reserved.

## 📞 Support

For development support and questions:
- **Technical Issues**: Create GitHub issues with detailed reproduction steps
- **Feature Requests**: Use GitHub discussions for feature proposals
- **Security Issues**: Contact security team directly

---

**Version**: 1.0.0 (Build 1)  
**Last Updated**: January 2025  
**Minimum iOS**: 18.0  
**Target Device**: iPhone (Universal)