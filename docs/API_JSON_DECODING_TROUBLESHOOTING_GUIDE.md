# API JSON Decoding Troubleshooting Guide

## Overview

This guide provides a systematic approach to diagnosing and fixing JSON decoding issues in iOS apps that consume REST APIs. It's based on successfully resolving the "Failed to decode response" error in the Super One health app.

## Common Symptoms

- ✅ API returns valid JSON (confirmed via curl/Postman)
- ❌ iOS app shows "Failed to decode response" or similar error
- ❌ JSON decoding exceptions in Swift code
- ❌ Empty/missing data in UI despite successful API calls

## Root Cause Analysis Framework

### Step 1: Verify API Response Structure

First, capture the actual API response:

```bash
curl -s "https://7cf3d2e510e2.ngrok-free.app/api/mobile/[endpoint]" | python3 -m json.tool
```

**Look for:**

- Response structure (success/data/error fields)
- Field naming conventions (camelCase vs snake_case)
- Data types (strings vs numbers vs booleans)
- Nested object structures
- Array contents and types

### Step 2: Examine Swift Models

**Critical checks:**

- Enum cases match API string values exactly
- Optional vs non-optional fields align with API
- CodingKeys map correctly to API field names
- Nested model structures match API response

**Common Mismatches:**

```swift
// ❌ API returns "cardiovascular", Swift expects "cardiology"
enum APITestCategory: String, Codable {
    case cardiology = "cardiology"  // Missing "cardiovascular" case
}

// ✅ Fixed - Add missing case
enum APITestCategory: String, Codable {
    case cardiology = "cardiology"
    case cardiovascular = "cardiovascular"  // Added missing case
}
```

### Step 3: Add Comprehensive JSON Debugging

Enhance your API service with detailed error logging:

```swift
do {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    #if DEBUG
    // Log raw JSON response for debugging
    if let jsonString = String(data: data, encoding: .utf8) {
        print("📄 Raw JSON Response:")
        print(jsonString)
    }
    #endif

    let decodedResponse = try decoder.decode(T.self, from: data)
    return decodedResponse
} catch {
    #if DEBUG
    print("🚨 JSON Decode Error: \(error)")
    if let decodingError = error as? DecodingError {
        print("🔍 Decoding Error Details:")
        switch decodingError {
        case .typeMismatch(let type, let context):
            print("  - Type mismatch for \(type) at \(context.codingPath)")
        case .valueNotFound(let type, let context):
            print("  - Value not found for \(type) at \(context.codingPath)")
        case .keyNotFound(let key, let context):
            print("  - Key '\(key.stringValue)' not found at \(context.codingPath)")
        case .dataCorrupted(let context):
            print("  - Data corrupted at \(context.codingPath): \(context.debugDescription)")
        @unknown default:
            print("  - Unknown decoding error: \(decodingError)")
        }
    }
    #endif
    throw APIError.decodingFailed("Failed to decode response: \(error.localizedDescription)")
}
```

## Systematic Fix Patterns

### Pattern 1: Missing Enum Cases

**Problem:** API returns enum values not defined in Swift

**Example Issue:**

```json
{
  "category": "cardiovascular" // API response
}
```

```swift
enum APITestCategory: String, Codable {
    case cardiology = "cardiology"  // ❌ No "cardiovascular" case
}
```

**Fix Steps:**

1. **Add Missing Enum Case:**

   ```swift
   enum APITestCategory: String, Codable {
       case cardiology = "cardiology"
       case cardiovascular = "cardiovascular"  // ✅ Add missing case
   }
   ```

2. **Update Display Names:**

   ```swift
   var displayName: String {
       switch self {
       case .cardiology: return "Cardiology"
       case .cardiovascular: return "Cardiovascular"  // ✅ Add display name
       }
   }
   ```

3. **Update Conversion Logic:**
   ```swift
   extension APITestCategory {
       var toUICategory: UICategory? {
           switch self {
           case .cardiology: return .cardiology
           case .cardiovascular: return .cardiology  // ✅ Map to existing UI category
           }
       }
   }
   ```

### Pattern 2: String vs Enum Mismatch

**Problem:** API uses strings, Swift expects enums

**Example Issue:**

```json
{
  "fasting": {
    "required": "twelve_hours" // API uses words
  }
}
```

```swift
enum FastingRequirement: String, Codable {
    case hours12 = "12_hours"  // ❌ Swift expects numbers
}
```

**Fix Options:**

**Option A: Make Swift Accept String (Recommended)**

```swift
struct FastingRequirementData: Codable {
    let required: String  // ✅ Accept any string

    var toFastingRequirement: FastingRequirement {
        switch self.required {
        case "none": return .none
        case "12_hours", "twelve_hours": return .hours12  // ✅ Handle both formats
        case "8_hours", "eight_hours": return .hours8
        default: return .none
        }
    }
}
```

**Option B: Normalize API Response**

```typescript
// Backend normalization function
private static normalizeFastingRequirement(fasting: string): string {
    switch (fasting) {
        case 'twelve_hours': return '12_hours';
        case 'eight_hours': return '8_hours';
        default: return fasting;
    }
}
```

### Pattern 3: Optional Field Mismatches

**Problem:** Swift models expect non-optional fields that API doesn't provide

**Example Issue:**

```swift
struct TestItemData: Codable {
    let shortName: String  // ❌ Non-optional but API might not provide
}
```

**Fix:**

```swift
struct TestItemData: Codable {
    let shortName: String?  // ✅ Make optional to match API reality
}
```

