# User API Specification - `/mobile/users/me` Endpoint

## Overview
This document specifies the complete User model that the `/mobile/users/me` endpoint should return to match the iOS application's User struct definition.

## Current Issue
The API testing console shows a simplified User format with only 8 basic properties, but the iOS User model expects 13+ properties including verification flags, nested profile, and preferences.

## Required Response Format

### Endpoint: `GET /mobile/users/me`
**Authentication**: Required (Bearer token)

### Complete User Model Response
The backend must return the following complete User object wrapped in the BaseResponse format:

```json
{
  "success": true,
  "message": "User retrieved successfully",
  "data": {
    "_id": "user_id_123",
    "email": "user@example.com",
    "name": "John Doe",
    "profile_image_url": "https://example.com/avatar.jpg",
    "phone_number": "+1234567890",
    "date_of_birth": "1990-01-01T00:00:00.000Z",
    "gender": "male",
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-15T10:30:00.000Z",
    "email_verified": true,
    "phone_verified": false,
    "two_factor_enabled": false,
    "profile": {
      "date_of_birth": "1990-01-01T00:00:00.000Z",
      "gender": "male",
      "height": 175.0,
      "weight": 70.5,
      "activity_level": "moderately_active",
      "health_goals": ["cardiovascular_health", "weight_loss"],
      "medical_conditions": ["hypertension"],
      "medications": ["lisinopril"],
      "allergies": ["peanuts"],
      "emergency_contact": {
        "name": "Jane Doe",
        "relationship": "spouse", 
        "phone_number": "+1234567891",
        "email": "jane@example.com"
      },
      "profile_image_url": "https://example.com/avatar.jpg",
      "labloop_patient_id": "ll_patient_123"
    },
    "preferences": {
      "notifications": {
        "health_alerts": true,
        "appointment_reminders": true,
        "report_ready": true,
        "recommendations": true,
        "weekly_digest": false,
        "monthly_report": true,
        "push_enabled": true,
        "email_enabled": true,
        "sms_enabled": false,
        "quiet_hours": {
          "enabled": true,
          "start_time": "22:00",
          "end_time": "08:00"
        }
      },
      "privacy": {
        "share_data_with_providers": true,
        "share_data_for_research": false,
        "allow_analytics": true,
        "allow_marketing": false,
        "data_retention_period": 365
      },
      "units": {
        "weight_unit": "kg",
        "height_unit": "cm",
        "temperature_unit": "celsius", 
        "date_format": "yyyy-MM-dd"
      },
      "theme": "system"
    }
  },
  "timestamp": "2024-01-15T10:30:00.000Z",
  "meta": {
    "requestedAt": "2024-01-15T10:30:00.000Z",
    "processingTime": 0.125,
    "version": "1.0.0",
    "requestId": "req_12345"
  }
}
```

## Field Specifications

### Core User Fields (Required)
| Field | Type | JSON Key | Required | Description |
|-------|------|----------|----------|-------------|
| id | String | `_id` | ✅ | Unique user identifier |
| email | String | `email` | ✅ | User's email address |
| name | String | `name` | ✅ | User's full name |
| createdAt | Date | `created_at` | ✅ | Account creation timestamp |
| updatedAt | Date | `updated_at` | ✅ | Last update timestamp |

### Optional User Fields
| Field | Type | JSON Key | Required | Description |
|-------|------|----------|----------|-------------|
| profileImageURL | String? | `profile_image_url` | ❌ | Profile image URL |
| phoneNumber | String? | `phone_number` | ❌ | Phone number |
| dateOfBirth | Date? | `date_of_birth` | ❌ | Date of birth |
| gender | String? | `gender` | ❌ | Gender (male/female/other/prefer_not_to_say/not_specified) |

### Verification Fields (Required)
| Field | Type | JSON Key | Required | Description |
|-------|------|----------|----------|-------------|
| emailVerified | Boolean | `email_verified` | ✅ | Email verification status |
| phoneVerified | Boolean | `phone_verified` | ✅ | Phone verification status |
| twoFactorEnabled | Boolean | `two_factor_enabled` | ✅ | 2FA enabled status |

### Nested Objects (Optional)
| Field | Type | JSON Key | Required | Description |
|-------|------|----------|----------|-------------|
| profile | UserProfile? | `profile` | ❌ | Extended profile information |
| preferences | UserPreferences? | `preferences` | ❌ | User preferences and settings |

## Error Response Format
```json
{
  "success": false,
  "message": "Authentication required",
  "data": null,
  "timestamp": "2024-01-15T10:30:00.000Z",
  "error": "UNAUTHORIZED"
}
```

## Validation Requirements

### iOS Validation Rules
The iOS application validates:
1. **Non-empty email** - Required for user identification
2. **Non-empty id** - Required for data relationships  
3. **Proper type casting** - All fields must match expected types
4. **Date format** - ISO 8601 format (`YYYY-MM-DDTHH:mm:ss.sssZ`)

### API Testing Console
The console validates the complete User object structure and will show mismatches if simplified format is returned.

## Migration Notes

### From Simplified to Complete Format
If currently returning simplified format:
```json
{
  "createdAt": "date",
  "dateOfBirth": "optional date", 
  "email": "user@example.com",
  "id": "string",
  "name": "User Name",
  "phoneNumber": "optional string",
  "profileImageURL": "optional string", 
  "updatedAt": "date"
}
```

**Add these required fields:**
- `email_verified`: Boolean
- `phone_verified`: Boolean  
- `two_factor_enabled`: Boolean
- `gender`: String (optional)
- `profile`: UserProfile object (optional)
- `preferences`: UserPreferences object (optional)

## Testing
Use the iOS API testing console to validate:
1. Complete User object structure
2. All required fields present
3. Proper data types
4. Nested object structure (if provided)

This ensures consistency between backend API and iOS application expectations.