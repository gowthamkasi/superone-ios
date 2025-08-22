# iOS Health Analysis App - Complete Functionality Specification

## 🎯 App Overview & Core Features

**App Name**: Super One Health  
**Platform**: iOS 18+ with SwiftUI 6.0  
**Core Purpose**: Comprehensive health analysis platform with AI-powered insights, OCR processing, and medical-grade security  
**Navigation**: Tab-based navigation with central upload action button

## 📱 Complete Screen Mapping & User Flows

### 1. 🔐 Authentication & Onboarding Flow

#### 1.1 Login Screen (`LoginView`)
```swift
struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
    // UI Elements:
    // - App logo (🏥)
    // - "Welcome Back" title
    // - "Sign in to access your health insights" subtitle
    // - Email input field
    // - Password input field
    // - "Sign In" primary button
    // - "Create Account" secondary button
    // - "Forgot Password?" link
    
    // Navigation:
    // - Success login → Dashboard
    // - Create Account → Onboarding Welcome
}
```

#### 1.2 Onboarding Welcome Screen (`OnboardingWelcomeView`)
```swift
struct OnboardingWelcomeView: View {
    // Progress indicators: 4 dots (1st active)
    
    // UI Elements:
    // - App logo (🏥)
    // - "Welcome to Super One Health" title
    // - Feature highlights with icons:
    //   • AI-powered lab report analysis
    //   • Personalized health recommendations
    //   • Easy appointment booking
    //   • Secure health data management
    // - "Get Started" primary button
    // - "Sign In" secondary button
    
    // Navigation:
    // - Get Started → Registration
    // - Sign In → Login
}
```

#### 1.3 Registration Screen (`RegistrationView`)
```swift
struct RegistrationView: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Progress indicators: 4 dots (2nd active)
    
    // UI Elements:
    // - "Create Account" title
    // - Full Name input
    // - Email input
    // - Phone Number input
    // - Password input
    // - Confirm Password input
    // - "Create Account" button
    // - Terms & Privacy disclaimer
    
    // Navigation:
    // - Create Account → Profile Setup
}
```

#### 1.4 Profile Setup Screen (`ProfileSetupView`)
```swift
struct ProfileSetupView: View {
    @State private var dateOfBirth: Date = Date()
    @State private var gender: String = ""
    @State private var selectedHealthGoals: Set<HealthGoal> = []
    
    // Progress indicators: 4 dots (3rd active)
    
    // Health Goals Grid (2x2):
    enum HealthGoal: String, CaseIterable {
        case preventiveCare = "Preventive Care"
        case weightManagement = "Weight Management"
        case heartHealth = "Heart Health"
        case diabetesManagement = "Diabetes Management"
    }
    
    // UI Elements:
    // - "Complete Your Profile" title
    // - Date of Birth picker
    // - Gender selector
    // - Health Goals grid (toggleable)
    // - "Continue" button
    
    // Navigation:
    // - Continue → Security Setup
}
```

#### 1.5 Security Setup Screen (`SecuritySetupView`)
```swift
struct SecuritySetupView: View {
    // Progress indicators: 4 dots (4th active)
    
    // UI Elements:
    // - Lock icon (🔒)
    // - "Secure Your Account" title
    // - Biometric authentication explanation
    // - Face ID and Touch ID options display
    // - "Enable Biometric Auth" primary button
    // - "Skip for Now" secondary button
    // - Privacy disclaimer
    
    // Navigation:
    // - Enable/Skip → Dashboard
}
```

### 2. 📊 Main Dashboard & Navigation

#### 2.1 Dashboard Screen (`DashboardView`)
```swift
struct DashboardView: View {
    @State private var healthScore: Int = 78
    @State private var recentTests: Int = 5
    @State private var recommendations: Int = 3
    @State private var healthAlerts: Int = 2
    @State private var upcomingAppointments: Int = 1
    
    // Header Elements:
    // - Greeting: "Good Morning, John"
    // - Subtitle: "Let's check your health today"
    // - Notification bell (with badge)
    // - Profile avatar
    
    // Hero Section:
    // - "Overall Health Score: 78%"
    // - Progress indicator
    // - "Good - Stable Trend" status
    
    // Stats Grid (2x2):
    struct HealthStat {
        let icon: String
        let value: String
        let label: String
        let badge: Int?
        let destination: String
    }
    
    let stats = [
        HealthStat(icon: "📋", value: "5", label: "Recent Tests", badge: nil, destination: "reports"),
        HealthStat(icon: "💡", value: "3", label: "Recommendations", badge: 1, destination: "recommendations"),
        HealthStat(icon: "⚠️", value: "2", label: "Health Alerts", badge: 2, destination: "notifications"),
        HealthStat(icon: "📅", value: "1", label: "Appointment", badge: nil, destination: "appointments")
    ]
    
    // Health Categories Horizontal Slider:
    // - Cardiovascular (65% - Needs Attention)
    // - Diabetes (82% - Good)
    // - Blood Pressure (70% - Monitor)
    // - Hematology (89% - Excellent)
    // - Liver Function (75% - Normal)
    
    // Navigation targets for each stat card
}
```

