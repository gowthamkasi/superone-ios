# Tests API Specification

**Generated**: 2025-08-31  
**Purpose**: Complete API specification for Tests and Health Packages backend implementation  
**Source**: iOS Swift codebase analysis for Tests feature integration

---

## Overview

This document provides the comprehensive API specification for the Tests feature, including individual tests and health packages. The iOS app requires these endpoints to replace mock data with real backend integration.

## Key Features Required

- **Tests List**: Paginated list of individual health tests with filtering
- **Test Details**: Comprehensive test information with preparation instructions
- **Health Packages**: List and details of test packages/bundles
- **Search & Filter**: Real-time search and category-based filtering
- **Favorites**: Save/unsave tests for later reference
- **Pagination**: Efficient data loading with offset/limit responses

---

## API Base Configuration

**Base URL**: Same as existing Super One API  
- Development: `https://3a1f05544bba.ngrok-free.app/api`
- Production: `https://api.superonehealth.com/api`

**Authentication**: JWT Bearer token required for all endpoints
**Headers**: Standard mobile headers as defined in existing API configuration

---

## API Endpoints

### 1. Get Tests List

```
GET /mobile/tests
```

**Purpose**: Get paginated list of available health tests with filtering and search

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `offset` | integer | No | Number of records to skip (default: 0) |
| `limit` | integer | No | Maximum records to return (default: 20, max: 50) |
| `search` | string | No | Search query (name, description, tags) |
| `category` | string | No | Filter by test category (see TestCategory enum) |
| `price_min` | integer | No | Minimum price filter (in rupees) |
| `price_max` | integer | No | Maximum price filter (in rupees) |
| `fasting_required` | boolean | No | Filter by fasting requirement |
| `sample_type` | string | No | Filter by sample type |
| `featured` | boolean | No | Show only featured tests |
| `available` | boolean | No | Show only available tests (default: true) |
| `sort_by` | string | No | Sort field: "name", "price", "duration", "popularity" |
| `sort_order` | string | No | Sort order: "asc", "desc" (default: "asc") |

**Response 200 OK**:
```json
{
  "success": true,
  "data": {
    "tests": [
      {
        "id": "string",
        "name": "string",
        "short_name": "string",
        "icon": "string",
        "category": "blood_test|imaging|cardiology|women|diabetes|thyroid|liver|kidney|cancer|fitness|allergy|infection",
        "duration": "string",
        "price": "string",
        "original_price": "string|null",
        "fasting": {
          "required": "none|8_hours|10_hours|12_hours|14_hours|overnight",
          "display_text": "string",
          "instructions": "string"
        },
        "sample_type": {
          "type": "blood|urine|saliva|stool|tissue|swab|breath|imaging",
          "display_name": "string",
          "icon": "string"
        },
        "report_time": "string",
        "description": "string",
        "tags": ["string"],
        "is_featured": boolean,
        "is_available": boolean,
        "category_color": "string" // Hex color code
      }
    ],
    "pagination": {
      "offset": integer,
      "limit": integer,
      "total": integer,
      "has_more": boolean
    },
    "filters_applied": {
      "search": "string|null",
      "category": "string|null",
      "price_range": {
        "min": integer,
        "max": integer
      },
      "fasting_required": "boolean|null"
    },
    "available_filters": {
      "categories": [
        {
          "key": "string",
          "display_name": "string",
          "count": integer,
          "color": "string"
        }
      ],
      "price_range": {
        "min": integer,
        "max": integer
      },
      "sample_types": [
        {
          "key": "string",
          "display_name": "string",
          "count": integer
        }
      ],
      "fasting_options": [
        {
          "key": "string",
          "display_text": "string",
          "count": integer
        }
      ]
    }
  },
  "message": "Tests retrieved successfully",
  "timestamp": "2025-08-31T10:30:00Z"
}
```

### 2. Get Test Details

```
GET /mobile/tests/{testId}
```

**Purpose**: Get comprehensive details for a specific test

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `testId` | string | Yes | Unique test identifier |

