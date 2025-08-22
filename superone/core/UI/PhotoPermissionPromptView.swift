//
//  PhotoPermissionPromptView.swift
//  SuperOne
//
//  Created by Claude Code on 8/3/25.
//  Reusable view for prompting users about photo library permissions

import SwiftUI
import Photos

/// A reusable view that prompts users for photo library permissions with clear messaging
struct PhotoPermissionPromptView: View {
    
    // MARK: - Properties
    
    let onPermissionGranted: () -> Void
    let onPermissionDenied: () -> Void
    
    @StateObject private var permissionHelper = PhotoPermissionHelper.shared
    @State private var isRequesting: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: HealthSpacing.xl) {
            // Icon
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(HealthColors.primary)
                .symbolRenderingMode(.hierarchical)
            
            // Content
            VStack(spacing: HealthSpacing.md) {
                Text("Photo Library Access")
                    .font(HealthTypography.headingMedium)
                    .foregroundColor(HealthColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(permissionHelper.getActionableMessage(permissionHelper.currentStatus))
                    .font(HealthTypography.bodyRegular)
                    .foregroundColor(HealthColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Action Button
            if let buttonTitle = permissionHelper.getActionButtonTitle(permissionHelper.currentStatus) {
                Button(action: {
                    handlePermissionAction()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isRequesting ? "Requesting..." : buttonTitle)
                            .font(HealthTypography.bodyMedium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(HealthColors.primary)
                    .cornerRadius(HealthCornerRadius.button)
                }
                .disabled(isRequesting)
            }
            
            // Alternative action for denied permissions
            if permissionHelper.currentStatus == .denied || permissionHelper.currentStatus == .restricted {
                Button("Continue without photos") {
                    onPermissionDenied()
                }
                .font(HealthTypography.bodyRegular)
                .foregroundColor(HealthColors.secondaryText)
            }
        }
        .padding(HealthSpacing.xl)
        .onAppear {
            permissionHelper.startMonitoring()
            _ = permissionHelper.getCurrentStatus()
        }
        .onDisappear {
            permissionHelper.stopMonitoring()
        }
        .alert("Permission Update", isPresented: $showingAlert) {
            Button("OK") {
                if permissionHelper.hasPhotoLibraryAccess() {
                    onPermissionGranted()
                } else {
                    onPermissionDenied()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: permissionHelper.currentStatus) { _, newStatus in
            handleStatusChange(newStatus)
        }
    }
    
    // MARK: - Actions
    
    private func handlePermissionAction() {
        Task {
            isRequesting = true
            
            let success = await permissionHelper.handlePermissionAction(permissionHelper.currentStatus)
            
            await MainActor.run {
                isRequesting = false
                
                if success {
                    onPermissionGranted()
                } else if permissionHelper.currentStatus == .denied || permissionHelper.currentStatus == .restricted {
                    alertMessage = "You can enable photo access later in Settings → Privacy & Security → Photos → SuperOne Health."
                    showingAlert = true
                }
            }
        }
    }
    
    private func handleStatusChange(_ newStatus: PHAuthorizationStatus) {
        if newStatus == .authorized || newStatus == .limited {
            // Permission was granted (possibly from settings)
            onPermissionGranted()
        }
    }
}

// MARK: - Convenience Modifiers

extension View {
    /// Present a photo permission prompt as a sheet
    func photoPermissionPrompt(
        isPresented: Binding<Bool>,
        onGranted: @escaping () -> Void,
        onDenied: @escaping () -> Void = {}
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            NavigationView {
                PhotoPermissionPromptView(
                    onPermissionGranted: {
                        isPresented.wrappedValue = false
                        onGranted()
                    },
                    onPermissionDenied: {
                        isPresented.wrappedValue = false
                        onDenied()
                    }
                )
                .navigationTitle("Photo Access")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Not Now") {
                            isPresented.wrappedValue = false
                            onDenied()
                        }
                        .foregroundColor(HealthColors.secondaryText)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Permission Prompt - Not Determined") {
    PhotoPermissionPromptView(
        onPermissionGranted: { },
        onPermissionDenied: { }
    )
}

#Preview("Permission Prompt - Denied") {
    let helper = PhotoPermissionHelper.shared
    helper.currentStatus = .denied
    
    return PhotoPermissionPromptView(
        onPermissionGranted: { },
        onPermissionDenied: { }
    )
}