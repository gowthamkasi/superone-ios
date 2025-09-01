import SwiftUI

/// Dedicated test booking date and time selection view
/// Replaces modal sheet with full-page navigation flow
struct TestBookingDateTimeView: View {
    
    // MARK: - Properties
    let testDetails: TestDetails?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedTimeSlot: String? = nil
    @State private var navigateToSummary = false
    
    private let timeSlots = [
        "08:00 AM - 10:00 AM", "10:00 AM - 12:00 PM", "02:00 PM - 04:00 PM",
        "04:00 PM - 06:00 PM", "06:00 PM - 08:00 PM", "08:00 PM - 10:00 PM"
    ]
    
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
        .navigationDestination(isPresented: $navigateToSummary) {
            BookingSummaryView(
                testDetails: testDetails!,
                selectedDate: selectedDate,
                selectedTimeSlot: selectedTimeSlot ?? ""
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
                
                // Navigation and actions
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
                    Text("Book Test")
                        .healthTextStyle(.title3, color: HealthColors.primaryText)
                        .lineLimit(1)
                        .padding(.horizontal, HealthSpacing.md)
                    
                    Spacer()
                    
                    // Cancel button
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .healthTextStyle(.body, color: HealthColors.secondaryText)
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContentWithoutHeader: some View {
        ScrollView {
            LazyVStack(spacing: HealthSpacing.xl) {
                // Header section with test details
                if let test = testDetails {
                    testHeaderCard(test: test)
                        .padding(.top, HealthSpacing.sm)
                }
                
                // Instructions
                instructionsSection
                
                // Date picker section
                datePickerSection
                
                // Time slot section
                timeSlotSection
                
                // Bottom spacing for action bar
                Spacer()
                    .frame(height: 140)
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Test Header Card
    private func testHeaderCard(test: TestDetails) -> some View {
        HStack(spacing: HealthSpacing.md) {
            // Test icon
            Text(test.icon)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(test.category.color.opacity(0.1))
                .clipShape(Circle())
            
            // Test info
            VStack(alignment: .leading, spacing: 4) {
                Text(test.name)
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: HealthSpacing.sm) {
                    Text(test.price)
                        .healthTextStyle(.subheadline, color: HealthColors.primary)
                        .fontWeight(.semibold)
                    
                    if let originalPrice = test.originalPrice, !originalPrice.isEmpty && originalPrice != test.price {
                        Text(originalPrice)
                            .healthTextStyle(.caption1, color: HealthColors.tertiaryText)
                            .strikethrough()
                    }
                }
            }
            
            Spacer()
        }
        .cardPadding()
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
    }
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.primary)
                
                Text("Booking Instructions")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
            }
            
            Text("Choose your preferred date and time slot for the test. Our team will confirm the appointment within 2 hours.")
                .healthTextStyle(.body, color: HealthColors.secondaryText)
                .multilineTextAlignment(.leading)
        }
        .cardPadding()
        .background(HealthColors.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                .stroke(HealthColors.primary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Date Picker Section
    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.primary)
                
                Text("Select Date")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
            }
            
            DatePicker(
                "Select Date", 
                selection: $selectedDate, 
                in: Date()..., 
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(HealthColors.primary)
            .labelsHidden()
        }
        .cardPadding()
        .background(HealthColors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.card))
        .healthCardShadow()
    }
    
    // MARK: - Time Slot Section
    private var timeSlotSection: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            HStack(spacing: HealthSpacing.sm) {
                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HealthColors.primary)
                
                Text("Select Time Slot")
                    .healthTextStyle(.headline, color: HealthColors.primaryText)
            }
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: HealthSpacing.sm), count: 2), 
                spacing: HealthSpacing.sm
            ) {
                ForEach(timeSlots, id: \.self) { timeSlot in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTimeSlot = timeSlot
                        }
                        
                        // Haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }) {
                        Text(timeSlot)
                            .healthTextStyle(
                                .footnote, 
                                color: selectedTimeSlot == timeSlot ? .white : HealthColors.primaryText
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(
                        selectedTimeSlot == timeSlot ? 
                        HealthColors.primary : 
                        HealthColors.tertiaryBackground
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .stroke(
                                selectedTimeSlot == timeSlot ? 
                                HealthColors.primary : 
                                HealthColors.border, 
                                lineWidth: 1
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                    .scaleEffect(selectedTimeSlot == timeSlot ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedTimeSlot)
                }
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
            
            // Action buttons
            HStack(spacing: HealthSpacing.md) {
                // Cancel button
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: HealthSpacing.sm) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("Cancel")
                            .healthTextStyle(.buttonSecondary)
                    }
                    .foregroundColor(HealthColors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(HealthColors.tertiaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .stroke(HealthColors.border, lineWidth: 1)
                    )
                }
                
                // Next button
                Button {
                    handleNextAction()
                } label: {
                    HStack(spacing: HealthSpacing.sm) {
                        Text("Next")
                            .healthTextStyle(.buttonPrimary, color: selectedTimeSlot != nil ? .white : HealthColors.secondaryText)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(selectedTimeSlot != nil ? .white : HealthColors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        selectedTimeSlot != nil ? 
                        HealthColors.primary : 
                        HealthColors.tertiaryBackground
                    )
                    .clipShape(RoundedRectangle(cornerRadius: HealthCornerRadius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.button)
                            .stroke(selectedTimeSlot == nil ? HealthColors.border : Color.clear, lineWidth: 1)
                    )
                }
                .disabled(selectedTimeSlot == nil)
                .scaleEffect(selectedTimeSlot != nil ? 1.0 : 0.98)
                .animation(.easeInOut(duration: 0.2), value: selectedTimeSlot)
            }
            .padding(.horizontal, HealthSpacing.screenPadding)
            .padding(.vertical, HealthSpacing.md)
            .padding(.bottom, max(safeAreaBottom, HealthSpacing.md))
            .background(HealthColors.secondaryBackground)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
        }
    }
    
    // MARK: - Actions
    private func handleNextAction() {
        guard selectedTimeSlot != nil else { return }
        
        // Haptic feedback for successful action
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Navigate to booking summary
        withAnimation(.easeInOut(duration: 0.3)) {
            navigateToSummary = true
        }
    }
}

// MARK: - Preview Removed
// Preview removed to eliminate hardcoded sample data references
// Use real LabLoop API data for development testing