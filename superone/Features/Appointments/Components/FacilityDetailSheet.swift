//
//  FacilityDetailSheet.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import SwiftUI

/// Sheet showing detailed lab facility information
struct FacilityDetailSheet: View {
    let facility: LabFacility
    @Environment(\.dismiss) private var dismiss
    @State private var showBookingSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: HealthSpacing.xl) {
                    // Facility header
                    facilityHeader
                    
                    // Services section
                    servicesSection
                    
                    // Information section
                    informationSection
                    
                    // Reviews section
                    reviewsSection
                    
                    // Contact section
                    contactSection
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                .padding(.bottom, HealthSpacing.xl)
            }
            .background(HealthColors.background.ignoresSafeArea())
            .navigationTitle(facility.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Book") {
                        showBookingSheet = true
                    }
                    .foregroundColor(HealthColors.primary)
                }
            }
            .sheet(isPresented: $showBookingSheet) {
                Text("Booking flow would open here")
            }
        }
    }
    
    // MARK: - Facility Header
    
    private var facilityHeader: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Rating and reviews
            HStack {
                HStack(spacing: HealthSpacing.xs) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(facility.rating) ? "star.fill" : "star")
                            .foregroundColor(HealthColors.healthWarning)
                            .font(.system(size: 16))
                    }
                }
                
                Text(facility.displayRating)
                    .font(HealthTypography.bodyMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("(\(facility.reviewCount) reviews)")
                    .font(HealthTypography.body)
                    .foregroundColor(HealthColors.secondaryText)
                
                Spacer()
            }
            
            // Location and key info
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                HStack(alignment: .top) {
                    Image(systemName: "location")
                        .foregroundColor(HealthColors.primary)
                        .frame(width: 20)
                    
                    Text(facility.location)
                        .font(HealthTypography.body)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Spacer()
                }
                
                HStack {
                    Label("15 min wait", systemImage: "clock")
                        .font(HealthTypography.captionMedium)
                        .foregroundColor(HealthColors.primary)
                    
                    Spacer()
                    
                    if facility.acceptsWalkIns {
                        Label("Walk-ins OK", systemImage: "checkmark.circle")
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.healthGood)
                    }
                    
                    if facility.acceptsInsurance {
                        Label("Insurance", systemImage: "creditcard")
                            .font(HealthTypography.captionMedium)
                            .foregroundColor(HealthColors.healthGood)
                    }
                }
            }
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
    
    // MARK: - Services Section
    
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Available Services")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: HealthSpacing.sm) {
                ForEach(facility.services, id: \.self) { service in
                    ServiceCard(service: service)
                }
            }
        }
    }
    
    // MARK: - Information Section
    
    private var informationSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Facility Information")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.md) {
                FacilityInfoRow(
                    icon: "clock",
                    title: "Operating Hours",
                    value: facility.operatingHours
                )
                
                FacilityInfoRow(
                    icon: "timer",
                    title: "Average Wait Time",
                    value: "15 min wait"
                )
                
                FacilityInfoRow(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "Walk-ins",
                    value: facility.acceptsWalkIns ? "Accepted" : "Appointment only"
                )
                
                FacilityInfoRow(
                    icon: "creditcard",
                    title: "Insurance",
                    value: facility.acceptsInsurance ? "Accepted" : "Cash only"
                )
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
        }
        .healthCardShadow()
    }
    
    // MARK: - Reviews Section
    
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack {
                Text("Reviews")
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                Button("View All") {
                    // Show all reviews feature will be implemented
                }
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primary)
            }
            
            VStack(spacing: HealthSpacing.md) {
                // Mock reviews
                ReviewCard(
                    rating: 5,
                    review: "Great service and very professional staff. Quick and efficient blood draw.",
                    author: "Sarah M.",
                    date: "2 weeks ago"
                )
                
                ReviewCard(
                    rating: 4,
                    review: "Clean facility with minimal wait time. Easy parking available.",
                    author: "Mike R.",
                    date: "1 month ago"
                )
            }
        }
    }
    
    // MARK: - Contact Section
    
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            Text("Contact & Directions")
                .font(HealthTypography.headingSmall)
                .foregroundColor(HealthColors.primaryText)
            
            VStack(spacing: HealthSpacing.sm) {
                ContactButton(
                    icon: "phone.fill",
                    title: "Call",
                    subtitle: facility.phoneNumber ?? "Not available",
                    action: {
                        // Phone call functionality will be implemented
                    }
                )
                
                ContactButton(
                    icon: "location.circle.fill",
                    title: "Directions",
                    subtitle: "Open in Maps",
                    action: {
                        // Maps integration will be implemented
                    }
                )
                
                ContactButton(
                    icon: "globe",
                    title: "Website",
                    subtitle: "Visit facility website",
                    action: {
                        // Website navigation will be implemented
                    }
                )
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.secondaryBackground)
            .cornerRadius(HealthCornerRadius.card)
        }
        .healthCardShadow()
    }
}

// MARK: - Supporting Views

struct ServiceCard: View {
    let service: String
    
    var body: some View {
        VStack(spacing: HealthSpacing.sm) {
            Image(systemName: getServiceIcon(for: service))
                .font(.system(size: 24))
                .foregroundColor(HealthColors.primary)
            
            Text(service)
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HealthSpacing.md)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
    }
}

struct FacilityInfoRow: View {
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

struct ReviewCard: View {
    let rating: Int
    let review: String
    let author: String
    let date: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.sm) {
            HStack {
                HStack(spacing: HealthSpacing.xs) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < rating ? "star.fill" : "star")
                            .foregroundColor(HealthColors.healthWarning)
                            .font(.system(size: 12))
                    }
                }
                
                Spacer()
                
                Text(date)
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Text(review)
                .font(HealthTypography.body)
                .foregroundColor(HealthColors.primaryText)
                .lineLimit(3)
            
            Text("- \(author)")
                .font(HealthTypography.captionMedium)
                .foregroundColor(HealthColors.secondaryText)
        }
        .padding(HealthSpacing.md)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.md)
    }
}

struct ContactButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                    Text(title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                    
                    Text(subtitle)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                }
                
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

// MARK: - Helper Functions

private func getServiceIcon(for service: String) -> String {
    switch service.lowercased() {
    case let s where s.contains("blood"):
        return "drop.fill"
    case let s where s.contains("x-ray"):
        return "xmark.rectangle"
    case let s where s.contains("ultrasound"):
        return "waveform.path.ecg"
    case let s where s.contains("ecg"):
        return "heart.text.square"
    case let s where s.contains("mri"):
        return "brain.head.profile"
    case let s where s.contains("ct"):
        return "rays"
    case let s where s.contains("pathology"):
        return "microscope"
    case let s where s.contains("collection"):
        return "testtube.2"
    default:
        return "medical.thermometer"
    }
}

#Preview {
    FacilityDetailSheet(
        facility: LabFacility(
            id: "preview-facility",
            name: "LabCorp - Downtown",
            type: .lab,
            rating: 4.5,
            distance: "2.3 km",
            availability: "Mon-Fri: 7:00 AM - 6:00 PM",
            price: 2800,
            isWalkInAvailable: true,
            nextSlot: "Today 3:00 PM",
            address: "123 Main St, Downtown, NY 10001",
            phoneNumber: "(555) 123-4567",
            location: "Downtown, NY",
            services: ["Blood Tests", "X-Ray", "ECG"],
            reviewCount: 145,
            operatingHours: "7:00 AM - 6:00 PM",
            isRecommended: true,
            offersHomeCollection: false,
            acceptsInsurance: true
        )
    )
}