#### 2.2 Health Categories Slider Component
```swift
struct HealthCategoryCard: View {
    let category: HealthCategory
    
    struct HealthCategory {
        let name: String
        let icon: String
        let score: Int
        let status: HealthStatus
        let trendData: [Double]
        let statusColor: Color
    }
    
    enum HealthStatus {
        case excellent, good, normal, monitor, needsAttention
        
        var displayText: String {
            switch self {
            case .excellent: return "✅ Excellent"
            case .good: return "✅ Good"
            case .normal: return "✅ Normal"
            case .monitor: return "⚠️ Monitor"
            case .needsAttention: return "⚠️ Needs Attention"
            }
        }
    }
    
    // Features:
    // - Category icon and name
    // - Health score percentage
    // - Status badge with appropriate color
    // - Mini trend chart with SVG
    // - Historical data points
    // - Smooth horizontal scrolling
    // - Scroll indicators (dots)
}
```

### 3. 📋 Lab Report Management System

#### 3.1 Upload Screen (`UploadView`)
```swift
struct UploadView: View {
    @State private var isShowingCamera = false
    @State private var isShowingDocumentPicker = false
    
    // Header:
    // - Back button
    // - "Upload Lab Report" title
    
    // Upload Area:
    // - Dashed border container
    // - Document icon (📄)
    // - "Upload Your Lab Report" title
    // - "Take a photo or select from your device" subtitle
    // - "📷 Take Photo" primary button
    // - "📁 Choose File" secondary button
    
    // Supported Formats Info:
    // - PDF documents
    // - Images (JPG, PNG)
    // - Multi-page reports
    // - Handwritten reports
    
    // Navigation:
    // - Take Photo → Camera/Processing
    // - Choose File → Document Picker → Processing
    // - Back → Dashboard
}
```

#### 3.2 Processing Screen (`ProcessingView`)
```swift
struct ProcessingView: View {
    @State private var processingSteps: [ProcessingStep] = [
        ProcessingStep(title: "Upload Complete", subtitle: "Document received and validated", status: .completed),
        ProcessingStep(title: "OCR Processing", subtitle: "Extracting text and values", status: .inProgress, progress: 85),
        ProcessingStep(title: "AI Analysis", subtitle: "Generating health insights", status: .pending)
    ]
    
    struct ProcessingStep {
        let title: String
        let subtitle: String
        let status: ProcessingStatus
        let progress: Int?
    }
    
    enum ProcessingStatus {
        case completed, inProgress, pending
    }
    
    // Header:
    // - Back button
    // - "Processing Report" title
    
    // Processing Steps:
    // - Visual step indicator (numbered circles)
    // - Step titles and descriptions
    // - Progress percentage for active step
    // - Real-time status updates
    
    // Actions:
    // - "View Analysis (Demo)" button
    
    // Navigation:
    // - View Analysis → Analysis Results
    // - Back → Upload
}
```

#### 3.3 Analysis Screen (`AnalysisView`)
```swift
struct AnalysisView: View {
    @State private var analysisResult: HealthAnalysisResult
    
    struct HealthAnalysisResult {
        let categoryScore: Int
        let categoryName: String
        let status: String
        let keyBiomarkers: [Biomarker]
        let recommendations: [Recommendation]
    }
    
    struct Biomarker {
        let name: String
        let value: String
        let unit: String
        let referenceRange: String
        let status: BiomarkerStatus
    }
    
    // Header:
    // - Back button
    // - "Health Analysis" title
    // - Share button (📤)
    
    // Analysis Result:
    // - "Cardiovascular Health Score: 65%"
    // - Status: "⚠️ Fair - Needs Attention"
    // - Progress indicator
    
    // Key Biomarkers Section:
    // - Total Cholesterol: 245 mg/dL
    // - LDL Cholesterol: 165 mg/dL
    // - HDL Cholesterol: 42 mg/dL
    
    // Actions:
    // - "View Recommendations" button
    
    // Navigation:
    // - View Recommendations → Recommendations
    // - Share → System share sheet
    // - Back → Dashboard/Reports
}
```

