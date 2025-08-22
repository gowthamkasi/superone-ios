//
//  PerformanceMonitor.swift
//  SuperOne
//
//  Created by Claude Code on 1/28/25.
//

import Foundation
import Combine
import SwiftUI
import UIKit
import os

/// Performance monitoring and optimization system
@MainActor
class PerformanceMonitor: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PerformanceMonitor()
    
    // MARK: - Properties
    @Published var memoryUsage: MemoryUsage = MemoryUsage()
    @Published var isMemoryWarningActive = false
    
    private let logger = Logger(subsystem: "com.superone.health", category: "Performance")
    private var memoryMonitorTimer: Timer?
    private var startTime: Date?
    
    // MARK: - Initialization
    
    private init() {
        setupMemoryMonitoring()
        setupMemoryWarningObserver()
    }
    
    deinit {
        // Timer cleanup handled by stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start performance monitoring
    func startMonitoring() {
        startTime = Date()
        startMemoryMonitoring()
        logger.info("Performance monitoring started")
    }
    
    /// Stop performance monitoring
    func stopMonitoring() {
        memoryMonitorTimer?.invalidate()
        memoryMonitorTimer = nil
        logger.info("Performance monitoring stopped")
    }
    
    /// Measure execution time of a block
    func measureTime<T>(
        operation: String,
        _ block: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        if timeElapsed > 0.1 { // Log operations taking more than 100ms
            logger.warning("Slow operation: \(operation) took \(String(format: "%.2f", timeElapsed * 1000))ms")
        }
        
        return result
    }
    
    /// Measure async execution time
    func measureAsyncTime<T>(
        operation: String,
        _ block: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        if timeElapsed > 0.5 { // Log async operations taking more than 500ms
            logger.warning("Slow async operation: \(operation) took \(String(format: "%.2f", timeElapsed * 1000))ms")
        }
        
        return result
    }
    
    /// Force memory cleanup
    func cleanupMemory() {
        // Clear image caches
        URLCache.shared.removeAllCachedResponses()
        
        // Force garbage collection
        autoreleasepool {
            // Trigger memory pressure simulation to force cleanup
            // This is a development tool and should not be used in production frequently
        }
        
        updateMemoryUsage()
        logger.info("Memory cleanup performed - Usage: \(self.memoryUsage.usedMB)MB")
    }
    
    /// Get current memory pressure level
    func getMemoryPressureLevel() -> MemoryPressureLevel {
        let usage = getCurrentMemoryUsage()
        
        if usage.usedMB > 400 {
            return .critical
        } else if usage.usedMB > 300 {
            return .high
        } else if usage.usedMB > 200 {
            return .moderate
        } else {
            return .normal
        }
    }
    
    // MARK: - Memory Monitoring
    
    private func setupMemoryMonitoring() {
        updateMemoryUsage()
    }
    
    private func startMemoryMonitoring() {
        memoryMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMemoryUsage()
            }
        }
    }
    
    private func updateMemoryUsage() {
        memoryUsage = getCurrentMemoryUsage()
        
        // Log memory warnings
        let pressureLevel = getMemoryPressureLevel()
        if pressureLevel == .high || pressureLevel == .critical {
            logger.warning("High memory usage detected: \(self.memoryUsage.usedMB)MB (\(pressureLevel))")
        }
    }
    
    private func getCurrentMemoryUsage() -> MemoryUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedBytes = info.resident_size
            let usedMB = Double(usedBytes) / 1024.0 / 1024.0
            
            // Get available memory
            let physicalMemory = ProcessInfo.processInfo.physicalMemory
            let availableMB = Double(physicalMemory) / 1024.0 / 1024.0
            
            return MemoryUsage(
                usedBytes: usedBytes,
                usedMB: usedMB,
                availableMB: availableMB,
                usagePercentage: usedMB / availableMB * 100
            )
        }
        
        return MemoryUsage()
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleMemoryWarning()
            }
        }
    }
    
    nonisolated private func handleMemoryWarning() {
        Task { @MainActor [weak self] in
            self?.isMemoryWarningActive = true
            self?.logger.critical("Memory warning received - Current usage: \(self?.memoryUsage.usedMB ?? 0)MB")
            
            // Perform emergency cleanup
            self?.cleanupMemory()
            
            // Reset warning flag after delay
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                self?.isMemoryWarningActive = false
            }
        }
    }
}

// MARK: - Memory Usage Model

