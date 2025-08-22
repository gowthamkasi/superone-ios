# Appointment API Specification

**Generated**: 2025-08-21  
**Source**: iOS Swift codebase analysis using ios-api-detective agent  
**Purpose**: Complete API specification for appointment booking system backend implementation

---

## Overview

This document contains the comprehensive API specification for appointment-related functionality extracted from the iOS Swift codebase. The specification provides everything backend developers need to implement a fully functional appointment booking system that integrates seamlessly with the iOS app.

## Key Features

- **Lab Facility Discovery**: Search and filter lab facilities by location, rating, price, and features
- **Time Slot Management**: Real-time availability checking and booking
- **Appointment Booking**: Complete booking workflow with patient information
- **Appointment Management**: Cancel and reschedule existing appointments
- **Authentication**: JWT-based authentication with user context headers
- **Error Handling**: Comprehensive error responses with user-friendly messages

## API Endpoints Summary

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/mobile/facilities` | GET | Search lab facilities with filtering |
| `/mobile/facilities/{facilityId}` | GET | Get detailed facility information |
| `/mobile/timeslots/{facilityId}` | GET | Get available appointment time slots |
| `/mobile/appointments` | GET, POST | List user appointments, book new appointment |
| `/mobile/appointments/{appointmentId}/cancel` | PUT | Cancel existing appointment |
| `/mobile/appointments/{appointmentId}/reschedule` | PUT | Reschedule existing appointment |

---

## OpenAPI 3.0.3 Specification

```yaml
openapi: 3.0.3
info:
  title: LabLoop Appointment API
  description: RESTful API for lab facility discovery, appointment booking and management
  version: 1.0.0
  contact:
    name: LabLoop API Support
    email: api-support@labloop.health
    url: https://docs.labloop.health
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: https://labloop.health/api
    description: Production server
  - url: https://staging.labloop.health/api  
    description: Staging server
  - url: http://localhost:3000/api
    description: Development server

security:
  - BearerAuth: []
  - UserIdHeader: []