#### 3.4 Recommendations Screen (`RecommendationsView`)
```swift
struct RecommendationsView: View {
    @State private var recommendations: [HealthRecommendation] = []
    
    struct HealthRecommendation {
        let priority: Priority
        let title: String
        let description: String
        let category: String
    }
    
    enum Priority {
        case high, medium, low
        
        var displayText: String {
            switch self {
            case .high: return "HIGH PRIORITY"
            case .medium: return "MEDIUM PRIORITY"
            case .low: return "LOW PRIORITY"
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .high: return Color.gray.opacity(0.2)
            case .medium: return Color.gray.opacity(0.1)
            case .low: return Color.gray.opacity(0.05)
            }
        }
    }
    
    // Sample Recommendations:
    // - HIGH PRIORITY: "Cholesterol Management"
    //   "Your LDL cholesterol (165 mg/dL) is above optimal levels. Consider adopting a Mediterranean diet rich in omega-3 fatty acids."
    // - MEDIUM PRIORITY: "Increase Physical Activity"
    //   "Regular aerobic exercise can help improve your HDL cholesterol. Aim for 150 minutes of moderate exercise weekly."
    
    // Header:
    // - Back button
    // - "Health Recommendations" title
    
    // Navigation:
    // - Back → Analysis
}
```

### 4. 📅 Appointment Management System

#### 4.1 Appointments Screen (`AppointmentsView`)
```swift
struct AppointmentsView: View {
    @State private var upcomingAppointments: [Appointment] = []
    @State private var pastAppointments: [Appointment] = []
    
    struct Appointment {
        let id: UUID
        let facilityName: String
        let date: Date
        let time: String
        let serviceType: String
        let status: AppointmentStatus
        let facilityIcon: String
    }
    
    enum AppointmentStatus {
        case upcoming, completed, cancelled
    }
    
    // Header:
    // - Back button
    // - "Appointments" title
    // - Add button (+) → Booking
    
    // Upcoming Section:
    // - "Upcoming" subtitle
    // - Appointment cards with:
    //   • Facility icon (🏥)
    //   • "Pacific Medical Lab"
    //   • "Tomorrow, 9:30 AM"
    //   • "Comprehensive Health Panel"
    
    // Past Appointments Section:
    // - "Past Appointments" subtitle
    // - Historical appointment cards
    
    // Navigation:
    // - Add → Booking
    // - Appointment card → Appointment details
    // - Back → Dashboard
}
```

#### 4.2 Booking Screen (`BookingView`)
```swift
struct BookingView: View {
    @State private var availableFacilities: [MedicalFacility] = []
    @State private var selectedFacility: MedicalFacility?
    
    struct MedicalFacility {
        let name: String
        let rating: Double
        let distance: String
        let priceRange: String
        let features: [String]
        let nextAvailable: String
    }
    
    // Sample Facilities:
    // - Pacific Medical Lab
    //   ⭐ 4.8 • 2.3 mi • $$ 45-60
    //   Same day • Home service
    // - HealthFirst Diagnostics
    //   ⭐ 4.6 • 1.8 mi • $ 35-50
    //   Next: Tomorrow 9AM
    
    // Header:
    // - Back button
    // - "Book Appointment" title
    
    // Facility List:
    // - Facility cards with ratings, distance, pricing
    // - Features/availability info
    // - Clickable for selection
    
    // Navigation:
    // - Facility selection → Appointment Details
    // - Back → Appointments
}
```

#### 4.3 Appointment Details Screen (`AppointmentDetailsView`)
```swift
struct AppointmentDetailsView: View {
    @State private var selectedDate: Date = Date()
    @State private var selectedTimeSlot: String = ""
    @State private var availableTimeSlots: [String] = ["8:00 AM", "9:30 AM", "11:00 AM"]
    
    // Header:
    // - Back button
    // - "Book Appointment" title
    
    // Facility Info:
    // - "Pacific Medical Lab"
    // - "2.3 miles • ⭐ 4.8 rating"
    
    // Date Selection:
    // - Calendar grid (7-day view)
    // - Selectable dates
    // - Visual feedback for selection
    
    // Time Selection:
    // - "Available Times - Dec 16" label
    // - Time slot grid (3 columns)
    // - Selected time highlighted
    
    // Actions:
    // - "Confirm Booking" button
    
    // Navigation:
    // - Confirm → Confirmation
    // - Back → Booking
}
```

