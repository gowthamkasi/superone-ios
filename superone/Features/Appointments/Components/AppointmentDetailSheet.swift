//
//  AppointmentDetailSheet.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Sheet showing detailed appointment information
struct AppointmentDetailSheet: View {
    let appointment: Appointment
    @Environment(\.dismiss) private var dismiss
    @State private var showDirections = false
    @State private var showCancelAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: HealthSpacing.xl) {
                    // Appointment header
                    appointmentHeader
                    
                    // Facility information
                    facilitySection
                    
                    // Appointment details
                    appointmentDetailsSection
                    
                    // Actions section
                    if appointment.status == .confirmed || appointment.status == .pending {
                        actionsSection
                    }
                    
                    // Notes section
                    if let notes = appointment.notes, !notes.isEmpty {
                        notesSection
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .padding(.bottom, HealthSpacing.xl)
            }
            .background(HealthColors.background.ignoresSafeArea())
            .navigationTitle("Appointment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Cancel Appointment", isPresented: $showCancelAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm", role: .destructive) {
                    // Appointment cancellation will be implemented
                }
            } message: {
                Text("Are you sure you want to cancel this appointment? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Appointment Header
    
    private var appointmentHeader: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Status badge
            AppointmentStatusBadge(status: appointment.status)
            
            // Main appointment info
            VStack(spacing: HealthSpacing.md) {
                Text(appointment.facilityName)
                    .font(HealthTypography.headingMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: HealthSpacing.sm) {
                    HStack(spacing: HealthSpacing.md) {
                        Image(systemName: "calendar")
                            .foregroundColor(HealthColors.primary)
                        
                        Text(appointment.displayDate)
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(HealthColors.primaryText)
                    }
                    
                    HStack(spacing: HealthSpacing.md) {
                        Image(systemName: "clock")
                            .foregroundColor(HealthColors.primary)
                        
                        Text(appointment.displayTime)
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(HealthColors.primaryText)
                    }
                }
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
    
    // MARK: - Facility Section
    
    private var facilitySection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Facility Information")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                DetailRow(
                    icon: "building.2",
                    title: "Name",
                    value: appointment.facilityName
                )
                
                DetailRow(
                    icon: "location",
                    title: "Address",
                    value: appointment.location
                )
                
                // Get directions button
                Button(action: { showDirections = true }) {
                    HStack {
                        Image(systemName: "location.circle")
                        Text("Get Directions")
                    }
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HealthSpacing.sm)
                    .background(HealthColors.primary.opacity(0.1))
                    .cornerRadius(HealthCornerRadius.button)
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
        }
        .healthCardShadow()
    }
    
    // MARK: - Appointment Details
    
    private var appointmentDetailsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Appointment Details")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                DetailRow(
                    icon: appointment.serviceType.icon,
                    title: "Service Type",
                    value: appointment.serviceType.displayName
                )
                
                DetailRow(
                    icon: "number",
                    title: "Appointment ID",
                    value: String(appointment.id.prefix(8))
                )
                
                DetailRow(
                    icon: "calendar.badge.plus",
                    title: "Booking Date", 
                    value: formatBookingDate()
                )
                
                if appointment.status == .completed {
                    DetailRow(
                        icon: "checkmark.circle",
                        title: "Completed",
                        value: formatCompletionDate()
                    )
                }
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
        }
        .healthCardShadow()
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Actions")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                // Add to calendar
                ActionButton(
                    icon: "calendar.badge.plus",
                    title: "Add to Calendar",
                    action: {
                        // Calendar integration will be implemented
                    }
                )
                
                // Share appointment
                ActionButton(
                    icon: "square.and.arrow.up",
                    title: "Share Appointment",
                    action: {
                        // Appointment sharing will be implemented
                    }
                )
                
                // Reschedule (only for confirmed appointments)
                if appointment.status == .confirmed {
                    ActionButton(
                        icon: "calendar.circle",
                        title: "Reschedule",
                        action: {
                            // Appointment rescheduling will be implemented
                        }
                    )
                }
                
                // Cancel appointment
                ActionButton(
                    icon: "xmark.circle",
                    title: "Cancel Appointment",
                    titleColor: HealthColors.healthCritical,
                    action: {
                        showCancelAlert = true
                    }
                )
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
        }
        .healthCardShadow()
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Notes")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            Text(appointment.notes ?? "")
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(HealthSpacing.lg)
                .background(HealthColors.secondaryBackground)
                .cornerRadius(HealthCornerRadius.card)
        }
        .healthCardShadow()
    }
    
    // MARK: - Helper Methods
    
    private func formatBookingDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: appointment.date)
    }
    
    private func formatCompletionDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: appointment.date)
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(HealthColors.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text(value)
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let titleColor: Color
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        titleColor: Color = HealthColors.primaryText,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.titleColor = titleColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(titleColor)
                    .frame(width: 20)
                
                Text(title)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(titleColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(HealthColors.secondaryText)
                    .font(.system(size: 14))
            }
            .padding(.vertical, HealthSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Confirmed Appointment") {
    AppointmentDetailSheet(
        appointment: Appointment(
            facilityName: "LabCorp - Downtown",
            facilityId: "lab001",
            date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            timeSlot: TimeSlot(startTime: "09:00", endTime: "09:30"),
            serviceType: .bloodWork,
            status: .confirmed,
            location: "123 Main St, Downtown, NY 10001",
            notes: "Comprehensive metabolic panel. Please fast for 12 hours before appointment."
        )
    )
}

#Preview("Completed Appointment") {
    AppointmentDetailSheet(
        appointment: Appointment(
            facilityName: "Quest Diagnostics - Midtown",
            facilityId: "lab002",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            timeSlot: TimeSlot(startTime: "14:30", endTime: "15:00"),
            serviceType: .lipidPanel,
            status: .completed,
            location: "456 Oak Ave, Midtown, NY 10017",
            notes: "Annual lipid screening completed successfully."
        )
    )
}