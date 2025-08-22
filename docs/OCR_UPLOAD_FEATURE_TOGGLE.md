# OCR Upload Feature Toggle Documentation

## Overview

The OCR Upload feature can be enabled/disabled per environment using a feature flag system. This allows for controlled rollouts and the ability to quickly disable the feature if needed without code changes or app store updates.

## How to Enable/Disable the Feature

### Location
The feature toggle is controlled in the `AppConfiguration.swift` file:
```
superone/core/Configuration/AppConfiguration.swift
```

### Configuration Settings

The OCR upload feature is controlled by the `ocrUpload` boolean flag in the `FeatureFlags` struct for each environment:

```swift
struct FeatureFlags {
    let ocrUpload: Bool  // Controls OCR upload feature visibility
    // ... other flags
}
```

### Environment-Specific Settings

#### Development Environment
```swift
static let development = AppConfiguration(
    // ... other configuration
    features: FeatureFlags(
        // ... other flags
        ocrUpload: true          // ✅ ENABLED for testing
    )
)
```

#### Staging Environment  
```swift
static let staging = AppConfiguration(
    // ... other configuration
    features: FeatureFlags(
        // ... other flags
        ocrUpload: true          // ✅ ENABLED for QA testing
    )
)
```

#### Production Environment
```swift
static let production = AppConfiguration(
    // ... other configuration
    features: FeatureFlags(
        // ... other flags
        ocrUpload: false         // ❌ DISABLED by default in production
    )
)
```

## How to Toggle the Feature

### To Enable OCR Upload Feature

1. Open `superone/core/Configuration/AppConfiguration.swift`
2. Find the environment you want to modify (development/staging/production)
3. Change the `ocrUpload` value to `true`:
   ```swift
   ocrUpload: true    // Feature ENABLED
   ```
4. Save the file
5. Build and run the app

### To Disable OCR Upload Feature

1. Open `superone/core/Configuration/AppConfiguration.swift`
2. Find the environment you want to modify (development/staging/production)  
3. Change the `ocrUpload` value to `false`:
   ```swift
   ocrUpload: false   // Feature DISABLED
   ```
4. Save the file
5. Build and run the app

## What Happens When Feature is Enabled vs Disabled

### ✅ Feature ENABLED (`ocrUpload: true`)
- **Upload tab**: Visible in bottom tab bar (+ button)
- **Tab functionality**: Tapping upload tab opens upload modal
- **Upload modal**: Full upload interface available
- **Upload buttons**: All upload options visible (Files, Photo Library, Document Scanner)
- **User experience**: Complete OCR upload workflow available

### ❌ Feature DISABLED (`ocrUpload: false`)
- **Upload tab**: Completely hidden from tab bar
- **Tab functionality**: No upload tab to tap (graceful handling)
- **Upload modal**: Auto-dismisses if opened programmatically
- **Upload buttons**: Completely hidden (EmptyView)
- **User experience**: Clean interface with no upload options visible

## Other App Flows Remain Intact

When the OCR upload feature is disabled, all other app functionality continues to work normally:
- ✅ Dashboard navigation
- ✅ Appointments tab
- ✅ Reports tab  
- ✅ Profile tab
- ✅ All existing navigation flows
- ✅ Tab bar layout (other tabs adjust spacing automatically)

## Build Requirements

After changing the feature flag:
1. Clean build recommended: `Product → Clean Build Folder` in Xcode
2. Build the app: `⌘+B`
3. Run on simulator or device: `⌘+R`

No additional configuration or code changes required.

## Current Default Settings

As of implementation:
- **Development**: ✅ ENABLED (`ocrUpload: true`)
- **Staging**: ✅ ENABLED (`ocrUpload: true`)
- **Production**: ❌ DISABLED (`ocrUpload: false`)

## Emergency Disable

If the OCR upload feature needs to be quickly disabled in production:

1. Change production setting to `ocrUpload: false`
2. Create emergency build
3. Deploy to App Store
4. Feature will be immediately hidden from users

## Testing the Toggle

### To Test Feature Toggle:
1. Set feature to `true` → Build → Verify upload tab is visible
2. Set feature to `false` → Build → Verify upload tab is hidden
3. Test navigation flows work in both states
4. Verify no crashes occur when toggling

### Test Scenarios:
- ✅ Upload tab visible when enabled
- ✅ Upload tab hidden when disabled  
- ✅ Upload modal opens when enabled
- ✅ Upload modal auto-dismisses when disabled
- ✅ Other tabs work normally in both states
- ✅ No crashes in either state

## Troubleshooting

### Feature not toggling correctly:
1. Verify you're modifying the correct environment configuration
2. Clean build folder and rebuild
3. Check that you're running the correct build configuration (Debug/Release)

### Build errors after toggle:
1. Ensure the boolean value is exactly `true` or `false` (lowercase)
2. Verify syntax is correct (comma placement, brackets)
3. Clean build folder and try again

## Related Files

The OCR upload feature toggle affects these files:
- `superone/core/Configuration/AppConfiguration.swift` - Main toggle configuration
- `superone/Features/Navigation/ViewModels/NavigationViewModel.swift` - Tab filtering logic
- `superone/Features/Navigation/Views/CustomTabBar.swift` - Tab display logic  
- `superone/Features/LabReports/Views/LabReportUploadView.swift` - Upload modal logic
- `superone/Features/LabReports/Components/UploadDropZone.swift` - Upload button logic

All changes are controlled by the single `ocrUpload` feature flag - no need to modify other files.