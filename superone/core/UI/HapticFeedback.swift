import UIKit

/// Centralized haptic feedback utility for consistent feedback across the app
struct HapticFeedback {
    // Cached feedback generators to prevent blocking initialization
    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()
    
    /// Light impact haptic feedback
    static func light() {
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                impactLight.impactOccurred()
            }
        }
    }
    
    /// Medium impact haptic feedback
    static func medium() {
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                impactMedium.impactOccurred()
            }
        }
    }
    
    /// Heavy impact haptic feedback
    static func heavy() {
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                impactHeavy.impactOccurred()
            }
        }
    }
    
    /// Success notification haptic feedback
    static func success() {
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                notification.notificationOccurred(.success)
            }
        }
    }
    
    /// Warning notification haptic feedback
    static func warning() {
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                notification.notificationOccurred(.warning)
            }
        }
    }
    
    /// Error notification haptic feedback
    static func error() {
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                notification.notificationOccurred(.error)
            }
        }
    }
}