#### 4.4 Appointment Confirmation Screen (`AppointmentConfirmationView`)
```swift
struct AppointmentConfirmationView: View {
    let confirmedAppointment: Appointment
    
    // Success Icon: ✅
    // - "Booking Confirmed!" title
    // - "Your appointment has been successfully scheduled" subtitle
    
    // Appointment Details Card:
    // - Facility: Pacific Medical Lab
    // - Date & Time: Dec 16, 9:30 AM
    // - Service: Health Panel
    
    // Actions:
    // - "View Appointments" button
    
    // Navigation:
    // - View Appointments → Appointments list
}
```

### 5. 📋 Reports Management

#### 5.1 Reports Screen (`ReportsView`)
```swift
struct ReportsView: View {
    @State private var labReports: [LabReport] = []
    
    struct LabReport {
        let id: UUID
        let title: String
        let date: Date
        let category: String
        let status: ReportStatus
        let analysisScore: Int?
    }
    
    enum ReportStatus {
        case analyzed, processing, uploaded
    }
    
    // Header:
    // - Back button
    // - "Lab Reports" title
    // - Add button (+) → Upload
    
    // Reports List:
    // - "Comprehensive Health Panel" (December 15, 2024)
    // - "Thyroid Function Test" (November 20, 2024)
    // - Clickable cards with chevron (›)
    
    // Navigation:
    // - Report card → Analysis view
    // - Add → Upload
    // - Back → Dashboard
}
```

### 6. 🔔 Notifications System

#### 6.1 Notifications Screen (`NotificationsView`)
```swift
struct NotificationsView: View {
    @State private var notifications: [HealthNotification] = []
    
    struct HealthNotification {
        let id: UUID
        let title: String
        let message: String
        let timestamp: Date
        let type: NotificationType
        let isRead: Bool
    }
    
    enum NotificationType {
        case healthAlert, analysisComplete, appointmentReminder, recommendation
        
        var indicatorColor: Color {
            switch self {
            case .healthAlert: return .red
            case .analysisComplete: return .gray
            case .appointmentReminder: return .blue
            case .recommendation: return .orange
            }
        }
    }
    
    // Sample Notifications:
    // - "High Cholesterol Alert" (2 hours ago)
    //   "Your recent lab results show elevated cholesterol levels. Consider reviewing dietary recommendations."
    // - "Analysis Complete" (4 hours ago)
    //   "Your Comprehensive Health Panel analysis is ready for review."
    // - "Appointment Reminder" (Yesterday)
    //   "Lab appointment tomorrow at 9:30 AM at Pacific Medical Lab."
    
    // Header:
    // - Back button
    // - "Notifications" title
    // - "Clear All" action
    
    // Notification Cards:
    // - Colored dot indicator
    // - Title and message
    // - Timestamp
    // - Tap to view/dismiss
    
    // Navigation:
    // - Back → Dashboard
    // - Notification tap → Relevant screen
}
```

### 7. 👤 Profile & Settings Management

#### 7.1 Profile Screen (`ProfileView`)
```swift
struct ProfileView: View {
    @State private var userProfile: UserProfile
    
    struct UserProfile {
        let name: String
        let email: String
        let avatar: String
        let stats: ProfileStats
    }
    
    struct ProfileStats {
        let labReports: Int
        let healthScore: Int
        let monthsActive: Int
    }
    
    // Header:
    // - Back button
    // - "Profile" title
    // - Settings gear (⚙️) → Settings
    
    // Profile Header:
    // - Avatar (👤)
    // - "John Doe"
    // - "john.doe@email.com"
    
    // Stats Grid (3 columns):
    // - 12 Lab Reports
    // - 78% Health Score
    // - 6 Months Active
    
    // Profile Options:
    // - 📋 Health Information (Age, gender, medical history)
    // - 🎯 Health Goals (Set and track health targets)
    // - 👨‍👩‍👧‍👦 Family Sharing (Share health data with family)
    
    // Navigation:
    // - Settings → Settings screen
    // - Profile options → Respective detail screens
    // - Back → Dashboard
}
```

