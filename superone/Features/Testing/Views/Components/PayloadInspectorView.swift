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
    let isExpectedResponse: Bool
    
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
        // Check if this is a raw response format from our API testing
        if !isExpectedResponse, let rawResponse = data as? [String: Any] {
            return formatRawResponse(rawResponse)
        }
        
        // Only try JSON formatting for expected responses
        if isExpectedResponse {
            // Try to convert to JSON format for expected responses
            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }
        
        // For other responses and fallback, use raw text
        return String(describing: data)
    }
    
    private func formatRawResponse(_ response: [String: Any]) -> String {
        var output: [String] = []
        
        // HTTP Status Line
        if let statusCode = response["status_code"] as? Int,
           let statusText = response["status_text"] as? String {
            output.append("HTTP/1.1 \(statusCode) \(statusText)")
        }
        
        // Headers
        if let headers = response["headers"] as? [String: Any], !headers.isEmpty {
            output.append("\n--- Response Headers ---")
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                output.append("\(key): \(value)")
            }
        }
        
        // Content info
        if let bodyBytes = response["body_bytes"] as? Int {
            output.append("\n--- Content Info ---")
            output.append("Body Size: \(bodyBytes) bytes")
            
            if let contentLength = response["content_length"] as? Int64, contentLength > 0 {
                output.append("Content-Length: \(contentLength)")
                if bodyBytes != contentLength {
                    output.append("⚠️  Size Mismatch: Expected \(contentLength), Got \(bodyBytes)")
                }
            }
        }
        
        // Response Body
        if let body = response["body"] as? String {
            output.append("\n--- Response Body ---")
            output.append(body)
        }
        
        // Error Information
        if let error = response["error"] as? Bool, error == true {
            output.append("\n--- Error Details ---")
            if let errorDesc = response["error_description"] as? String {
                output.append("Error: \(errorDesc)")
            }
            if let errorType = response["error_type"] as? String {
                output.append("Type: \(errorType)")
            }
        }
        
        // Request Info
        if let url = response["url"] as? String {
            output.append("\n--- Request Info ---")
            output.append("URL: \(url)")
        }
        if let method = response["method"] as? String {
            output.append("Method: \(method)")
        }
        
        return output.joined(separator: "\n")
    }
    
    // MARK: - Actions
    
    private func copyToClipboard() {
        UIPasteboard.general.string = formattedDataString
        showCopySuccessAlert = true
    }
}
