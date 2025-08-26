//
//  PayloadInspectorView.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Simple payload inspector with raw text display
//

import SwiftUI
import Foundation

/// Simple payload inspector showing raw text
struct PayloadInspectorView: View {
    let data: Any
    let title: String
    
    @State private var showCopySuccessAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthSpacing.md) {
            // Header with title and copy button
            headerSection
            
            // Raw text content
            contentSection
                .frame(maxHeight: 400)
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.secondaryBackground)
        .cornerRadius(HealthCornerRadius.card)
        .healthCardShadow()
        .alert("Copied!", isPresented: $showCopySuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Payload copied to clipboard")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: HealthSpacing.xs) {
                Text(title)
                    .font(HealthTypography.headingSmall)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("Raw Payload Inspector")
                    .font(HealthTypography.captionRegular)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Spacer()
            
            // Copy button only
            Button(action: copyToClipboard) {
                HStack(spacing: HealthSpacing.xs) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.caption)
                    Text("Copy")
                        .font(HealthTypography.captionMedium)
                }
                .foregroundColor(HealthColors.primary)
                .padding(.horizontal, HealthSpacing.sm)
                .padding(.vertical, 6)
                .background(HealthColors.primary.opacity(0.1))
                .cornerRadius(HealthCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        ScrollView {
            Text(formattedDataString)
                .font(HealthTypography.captionRegular.monospaced())
                .foregroundColor(HealthColors.primaryText)
                .padding(HealthSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(HealthColors.background)
        .cornerRadius(HealthCornerRadius.sm)
    }
    
    // MARK: - Computed Properties
    
    private var formattedDataString: String {
        // Try to convert to JSON format first
        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        // Fallback to Swift's native description if JSON serialization fails
        return String(describing: data)
    }
    
    // MARK: - Actions
    
    private func copyToClipboard() {
        UIPasteboard.general.string = formattedDataString
        showCopySuccessAlert = true
    }
}