#### 7.2 Settings Screen (`SettingsView`)
```swift
struct SettingsView: View {
    @State private var healthAlertsEnabled = true
    @State private var emailNotificationsEnabled = false
    
    // Header:
    // - Back button
    // - "Settings" title
    
    // Account Section:
    // - 👤 Personal Information
    // - 🔒 Privacy & Security
    
    // Notifications Section:
    // - 🔔 Health Alerts (Toggle - ON)
    // - 📧 Email Notifications (Toggle - OFF)
    
    // Data & Privacy Section:
    // - 📤 Export Data
    // - 🗑️ Delete Account
    
    // Support Section:
    // - ❓ Help Center
    // - 🚪 Sign Out
    
    // Navigation:
    // - Setting items → Detail screens
    // - Sign Out → Login screen
    // - Back → Profile
}
```

### 8. 🧭 Navigation System

#### 8.1 Bottom Tab Bar Navigation
```swift
struct MainTabView: View {
    @State private var selectedTab = 0
    
    enum TabItem: Int, CaseIterable {
        case home = 0
        case appointments = 1
        case upload = 2  // Special case - not a tab
        case reports = 3
        case settings = 4
        
        var icon: String {
            switch self {
            case .home: return "🏠"
            case .appointments: return "📅"
            case .upload: return "+"
            case .reports: return "📋"
            case .settings: return "⚙️"
            }
        }
        
        var label: String {
            switch self {
            case .home: return "Home"
            case .appointments: return "Appointments"
            case .upload: return ""
            case .reports: return "Reports"
            case .settings: return "Settings"
            }
        }
    }
    
    // Central Upload Button:
    // - Floating action button
    // - Elevated above tab bar
    // - Black circular button with white "+" icon
    // - Drop shadow effect
    // - Direct navigation to Upload screen
    
    // Tab Bar Features:
    // - Fixed bottom position
    // - 5 items with central upload action
    // - Active state indication
    // - Icon + label for each tab
    // - Smooth transitions between tabs
}
```

#### 8.2 Navigation Patterns
```swift
// Primary Navigation Flows:

// Authentication Flow:
// Login → [Register → Profile Setup → Security] → Dashboard

// Dashboard Flows:
// Dashboard → Notifications → [Individual notification actions]
// Dashboard → Profile → Settings → [Setting details]
// Dashboard → Stats → [Reports/Recommendations/Appointments]

// Lab Report Flow:
// Upload → Processing → Analysis → Recommendations
// Reports → Analysis → Recommendations

// Appointment Flow:
// Appointments → Booking → Details → Confirmation → Appointments

// Universal Back Navigation:
// - All screens support back navigation
// - Breadcrumb-style navigation paths
// - Consistent header structure
// - Modal dismissal for overlays
```

## 🎨 UI/UX Interaction Patterns

### Visual Feedback Systems
```swift
// Button States:
// - Default, Pressed, Disabled states
// - Scale animation on tap (0.98 scale)
// - Color transitions
// - Loading states with activity indicators

// Card Interactions:
// - Subtle shadow on hover/press
// - Highlight border for selection
// - Smooth transitions between states
// - Chevron (›) indicators for navigation

// Form Elements:
// - Focus states with border highlights
// - Validation feedback (success/error states)
// - Real-time input validation
// - Placeholder text guidance

// List Scrolling:
// - Smooth momentum scrolling
// - Pull-to-refresh capability
// - Infinite scroll for large datasets
// - Loading states between sections
```

### Health-Specific UI Components
```swift
// Health Score Displays:
// - Circular progress indicators
// - Color-coded health status
// - Trend arrows and indicators
// - Animated value changes

// Chart Components:
// - Mini trend charts in category cards
// - Interactive full-screen charts
// - Historical data visualization
// - Comparative analysis views

// Status Indicators:
// - Health status badges (✅ ⚠️ 🔴)
// - Priority indicators for recommendations
// - Progress tracking for goals
// - Alert notification badges

// Medical Data Presentation:
// - Biomarker cards with reference ranges
// - Color-coded values (normal/abnormal)
// - Trend indicators for changes
// - Contextual explanations
```

## 🔄 State Management & Data Flow

### App State Architecture
```swift
@main
struct SuperOneHealthApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var healthStore = HealthDataStore()
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(healthStore)
            } else {
                AuthenticationFlow()
                    .environmentObject(authManager)
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var healthScore: Int = 78
    @Published var notifications: [HealthNotification] = []
    @Published var isProcessingReport: Bool = false
    @Published var currentAnalysis: HealthAnalysisResult?
}
```

This comprehensive specification captures every screen, interaction, and user flow from the wireframe, providing Claude Code with detailed implementation guidance for building the complete iOS health analysis application.