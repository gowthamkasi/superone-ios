//
//  UploadDropZone.swift
//  SuperOne
//
//  Created by Claude Code on 7/27/25.
//

import SwiftUI
import PhotosUI

/// Reusable drag-and-drop upload zone for lab report documents
struct UploadDropZone: View {
    
    // MARK: - Properties
    
    let onFileUpload: () -> Void
    let onPhotoLibrarySelect: () -> Void
    let onDocumentScan: () -> Void
    
    // MARK: - Initialization
    
    init(
        onFileUpload: @escaping () -> Void,
        onPhotoLibrarySelect: @escaping () -> Void,
        onDocumentScan: @escaping () -> Void
    ) {
        self.onFileUpload = onFileUpload
        self.onPhotoLibrarySelect = onPhotoLibrarySelect
        self.onDocumentScan = onDocumentScan
    }
    
    // MARK: - Body
    
    var body: some View {
        if AppConfiguration.current.isFeatureEnabled(.ocrUpload) {
            uploadOptions
        } else {
            EmptyView()
        }
    }
    
    
    // MARK: - Upload Options
    
    private var uploadOptions: some View {
        VStack(spacing: HealthSpacing.lg) {
            uploadOptionButton(
                icon: "folder.fill",
                title: "Choose Files",
                subtitle: "Select PDFs or images from Files app",
                action: onFileUpload
            )
            
            uploadOptionButton(
                icon: "photo.on.rectangle.angled",
                title: "Photo Library",
                subtitle: "Select lab report images from Photos",
                action: onPhotoLibrarySelect
            )
            
            uploadOptionButton(
                icon: "doc.viewfinder.fill",
                title: "Scan Documents",
                subtitle: "Use camera to scan reports",
                action: onDocumentScan
            )
        }
    }
    
    private func uploadOptionButton(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: HealthSpacing.lg) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(HealthColors.primary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(HealthTypography.bodyMedium)
                        .foregroundColor(HealthColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(HealthTypography.captionRegular)
                        .foregroundColor(HealthColors.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(HealthColors.secondaryText)
                    .font(.caption)
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.primaryBackground)
            .cornerRadius(HealthCornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.lg)
                    .stroke(HealthColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Specialized Upload Zones

/// Compact upload zone for use in cards or smaller spaces
struct CompactUploadZone: View {
    let onFileUpload: () -> Void
    let onPhotoLibrarySelect: () -> Void
    let onDocumentScan: () -> Void
    
    var body: some View {
        if AppConfiguration.current.isFeatureEnabled(.ocrUpload) {
            HStack(spacing: HealthSpacing.md) {
            // File upload button
            compactButton(
                icon: "doc.fill",
                title: "Files",
                color: HealthColors.primary,
                action: onFileUpload
            )
            
            // Scanner button  
            compactButton(
                icon: "doc.text.viewfinder",
                title: "Scanner",
                color: HealthColors.secondary,
                action: onDocumentScan
            )
            
            // Library button
            compactButton(
                icon: "photo.on.rectangle",
                title: "Library",
                color: HealthColors.healthGood,
                action: onPhotoLibrarySelect
            )
        }
        .padding(HealthSpacing.lg)
        .background(HealthColors.background)
        .cornerRadius(HealthCornerRadius.md)
        } else {
            EmptyView()
        }
    }
    
    private func compactButton(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.primaryText)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .padding(.vertical, HealthSpacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(HealthCornerRadius.md)
    }
}

// MARK: - Preview

#Preview("Full Upload Zone") {
    UploadDropZone(
        onFileUpload: {  },
        onPhotoLibrarySelect: {  },
        onDocumentScan: {  }
    )
    .padding()
}

#Preview("Compact Upload Zone") {
    CompactUploadZone(
        onFileUpload: {  },
        onPhotoLibrarySelect: {  },
        onDocumentScan: {  }
    )
    .padding()
}

