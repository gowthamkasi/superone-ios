//
//  DocumentScannerView.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

import SwiftUI
import VisionKit

/// Document scanner view for batch uploading scanned lab reports
struct DocumentScannerView: UIViewControllerRepresentable {
    let onScanComplete: ([UIImage]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        
        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                images.append(image)
            }
            
            parent.onScanComplete(images)
            parent.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Enhanced Batch Scanner View

/// Enhanced scanner view with preview and selection capabilities
struct EnhancedBatchScannerView: View {
    let onScanComplete: ([UIImage]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var scannedImages: [UIImage] = []
    @State private var showingDocumentScanner = false
    @State private var selectedImages: Set<Int> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: HealthSpacing.lg) {
                if scannedImages.isEmpty {
                    emptyStateView
                } else {
                    scannedImagesView
                }
            }
            .padding(HealthSpacing.lg)
            .navigationTitle("Scan Lab Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !scannedImages.isEmpty {
                        Button("Use Selected") {
                            let selectedImageArray = selectedImages.sorted().map { scannedImages[$0] }
                            onScanComplete(selectedImageArray.isEmpty ? scannedImages : selectedImageArray)
                        }
                        .fontWeight(.semibold)
                        .disabled(selectedImages.isEmpty && scannedImages.isEmpty)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingDocumentScanner) {
                DocumentScannerView { images in
                    scannedImages.append(contentsOf: images)
                    // Auto-select all new images
                    let startIndex = scannedImages.count - images.count
                    for i in startIndex..<scannedImages.count {
                        selectedImages.insert(i)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: HealthSpacing.xl) {
            Spacer()
            
            Image(systemName: "doc.viewfinder.fill")
                .font(.system(size: 64))
                .foregroundColor(HealthColors.primary)
            
            VStack(spacing: HealthSpacing.md) {
                Text("Scan Lab Reports")
                    .font(HealthTypography.headingLarge)
                    .foregroundColor(HealthColors.primaryText)
                
                Text("Use your camera to scan multiple lab reports. Each page will be processed separately.")
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button {
                showingDocumentScanner = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Start Scanning")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HealthSpacing.lg)
                .background(HealthColors.primary)
                .cornerRadius(HealthCornerRadius.lg)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Scanned Images View
    
    private var scannedImagesView: some View {
        VStack(spacing: HealthSpacing.lg) {
            // Header with stats
            scanSummaryHeader
            
            // Action buttons
            actionButtonsRow
            
            // Scanned images grid
            scannedImagesGrid
        }
    }
    
    private var scanSummaryHeader: some View {
        VStack(spacing: HealthSpacing.md) {
            HStack {
                Text("Scanned Pages")
                    .font(HealthTypography.headingMedium)
                    .foregroundColor(HealthColors.primaryText)
                
                Spacer()
                
                Text("\(selectedImages.count)/\(scannedImages.count) selected")
                    .font(HealthTypography.captionMedium)
                    .foregroundColor(HealthColors.secondaryText)
            }
            
            Text("Tap images to select/deselect them for upload")
                .font(HealthTypography.captionRegular)
                .foregroundColor(HealthColors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var actionButtonsRow: some View {
        HStack(spacing: HealthSpacing.md) {
            Button("Scan More") {
                showingDocumentScanner = true
            }
            .buttonStyle(HealthSecondaryButtonStyle())
            
            Button("Select All") {
                selectedImages = Set(0..<scannedImages.count)
            }
            .buttonStyle(HealthSecondaryButtonStyle())
            
            Button("Clear All") {
                selectedImages.removeAll()
                scannedImages.removeAll()
            }
            .buttonStyle(HealthSecondaryButtonStyle())
        }
    }
    
    private var scannedImagesGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: HealthSpacing.md) {
                ForEach(Array(scannedImages.enumerated()), id: \.offset) { index, image in
                    ScannedImageCard(
                        image: image,
                        index: index,
                        isSelected: selectedImages.contains(index)
                    ) {
                        if selectedImages.contains(index) {
                            selectedImages.remove(index)
                        } else {
                            selectedImages.insert(index)
                        }
                    }
                }
            }
            .padding(.horizontal, HealthSpacing.sm)
        }
    }
}

// MARK: - Supporting Views

struct ScannedImageCard: View {
    let image: UIImage
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(HealthCornerRadius.md)
                
                // Selection overlay
                if isSelected {
                    RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                        .fill(HealthColors.primary.opacity(0.3))
                    
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(HealthColors.primary)
                                .font(.title2)
                                .background(Circle().fill(.white))
                        }
                        Spacer()
                    }
                    .padding(HealthSpacing.sm)
                }
                
                // Page number
                VStack {
                    Spacer()
                    HStack {
                        Text("Page \(index + 1)")
                            .font(HealthTypography.captionSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.7))
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                }
                .padding(HealthSpacing.sm)
            }
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .stroke(isSelected ? HealthColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Scanner View

/// Simple scanner view for immediate scanning without preview
struct QuickScannerView: View {
    let onScanComplete: ([UIImage]) -> Void
    @State private var showingDocumentScanner = true
    
    var body: some View {
        Color.clear
            .fullScreenCover(isPresented: $showingDocumentScanner) {
                DocumentScannerView(onScanComplete: onScanComplete)
            }
    }
}

// MARK: - Scanner Button

/// Reusable scanner button component
struct ScannerButton: View {
    let title: String
    let subtitle: String
    let onScan: ([UIImage]) -> Void
    
    @State private var showingScanner = false
    
    var body: some View {
        Button {
            showingScanner = true
        } label: {
            HStack(spacing: HealthSpacing.md) {
                Image(systemName: "doc.viewfinder.fill")
                    .foregroundColor(HealthColors.primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
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
                    .font(.caption)
            }
            .padding(HealthSpacing.lg)
            .background(HealthColors.primaryBackground)
            .cornerRadius(HealthCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: HealthCornerRadius.md)
                    .stroke(HealthColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingScanner) {
            EnhancedBatchScannerView(onScanComplete: onScan)
        }
    }
}

// MARK: - Preview

#Preview("Empty Scanner") {
    EnhancedBatchScannerView { images in
    }
}

#Preview("Scanner Button") {
    VStack {
        ScannerButton(
            title: "Scan Documents",
            subtitle: "Use camera to scan lab reports"
        ) { images in
        }
    }
    .padding()
}