**Response 200 OK**:
```json
{
  "success": true,
  "data": {
    "id": "string",
    "name": "string",
    "short_name": "string",
    "icon": "string",
    "category": "blood_test|imaging|cardiology|women|diabetes|thyroid|liver|kidney|cancer|fitness|allergy|infection",
    "duration": "string",
    "price": "string",
    "original_price": "string|null",
    "fasting": {
      "required": "none|8_hours|10_hours|12_hours|14_hours|overnight",
      "display_text": "string",
      "instructions": "string"
    },
    "sample_type": {
      "type": "blood|urine|saliva|stool|tissue|swab|breath|imaging",
      "display_name": "string",
      "icon": "string"
    },
    "report_time": "string",
    "description": "string",
    "key_measurements": ["string"],
    "health_benefits": "string",
    "sections": [
      {
        "type": "about|why_needed|insights|preparation|results",
        "title": "string",
        "content": {
          "overview": "string|null",
          "bullet_points": ["string"],
          "categories": [
            {
              "icon": "string",
              "title": "string",
              "items": ["string"],
              "color": "string|null"
            }
          ],
          "tips": ["string"],
          "warnings": ["string"]
        }
      }
    ],
    "is_featured": boolean,
    "is_available": boolean,
    "tags": ["string"],
    "related_tests": [
      {
        "id": "string",
        "name": "string",
        "price": "string",
        "category": "string"
      }
    ],
    "available_labs": [
      {
        "id": "string",
        "name": "string",
        "location": "string",
        "rating": number,
        "price": "string",
        "next_available": "string"
      }
    ]
  },
  "message": "Test details retrieved successfully",
  "timestamp": "2025-08-31T10:30:00Z"
}
```

### 3. Get Health Packages List

```
GET /mobile/packages
```

**Purpose**: Get paginated list of available health packages

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `offset` | integer | No | Number of records to skip (default: 0) |
| `limit` | integer | No | Maximum records to return (default: 10, max: 20) |
| `search` | string | No | Search query (name, description) |
| `price_min` | integer | No | Minimum price filter |
| `price_max` | integer | No | Maximum price filter |
| `test_count_min` | integer | No | Minimum number of tests |
| `test_count_max` | integer | No | Maximum number of tests |
| `featured` | boolean | No | Show only featured packages |
| `popular` | boolean | No | Show only popular packages |
| `available` | boolean | No | Show only available packages (default: true) |
| `sort_by` | string | No | Sort field: "name", "price", "test_count", "popularity", "savings" |
| `sort_order` | string | No | Sort order: "asc", "desc" |

**Response 200 OK**:
```json
{
  "success": true,
  "data": {
    "packages": [
      {
        "id": "string",
        "name": "string",
        "short_name": "string",
        "icon": "string",
        "description": "string",
        "duration": "string",
        "total_tests": integer,
        "fasting_requirement": {
          "required": "none|8_hours|10_hours|12_hours|14_hours|overnight",
          "display_text": "string"
        },
        "report_time": "string",
        "package_price": integer,
        "individual_price": integer,
        "savings": integer,
        "discount_percentage": integer,
        "formatted_price": "string",
        "formatted_original_price": "string",
        "formatted_savings": "string",
        "is_featured": boolean,
        "is_available": boolean,
        "is_popular": boolean,
        "category": "string",
        "average_rating": number,
        "review_count": integer,
        "test_categories": [
          {
            "name": "string",
            "icon": "string",
            "test_count": integer
          }
        ]
      }
    ],
    "pagination": {
      "offset": integer,
      "limit": integer,
      "total": integer,
      "has_more": boolean
    },
    "filters_applied": {
      "search": "string|null",
      "price_range": {
        "min": integer,
        "max": integer
      }
    },
    "available_filters": {
      "price_range": {
        "min": integer,
        "max": integer
      },
      "test_count_range": {
        "min": integer,
        "max": integer
      },
      "categories": [
        {
          "key": "string",
          "display_name": "string",
          "count": integer
        }
      ]
    }
  },
  "message": "Health packages retrieved successfully",
  "timestamp": "2025-08-31T10:30:00Z"
}
```

