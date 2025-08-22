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
                    Label(facility.waitTimeText, systemImage: "clock")
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
                    value: facility.waitTimeText
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
                    subtitle: facility.phoneNumber,
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
    let service: ServiceType
    
    var body: some View {
        VStack(spacing: HealthSpacing.sm) {
            Image(systemName: service.icon)
                .font(.system(size: 24))
                .foregroundColor(HealthColors.primary)
            
            Text(service.displayName)
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

#Preview {
    FacilityDetailSheet(
        facility: LabFacility(
            name: "LabCorp - Downtown",
            location: "123 Main St, Downtown, NY 10001",
            services: [.bloodWork, .urinalysis, .lipidPanel, .thyroidFunction],
            rating: 4.5,
            reviewCount: 156,
            estimatedWaitTime: 15,
            operatingHours: "Mon-Fri: 7:00 AM - 6:00 PM, Sat: 8:00 AM - 4:00 PM",
            phoneNumber: "(555) 123-4567",
            acceptsInsurance: true,
            acceptsWalkIns: true
        )
    )
}