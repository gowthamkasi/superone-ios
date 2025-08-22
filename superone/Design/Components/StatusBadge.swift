//
//  StatusBadge.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI

/// A reusable status badge component for displaying processing status
struct StatusBadge: View {
    let status: ProcessingStatus
    
    var body: some View {
        Text(status.displayName)
            .font(HealthTypography.captionSmall)
            .foregroundColor(statusColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.1))
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return HealthColors.secondaryText
        case .uploading:
            return HealthColors.primary
        case .preprocessing:
            return HealthColors.primary
        case .processing:
            return HealthColors.primary
        case .analyzing:
            return HealthColors.healthGood
        case .extracting:
            return HealthColors.healthGood
        case .validating:
            return HealthColors.healthGood
        case .retrying:
            return HealthColors.healthWarning
        case .paused:
            return HealthColors.secondaryText
        case .completed:
            return HealthColors.healthExcellent
        case .failed:
            return HealthColors.healthCritical
        case .cancelled:
            return HealthColors.secondaryText
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        StatusBadge(status: .pending)
        StatusBadge(status: .processing)
        StatusBadge(status: .completed)
        StatusBadge(status: .failed)
    }
    .padding()
}