### 4. Get Health Package Details

```
GET /mobile/packages/{packageId}
```

**Purpose**: Get comprehensive details for a specific health package

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `packageId` | string | Yes | Unique package identifier |

**Response 200 OK**:
```json
{
  "success": true,
  "data": {
    "id": "string",
    "name": "string",
    "short_name": "string",
    "icon": "string",
    "description": "string",
    "duration": "string",
    "total_tests": integer,
    "fasting_requirement": {
      "required": "none|8_hours|10_hours|12_hours|14_hours|overnight",
      "display_text": "string",
      "instructions": "string"
    },
    "report_time": "string",
    "package_price": integer,
    "individual_price": integer,
    "savings": integer,
    "discount_percentage": integer,
    "formatted_price": "string",
    "formatted_original_price": "string",
    "formatted_savings": "string",
    "test_categories": [
      {
        "id": "string",
        "name": "string",
        "icon": "string",
        "test_count": integer,
        "tests": [
          {
            "id": "string",
            "name": "string",
            "short_name": "string|null",
            "description": "string|null"
          }
        ]
      }
    ],
    "recommended_for": ["string"],
    "not_suitable_for": ["string"],
    "health_insights": {
      "early_detection": ["string"],
      "health_monitoring": ["string"],
      "ai_powered_analysis": ["string"],
      "additional_benefits": ["string"]
    },
    "preparation_instructions": {
      "fasting_hours": integer,
      "day_before": ["string"],
      "morning_of_test": ["string"],
      "what_to_bring": ["string"],
      "general_tips": ["string"]
    },
    "available_labs": [
      {
        "id": "string",
        "name": "string",
        "type": "lab|hospital|home_collection|clinic",
        "rating": number,
        "distance": "string",
        "availability": "string",
        "price": integer,
        "formatted_price": "string",
        "is_walk_in_available": boolean,
        "next_slot": "string|null",
        "address": "string|null",
        "phone_number": "string|null",
        "location": "string",
        "services": ["string"],
        "review_count": integer,
        "operating_hours": "string",
        "is_recommended": boolean,
        "offers_home_collection": boolean,
        "accepts_insurance": boolean
      }
    ],
    "package_variants": [
      {
        "id": "string",
        "name": "string",
        "price": integer,
        "formatted_price": "string",
        "test_count": integer,
        "duration": "string",
        "description": "string",
        "is_popular": boolean
      }
    ],
    "customer_reviews": [
      {
        "id": "string",
        "customer_name": "string",
        "rating": number,
        "comment": "string",
        "date": "2025-08-31T10:30:00Z",
        "is_verified": boolean,
        "time_ago": "string"
      }
    ],
    "faq_items": [
      {
        "id": "string",
        "question": "string",
        "answer": "string"
      }
    ],
    "is_featured": boolean,
    "is_available": boolean,
    "is_popular": boolean,
    "category": "string",
    "average_rating": number,
    "related_packages": [
      {
        "id": "string",
        "name": "string",
        "price": integer,
        "test_count": integer
      }
    ]
  },
  "message": "Package details retrieved successfully",
  "timestamp": "2025-08-31T10:30:00Z"
}
```

### 5. Favorites Management

#### Add/Remove Test Favorite
```
POST /mobile/tests/{testId}/favorite
DELETE /mobile/tests/{testId}/favorite
```

**Purpose**: Add or remove test from user favorites

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `testId` | string | Yes | Unique test identifier |

**Response 200 OK**:
```json
{
  "success": true,
  "data": {
    "test_id": "string",
    "is_favorite": boolean
  },
  "message": "Favorite status updated successfully",
  "timestamp": "2025-08-31T10:30:00Z"
}
```

#### Get User Favorites
```
GET /mobile/favorites/tests
```

**Purpose**: Get user's favorite tests

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `offset` | integer | No | Number of records to skip (default: 0) |
| `limit` | integer | No | Maximum records to return (default: 20) |

