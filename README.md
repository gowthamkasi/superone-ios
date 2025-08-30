# Super One Health - iOS App

A comprehensive health tracking and lab appointment booking app built with SwiftUI for iOS 18+.

## 🚧 Project Status

**Current Phase**: Planning & Documentation  
**Implementation Status**: Documentation-only (no actual iOS code exists yet)  
**Next Phase**: Foundation setup and Xcode project creation

This repository currently contains comprehensive planning documentation for a future native iOS SwiftUI application. The planned iOS app will provide a native SwiftUI interface for the Super One Health ecosystem, featuring lab report OCR processing, AI-powered health insights, and appointment booking.

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

### Current Setup (Documentation Phase)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd "Super One/superone"
   ```

2. **Review planning documentation**
   - `docs/ios_app_functionality.md` - Complete screen specifications and user flows
   - `docs/ios_design_style_guide.md` - UI/UX implementation details
   - `docs/ios_health_app_setup.md` - Technical setup requirements
   - `DEVELOPMENT_PLAN.md` - 7-phase implementation roadmap

3. **Future setup (when Xcode project is created)**
   ```bash
   # Open in Xcode
   open superone.xcodeproj
   
   # Build the app
   xcodebuild -scheme superone -configuration Debug build
   
   # Run tests
   xcodebuild -scheme superone -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
   ```

## 📁 Current Project Structure

**Current (Documentation Phase):**
```
superone/
├── README.md                     # This file
├── CLAUDE.md                     # Development guidance
├── DEVELOPMENT_PLAN.md           # 7-phase implementation roadmap
├── docs/                         # Comprehensive planning documentation
│   ├── ios_app_functionality.md  # Complete screen specifications (862 lines)
│   ├── ios_design_style_guide.md # UI/UX implementation details (714 lines)
│   └── ios_health_app_setup.md   # Technical setup requirements (523 lines)
└── superone.xcodeproj/           # Xcode project shell
```

**Planned Structure (When Implementation Begins):**
```
superone/
├── App/                          # App configuration and entry point
│   ├── superoneApp.swift         # Main app file
│   └── AppState.swift            # Global app state management
├── Features/                     # Feature-based modular architecture
│   ├── Appointments/             # Appointment booking and management
│   ├── Dashboard/               # Main health overview
│   ├── LabReports/              # Lab report processing and analysis
│   ├── Profile/                 # User profile and settings
│   └── Location/                # Location services and UI
├── Core/                        # Shared business logic
│   ├── Services/                # Business services
│   ├── Models/                  # Data models and entities
│   └── Configuration/           # App configuration
├── Design/                      # Design system and components
│   ├── DesignSystem/            # Colors, typography, spacing
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

## 📋 Development Phases

The project follows a comprehensive 7-phase development approach over 12 weeks:

1. **Foundation Setup** (Week 1-2): Project initialization, dependencies, design system
2. **Core Services & Authentication** (Week 3-4): HealthKit, networking, biometric auth
3. **Dashboard & Health Overview** (Week 5-6): Main interface, health scores
4. **Lab Report Processing** (Week 7-8): OCR integration, document scanning
5. **AI Health Analysis** (Week 9-10): Backend integration, recommendations
6. **Appointments & Integration** (Week 11): LabLoop integration, booking system
7. **Profile & Settings** (Week 12): User management, settings, help system

## 🧪 Testing (Planned)

### Test Coverage Goals
- **Unit Tests**: 80% coverage for core services
- **Integration Tests**: HealthKit, API, OCR workflows
- **UI Tests**: Critical user flows, accessibility compliance

### Future Testing Commands
```bash
# Run all tests (when implemented)
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

### Super One Health Ecosystem
- **[Super One Backend](../backend/)**: Node.js/Fastify health analysis API (primary integration)
- **[React Native App](../mobile-app/)**: Cross-platform health companion app
- **[LabLoop B2B](../../labloop/)**: Lab management system for healthcare providers

### Integration Points
- **Backend API**: Real-time health data synchronization via REST API
- **OCR Processing**: AWS Textract via backend (primary), Vision framework (fallback)
- **LabLoop Integration**: Appointment booking and lab facility discovery
- **HealthKit**: Native iOS health data integration with backend sync

## 📄 License

This project is proprietary software. All rights reserved.

## 📞 Support

For development support and questions:
- **Technical Issues**: Create GitHub issues with detailed reproduction steps
- **Feature Requests**: Use GitHub discussions for feature proposals
- **Security Issues**: Contact security team directly

---

**Project Phase**: Planning & Documentation  
**Target Version**: 1.0.0 (Build 1)  
**Last Updated**: August 2025  
**Planned iOS Target**: 18.0+  
**Target Device**: iPhone (Universal)

## 📚 Next Steps

1. **Review Documentation**: Examine comprehensive planning docs in `docs/` directory
2. **Create Xcode Project**: Initialize actual iOS project structure
3. **Implement Foundation**: Set up core services and architecture
4. **Begin Development**: Follow the 7-phase development plan

For detailed implementation guidance, see `DEVELOPMENT_PLAN.md` and `CLAUDE.md`.