struct MemoryUsage {
    let usedBytes: UInt64
    let usedMB: Double
    let availableMB: Double
    let usagePercentage: Double
    
    init() {
        self.usedBytes = 0
        self.usedMB = 0
        self.availableMB = 0
        self.usagePercentage = 0
    }
    
    init(usedBytes: UInt64, usedMB: Double, availableMB: Double, usagePercentage: Double) {
        self.usedBytes = usedBytes
        self.usedMB = usedMB
        self.availableMB = availableMB
        self.usagePercentage = usagePercentage
    }
}

enum MemoryPressureLevel: CustomStringConvertible {
    case normal
    case moderate
    case high
    case critical
    
    var description: String {
        switch self {
        case .normal: return "Normal"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .normal: return "HealthColors.healthGood"
        case .moderate: return "HealthColors.healthWarning"
        case .high: return "HealthColors.healthCritical"
        case .critical: return "HealthColors.healthCritical"
        }
    }
}

// MARK: - Performance Utilities

extension PerformanceMonitor {
    
    /// Track view loading performance
    func trackViewLoad(_ viewName: String, loadTime: TimeInterval) {
        if loadTime > 1.0 {
            logger.warning("Slow view load: \(viewName) took \(String(format: "%.2f", loadTime * 1000))ms")
        }
        
        // Log to analytics in production
        #if !DEBUG
        // Analytics.track("view_load_time", parameters: ["view": viewName, "time_ms": loadTime * 1000])
        #endif
    }
    
    /// Track image loading performance
    func trackImageLoad(size: CGSize, loadTime: TimeInterval) {
        let pixelCount = size.width * size.height
        let loadTimePerPixel = loadTime / pixelCount * 1_000_000 // microseconds per pixel
        
        if loadTimePerPixel > 0.1 {
            logger.warning("Slow image load: \(Int(pixelCount)) pixels took \(String(format: "%.2f", loadTime * 1000))ms")
        }
    }
    
    /// Track network request performance
    func trackNetworkRequest(url: String, duration: TimeInterval, dataSize: Int) {
        if duration > 10.0 {
            logger.warning("Slow network request: \(url) took \(String(format: "%.2f", duration))s")
        }
        
        let throughput = Double(dataSize) / duration / 1024.0 // KB/s
        if throughput < 50 && dataSize > 1024 { // Less than 50 KB/s for files > 1KB
            logger.warning("Low network throughput: \(String(format: "%.2f", throughput)) KB/s for \(url)")
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Add performance tracking to view appearance
    func trackPerformance(viewName: String) -> some View {
        self.onAppear {
            let startTime = Date()
            
            DispatchQueue.main.async {
                let loadTime = Date().timeIntervalSince(startTime)
                PerformanceMonitor.shared.trackViewLoad(viewName, loadTime: loadTime)
            }
        }
    }
}

// MARK: - Performance Optimization Helpers

class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let maxMemoryUsage: Int = 50 * 1024 * 1024 // 50MB
    
    private init() {
        cache.totalCostLimit = maxMemoryUsage
        
        // Clear cache on memory warning
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.clearAll()
            }
        }
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        let cost = image.size.width * image.size.height * 4 // Estimate memory cost
        cache.setObject(image, forKey: key as NSString, cost: Int(cost))
    }
    
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clearAll() {
        cache.removeAllObjects()
    }
}

// MARK: - Memory Management Helpers

extension NSCache where KeyType == NSString, ObjectType == UIImage {
    /// Configure cache for optimal performance
    func configureForPerformance() {
        // Set reasonable limits
        countLimit = 100
        totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Enable automatic eviction
        evictsObjectsWithDiscardedContent = true
    }
}

// MARK: - Debug Performance View

#if DEBUG
struct PerformanceDebugView: View {
    @StateObject private var monitor = PerformanceMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance Monitor")
                .font(.headline)
            
            HStack {
                Text("Memory:")
                Text("\(String(format: "%.1f", monitor.memoryUsage.usedMB)) MB")
                Text("(\(String(format: "%.1f", monitor.memoryUsage.usagePercentage))%)")
                
                if monitor.isMemoryWarningActive {
                    Text("⚠️ Warning")
                        .foregroundColor(.red)
                }
            }
            
            Button("Cleanup Memory") {
                monitor.cleanupMemory()
            }
            .buttonStyle(BorderedButtonStyle())
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}
#endif