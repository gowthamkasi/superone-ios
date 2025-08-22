//
//  BookingSheet.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Sheet for booking appointments with lab facilities
struct BookingSheet: View {
    @Bindable var viewModel: AppointmentsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let facility = viewModel.selectedFacility {
                    // Facility header
                    facilityHeader(facility)
                    
                    if viewModel.isBooking {
                        // Booking in progress
                        bookingProgressView
                    } else {
                        // Booking form
                        bookingFormView
                    }
                } else {
                    // No facility selected (shouldn't happen)
                    Text("No facility selected")
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                }
            }
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isBooking)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Book") {
                        viewModel.bookAppointment()
                    }
                    .disabled(!canBook || viewModel.isBooking)
                }
            }
        }
    }
    
    // MARK: - Facility Header
    
    private func facilityHeader(_ facility: LabFacility) -> some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(facility.name)
                        .font(HealthTypography.headingSmall)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text(facility.location)
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: HealthSpacing.xs) {
                    Image(systemName: "star.fill")
                        .foregroundColor(HealthColors.healthWarning)
                        .font(.system(size: 14))
                    
                    Text(facility.displayRating)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                }
            }
            
            // Operating hours and wait time
            HStack {
                Label(facility.waitTimeText, systemImage: "clock")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primary)
                
                Spacer()
                
                if facility.acceptsInsurance {
                    Label("Insurance OK", systemImage: "creditcard")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.healthGood)
                }
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
    }
    
    // MARK: - Booking Form
    
    private var bookingFormView: some View {
        ScrollView {
            VStack(spacing: HealthSpacing.xl) {
                // Service type selection
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    Text("Select Service")
                        .font(HealthTypography.headingSmall)
                        .foregroundColor(HealthColors.primaryText)
                    
                    if let facility = viewModel.selectedFacility {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: HealthSpacing.sm) {
                            ForEach(facility.services, id: \.self) { service in
                                Button(action: {
                                    // Map ServiceType to ServiceTypeOption if needed
                                    // For now, just handle the selection differently
                                }) {
                                    VStack(spacing: HealthSpacing.sm) {
                                        Image(systemName: service.icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(HealthColors.primary)
                                        
                                        Text(service.displayName)
                                            .font(HealthTypography.captionMedium)
                                            .foregroundColor(HealthColors.primaryText)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(HealthSpacing.md)
                                    .background(HealthColors.secondaryBackground)
                                    .cornerRadius(HealthCornerRadius.card)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // Date selection
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    Text("Select Date")
                        .font(HealthTypography.headingSmall)
                        .foregroundColor(HealthColors.primaryText)
                    
                    DatePicker(
                        "Appointment Date",
                        selection: Binding(
                            get: { viewModel.selectedDate },
                            set: { newValue in
                                viewModel.selectedDate = newValue
                                viewModel.loadAvailableTimeSlots()
                            }
                        ),
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding(HealthSpacing.md)
                    .background(HealthColors.secondaryBackground)
                    .cornerRadius(HealthCornerRadius.card)
                }
                
                // Time slot selection
                VStack(alignment: .leading, spacing: HealthSpacing.md) {
                    Text("Select Time")
                        .font(HealthTypography.headingSmall)
                        .foregroundColor(HealthColors.primaryText)
                    
                    if viewModel.isLoadingTimeSlots {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading available times...")
                                .font(HealthTypography.body)
                                .foregroundColor(HealthColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(HealthSpacing.lg)
                    } else if viewModel.availableTimeSlots.isEmpty {
                        Text("No available time slots for this date")
                            .font(HealthTypography.body)
                            .foregroundColor(HealthColors.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(HealthSpacing.lg)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: HealthSpacing.sm) {
                            ForEach(viewModel.availableTimeSlots.filter { $0.isAvailable }, id: \.startTime) { timeSlot in
                                TimeSlotCard(
                                    timeSlot: timeSlot,
                                    isSelected: viewModel.selectedTimeSlot?.startTime == timeSlot.startTime,
                                    onSelect: {
                                        viewModel.selectedTimeSlot = timeSlot
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Booking summary
                if viewModel.selectedServiceType != nil && viewModel.selectedTimeSlot != nil {
                    bookingSummary
                }
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.bottom, HealthSpacing.xl)
        }
    }
    
    // MARK: - Booking Progress
    
    private var bookingProgressView: some View {
        VStack(spacing: HealthSpacing.xl) {
            Spacer()
            
            VStack(spacing: HealthSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(HealthColors.primary)
                
                Text("Booking your appointment...")
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("Please wait while we confirm your appointment with the lab facility.")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HealthSpacing.xl)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Booking Summary
    
    private var bookingSummary: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Booking Summary")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                SummaryRow(
                    icon: "building.2",
                    title: "Facility",
                    value: viewModel.selectedFacility?.name ?? ""
                )
                
                SummaryRow(
                    icon: "testtube.2",
                    title: "Service",
                    value: viewModel.selectedServiceType?.displayName ?? ""
                )
                
                SummaryRow(
                    icon: "calendar",
                    title: "Date",
                    value: DateFormatter.mediumDate.string(from: viewModel.selectedDate)
                )
                
                SummaryRow(
                    icon: "clock",
                    title: "Time",
                    value: viewModel.selectedTimeSlot?.displayTime ?? ""
                )
            }
            .padding(HealthSpacing.md)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canBook: Bool {
        return viewModel.selectedServiceType != nil &&
               viewModel.selectedTimeSlot != nil &&
               !viewModel.isLoadingTimeSlots
    }
}

// MARK: - Supporting Views

struct ServiceSelectionCard: View {
    let service: ServiceType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: HealthSpacing.sm) {
                Image(systemName: service.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.secondaryText)
                
                Text(service.displayName)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(isSelected ? HealthColors.primary : HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, HealthSpacing.md)
            .background(isSelected ? HealthColors.primary.opacity(0.1) : HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                    .stroke(isSelected ? HealthColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimeSlotCard: View {
    let timeSlot: TimeSlot
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            Text(timeSlot.displayTime)
                .font(HealthTypography.captionMedium)
                .foregroundColor(isSelected ? .white : HealthColors.primaryText)
                .padding(.vertical, HealthSpacing.sm)
                .frame(maxWidth: .infinity)
                .background(isSelected ? HealthColors.primary : HealthColors.secondaryBackground)
                .cornerRadius(HealthCornerRadius.button)
                .overlay(
                    RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                        .stroke(isSelected ? HealthColors.primary : HealthColors.secondaryText.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(HealthColors.primary)
                .frame(width: 20)
            
            Text(title)
                .font(HealthTypography.bodyMedium)
                .foregroundColor(HealthColors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.secondaryText)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    BookingSheet(viewModel: AppointmentsViewModel())
}