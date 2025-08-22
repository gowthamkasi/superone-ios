import SwiftUI

/// Health goals selection view for personalized health experience
struct HealthGoalsView: View {
    @Environment(OnboardingViewModel.self) var viewModel
    @State private var animateContent = false
    @State private var selectedGoals: Set<OnboardingHealthGoal> = []
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                HealthColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: HealthSpacing.formGroupSpacing) {
                        // Header Section
                        headerSection
                        
                        // Progress Indicator
                        ProgressView(value: viewModel.progressValue)
                            .progressViewStyle(HealthProgressViewStyle())
                            .padding(.horizontal, HealthSpacing.screenPadding)
                        
                        // Goals Selection
                        goalsSelectionSection
                        
                        // Bottom spacing for content separation
                        Spacer(minLength: HealthSpacing.xxl)
                    }
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: animateContent)
            }
        }
        .safeAreaInset(edge: .bottom) {
            OnboardingBottomButtonBar(
                configuration: .dual(
                    leftTitle: "Back",
                    leftHandler: {
                        viewModel.previousStep()
                    },
                    rightTitle: "Continue",
                    rightIsLoading: viewModel.isLoading,
                    rightIsDisabled: selectedGoals.isEmpty,
                    rightHandler: {
                        updateSelectedGoals()
                        viewModel.nextStep()
                    }
                )
            )
        }
        .onAppear {
            selectedGoals = viewModel.userProfile.selectedGoals
            animateContent = true
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: HealthSpacing.md) {
            Image(systemName: "target")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(HealthColors.primary)
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
            
            VStack(spacing: HealthSpacing.sm) {
                Text("Health Goals")
                    .healthTextStyle(.title1, color: HealthColors.primaryText, alignment: .center)
                
                Text("What would you like to focus on?")
                    .healthTextStyle(.body, color: HealthColors.secondaryText, alignment: .center)
                
                Text("Select all that apply to personalize your experience")
                    .healthTextStyle(.footnote, color: HealthColors.tertiaryText, alignment: .center)
            }
        }
        .padding(.top, HealthSpacing.xxl)
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    // MARK: - Goals Selection Section
    
    private var goalsSelectionSection: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Primary Goals (Most Popular)
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(HealthColors.primary)
                    
                    Text("Popular Goals")
                        .healthTextStyle(.headline, color: HealthColors.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                
                LazyVGrid(columns: columns, spacing: HealthSpacing.md) {
                    ForEach(popularGoals, id: \.id) { goal in
                        HealthGoalCard(
                            goal: goal,
                            isSelected: selectedGoals.contains(goal),
                            action: { toggleGoal(goal) }
                        )
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
            }
            
            // All Other Goals
            VStack(alignment: .leading, spacing: HealthSpacing.md) {
                HStack {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(HealthColors.secondary)
                    
                    Text("Other Goals")
                        .healthTextStyle(.headline, color: HealthColors.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
                
                LazyVGrid(columns: columns, spacing: HealthSpacing.md) {
                    ForEach(otherGoals, id: \.id) { goal in
                        HealthGoalCard(
                            goal: goal,
                            isSelected: selectedGoals.contains(goal),
                            action: { toggleGoal(goal) }
                        )
                    }
                }
                .padding(.horizontal, HealthSpacing.screenPadding)
            }
            
            // Selection Summary
            selectionSummary
        }
    }
    
    // MARK: - Selection Summary
    
    private var selectionSummary: some View {
        VStack(spacing: HealthSpacing.sm) {
            if !selectedGoals.isEmpty {
                Text("\(selectedGoals.count) goal\(selectedGoals.count == 1 ? "" : "s") selected")
                    .healthTextStyle(.bodyEmphasized, color: HealthColors.primary)
                
                Text("You can always change these later in Settings")
                    .healthTextStyle(.footnote, color: HealthColors.tertiaryText)
            } else {
                VStack(spacing: HealthSpacing.xs) {
                    Image(systemName: "hand.point.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(HealthColors.healthWarning)
                    
                    Text("Please select at least one goal to continue")
                        .healthTextStyle(.footnote, color: HealthColors.healthWarning)
                }
            }
        }
        .padding(.horizontal, HealthSpacing.screenPadding)
    }
    
    
    // MARK: - Private Methods
    
    private var popularGoals: [OnboardingHealthGoal] {
        [
            .generalWellness,
            .weightManagement,
            .fitnessTracking,
            .preventiveHealth
        ]
    }
    
    private var otherGoals: [OnboardingHealthGoal] {
        OnboardingHealthGoal.allCases.filter { !popularGoals.contains($0) }
    }
    
    private func toggleGoal(_ goal: OnboardingHealthGoal) {
        HapticFeedback.light()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedGoals.contains(goal) {
                selectedGoals.remove(goal)
            } else {
                selectedGoals.insert(goal)
            }
        }
    }
    
    private func updateSelectedGoals() {
        for goal in selectedGoals {
            if !viewModel.userProfile.selectedGoals.contains(goal) {
                viewModel.toggleHealthGoal(goal)
            }
        }
        
        for goal in viewModel.userProfile.selectedGoals {
            if !selectedGoals.contains(goal) {
                viewModel.toggleHealthGoal(goal)
            }
        }
    }
}

// MARK: - Health Goal Card Component

struct HealthGoalCard: View {
    let goal: OnboardingHealthGoal
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            
            Task.detached(priority: .userInitiated) {
                try? await Task.sleep(nanoseconds: 100_000_000)
                await MainActor.run {
                    isPressed = false
                    action()
                }
            }
        }) {
            ZStack {
                // Main card content
                VStack(spacing: HealthSpacing.md) {
                    // Icon with consistent centering
                    ZStack {
                        Circle()
                            .fill(isSelected ? goal.color : goal.color.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: goal.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isSelected ? .white : goal.color)
                    }
                    .frame(maxWidth: .infinity) // Ensure consistent centering
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                    
                    // Title and Description
                    VStack(spacing: HealthSpacing.xs) {
                        Text(goal.displayName)
                            .healthTextStyle(.bodyEmphasized, color: HealthColors.primaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text(goal.description)
                            .healthTextStyle(.caption1, color: HealthColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                .padding(HealthSpacing.lg)
                
                // Selection Indicator as overlay - properly positioned within card bounds
                VStack {
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(isSelected ? goal.color : HealthColors.secondaryBackground)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            isSelected ? goal.color : HealthColors.healthNeutral,
                                            lineWidth: isSelected ? 1 : 2
                                        )
                                )
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                    }
                    .padding(.trailing, 12) // Proper edge spacing from card border
                    
                    Spacer()
                }
                .padding(.top, 12) // Proper top spacing from card edge
            }
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                    .fill(isSelected ? goal.color.opacity(0.05) : HealthColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: HealthCornerRadius.card)
                            .strokeBorder(
                                isSelected ? goal.color : HealthColors.accent.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Health Goals View") {
    HealthGoalsView()
        .environment(OnboardingViewModel())
}

#Preview("Health Goal Card - Selected") {
    HealthGoalCard(
        goal: .weightManagement,
        isSelected: true,
        action: {}
    )
    .padding()
}

#Preview("Health Goal Card - Unselected") {
    HealthGoalCard(
        goal: .fitnessTracking,
        isSelected: false,
        action: {}
    )
    .padding()
}