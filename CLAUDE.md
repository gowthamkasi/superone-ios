# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This directory contains **planning and documentation** for a future native iOS SwiftUI application as part of the Super One Health ecosystem. The planned iOS app will provide a native SwiftUI interface for the comprehensive health analysis platform, featuring lab report OCR processing, AI-powered health insights, and appointment booking.

**Current Status**: Planning and documentation phase only - no actual iOS code exists yet.

**Backend Integration:**
- **Backend API**: `../backend/` - Node.js/Fastify health analysis service (primary integration point)

## Development Commands

**Important**: This iOS app project is currently in the planning phase. No Xcode project, Swift code, or actual iOS development exists yet. The commands below are for reference when the project is actually created.

### Future Commands (When Xcode Project Exists):
```bash
# Build the app
xcodebuild -scheme HealthTrackerUniversal -configuration Debug build

# Run tests
xcodebuild -scheme HealthTrackerUniversal -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test

# Clean build artifacts
xcodebuild -scheme HealthTrackerUniversal clean

# Archive for distribution
xcodebuild -scheme HealthTrackerUniversal -configuration Release archive
```

### Development Setup:
- **Xcode Version**: 16.0 Beta or later
- **macOS Requirement**: macOS Sonoma 14.5+ with Apple Silicon Mac (16GB+ unified memory)
- **Swift Version**: Swift 6.0 with strict concurrency
- **Deployment Target**: iOS 18.0+

## Architecture Overview

### Technical Stack
- **Framework**: SwiftUI 6.0 with iOS 18+ features
- **Authentication**: Biometric (Face ID/Touch ID) + JWT tokens
- **Health Integration**: HealthKit with comprehensive biomarker support
- **OCR Processing**: AWS Textract via backend API (primary), Vision framework (fallback)
- **Data Storage**: Core Data + Keychain for sensitive data
- **Network**: Alamofire for API communication

### Planned Project Structure
```
HealthTrackerUniversal/
├── App/                    # App configuration and entry point
├── Features/               # Feature-based modular architecture
│   ├── Authentication/     # Login, registration, biometric auth
│   ├── Dashboard/         # Main health overview with scores
│   ├── LabReports/        # Upload, OCR, analysis workflow
│   ├── HealthInsights/    # AI-powered recommendations
│   ├── Appointments/      # Booking and management
│   └── Profile/           # Settings and preferences
├── Core/                  # Shared business logic
│   ├── Services/          # HealthKit, Network, Camera, OCR
│   ├── Models/            # Data models and entities
│   └── Utilities/         # Helper functions and extensions
├── Design/                # Design system and components
│   ├── DesignSystem/      # Colors, typography, spacing
│   └── Components/        # Reusable UI components
└── Tests/                 # Unit, integration, and UI tests
```

### Key Architectural Patterns

**MVVM + Clean Architecture:**
- **Models**: Data layer with Core Data and HealthKit integration
- **ViewModels**: Presentation logic with @ObservableObject and async/await
- **Views**: SwiftUI views with declarative UI
- **Services**: Business logic for health data, networking, and OCR

**OCR Processing Architecture:**
1. **Primary**: AWS Textract via backend API (`../backend/src/infrastructure/services/ocr-textract.service.ts`)
2. **Fallback**: Local Vision framework when backend unavailable
3. **User Experience**: Seamless fallback with user notification

**Health Data Integration:**
- **HealthKit Integration**: Read/write health data with user permission
- **Backend Sync**: Real-time synchronization with Super One backend
- **12+ Health Categories**: Cardiovascular, Metabolic, Hematology, etc.
- **50+ Biomarker Types**: Complete medical test support

### Backend API Integration

The iOS app integrates with the Super One backend API:

**Base URL**: `https://api.superonehealth.com` (production)
**Key Endpoints:**
- `POST /api/v1/ocr/process` - OCR processing via AWS Textract
- `POST /api/v1/health/analyze` - AI health analysis
- `GET /api/v1/mobile/dashboard` - Dashboard data
- `POST /api/v1/appointments/book` - Appointment booking

**Authentication Flow:**
1. JWT token from backend auth
2. Biometric verification (Face ID/Touch ID)
3. Secure token storage in Keychain

## Development Phases

The project follows a 7-phase development approach over 12 weeks:

