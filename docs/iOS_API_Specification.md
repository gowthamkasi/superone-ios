# Super One iOS App - Complete API Specification

## Executive Summary

This document provides a comprehensive analysis of all API endpoints, data structures, and networking requirements discovered from the Super One iOS Swift codebase. The iOS app integrates with a Node.js/Fastify backend using REST APIs with JWT authentication.

**Base URLs:**
- Development: `https://44672c695c91.ngrok-free.app`
- Staging: `https://staging-api.superonehealth.com`
- Production: `https://api.superonehealth.com`

**API Version:** `/api` (base path) and `/api/mobile` (mobile-specific endpoints)

---

## Table of Contents

1. [Authentication & Authorization](#authentication--authorization)
2. [User Management](#user-management)
3. [Health Analysis](#health-analysis)
4. [Lab Report Upload & Processing](#lab-report-upload--processing)
5. [Dashboard & Insights](#dashboard--insights)
6. [Appointment Management](#appointment-management)
7. [Data Export](#data-export)
8. [Error Handling](#error-handling)
9. [Request/Response Standards](#requestresponse-standards)
10. [Security Requirements](#security-requirements)

---

## Authentication & Authorization

### JWT Token-Based Authentication
- **Token Type:** Bearer tokens
- **Header:** `Authorization: Bearer <token>`
- **Token Storage:** iOS Keychain (secure enclave)
- **Refresh Mechanism:** Automatic token refresh using refresh tokens

### Authentication Endpoints

#### 1. User Registration
```
POST /api/mobile/auth/register
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "string",
  "password": "string",
  "name": "string",
  "date_of_birth": "string (YYYY-MM-DD, optional)",
  "phone_number": "string (optional)",
  "device_id": "string (optional)",
  "accepted_terms": true,
  "accepted_privacy": true
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "_id": "string",
      "email": "string",
      "name": "string",
      "profile_image_url": "string?",
      "phone_number": "string?",
      "date_of_birth": "string?",
      "gender": "string?",
      "created_at": "string (ISO8601)",
      "updated_at": "string (ISO8601)",
      "email_verified": false,
      "phone_verified": false,
      "two_factor_enabled": false,
      "profile": {
        "date_of_birth": "string?",
        "gender": "string?",
        "height": 0.0,
        "weight": 0.0,
        "activity_level": "string?",
        "health_goals": ["string"],
        "medical_conditions": ["string"],
        "medications": ["string"],
        "allergies": ["string"],
        "emergency_contact": {
          "name": "string",
          "relationship": "string",
          "phone_number": "string",
          "email": "string?"
        },
        "profile_image_url": "string?",
        "labloop_patient_id": "string?"
      },
      "preferences": {
        "notifications": {
          "health_alerts": true,
          "appointment_reminders": true,
          "report_ready": true,
          "recommendations": true,
          "weekly_digest": true,
          "monthly_report": true,
          "push_enabled": true,
          "email_enabled": true,
          "sms_enabled": false,
          "quiet_hours": {
            "enabled": false,
            "start_time": "22:00",
            "end_time": "07:00"
          }
        },
        "privacy": {
          "share_data_with_providers": false,
          "share_data_for_research": false,
          "allow_analytics": true,
          "allow_marketing": false,
          "data_retention_period": 2555
        },
        "units": {
          "weight_unit": "kg",
          "height_unit": "cm",
          "temperature_unit": "celsius",
          "date_format": "MM/dd/yyyy"
        },
        "theme": "system"
      }
    },
    "tokens": {
      "accessToken": "string",
      "refreshToken": "string",
      "tokenType": "Bearer",
      "expiresIn": 900
    },
    "expiresAt": "string (ISO8601)",
    "refreshExpiresAt": "string (ISO8601)"
  },
  "timestamp": "string (ISO8601)"
}
```

#### 2. User Login
```
POST /api/mobile/auth/login
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "_id": "string",
      "email": "string",
      "name": "string",
      "profile_image_url": "string?",
      "phone_number": "string?",
      "date_of_birth": "string?",
      "gender": "string?",
      "created_at": "string (ISO8601)",
      "updated_at": "string (ISO8601)",
      "email_verified": false,
      "phone_verified": false,
      "two_factor_enabled": false,
      "profile": {
        "date_of_birth": "string?",
        "gender": "string?",
        "height": 0.0,
        "weight": 0.0,
        "activity_level": "string?",
        "health_goals": ["string"],
        "medical_conditions": ["string"],
        "medications": ["string"],
        "allergies": ["string"],
        "emergency_contact": {
          "name": "string",
          "relationship": "string",
          "phone_number": "string",
          "email": "string?"
        },
        "profile_image_url": "string?",
        "labloop_patient_id": "string?"
      },
      "preferences": {
        "notifications": {
          "health_alerts": true,
          "appointment_reminders": true,
          "report_ready": true,
          "recommendations": true,
          "weekly_digest": true,
          "monthly_report": true,
          "push_enabled": true,
          "email_enabled": true,
          "sms_enabled": false,
          "quiet_hours": {
            "enabled": false,
            "start_time": "22:00",
            "end_time": "07:00"
          }
        },
        "privacy": {
          "share_data_with_providers": false,
          "share_data_for_research": false,
          "allow_analytics": true,
          "allow_marketing": false,
          "data_retention_period": 2555
        },
        "units": {
          "weight_unit": "kg",
          "height_unit": "cm",
          "temperature_unit": "celsius",
          "date_format": "MM/dd/yyyy"
        },
        "theme": "system"
      }
    },
    "tokens": {
      "accessToken": "string",
      "refreshToken": "string",
      "tokenType": "Bearer",
      "expiresIn": 900
    },
    "expiresAt": "string (ISO8601)",
    "refreshExpiresAt": "string (ISO8601)"
  },
  "timestamp": "string (ISO8601)"
}
```

#### 3. Token Refresh
```
POST /api/mobile/auth/refresh
Content-Type: application/json
Authorization: Bearer <refresh_token>
```

**Request Body:**
```json
{
  "refreshToken": "string"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "accessToken": "string",
    "refreshToken": "string",
    "tokenType": "Bearer",
    "expiresIn": 900
  },
  "message": "Token refreshed successfully",
  "timestamp": "string (ISO8601)"
}
```

#### 4. Logout
```
POST /api/mobile/auth/logout
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Logout successful",
  "timestamp": "string (ISO8601)"
}
```

#### 5. Password Reset Request
```
POST /api/mobile/auth/forgot-password
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "string"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Password reset email sent",
  "data": {
    "resetToken": "string?",
    "expiresAt": "string (ISO8601)?"
  },
  "timestamp": "string (ISO8601)"
}
```

#### 6. Get Current User
```
GET /auth/profile
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "_id": "string",
  "email": "string",
  "name": "string",
  "profile_image_url": "string?",
  "phone_number": "string?",
  "date_of_birth": "string?",
  "gender": "string?",
  "created_at": "string (ISO8601)",
  "updated_at": "string (ISO8601)",
  "email_verified": true,
  "phone_verified": false,
  "two_factor_enabled": false,
  "profile": {
    "date_of_birth": "string?",
    "gender": "string?",
    "height": 0.0,
    "weight": 0.0,
    "activity_level": "string?",
    "health_goals": ["string"],
    "medical_conditions": ["string"],
    "medications": ["string"],
    "allergies": ["string"],
    "emergency_contact": {
      "name": "string",
      "relationship": "string",
      "phone_number": "string",
      "email": "string?"
    },
    "profile_image_url": "string?",
    "labloop_patient_id": "string?"
  },
  "preferences": {
    "notifications": {
      "health_alerts": true,
      "appointment_reminders": true,
      "report_ready": true,
      "recommendations": true,
      "weekly_digest": true,
      "monthly_report": true,
      "push_enabled": true,
      "email_enabled": true,
      "sms_enabled": false,
      "quiet_hours": {
        "enabled": false,
        "start_time": "22:00",
        "end_time": "07:00"
      }
    },
    "privacy": {
      "share_data_with_providers": false,
      "share_data_for_research": false,
      "allow_analytics": true,
      "allow_marketing": false,
      "data_retention_period": 2555
    },
    "units": {
      "weight_unit": "kg",
      "height_unit": "cm",
      "temperature_unit": "celsius",
      "date_format": "MM/dd/yyyy"
    },
    "theme": "system"
  }
}
```

---

## User Management

### Profile Management Endpoints

#### 1. Update User Profile
```
PUT /api/mobile/users/profile
Content-Type: application/json
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "date_of_birth": "string (ISO8601)?",
  "gender": "string?",
  "height": 0.0,
  "weight": 0.0,
  "activity_level": "string?",
  "health_goals": ["string"],
  "medical_conditions": ["string"],
  "medications": ["string"],
  "allergies": ["string"]
}
```

#### 2. Get User Devices
```
GET /api/mobile/users/devices
Authorization: Bearer <access_token>
```

---

## Health Analysis

### Health Analysis Endpoints

#### 1. Generate Health Analysis
```
POST /api/v1/health-analysis/generate
Content-Type: application/json
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "lab_report_id": "string",
  "user_preferences": {
    "riskTolerance": "conservative|moderate|aggressive",
    "detailLevel": "basic|standard|comprehensive",
    "focusAreas": ["cardiovascular", "metabolic", "nutritional"],
    "includeRecommendations": true,
    "includeComparisons": true,
    "language": "en"
  }
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Health analysis generated successfully",
  "data": {
    "analysis_id": "string",
    "overall_health_score": 85,
    "health_trend": "improving|stable|declining",
    "risk_level": "low|moderate|high|severe",
    "primary_concerns": ["string"],
    "immediate_actions": ["string"],
    "confidence": 0.95,
    "analysis_date": "string (ISO8601)"
  },
  "timestamp": "string (ISO8601)"
}
```

#### 2. Get Analysis by ID
```
GET /api/v1/health-analysis/{analysisId}?includeRawResponse=false
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Analysis retrieved successfully",
  "data": {
    "analysis_id": "string",
    "overall_health_score": 85,
    "health_trend": "improving",
    "risk_level": "moderate",
    "primary_concerns": ["Elevated cholesterol levels", "Vitamin D deficiency"],
    "immediate_actions": ["Consult with healthcare provider", "Consider dietary changes"],
    "confidence": 0.95,
    "analysis_date": "string (ISO8601)"
  },
  "timestamp": "string (ISO8601)"
}
```

#### 3. Get Latest Analysis
```
GET /api/v1/health-analysis/latest
Authorization: Bearer <access_token>
```

**Response (200 OK or 404 Not Found):**
```json
{
  "success": true,
  "message": "Analysis retrieved successfully",
  "data": {
    "analysis_id": "string",
    "overall_health_score": 85,
    "health_trend": "improving",
    "risk_level": "moderate",
    "primary_concerns": ["Elevated cholesterol levels", "Vitamin D deficiency"],
    "immediate_actions": ["Consult with healthcare provider", "Consider dietary changes"],
    "confidence": 0.95,
    "analysis_date": "string (ISO8601)"
  },
  "timestamp": "string (ISO8601)"
}
```

#### 4. Get Analysis History
```
GET /api/v1/health-analysis/history?page=1&limit=10
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Analysis history retrieved",
  "data": [
    {
      "analysis_id": "string",
      "overall_health_score": 85,
      "health_trend": "improving",
      "risk_level": "moderate",
      "primary_concerns": ["Elevated cholesterol levels", "Vitamin D deficiency"],
      "immediate_actions": ["Consult with healthcare provider", "Consider dietary changes"],
      "confidence": 0.95,
      "analysis_date": "string (ISO8601)"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_items": 45,
    "items_per_page": 10
  },
  "timestamp": "string (ISO8601)"
}
```

#### 5. Get Analysis Statistics
```
GET /api/v1/health-analysis/stats?timeRange=365
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Analysis statistics retrieved",
  "data": {
    "total_analyses": 12,
    "average_score": 78.5,
    "trend_direction": "improving",
    "improvement_percentage": 15.2,
    "last_analysis_date": "string (ISO8601)"
  },
  "timestamp": "string (ISO8601)"
}
```

#### 6. Personalize Recommendations
```
POST /api/v1/health-analysis/{analysisId}/personalize
Content-Type: application/json
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "user_preferences": {
    "riskTolerance": "moderate",
    "detailLevel": "comprehensive",
    "focusAreas": ["cardiovascular", "nutritional"]
  }
}
```

#### 7. Compare Analyses
```
GET /api/v1/health-analysis/compare?analysisIds=id1,id2,id3
Authorization: Bearer <access_token>
```

#### 8. Get Biomarker Trends
```
GET /api/v1/health-analysis/trends?timeRange=6months
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Biomarker trends retrieved",
  "data": {
    "Total Cholesterol": [
      {
        "date": "string (ISO8601)",
        "value": 185.5,
        "status": "normal",
        "isOptimal": true
      }
    ],
    "HDL Cholesterol": [
      {
        "date": "string (ISO8601)",
        "value": 65.2,
        "status": "optimal",
        "isOptimal": true
      }
    ]
  },
  "timestamp": "string (ISO8601)"
}
```

#### 9. Delete Analysis
```
DELETE /api/v1/health-analysis/{analysisId}
Authorization: Bearer <access_token>
```

---

## Lab Report Upload & Processing

### File Upload Endpoints

#### 1. Upload Single Lab Report
```
POST /api/v1/upload/lab-report
Content-Type: multipart/form-data
Authorization: Bearer <access_token>
```

**Form Data:**
- `file`: Binary file data (PDF, JPEG, PNG, HEIC)
- `userPreferences`: JSON string (optional)

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Lab report uploaded successfully",
  "data": {
    "id": "string",
    "document": {
      "id": "string",
      "fileName": "string",
      "filePath": "string?",
      "fileSize": 1024000,
      "mimeType": "application/pdf",
      "uploadDate": "string (ISO8601)",
      "processingStatus": "pending|uploading|processing|completed|failed",
      "documentType": "lab_report|blood_work|lipid_panel",
      "healthCategory": "cardiovascular|metabolic|nutritional",
      "extractedText": "string?",
      "ocrConfidence": 0.95,
      "thumbnail": "base64_string?",
      "metadata": { "key": "value" }
    },
    "extractedBiomarkers": [
      {
        "id": "string",
        "name": "Total Cholesterol",
        "value": "185",
        "unit": "mg/dL",
        "referenceRange": "< 200 mg/dL",
        "status": "normal",
        "confidence": 0.92,
        "extractionMethod": "aws_textract",
        "textLocation": "string?",
        "category": "cardiovascular",
        "normalizedValue": 185.0,
        "isNumeric": true,
        "notes": "string?"
      }
    ],
    "healthAnalysis": {
      "analysis_id": "string",
      "overall_health_score": 85,
      "health_trend": "improving",
      "risk_level": "moderate",
      "primary_concerns": ["Elevated cholesterol levels"],
      "immediate_actions": ["Consult with healthcare provider"],
      "confidence": 0.95,
      "analysis_date": "string (ISO8601)"
    },
    "processingStatus": "completed",
    "createdAt": "string (ISO8601)"
  },
  "timestamp": "string (ISO8601)"
}
```

#### 2. Upload Multiple Lab Reports (Batch)
```
POST /api/v1/upload/lab-reports/batch
Content-Type: multipart/form-data
Authorization: Bearer <access_token>
```

**Form Data:**
- `files`: Multiple binary file data
- `userPreferences`: JSON string (optional)

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Batch upload completed",
  "data": {
    "successful": [
      {
        "id": "string",
        "document": {
          "id": "string",
          "fileName": "string",
          "filePath": "string?",
          "fileSize": 1024000,
          "mimeType": "application/pdf",
          "uploadDate": "string (ISO8601)",
          "processingStatus": "completed",
          "documentType": "lab_report",
          "healthCategory": "cardiovascular",
          "extractedText": "string?",
          "ocrConfidence": 0.95,
          "thumbnail": "base64_string?",
          "metadata": { "key": "value" }
        },
        "extractedBiomarkers": [],
        "healthAnalysis": null,
        "processingStatus": "completed",
        "createdAt": "string (ISO8601)"
      }
    ],
    "failed": [
      {
        "file_name": "string",
        "error": "string",
        "error_code": "string?"
      }
    ],
    "total_uploaded": 3,
    "total_failed": 1
  },
  "timestamp": "string (ISO8601)"
}
```

#### 3. Get Processing Status
```
GET /api/v1/upload/status/{labReportId}
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "labReportId": "string",
    "status": "pending|processing|completed|failed",
    "progress": 0.75,
    "currentStep": "extracting",
    "estimatedTimeRemaining": 30,
    "extractedData": {
      "biomarkersFound": 12,
      "confidence": 0.89,
      "categories": ["cardiovascular", "metabolic"]
    },
    "errors": [
      {
        "step": "ocr_processing",
        "error": "Low image quality detected",
        "recoverable": true
      }
    ]
  },
  "message": "Processing status retrieved",
  "timestamp": "string (ISO8601)"
}
```

#### 4. Get Upload History
```
GET /api/v1/upload/history?page=1&limit=10
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Upload history retrieved",
  "data": {
    "uploads": [
      {
        "id": "string",
        "document": {
          "id": "string",
          "fileName": "string",
          "filePath": "string?",
          "fileSize": 1024000,
          "mimeType": "application/pdf",
          "uploadDate": "string (ISO8601)",
          "processingStatus": "completed",
          "documentType": "lab_report",
          "healthCategory": "cardiovascular",
          "extractedText": "string?",
          "ocrConfidence": 0.95,
          "thumbnail": "base64_string?",
          "metadata": { "key": "value" }
        },
        "extractedBiomarkers": [],
        "healthAnalysis": null,
        "processingStatus": "completed",
        "createdAt": "string (ISO8601)"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 45,
      "totalPages": 5,
      "hasNext": true,
      "hasPrevious": false
    },
    "total_size": 104857600,
    "categories": ["lab_report", "blood_work", "lipid_panel"]
  },
  "timestamp": "string (ISO8601)"
}
```

#### 5. Get Upload Statistics
```
GET /api/v1/upload/statistics?timeRange=6months
Authorization: Bearer <access_token>
```

#### 6. Filter Upload History
```
POST /api/v1/upload/history/filtered
Content-Type: application/json
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "filters": {
    "dateRange": {
      "startDate": "string (ISO8601)",
      "endDate": "string (ISO8601)"
    },
    "processingStatus": ["completed", "failed"],
    "documentTypes": ["lab_report", "blood_work"],
    "healthCategories": ["cardiovascular", "metabolic"],
    "searchTerm": "cholesterol",
    "fileTypes": ["application/pdf"],
    "confidenceRange": {
      "min": 0.8,
      "max": 1.0
    }
  },
  "pagination": {
    "page": 1,
    "limit": 10
  }
}
```

#### 7. Batch History Operations
```
POST /api/v1/upload/history/batch
Content-Type: application/json
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "operation": "delete|export|reprocess",
  "labReportIds": ["string"],
  "options": {
    "exportFormat": "pdf|csv|json",
    "includeAnalysis": true
  }
}
```

#### 8. Delete Upload
```
DELETE /api/v1/upload/{labReportId}
Authorization: Bearer <access_token>
```

---

## Dashboard & Insights

### Dashboard Endpoints

#### 1. Get Dashboard Overview
```
GET /api/mobile/dashboard/overview
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "user": {
      "name": "John Doe",
      "email": "john.doe@example.com"
    },
    "healthScore": {
      "overall": 85.5,
      "trend": "improving",
      "status": "good",
      "lastCalculated": "2025-01-20T10:30:00.000Z",
      "categoryBreakdown": {
        "cardiovascular": 78.0,
        "metabolic": 92.0,
        "nutritional": 85.0,
        "hematology": 88.0,
        "hepatic_renal": 82.0,
        "immune": 90.0,
        "endocrine": 75.0
      }
    },
    "greeting": {
      "timeBasedGreeting": "Good morning",
      "personalizedMessage": "Your health score has improved by 5 points this month!"
    },
    "stats": {
      "recentTests": 3,
      "recommendations": 7,
      "healthAlerts": 1,
      "upcomingAppointments": 2
    },
    "alerts": [
      {
        "id": "alert_001",
        "type": "abnormal_result",
        "severity": "warning",
        "title": "Vitamin D Deficiency Detected",
        "message": "Your latest test shows low vitamin D levels (18 ng/mL). Normal range is 30-100 ng/mL.",
        "category": "nutritional",
        "createdAt": "2025-01-20T09:15:00.000Z",
        "actionRequired": true
      },
      {
        "id": "alert_002",
        "type": "trend_change",
        "severity": "info",
        "title": "Cholesterol Improving",
        "message": "Your cholesterol levels have decreased by 15% over the last 3 months.",
        "category": "cardiovascular",
        "createdAt": "2025-01-19T14:22:00.000Z",
        "actionRequired": false
      }
    ],
    "lastUpdated": "2025-01-20T10:30:00.000Z"
  },
  "message": "Dashboard data retrieved",
  "timestamp": "2025-01-20T10:30:15.123Z"
}
```

#### 2. Get Health Score
```
GET /api/mobile/dashboard/health-score
Authorization: Bearer <access_token>
```

#### 3. Get Dashboard Statistics
```
GET /api/mobile/dashboard/stats
Authorization: Bearer <access_token>
```

#### 4. Get Health Categories (Slider)
```
GET /api/mobile/health-categories/slider
Authorization: Bearer <access_token>
```

#### 5. Get Health Categories Detail
```
GET /api/mobile/health-categories
Authorization: Bearer <access_token>
```

#### 6. Get Health Category Trends
```
GET /api/mobile/health-categories/trends
Authorization: Bearer <access_token>
```

### Mobile-Specific Endpoints

#### 7. Get Mobile Processing Status
```
GET /api/mobile/processing
Authorization: Bearer <access_token>
```

#### 8. Get Mobile Reports
```
GET /api/mobile/reports
Authorization: Bearer <access_token>
```

#### 9. Get Mobile Analytics
```
GET /api/mobile/analytics
Authorization: Bearer <access_token>
```

### Recommendations

#### 10. Get Recommendations List
```
GET /api/mobile/recommendations/list
Authorization: Bearer <access_token>
```

#### 11. Get Smart Recommendations
```
GET /api/mobile/recommendations/smart
Authorization: Bearer <access_token>
```

#### 12. Acknowledge Recommendation
```
POST /api/mobile/recommendations/acknowledge
Content-Type: application/json
Authorization: Bearer <access_token>
```

#### 13. Get Recommendations Statistics
```
GET /api/mobile/recommendations/stats
Authorization: Bearer <access_token>
```

#### 14. Get Recommendations Insights
```
GET /api/mobile/recommendations/insights
Authorization: Bearer <access_token>
```

---

## Appointment Management

### Appointment Endpoints

#### 1. Get Appointments
```
GET /api/mobile/appointments
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "string",
      "userId": "string",
      "facilityId": "string",
      "facilityName": "LabCorp",
      "location": "Downtown Medical Center",
      "serviceType": "blood_work",
      "appointmentDate": "string (ISO8601)",
      "appointmentTime": "09:30",
      "status": "scheduled",
      "confirmationNumber": "LC123456",
      "notes": "Fasting required",
      "createdAt": "string (ISO8601)",
      "updatedAt": "string (ISO8601)"
    }
  ],
  "message": "Appointments retrieved",
  "timestamp": "string (ISO8601)"
}
```

#### 2. Book Appointment
```
POST /api/mobile/appointments
Content-Type: application/json
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "facilityId": "string",
  "serviceType": "blood_work",
  "preferredDate": "string (ISO8601)",
  "preferredTime": "09:30",
  "notes": "string?",
  "insuranceProvider": "string?",
  "emergencyContact": {
    "name": "string",
    "relationship": "string",
    "phone_number": "string",
    "email": "string?"
  }
}
```

#### 3. Get Lab Facilities
```
GET /api/mobile/facilities
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "string",
      "name": "LabCorp",
      "location": "Downtown Medical Center",
      "address": {
        "street": "123 Medical Drive",
        "city": "San Francisco",
        "state": "CA",
        "zipCode": "94102",
        "country": "USA",
        "coordinates": {
          "latitude": 37.7749,
          "longitude": -122.4194
        }
      },
      "phoneNumber": "+1-555-0123",
      "email": "info@labcorp.com",
      "website": "https://labcorp.com",
      "services": ["blood_work", "urinalysis", "lipid_panel", "metabolic_panel", "thyroid_function"],
      "operatingHours": [
        {
          "dayOfWeek": 1,
          "openTime": "08:00",
          "closeTime": "17:00",
          "isClosed": false
        },
        {
          "dayOfWeek": 2,
          "openTime": "08:00",
          "closeTime": "17:00",
          "isClosed": false
        },
        {
          "dayOfWeek": 3,
          "openTime": "08:00",
          "closeTime": "17:00",
          "isClosed": false
        },
        {
          "dayOfWeek": 4,
          "openTime": "08:00",
          "closeTime": "17:00",
          "isClosed": false
        },
        {
          "dayOfWeek": 5,
          "openTime": "08:00",
          "closeTime": "17:00",
          "isClosed": false
        },
        {
          "dayOfWeek": 6,
          "openTime": "09:00",
          "closeTime": "12:00",
          "isClosed": false
        },
        {
          "dayOfWeek": 0,
          "openTime": "00:00",
          "closeTime": "00:00",
          "isClosed": true
        }
      ],
      "rating": 4.5,
      "reviewCount": 125,
      "acceptsInsurance": true,
      "acceptsWalkIns": false,
      "averageWaitTime": 15,
      "distance": 2.5,
      "amenities": ["parking", "wheelchair_accessible"]
    }
  ],
  "message": "Lab facilities retrieved",
  "timestamp": "string (ISO8601)"
}
```

---

## Data Export

### Export Endpoints

#### 1. Export User Data
```
GET /api/mobile/export/user-data?format=json&includeAnalysis=true
Authorization: Bearer <access_token>
```

#### 2. Export Health Reports
```
GET /api/mobile/export/health-reports?format=pdf&timeRange=6months
Authorization: Bearer <access_token>
```

---

## Error Handling

### Standard Error Response Format

All API errors follow this consistent format:

```json
{
  "success": false,
  "error": "Error type",
  "message": "Human-readable error message",
  "code": "ERROR_CODE",
  "details": "Additional error details",
  "timestamp": "string (ISO8601)",
  "request_id": "string"
}
```

### HTTP Status Codes

- **200 OK**: Successful GET, PUT requests
- **201 Created**: Successful POST requests (resource creation)
- **400 Bad Request**: Invalid request data
- **401 Unauthorized**: Missing or invalid authentication token
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **409 Conflict**: Resource conflict (e.g., duplicate email)
- **422 Unprocessable Entity**: Validation errors
- **429 Too Many Requests**: Rate limiting
- **500 Internal Server Error**: Server-side errors
- **502 Bad Gateway**: Upstream service errors
- **503 Service Unavailable**: Temporary service outage

### Common Error Codes

- `AUTHENTICATION_REQUIRED`: User needs to log in
- `TOKEN_EXPIRED`: Access token has expired
- `VALIDATION_ERROR`: Request validation failed
- `NETWORK_ERROR`: Network connectivity issues
- `FILE_SIZE_EXCEEDED`: Upload file too large
- `UNSUPPORTED_FILE_TYPE`: Invalid file format
- `PROCESSING_FAILED`: OCR or analysis processing failed
- `INSUFFICIENT_DATA`: Not enough data for analysis
- `ANALYSIS_TIMEOUT`: Analysis processing timed out

---

## Request/Response Standards

### Headers

**Standard Request Headers:**
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer <access_token>
User-Agent: SuperOne-iOS/1.0.0
X-Platform: iOS
X-App-Version: 1.0.0
X-Build-Number: 1
ngrok-skip-browser-warning: true
```

**Multipart Upload Headers:**
```
Content-Type: multipart/form-data; boundary=<boundary>
Authorization: Bearer <access_token>
```

### Date Formats

- **ISO8601 with timezone**: `2025-01-29T15:30:45.123Z`
- **Date only**: `2025-01-29` (for date of birth, etc.)
- **Time only**: `09:30` (for appointment times)

### Pagination

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10, max: 100)

**Response Format:**
```json
{
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 45,
    "totalPages": 5,
    "hasNext": true,
    "hasPrevious": false,
    "currentPage": 1
  }
}
```

### File Upload Constraints

- **Maximum file size**: 10MB
- **Supported formats**: PDF, JPEG, PNG, HEIC
- **Batch upload limit**: 5 files per request
- **Timeout**: 30 seconds for uploads

---

## Security Requirements

### Authentication & Authorization

1. **JWT Tokens**:
   - Access token expiry: 15 minutes
   - Refresh token expiry: 7 days
   - Secure storage in iOS Keychain

2. **HTTPS Only**: All endpoints must use HTTPS in production

3. **Request Validation**:
   - Input validation and sanitization
   - File type and size validation
   - Rate limiting per user/IP

### Data Protection

1. **Personal Health Information (PHI)**:
   - HIPAA compliance required
   - End-to-end encryption for sensitive data
   - Audit logging for all data access

2. **File Processing**:
   - Virus scanning for uploaded files
   - Secure temporary storage
   - Automatic cleanup of processed files

### App Integrity

1. **Production Validation**:
   - No debug flags in production builds
   - Certificate pinning for API calls
   - App store validation

2. **Biometric Authentication**:
   - Face ID/Touch ID support
   - Secure enclave integration
   - Fallback to device passcode

---

## Integration Notes

### Backend Technology Stack
- **Framework**: Node.js with Fastify 5.x
- **Database**: MongoDB with Mongoose ODM
- **File Storage**: AWS S3
- **OCR Processing**: AWS Textract
- **AI Analysis**: AWS Bedrock Claude 4 + Anthropic Claude SDK + Ollama Llama 3.2
- **Authentication**: JWT with bcrypt

### iOS Implementation Details
- **Networking**: Alamofire 5.x for HTTP requests
- **Architecture**: MVVM with Clean Architecture
- **Data Storage**: Core Data + Keychain
- **UI Framework**: SwiftUI 6.0
- **Minimum iOS**: 18.0+

### Performance Considerations

1. **Request Timeouts**:
   - Standard requests: 15 seconds
   - Upload requests: 30 seconds
   - Analysis requests: 5 minutes (with polling)

2. **Retry Logic**:
   - Automatic retry for 5xx errors (max 2 attempts)
   - Exponential backoff (0.5s, 1s delays)
   - User-initiated retry for network errors

3. **Caching**:
   - Response caching for static data
   - Image caching for reports
   - Offline support for cached data

---

This comprehensive API specification documents all network interactions discovered in the Super One iOS codebase and provides the foundation for implementing a compatible backend service.