**Response 200 OK**:
```json
{
  "success": true,
  "data": {
    "favorites": [
      {
        "id": "string",
        "name": "string",
        "price": "string",
        "category": "string",
        "added_at": "2025-08-31T10:30:00Z"
      }
    ],
    "pagination": {
      "offset": integer,
      "limit": integer,
      "total": integer,
      "has_more": boolean
    }
  },
  "message": "Favorites retrieved successfully",
  "timestamp": "2025-08-31T10:30:00Z"
}
```

### 6. Search Suggestions

```
GET /mobile/tests/search/suggestions?q={query}
```

**Purpose**: Get search suggestions for tests and packages

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Search query (minimum 2 characters) |
| `limit` | integer | No | Maximum suggestions (default: 10) |

**Response 200 OK**:
```json
{
  "success": true,
  "data": {
    "suggestions": [
      {
        "text": "string",
        "type": "test|package|category",
        "count": integer
      }
    ],
    "popular_searches": ["string"]
  },
  "message": "Search suggestions retrieved successfully",
  "timestamp": "2025-08-31T10:30:00Z"
}
```

---

## Data Models Reference

### TestCategory Enum
```
blood_test, imaging, cardiology, women, diabetes, thyroid, liver, kidney, cancer, fitness, allergy, infection
```

### FastingRequirement Enum
```
none, 8_hours, 10_hours, 12_hours, 14_hours, overnight
```

### SampleType Enum
```
blood, urine, saliva, stool, tissue, swab, breath, imaging
```

### SectionType Enum
```
about, why_needed, insights, preparation, results
```

### LabType Enum
```
lab, hospital, home_collection, clinic
```

---

## Error Handling

All endpoints follow the standard error response format:

```json
{
  "success": false,
  "error": {
    "code": "string",
    "message": "string",
    "user_message": "string",
    "retryable": boolean
  },
  "timestamp": "2025-08-31T10:30:00Z"
}
```

### Common Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | INVALID_PARAMETERS | Invalid query parameters |
| 401 | UNAUTHORIZED | Authentication required |
| 404 | TEST_NOT_FOUND | Test not found |
| 404 | PACKAGE_NOT_FOUND | Package not found |
| 429 | RATE_LIMITED | Too many requests |
| 500 | INTERNAL_ERROR | Server error |

---

## Implementation Notes

### Search Functionality
- **Full-text search** across test names, descriptions, and tags
- **Autocomplete** with real-time suggestions
- **Search history** for logged-in users
- **Fuzzy matching** for typos and partial matches

### Filtering System
- **Multiple filters** can be applied simultaneously
- **Filter combinations** are AND-ed together
- **Available filters** are dynamically calculated based on current results
- **Filter counts** show number of results for each option

### Pagination Strategy
- **Offset/limit pagination** with configurable record limits
- **Cursor-based pagination** for real-time updates (optional)
- **Total count** provided for UI pagination controls
- **Deep linking** support with offset parameters

### Caching Recommendations
- **Test list**: Cache for 30 minutes
- **Test details**: Cache for 2 hours
- **Package details**: Cache for 2 hours
- **Search suggestions**: Cache for 1 hour
- **Favorites**: No caching (always fresh)

### Performance Considerations
- **Database indexing** on searchable fields
- **Search optimization** with dedicated search indexes
- **Image optimization** for test and package icons
- **Response compression** for large payloads
- **CDN caching** for static content

---

## iOS Integration Points

### Existing Models Compatibility
- All response models are compatible with existing Swift models
- Codable conformance for easy JSON mapping
- Optional fields handled properly
- Date formatting in ISO8601 standard

### View Model Integration
- Replace `MockTestService` with `TestsAPIService`
- Replace `MockPackageService` with `PackagesAPIService`
- Maintain existing protocol contracts
- Add proper error handling and loading states

### UI Components Integration
- `TestsListView` will use paginated API responses
- Search and filter UI will trigger API calls
- Loading states for better user experience
- Error handling with retry mechanisms

---

This specification provides the complete contract needed for backend implementation. All field names, data types, and response structures match the iOS app's expectations for seamless integration.