### Pattern 4: Response Structure Misalignment

**Problem:** Swift models expect different JSON structure than API provides

**Example Issue:**

```json
// API Response
{
  "success": true,
  "data": {
    "tests": [...],
    "pagination": {...}
  },
  "pagination": {
    "total_count": 5
  }
}
```

```swift
// Swift expectation
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
    let pagination: Pagination?  // Which pagination to use?
}
```

**Fix:** Choose consistent pagination source and document it:

```swift
extension APIService {
    private func extractPagination<T>(from response: APIResponse<T>) -> Pagination? {
        // Use root-level pagination as single source of truth
        return response.pagination
    }
}
```

## Debugging Workflow

### Phase 1: Capture & Compare

1. **Capture API Response:** Use curl or API client
2. **Capture Swift Model:** Review struct definitions
3. **Compare Structures:** Identify mismatches systematically

### Phase 2: Add Logging

1. **Enable Debug Logging:** Add comprehensive JSON decode error logging
2. **Test API Call:** Trigger the failing decode
3. **Analyze Error Details:** Focus on specific field/path causing issues

### Phase 3: Fix & Validate

1. **Apply Appropriate Pattern:** Use one of the fix patterns above
2. **Test Compilation:** Ensure no Swift compile errors
3. **Test Runtime:** Verify JSON decoding succeeds
4. **Test UI:** Confirm data displays correctly

## Backend API Best Practices

### Consistent Response Format

```typescript
interface StandardAPIResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  timestamp: string;
  error?: APIError;
  pagination?: Pagination;
}
```

### String Enum Normalization

```typescript
// Good: Normalize string enums at API layer
function normalizeEnumValues(input: string): string {
  return input.toLowerCase().replace(/\s+/g, '_');
}
```

### Field Naming Convention

```typescript
// Good: Consistent snake_case for API, camelCase internally
interface APITestResponse {
  short_name: string; // API field
  display_text: string; // API field
  is_featured: boolean; // API field
}
```

## iOS Swift Best Practices

### Robust Enum Handling

```swift
enum APICategory: String, Codable {
    case bloodTest = "blood_test"
    case cardiovascular = "cardiovascular"
    case cardiology = "cardiology"
    // Add unknown case for future API changes
    case unknown = "unknown"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = APICategory(rawValue: rawValue) ?? .unknown
    }
}
```

### Flexible String Fields

```swift
// Prefer strings over enums for volatile API fields
struct APIData: Codable {
    let category: String        // Flexible
    let status: APIStatus      // Use enum only for stable fields
}
```

### Comprehensive Error Context

```swift
struct APIError: Error, LocalizedError {
    let code: String
    let message: String
    let field: String?
    let rawJSON: String?

    var errorDescription: String? {
        return "API Error [\(code)]: \(message)"
    }
}
```

## Testing Strategy

### Unit Test JSON Decoding

```swift
func testJSONDecoding() {
    let jsonData = """
    {
        "category": "cardiovascular",
        "fasting": {
            "required": "twelve_hours"
        }
    }
    """.data(using: .utf8)!

    XCTAssertNoThrow {
        let result = try JSONDecoder().decode(TestData.self, from: jsonData)
        XCTAssertEqual(result.category, .cardiovascular)
        XCTAssertEqual(result.fasting.toFastingRequirement, .hours12)
    }
}
```

### Integration Test with Mock API

```swift
func testAPIIntegration() async throws {
    let mockResponse = createMockAPIResponse()
    let result = try await apiService.fetchData()
    XCTAssertNotNil(result)
    XCTAssertFalse(result.isEmpty)
}
```

## Quick Reference Checklist

### When You See "Failed to decode response":

- [ ] **Capture actual API JSON response**
- [ ] **Add JSON decode error logging to Swift**
- [ ] **Compare API fields to Swift model fields**
- [ ] **Check enum case matches (exact strings)**
- [ ] **Verify optional vs non-optional fields**
- [ ] **Look for snake_case vs camelCase mismatches**
- [ ] **Test with actual API data, not mock data**
- [ ] **Check nested object structures**
- [ ] **Validate array element types**
- [ ] **Ensure CodingKeys are correct**

### Fix Priority Order:

1. **Missing enum cases** (most common)
2. **Optional field mismatches**
3. **String format differences**
4. **Response structure alignment**
5. **Data type mismatches**

## Success Metrics

After applying fixes, you should see:

- ✅ No more "Failed to decode response" errors
- ✅ Swift code compiles without warnings
- ✅ API data displays correctly in UI
- ✅ Comprehensive error logging for future issues
- ✅ Graceful handling of API changes

## Reusable Code Templates

### Enhanced API Service Template

```swift
class GenericAPIService {
    func makeRequest<T: Codable>(url: URL, responseType: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw APIError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            #if DEBUG
            logRawJSON(data)
            #endif

            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            logDecodingError(error, data: data)
            #endif
            throw APIError.decodingFailed(error)
        }
    }

    #if DEBUG
    private func logRawJSON(_ data: Data) {
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Raw JSON: \(jsonString)")
        }
    }

    private func logDecodingError(_ error: Error, data: Data) {
        print("🚨 Decode Error: \(error)")
        if let decodingError = error as? DecodingError {
            // ... detailed error logging
        }
    }
    #endif
}
```

This guide should help diagnose and fix any similar JSON decoding issues in the future. The key is systematic comparison between API reality and Swift expectations, combined with comprehensive error logging.
