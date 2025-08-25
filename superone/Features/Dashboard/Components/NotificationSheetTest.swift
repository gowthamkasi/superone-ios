//
//  NotificationSheetTest.swift
//  SuperOne
//
//  Created by Claude Code on 2024-12-20.
//  Test view for notification sheet functionality
//

import SwiftUI

/// Test view to verify notification sheet implementation
@MainActor
struct NotificationSheetTest: View {
    @State private var showingSheet = false
    @State private var notificationCount = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Text("Notification System Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Notification button simulation
                Button(action: {
                    showingSheet = true
                }) {
                    ZStack {
                        Image(systemName: "bell")
                            .font(.system(size: 32))
                            .foregroundColor(HealthColors.primary)
                        
                        if notificationCount > 0 {
                            Text("\(notificationCount)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 20, minHeight: 20)
                                .background(Circle().fill(Color.red))
                                .offset(x: 16, y: -16)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(HealthColors.accent.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(HealthColors.primary, lineWidth: 1)
                            )
                    )
                }
                
                Text("Tap the bell to open notifications")
                    .font(.subheadline)
                    .foregroundColor(HealthColors.secondaryText)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Test")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingSheet) {
            NotificationSheet()
                .onDisappear {
                    // Simulate count reduction after viewing
                    if notificationCount > 0 {
                        notificationCount = max(0, notificationCount - 1)
                    }
                }
        }
    }
}

#Preview {
    NotificationSheetTest()
}