1. **Foundation Setup** (Week 1-2): Project initialization, dependencies, design system
2. **Core Services & Authentication** (Week 3-4): HealthKit, networking, biometric auth
3. **Dashboard & Health Overview** (Week 5-6): Main interface, health scores
4. **Lab Report Processing** (Week 7-8): OCR integration, document scanning
5. **AI Health Analysis** (Week 9-10): Backend integration, recommendations
6. **Appointments & Integration** (Week 11): LabLoop integration, booking system
7. **Profile & Settings** (Week 12): User management, settings, help system

## Key iOS-Specific Features

### iOS 18+ Integration
- **Control Center Widgets**: Quick health data logging
- **Live Activities**: Health monitoring sessions
- **Dynamic Island**: Active health tracking display
- **App Shortcuts**: Common workflow shortcuts

### Health & Privacy
- **HealthKit Permissions**: Comprehensive health data access
- **Biometric Security**: Face ID/Touch ID for app access
- **Data Encryption**: End-to-end encryption for sensitive data
- **Privacy Compliance**: HIPAA-aligned data handling

### Performance Optimizations
- **SwiftUI 6.0**: Enhanced performance features
- **Async/Await**: Modern concurrency throughout
- **Memory Efficiency**: Optimized image and data processing
- **Background Sync**: Health data synchronization

## Dependencies (Swift Package Manager)

```swift
dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire", from: "5.8.0"),
    .package(url: "https://github.com/KeychainAccess/KeychainAccess", from: "4.2.2"),
    .package(url: "https://github.com/danielgindi/Charts", from: "5.0.0"),
    .package(url: "https://github.com/onevcat/Kingfisher", from: "7.9.0"),
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.3.0")
]
```

## Configuration Requirements

### Info.plist Permissions
```xml
<key>NSHealthShareUsageDescription</key>
<string>Access health data for personalized insights</string>
<key>NSCameraUsageDescription</key>
<string>Capture lab reports for analysis</string>
<key>NSFaceIDUsageDescription</key>
<string>Secure authentication for health data</string>
```

### Entitlements
- HealthKit capabilities
- Keychain access groups
- App groups for data sharing

## Testing Strategy

### Test Coverage Goals
- **Unit Tests**: 80% coverage for core services
- **Integration Tests**: HealthKit, API, OCR workflows
- **UI Tests**: Critical user flows, accessibility compliance

### Performance Benchmarks
- App launch time: < 2 seconds
- OCR processing: < 30 seconds (with backend)
- Health data sync: < 5 seconds
- Memory usage optimization

## Integration Points

### Super One Backend
- Real-time health data synchronization
- OCR processing via AWS Textract
- AI analysis and recommendations
- User authentication and profiles

### LabLoop Integration (via backend)
- Appointment booking system
- Lab facility discovery
- Test result synchronization
- Invoice and billing integration

## Documentation References

- **App Functionality**: `docs/ios_app_functionality.md` - Complete screen specifications
- **Design Guide**: `docs/ios_design_style_guide.md` - UI/UX implementation details  
- **Setup Plan**: `docs/ios_health_app_setup.md` - Technical setup requirements
- **Development Plan**: `DEVELOPMENT_PLAN.md` - Detailed implementation roadmap

## Current Documentation Status

This directory contains comprehensive planning documentation for the future iOS app:

- **`docs/ios_app_functionality.md`**: Complete 862-line specification with detailed screen flows, UI components, and user interactions
- **`docs/ios_design_style_guide.md`**: 714-line comprehensive design system with health-focused green color palette, typography, and component specifications  
- **`docs/ios_health_app_setup.md`**: 523-line technical setup plan with project structure, dependencies, and deployment requirements
- **`DEVELOPMENT_PLAN.md`**: Detailed 7-phase implementation roadmap with progress tracking

## Notes for Future Development

- The planned iOS app is designed to work seamlessly with the existing Super One backend (`../backend/`)
- OCR processing will prioritize backend AWS Textract with Vision framework fallback
- Health data will flow through HealthKit with backend synchronization
- User authentication will integrate with existing backend JWT system
- Design system follows iOS 18 Human Interface Guidelines with health-focused theming
- This is a **native iOS app plan**, separate from the existing React Native app in `../mobile-app/`