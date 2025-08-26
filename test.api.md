API Response Structure Needed:

Your API should return an array of appointment objects with this structure:

{
"appointments": [
{
"id": "appt_001",
"facilityName": "LabLoop Central Laboratory",
"location": "Koregaon Park, Pune",
"date": "2025-01-29T14:00:00Z",
"status": "confirmed",
"serviceType": "bloodTest",
"cost": 1200,
"paymentStatus": "Paid",
"distanceText": "2.5 km",
"travelTime": "8 min drive",
"preparationReminder": "Fast for 12 hours before test",
"preparationSteps": [
{
"description": "No food or drinks (except water)",
"isCompleted": true
},
{
"description": "Take required medications",
"isCompleted": false
}
]
},
{
"id": "appt_002",
"facilityName": "Super Health Diagnostics",
"location": "Baner, Pune",
"date": "2025-01-30T10:30:00Z",
"status": "confirmed",
"serviceType": "healthPackage",
"cost": 2500,
"paymentStatus": "Pending",
"distanceText": "4.2 km",
"travelTime": "12 min drive"
},
{
"id": "appt_003",
"facilityName": "MedCheck Laboratory",
"location": "Viman Nagar, Pune",
"date": "2025-01-25T09:00:00Z",
"status": "completed",
"serviceType": "bloodTest",
"cost": 800,
"paymentStatus": "Paid",
"resultStatus": "Results available",
"needsFollowUp": true
}
]
}

Required Fields for Each Appointment:

Core Information:

- id: Unique appointment identifier
- facilityName: Lab/facility name
- location: Address or area name
- date: ISO 8601 timestamp
- status: "confirmed" | "pending" | "completed" | "cancelled"
- serviceType: "bloodTest" | "healthPackage" | "xray" | "consultation"

Financial Information:

- cost: Number (price in rupees)
- paymentStatus: "Paid" | "Pending" | "Failed"

Location & Logistics:

- distanceText: String like "2.5 km"
- travelTime: String like "8 min drive"

For Today's Appointments (Optional):

- preparationReminder: String with key preparation info
- preparationSteps: Array of objects with:
  - description: String
  - isCompleted: Boolean

For Completed Appointments (Optional):

- resultStatus: String like "Results available"
- needsFollowUp: Boolean

Service Type Values:

Your API should use these serviceType values which map to icons:

- "bloodTest" → Shows drop icon
- "healthPackage" → Shows heart icon
- "xray" → Shows xray icon
- "consultation" → Shows person icon
- "labTest" → Shows testtube icon

Status Values:

- "confirmed" → Green badge
- "pending" → Yellow badge
- "completed" → Blue badge
- "cancelled" → Red badge

API Endpoint:

Update your API service at /api/v1/appointments/user/{userId} to return this structure, and the UI will
automatically categorize appointments into "Today", "Tomorrow", "This Week", "Later", and "Recent Completed"
sections based on the dates.
