# Upcoming Appointments Flow - Mobile App Design

## Header Section

```
┌─────────────────────────────────────────────┐
│ ← Appointments                            + │
└─────────────────────────────────────────────┘
```

## Navigation Tabs

```
┌─────────────────────────────────────────────┐
│  📅          🔬        🔍
│ Schedules   Tests   Labs                    │
│ ────────                                    │
└─────────────────────────────────────────────┘
```

## Today's Schedule Banner

```
┌─────────────────────────────────────────────┐
│ 📅 Today, Friday Aug 22                     │
│ Next: CBC Test in 2 hours                   │
│ [View Details] [Get Directions]             │
└─────────────────────────────────────────────┘
```

## Schedules Appointments List

### Today's Appointments

```
┌─────────────────────────────────────────────┐
│ Today                                       │
├─────────────────────────────────────────────┤
│ 🩸 Complete Blood Count (CBC)               │
│ 2:30 PM - 2:45 PM                          │
│ LabLoop Central Laboratory                  │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ 🚨 Reminder: Fast for 12 hours          │ │
│ │ 📍 2.3 km away • 15 min drive          │ │
│ │ 💰 ₹500 • Pre-paid                     │ │
│ │                                         │ │
│ │ Preparation:                            │ │
│ │ ✅ Fasting completed                    │ │
│ │ ✅ ID documents ready                   │ │
│ │ ⏰ Leave by 2:00 PM                     │ │
│ │                                         │ │
│ │ [Get Directions] [Reschedule] [Cancel]  │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Tomorrow's Appointments

```
┌─────────────────────────────────────────────┐
│ Tomorrow, Aug 23                            │
├─────────────────────────────────────────────┤
│ 🫀 Lipid Profile                           │
│ 9:00 AM - 9:15 AM                          │
│ zero hopital • Bengaluru                   │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ 📋 Test Details:                        │ │
│ │ • Total Cholesterol                     │ │
│ │ • HDL, LDL, Triglycerides              │ │
│ │ • No fasting required                   │ │
│ │                                         │ │
│ │ 📍 1.8 km away • Walk-ins OK           │ │
│ │ 💰 ₹800 • Pay at lab                   │ │
│ │                                         │ │
│ │ [View Details] [Reschedule] [Cancel]    │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### This Week

```
┌─────────────────────────────────────────────┐
│ This Week                                   │
├─────────────────────────────────────────────┤
│ 🦴 Vitamin D Test                          │
│ Monday, Aug 26 at 11:00 AM                 │
│ Downtown Collection Center                  │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ 🏠 Home Collection Scheduled            │ │
│ │ 📍 123 Main St, Apartment 4B           │ │
│ │ 📞 Contact: +91 98765 43210            │ │
│ │ 💰 ₹1200 (includes collection fee)     │ │
│ │                                         │ │
│ │ [Modify Address] [Reschedule] [Cancel]  │ │
│ └─────────────────────────────────────────┘ │
│                                             │
├─────────────────────────────────────────────┤
│ 🔬 Thyroid Function Test                   │
│ Wednesday, Aug 28 at 3:00 PM               │
│ LabLoop Central Laboratory                  │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ Regular check-up appointment            │ │
│ │ Tests: TSH, T3, T4                      │ │
│ │ Duration: 10 minutes                    │ │
│ │ 💰 ₹900 • Insurance covered            │ │
│ │                                         │ │
│ │ [View Details] [Reschedule] [Cancel]    │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## Quick Actions Bar

```
┌─────────────────────────────────────────────┐
│ [📋 Book New Test] [📅 View Calendar]        │
└─────────────────────────────────────────────┘
```

## Preparation Checklist (Expandable)

```
┌─────────────────────────────────────────────┐
│ ▼ Today's Preparation Checklist             │
├─────────────────────────────────────────────┤
│ For: CBC Test at 2:30 PM                    │
│                                             │
│ ✅ Fast for 12 hours (since 2:30 AM)       │
│ ✅ Drink plenty of water                    │
│ ⏰ Take prescribed medications               │
│ 📄 Bring ID and insurance card              │
│ 🚗 Leave home by 2:00 PM                   │
│                                             │
│ [Set Reminder] [Mark Complete]              │
└─────────────────────────────────────────────┘
```

## Appointment History Preview

```
┌─────────────────────────────────────────────┐
│ Recent Completed                            │
├─────────────────────────────────────────────┤
│ 📊 Diabetes Panel - Aug 15                 │
│ ✅ Results available • Normal ranges        │
│ [View Report]                               │
│                                             │
│ 🩸 Basic Blood Panel - Aug 1               │
│ ✅ Results available • Action needed        │
│ [View Report] [Book Follow-up]              │
│                                             │
│ [View All History]                          │
└─────────────────────────────────────────────┘
```

## Empty State (No Upcoming Appointments)

```
┌─────────────────────────────────────────────┐
│              📅                             │
│       No Upcoming Appointments              │
│                                             │
│    Schedule your next health check-up       │
│                                             │
│        [Browse Tests]                       │
│        [Find Labs]                          │
│                                             │
│    Recommended based on history:            │
│    • Quarterly Blood Panel                  │
│    • Annual Health Checkup                 │
│    • Follow-up Vitamin D Test              │
└─────────────────────────────────────────────┘
```

## Contextual Actions

### Appointment Card Actions

- **View Details**: Full appointment info and lab details
- **Reschedule**: Calendar picker with available slots
- **Cancel**: Cancellation policy and confirmation
- **Get Directions**: Maps integration with real-time traffic
- **Contact Lab**: Direct phone/chat with facility

### Smart Notifications

- **Preparation Reminders**: Fasting, medication instructions
- **Travel Alerts**: Traffic-based departure reminders
- **Document Checks**: ID, insurance, prescription reminders
- **Follow-up Prompts**: Book next appointment suggestions

### Calendar Integration

- **Sync with Device Calendar**: Auto-add appointments
- **Conflict Detection**: Warn about scheduling conflicts
- **Travel Time**: Calculate and include travel duration
- **Weather Alerts**: Notify about weather affecting travel
