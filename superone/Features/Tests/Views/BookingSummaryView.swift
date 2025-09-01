import SwiftUI

/// Booking summary view for test appointment confirmation
/// Displays all booking details and handles final booking confirmation
@MainActor
struct BookingSummaryView: View {
    
    // MARK: - Properties
    let testDetails: TestDetails
    let selectedDate: Date
    let selectedTimeSlot: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingBooking = false
    @State private var showingSuccessView = false
    
    // Lab data should be passed from previous screen or fetched from LabLoop API
    // No hardcoded lab data - temporary placeholder for UI consistency
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Main content with header
                VStack(spacing: 0) {
                    headerSection
                    mainContentWithoutHeader
                }
                
                // Fixed bottom action bar
                bottomActionBar(safeAreaBottom: geometry.safeAreaInsets.bottom)
            }
        }
        .navigationBarHidden(true)
        .background(HealthColors.secondaryBackground.ignoresSafeArea())
        .fullScreenCover(isPresented: $showingSuccessView) {
            BookingSuccessView(
                testDetails: testDetails,
                selectedDate: selectedDate,
                selectedTimeSlot: selectedTimeSlot
            )
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        ZStack(alignment: .topLeading) {
            // Background gradient
            LinearGradient(
                colors: [
                    HealthColors.primary.opacity(0.1),
                    HealthColors.secondaryBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            
            // Header content
            VStack(spacing: 0) {
                // Status bar spacer
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 44)
                
                // Navigation and title
                HStack {
                    // Back button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(HealthColors.primaryText)
                            .frame(width: 44, height: 44)
                            .background(HealthColors.primaryBackground)
                            .clipShape(Circle())
                            .healthCardShadow()
                    }
                    
                    // Title
                    Text("Booking Summary")
                        .healthTextStyle(.title3, color: HealthColors.primaryText)
                        .lineLimit(1)
                        .padding(.horizontal, HealthSpacing.md)
                    
                    Spacer()
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContentWithoutHeader: some View {
        ScrollView {
            LazyVStack(spacing: HealthSpacing.xl) {
                // Test details card
                testDetailsCard
                    .padding(.top, HealthSpacing.sm)
                
                // Lab information card
                // Lab information will be loaded from LabLoop API
                loadingLabCard
                
                // Schedule card
                scheduleCard
                
                // Pricing card
                pricingCard
                
                // Bottom spacing for action bar
                Spacer()
                    .frame(height: 140)
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Test Details Card
    private var testDetailsCard: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.sm) {
                // Test icon
                Text(testDetails.icon)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(testDetails.category.color.opacity(0.1))
                    .clipShape(Circle())
                
                // Test title
                Text(testDetails.name)
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
            }
            
            // Test description
            Text(testDetails.description)
                .healthTextStyle(.body, color: HealthColors.secondaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .cardPadding()
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
    }
    
    // MARK: - Loading Lab Information Card
    private var loadingLabCard: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.sm) {
                // Lab icon
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 40, height: 40)
                    .background(HealthColors.primary.opacity(0.1))
                    .clipShape(Circle())
                
                // Lab name
                Text("Lab Information Loading...")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
            }
            
            // Lab address with location icon
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(HealthColors.secondaryText)
                
                Text("Please wait while we load lab details")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                
                Spacer()
            }
            
            // Get Directions button
            Button {
                openMaps()
            } label: {
                HStack(spacing: HealthSpacing.sm) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("Get Directions")
                        .healthTextStyle(.buttonSecondary)
                }
                .foregroundColor(HealthColors.primary)
                .padding(.vertical, HealthSpacing.sm)
                .padding(.horizontal, HealthSpacing.lg)
                .background(HealthColors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                        .stroke(HealthColors.primary.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .cardPadding()
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
    }
    
    // MARK: - Schedule Card
    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.sm) {
                // Calendar icon
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 40, height: 40)
                    .background(HealthColors.primary.opacity(0.1))
                    .clipShape(Circle())
                
                Text("Schedule")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
            }
            
            // Date information
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(HealthColors.secondaryText)
                
                Text(formatDate(selectedDate))
                    .healthTextStyle(.body, color: HealthColors.primaryText)
                
                Spacer()
            }
            
            // Time information
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(HealthColors.secondaryText)
                
                Text(selectedTimeSlot)
                    .healthTextStyle(.body, color: HealthColors.primaryText)
                
                Spacer()
            }
            
            // Reschedule button
            Button {
                // Navigate back to date/time selection
                dismiss()
            } label: {
                HStack(spacing: HealthSpacing.sm) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("Reschedule")
                        .healthTextStyle(.buttonSecondary)
                }
                .foregroundColor(HealthColors.secondaryText)
                .padding(.vertical, HealthSpacing.sm)
                .padding(.horizontal, HealthSpacing.lg)
                .background(HealthColors.tertiaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                        .stroke(HealthColors.border, lineWidth: 1)
                )
            }
        }
        .cardPadding()
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
    }
    
    // MARK: - Pricing Card
    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.sm) {
                // Pricing icon
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 40, height: 40)
                    .background(HealthColors.primary.opacity(0.1))
                    .clipShape(Circle())
                
                Text("Pricing")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                
                Spacer()
            }
            
            // Total price
            HStack {
                Text("Total:")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                
                Spacer()
                
                Text(testDetails.price)
                    .healthTextStyle(.title3, color: HealthColors.primary)
                    .fontWeight(.bold)
            }
            
            // Payment method
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 14))
                    .foregroundColor(HealthColors.secondaryText)
                
                Text("Payment: Pay at Lab")
                    .healthTextStyle(.body, color: HealthColors.secondaryText)
                
                Spacer()
            }
        }
        .cardPadding()
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
    }
    
    // MARK: - Bottom Action Bar
    private func bottomActionBar(safeAreaBottom: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Gradient overlay for better visual separation
            LinearGradient(
                colors: [HealthColors.secondaryBackground.opacity(0), HealthColors.secondaryBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            // Confirm booking button
            Button {
                handleConfirmBooking()
            } label: {
                HStack(spacing: HealthSpacing.sm) {
                    if isConfirmingBooking {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Confirm Booking")
                            .healthTextStyle(.buttonPrimary, color: .white)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    isConfirmingBooking ? 
                    HealthColors.primary.opacity(0.7) : 
                    HealthColors.primary
                )
                .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                .scaleEffect(isConfirmingBooking ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isConfirmingBooking)
            }
            .disabled(isConfirmingBooking)
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.vertical, HealthSpacing.md)
            .padding(.bottom, max(safeAreaBottom, HealthSpacing.md))
            .background(HealthColors.secondaryBackground)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        // Check if date is today, tomorrow, or another date
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today, \(date.formatted(.dateTime.month().day().year()))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow, \(date.formatted(.dateTime.month().day().year()))"
        } else {
            // Use relative date formatting for dates within a week
            let daysDifference = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
            if daysDifference > 0 && daysDifference <= 7 {
                formatter.dateFormat = "EEEE, MMMM d, yyyy"
            } else {
                formatter.dateFormat = "MMMM d, yyyy"
            }
            return formatter.string(from: date)
        }
    }
    
    /// Maps functionality disabled - lab data needs to be loaded from API first
    private func openMaps() {
        // Maps functionality disabled until lab data is loaded from LabLoop API
        // TODO: Implement once real lab facility data is available
    }
    
    /// Handle booking confirmation
    private func handleConfirmBooking() {
        // Start loading state
        withAnimation(.easeInOut(duration: 0.3)) {
            isConfirmingBooking = true
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Simulate booking API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isConfirmingBooking = false
                showingSuccessView = true
            }
            
            // Success haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
}


// MARK: - Booking Success View

@MainActor
struct BookingSuccessView: View {
    let testDetails: TestDetails
    let selectedDate: Date
    let selectedTimeSlot: String
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: HealthSpacing.xxxl) {
                Spacer()
                
                // Success animation
                VStack(spacing: HealthSpacing.xl) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(HealthColors.primary.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(HealthColors.primary)
                    }
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: true)
                    
                    // Success message
                    VStack(spacing: HealthSpacing.md) {
                        Text("Booking Confirmed!")
                            .healthTextStyle(.title1, color: HealthColors.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Your test appointment has been successfully booked. We'll send you a confirmation shortly.")
                            .healthTextStyle(.body, color: HealthColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Booking details summary
                VStack(spacing: HealthSpacing.lg) {
                    // Test info
                    HStack {
                        Text(testDetails.icon)
                            .font(.title2)
                        Text(testDetails.name)
                            .healthTextStyle(.headline, color: HealthColors.primaryText)
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Date and time
                    VStack(spacing: HealthSpacing.sm) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(HealthColors.secondaryText)
                            Text(selectedDate.formatted(.dateTime.weekday(.wide).month().day().year()))
                                .healthTextStyle(.body, color: HealthColors.primaryText)
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(HealthColors.secondaryText)
                            Text(selectedTimeSlot)
                                .healthTextStyle(.body, color: HealthColors.primaryText)
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(HealthColors.secondaryText)
                            Text("Lab details will be sent via email")
                                .healthTextStyle(.body, color: HealthColors.primaryText)
                            Spacer()
                        }
                    }
                }
                .cardPadding()
                .background(HealthColors.primaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
                .healthCardShadow()
                
                Spacer()
                
                // Done button
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: HealthSpacing.sm) {
                        Text("Done")
                            .healthTextStyle(.buttonPrimary, color: .white)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(HealthColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                }
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, HealthSpacing.lg))
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
        }
        .background(HealthColors.secondaryBackground.ignoresSafeArea())
    }
}

// MARK: - Previews Removed
// Preview data removed to eliminate all hardcoded test data
// Use real LabLoop API data for development testing