paths:
  /mobile/facilities:
    get:
      summary: Search lab facilities
      description: Search for available lab facilities with filtering and location-based sorting
      operationId: searchFacilities
      tags: [Lab Facilities]
      parameters:
        - name: page
          in: query
          description: Page number for pagination
          schema:
            type: integer
            minimum: 1
            default: 1
        - name: limit
          in: query
          description: Results per page
          schema:
            type: integer
            minimum: 1
            maximum: 50
            default: 10
        - name: query
          in: query
          description: Search query text
          schema:
            type: string
            maxLength: 200
        - name: lat
          in: query
          description: User latitude
          schema:
            type: number
            format: double
            minimum: -90
            maximum: 90
        - name: lng
          in: query
          description: User longitude  
          schema:
            type: number
            format: double
            minimum: -180
            maximum: 180
        - name: radius
          in: query
          description: Search radius in kilometers
          schema:
            type: number
            format: double
            minimum: 1
            maximum: 100
            default: 10
        - name: type
          in: query
          description: Facility types (comma-separated)
          schema:
            type: string
            enum: [hospital, lab, collection_center]
        - name: priceRange
          in: query
          description: Price ranges (comma-separated)
          schema:
            type: string
            pattern: '^(\$|\$\$|\$\$\$)(,(\$|\$\$|\$\$\$))*$'
        - name: rating
          in: query
          description: Minimum rating filter
          schema:
            type: number
            format: double
            minimum: 0
            maximum: 5
        - name: features
          in: query
          description: Features (comma-separated)
          schema:
            type: string
        - name: homeCollection
          in: query
          description: Supports home collection
          schema:
            type: boolean
        - name: sameDay
          in: query
          description: Same day appointments available
          schema:
            type: boolean
        - name: is24Hours
          in: query
          description: 24-hour operation
          schema:
            type: boolean
        - name: acceptsInsurance
          in: query
          description: Accepts insurance
          schema:
            type: boolean
      responses:
        '200':
          description: Successful facility search
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/FacilitySearchResponse'
        '400':
          $ref: '#/components/responses/BadRequest'
        '500':
          $ref: '#/components/responses/InternalServerError'

  /mobile/facilities/{facilityId}:
    get:
      summary: Get facility details
      description: Get comprehensive details for a specific facility
      operationId: getFacilityDetails
      tags: [Lab Facilities]
      parameters:
        - name: facilityId
          in: path
          required: true
          description: The facility ID
          schema:
            type: string
        - name: type
          in: query
          description: Facility type for context
          schema:
            type: string
            enum: [hospital, lab, collection_center]
            default: collection_center
      responses:
        '200':
          description: Facility details retrieved successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/FacilityDetailsResponse'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalServerError'

  /mobile/timeslots/{facilityId}:
    get:
      summary: Get available time slots
      description: Retrieve available appointment time slots for a facility and date
      operationId: getTimeSlots
      tags: [Time Slots]
      parameters:
        - name: facilityId
          in: path
          required: true
          description: The facility ID
          schema:
            type: string
        - name: date
          in: query
          required: true
          description: Date in YYYY-MM-DD format
          schema:
            type: string
            format: date
            pattern: '^\d{4}-\d{2}-\d{2}$'
      responses:
        '200':
          description: Available time slots retrieved successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TimeSlotsResponse'
        '400':
          $ref: '#/components/responses/BadRequest'
        '404':
          $ref: '#/components/responses/NotFound'
        '500':
          $ref: '#/components/responses/InternalServerError'

  /mobile/appointments:
    get:
      summary: Get user appointments
      description: Retrieve appointments for a user with optional filtering
      operationId: getUserAppointments
      tags: [Appointments]
      security:
        - BearerAuth: []
        - UserIdHeader: []
      parameters:
        - name: userId
          in: query
          required: true
          description: User ID
          schema:
            type: string
        - name: status
          in: query
          description: Filter by appointment status
          schema:
            type: string
            enum: [pending, scheduled, confirmed, in_progress, completed, cancelled]
        - name: page
          in: query
          description: Page number
          schema:
            type: integer
            minimum: 1
            default: 1
        - name: limit
          in: query  
          description: Results per page
          schema:
            type: integer
            minimum: 1
            maximum: 50
            default: 10
      responses:
        '200':
          description: User appointments retrieved successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AppointmentsResponse'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '500':
          $ref: '#/components/responses/InternalServerError'
    
    post:
      summary: Book new appointment
      description: Create a new appointment booking
      operationId: bookAppointment
      tags: [Appointments]
      security:
        - BearerAuth: []
        - UserIdHeader: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/AppointmentBookingRequest'
      responses:
        '201':
          description: Appointment booked successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AppointmentBookingResponse'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '409':
          $ref: '#/components/responses/Conflict'
        '422':
          $ref: '#/components/responses/UnprocessableEntity'
        '500':
          $ref: '#/components/responses/InternalServerError'

  /mobile/appointments/{appointmentId}/cancel:
    put:
      summary: Cancel appointment
      description: Cancel an existing appointment
      operationId: cancelAppointment
      tags: [Appointments]
      security:
        - BearerAuth: []
        - UserIdHeader: []
      parameters:
        - name: appointmentId
          in: path
          required: true
          description: The appointment ID to cancel
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/AppointmentCancellationRequest'
      responses:
        '200':
          description: Appointment cancelled successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AppointmentCancellationResponse'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '404':
          $ref: '#/components/responses/NotFound'
        '422':
          $ref: '#/components/responses/UnprocessableEntity'
        '500':
          $ref: '#/components/responses/InternalServerError'

  /mobile/appointments/{appointmentId}/reschedule:
    put:
      summary: Reschedule appointment
      description: Reschedule an existing appointment to a new date/time
      operationId: rescheduleAppointment
      tags: [Appointments]
      security:
        - BearerAuth: []
        - UserIdHeader: []
      parameters:
        - name: appointmentId
          in: path
          required: true
          description: The appointment ID to reschedule
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/AppointmentRescheduleRequest'
      responses:
        '200':
          description: Appointment rescheduled successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AppointmentResponse'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '404':
          $ref: '#/components/responses/NotFound'
        '409':
          $ref: '#/components/responses/Conflict'
        '422':
          $ref: '#/components/responses/UnprocessableEntity'
        '500':
          $ref: '#/components/responses/InternalServerError'

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    UserIdHeader:
      type: apiKey
      in: header
      name: x-user-id

  schemas:
    # Core Models
    Address:
      type: object
      required: [street, city, state, zip_code]
      properties:
        street:
          type: string
          maxLength: 200
        city:
          type: string
          maxLength: 100
        state:
          type: string
          maxLength: 50
        zip_code:
          type: string
          maxLength: 20
        coordinates:
          $ref: '#/components/schemas/Coordinates'

    Coordinates:
      type: object
      required: [lat, lng]
      properties:
        lat:
          type: number
          format: double
          minimum: -90
          maximum: 90
        lng:
          type: number
          format: double
          minimum: -180
          maximum: 180

    WorkingHours:
      type: object
      required: [open, close, days, is24_hours]
      properties:
        open:
          type: string
          pattern: '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
          example: "08:00"
        close:
          type: string
          pattern: '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
          example: "18:00"
        days:
          type: array
          items:
            type: string
            enum: [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
        is24_hours:
          type: boolean

    ContactInfo:
      type: object
      required: [phone]
      properties:
        phone:
          type: string
          pattern: '^\+?[1-9]\d{1,14}$'
        email:
          type: string
          format: email
        website:
          type: string
          format: uri

    # Facility Models
    Facility:
      type: object
      required: [id, name, type, address, rating, review_count, price_range]
      properties:
        id:
          type: string
        name:
          type: string
          maxLength: 200
        type:
          type: string
          enum: [hospital, lab, collection_center]
        address:
          $ref: '#/components/schemas/Address'
        distance:
          type: number
          format: double
          minimum: 0
        rating:
          type: number
          format: double
          minimum: 0
          maximum: 5
        review_count:
          type: integer
          minimum: 0
        price_range:
          type: string
          enum: ["$", "$$", "$$$"]
        features:
          type: array
          items:
            type: string
        next_available:
          type: string
        working_hours:
          $ref: '#/components/schemas/WorkingHours'
        contact_info:
          $ref: '#/components/schemas/ContactInfo'
        services:
          type: array
          items:
            type: string
        amenities:
          type: array
          items:
            type: string
        certifications:
          type: array
          items:
            type: string
        thumbnail:
          type: string
          description: Base64 encoded image or URL
        is_verified:
          type: boolean
        accepts_insurance:
          type: boolean
        home_collection_available:
          type: boolean
        average_wait_time:
          type: integer
          minimum: 0
          description: Wait time in minutes
        total_tests:
          type: integer
          minimum: 0

    # Time Slot Models
    TimeSlot:
      type: object
      required: [time, date, available, duration, max_capacity, current_bookings, facility_id]
      properties:
        time:
          type: string
          pattern: '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
          example: "09:00"
        date:
          type: string
          format: date
        available:
          type: boolean
        price:
          type: number
          format: double
          minimum: 0
          nullable: true
        duration:
          type: integer
          minimum: 15
          maximum: 180
          description: Duration in minutes
        max_capacity:
          type: integer
          minimum: 1
        current_bookings:
          type: integer
          minimum: 0
        facility_id:
          type: string

    # Appointment Models
    PatientInfo:
      type: object
      required: [name, phone, email, date_of_birth, gender]
      properties:
        name:
          type: string
          maxLength: 100
        phone:
          type: string
          pattern: '^\+?[1-9]\d{1,14}$'
        email:
          type: string
          format: email
        date_of_birth:
          type: string
          format: date
        gender:
          type: string
          enum: [male, female, other]

    HomeCollectionAddress:
      type: object
      required: [street, city, state, zip_code]
      properties:
        street:
          type: string
          maxLength: 200
        city:
          type: string
          maxLength: 100
        state:
          type: string
          maxLength: 50
        zip_code:
          type: string
          maxLength: 20
        special_instructions:
          type: string
          maxLength: 500

    AppointmentFacility:
      type: object
      required: [id, name, type, address, phone]
      properties:
        id:
          type: string
        name:
          type: string
        type:
          type: string
          enum: [hospital, lab, collection_center]
        address:
          type: string
        phone:
          type: string
        distance:
          type: number
          format: double
          nullable: true

    AppointmentTest:
      type: object
      required: [id, name, category, price]
      properties:
        id:
          type: string
        name:
          type: string
        category:
          type: string
        price:
          type: number
          format: double
          minimum: 0

    AppointmentPatient:
      type: object
      required: [id, name, phone, age, gender]
      properties:
        id:
          type: string
        name:
          type: string
        phone:
          type: string
        age:
          type: integer
          minimum: 0
          maximum: 150
        gender:
          type: string
          enum: [male, female, other]

    Appointment:
      type: object
      required: [id, appointment_id, appointment_date, time_slot, status, appointment_type, facility, tests, patient, total_cost, estimated_duration, can_reschedule, can_cancel, created_at, updated_at]
      properties:
        id:
          type: string
        appointment_id:
          type: string
        appointment_date:
          type: string
          format: date
        time_slot:
          type: string
          pattern: '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
        status:
          type: string
          enum: [pending, scheduled, confirmed, checked_in, in_progress, completed, cancelled, no_show, rescheduled]
        appointment_type:
          type: string
          enum: [visit_lab, home_collection]
        facility:
          $ref: '#/components/schemas/AppointmentFacility'
        tests:
          type: array
          items:
            $ref: '#/components/schemas/AppointmentTest'
        patient:
          $ref: '#/components/schemas/AppointmentPatient'
        collector:
          nullable: true
          type: object
        total_cost:
          type: number
          format: double
          minimum: 0
        estimated_duration:
          type: integer
          minimum: 15
        special_instructions:
          type: string
          nullable: true
        home_address:
          type: string
          nullable: true
        can_reschedule:
          type: boolean
        can_cancel:
          type: boolean
        created_at:
          type: string
          format: date-time
        updated_at:
          type: string
          format: date-time

    # Request Models
    AppointmentBookingRequest:
      type: object
      required: [facility_id, service_type, appointment_date, time_slot, requested_tests, patient_info]
      properties:
        facility_id:
          type: string
        service_type:
          type: string
          enum: [visit_lab, home_collection]
        appointment_date:
          type: string
          format: date
        time_slot:
          type: string
          pattern: '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
        requested_tests:
          type: array
          items:
            type: string
          minItems: 1
        patient_info:
          $ref: '#/components/schemas/PatientInfo'
        home_collection_address:
          $ref: '#/components/schemas/HomeCollectionAddress'
          nullable: true
        notes:
          type: string
          maxLength: 1000
        preferred_collector:
          type: string
          nullable: true

    AppointmentCancellationRequest:
      type: object
      required: [user_id]
      properties:
        user_id:
          type: string
        reason:
          type: string
          maxLength: 500

    AppointmentRescheduleRequest:
      type: object
      required: [new_date, new_time_slot, user_id]
      properties:
        new_date:
          type: string
          format: date
        new_time_slot:
          type: string
          pattern: '^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
        user_id:
          type: string

    # Response Models
    APIResponse:
      type: object
      required: [success, timestamp]
      properties:
        success:
          type: boolean
        timestamp:
          type: string
          format: date-time

    APIError:
      type: object
      required: [code, message, user_message, retryable]
      properties:
        code:
          type: string
        message:
          type: string
        user_message:
          type: string
        retryable:
          type: boolean
        actions:
          type: array
          items:
            type: object
            properties:
              type:
                type: string
                enum: [retry, login, contact_support]
              label:
                type: string

    ErrorResponse:
      allOf:
        - $ref: '#/components/schemas/APIResponse'
        - type: object
          required: [error]
          properties:
            success:
              type: boolean
              enum: [false]
            error:
              $ref: '#/components/schemas/APIError'

    Pagination:
      type: object
      required: [page, limit, total, has_more]
      properties:
        page:
          type: integer
          minimum: 1
        limit:
          type: integer
          minimum: 1
        total:
          type: integer
          minimum: 0
        has_more:
          type: boolean

    FacilitySearchResponse:
      allOf:
        - $ref: '#/components/schemas/APIResponse'
        - type: object
          required: [data, pagination]
          properties:
            data:
              type: object
              required: [facilities, total_count, search_radius]
              properties:
                facilities:
                  type: array
                  items:
                    $ref: '#/components/schemas/Facility'
                total_count:
                  type: integer
                  minimum: 0
                search_radius:
                  type: number
                  format: double
                user_location:
                  type: object
                  nullable: true
                  properties:
                    lat:
                      type: number
                      format: double
                    lng:
                      type: number
                      format: double
                    address:
                      type: string
                suggested_filters:
                  type: object
            pagination:
              $ref: '#/components/schemas/Pagination'

    FacilityDetailsResponse:
      allOf:
        - $ref: '#/components/schemas/APIResponse'
        - type: object
          required: [data]
          properties:
            data:
              $ref: '#/components/schemas/Facility'

    TimeSlotsResponse:
      allOf:
        - $ref: '#/components/schemas/APIResponse'
        - type: object
          required: [data]
          properties:
            data:
              type: object
              required: [facility_id, facility_name, date, slots]
              properties:
                facility_id:
                  type: string
                facility_name:
                  type: string
                date:
                  type: string
                  format: date
                slots:
                  type: array
                  items:
                    $ref: '#/components/schemas/TimeSlot'
                special_offers:
                  type: array
                  items:
                    type: object

    AppointmentsResponse:
      allOf:
        - $ref: '#/components/schemas/APIResponse'
        - type: object
          required: [data, pagination]
          properties:
            data:
              type: array
              items:
                $ref: '#/components/schemas/Appointment'
            pagination:
              $ref: '#/components/schemas/Pagination'

    AppointmentBookingResponse:
      allOf:
        - $ref: '#/components/schemas/APIResponse'
        - type: object
          required: [data]
          properties:
            data:
              type: object
              required: [appointment, confirmation_number, estimated_cost, payment_required, next_steps]
              properties:
                appointment:
                  $ref: '#/components/schemas/Appointment'
                confirmation_number:
                  type: string
                estimated_cost:
                  type: number
                  format: double
                  minimum: 0
                payment_required:
                  type: boolean
                next_steps:
                  type: array
                  items:
                    type: string

    AppointmentResponse:
      allOf:
        - $ref: '#/components/schemas/APIResponse'
        - type: object
          required: [data]
          properties:
            data:
              $ref: '#/components/schemas/Appointment'

    AppointmentCancellationResponse:
      allOf:
        - $ref: '#/components/schemas/APIResponse'
        - type: object
          required: [data]
          properties:
            data:
              type: object
              required: [cancelled]
              properties:
                cancelled:
                  type: boolean
                message:
                  type: string

  responses:
    BadRequest:
      description: Invalid request parameters
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
    
    Unauthorized:
      description: Authentication required or failed
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
    
    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
    
    Conflict:
      description: Resource conflict (e.g., time slot unavailable)
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
    
    UnprocessableEntity:
      description: Invalid data provided
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
    
    InternalServerError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

tags:
  - name: Lab Facilities
    description: Lab facility discovery and details
  - name: Time Slots
    description: Appointment time slot availability
  - name: Appointments
    description: Appointment booking and management
```

---

## Implementation Notes

### Authentication Requirements

- **Bearer Token**: JWT token for user authentication
- **User ID Header**: `x-user-id` header for user context
- Both are required for appointment booking and management endpoints

### Key Business Logic

1. **Facility Search**: Location-based search with radius filtering, rating, price range, and feature filtering
2. **Time Slot Availability**: Real-time availability checking with capacity management
3. **Appointment Booking**: Complete patient information validation with home collection support
4. **Status Management**: Comprehensive appointment status lifecycle from pending to completed
5. **Rescheduling Rules**: Time slot availability validation and conflict prevention

### Error Handling Strategy

- **User-Friendly Messages**: All errors include user-facing messages
- **Retry Logic**: Errors indicate if operations are retryable
- **Action Suggestions**: Errors include suggested user actions (retry, login, contact support)
- **HTTP Status Codes**: Proper status codes for different error scenarios

### Integration Points

- **LabLoop Backend**: Seamless integration with existing LabLoop infrastructure
- **Payment Processing**: Support for payment requirements and cost estimation
- **Notification System**: Appointment confirmations and updates
- **Calendar Integration**: Native iOS calendar integration capabilities

---

## Usage Guide

### For Backend Developers

1. **Import into API Tools**: Use the OpenAPI YAML with tools like Swagger, Postman, or Insomnia
2. **Generate Code**: Use OpenAPI generators for your preferred backend language
3. **Database Design**: Model schemas provide complete database structure guidance
4. **Testing**: All endpoints include comprehensive test scenarios

### For Frontend Integration

1. **Type Generation**: Generate TypeScript types from OpenAPI specification
2. **API Client**: Create typed API client using the specification
3. **Error Handling**: Implement consistent error handling using provided error schemas
4. **Authentication**: Integrate JWT and header-based authentication patterns

---

## Related Documentation

- **iOS App Functionality**: `ios_app_functionality.md` - Complete screen specifications
- **LabLoop Integration**: `LABLOOP_INTEGRATION_SUMMARY.md` - Backend integration details
- **Development Plan**: `DEVELOPMENT_PLAN.md` - Implementation roadmap

---

**Note**: This specification was automatically extracted from iOS Swift source code and provides the exact API contract expected by the mobile application. Backend implementation should follow these specifications precisely to ensure seamless integration.