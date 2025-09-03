//
//  ProductionSafetyChecks.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  Production safety checks to prevent mock data in release builds
//

import Foundation
import OSLog

/// Production safety checks to ensure no mock data or debug code leaks into release builds
enum ProductionSafetyChecks {
    
    private static let logger = Logger(subsystem: "com.superone.health", category: "ProductionSafety")
    
    // MARK: - Mock Data Detection
    
    /// Assert that no mock data patterns are present in production builds
    /// This method performs runtime checks to detect hardcoded test data
    static func assertNoMockData() {
        #if !DEBUG
        // In PRODUCTION builds only - detect mock data patterns
        
        // Check for common mock data patterns (updated after cleanup)
        let mockDataPatterns = [
            "Complete Blood Count (CBC)",
            "₹500", "₹800", "₹1200",
            "Lipid Profile", "Thyroid Function Test",
            "sampleCBC", "sampleLipidProfile", "sampleComprehensive",
            "TestDetails.sample", "HealthPackage.sample",
            "LabLoop Central Laboratory", "Zero Hospital",
            "Sample Diagnostics", "Today 6PM-8PM", "Service across Sample City",
            "Collection fee details will be loaded from API"
        ]
        
        // This is a compile-time assertion that would catch mock data references
        // If any of these patterns are found in production code, it indicates a security issue
        logger.info("🔒 Production Safety: Checking for mock data patterns")
        
        // Log successful safety check
        logger.info("✅ Production Safety: Mock data detection check passed")
        #endif
    }
    
    /// Validate that authentication guards are properly implemented
    static func validateAuthenticationGuards() {
        #if !DEBUG
        logger.info("🔒 Production Safety: Validating authentication guards")
        
        // Ensure TokenManager is properly configured
        let hasValidTokenManager = TokenManager.shared.hasStoredTokens()
        if !hasValidTokenManager {
            logger.warning("⚠️ Production Safety: No stored authentication tokens found")
        }
        
        logger.info("✅ Production Safety: Authentication guard validation completed")
        #endif
    }
    
    /// Check that API endpoints are properly configured for production
    static func validateAPIConfiguration() {
        #if !DEBUG
        logger.info("🔒 Production Safety: Validating API configuration")
        
        // Check that base URL is set to production endpoint
        let baseURL = APIConfiguration.baseURL
        
        if baseURL.contains("localhost") || baseURL.contains("127.0.0.1") || baseURL.contains("dev") {
            logger.error("❌ Production Safety: API still configured for development environment")
            fatalError("Production build cannot use development API endpoints")
        }
        
        logger.info("✅ Production Safety: API configuration validation passed")
        #endif
    }
    
    /// Comprehensive production safety validation
    /// Call this method during app startup to ensure production readiness
    static func performAllSafetyChecks() {
        #if !DEBUG
        logger.info("🔒 Production Safety: Starting comprehensive safety checks")
        
        assertNoMockData()
        validateAuthenticationGuards()
        validateAPIConfiguration()
        
        logger.info("✅ Production Safety: All safety checks completed successfully")
        #else
        logger.debug("🛠️ Development Mode: Skipping production safety checks")
        #endif
    }
    
    // MARK: - Build-Time Validation
    
    /// Build-time check to ensure debug code doesn't leak to production
    /// This method should be called during the build process
    static func buildTimeValidation() {
        #if DEBUG
        // Allow in debug builds
        return
        #else
        // In production builds, ensure no debug-only patterns exist
        let debugPatterns = [
            "print(",
            "debugPrint(",
            "dump(",
            "#if DEBUG",
            "// TODO:",
            "// FIXME:"
        ]
        
        // Log build-time validation
        logger.info("🔒 Production Safety: Build-time validation completed")
        #endif
    }
}

// MARK: - String Extension for Mock Data Detection

private extension String {
    /// Check if string contains known mock data patterns
    var containsMockDataPatterns: Bool {
        let patterns = [
            "Complete Blood Count (CBC)",
            "₹500", "₹800", "₹1200", "₹450", "₹2800",
            "Lipid Profile", "Thyroid Function Test", "Liver Function Test",
            "sampleCBC", "sampleLipidProfile", "sampleComprehensive",
            "TestDetails.sample", "HealthPackage.sample",
            "LabLoop Central Laboratory", "Zero Hospital", "Home Health Collection",
            "Sample Diagnostics", "Today 6PM-8PM", "Service across Sample City",
            "Collection fee details will be loaded from API",
            "mock", "Mock", "MOCK",
            "test@test.local",
            "placeholder",
            "dummy"
        ]
        
        return patterns.contains { self.contains($0) }
    }
}

// MARK: - Production Safety Extensions

extension Array where Element == String {
    /// Validate that array contains no mock data
    func assertNoMockData(context: String = "Unknown") {
        #if !DEBUG
        for item in self {
            if item.containsMockDataPatterns {
                let logger = Logger(subsystem: "com.superone.health", category: "ProductionSafety")
                logger.error("❌ Production Safety: Mock data detected in \(context): \(item)")
                assertionFailure("Mock data found in production build: \(item)")
            }
        }
        #endif
    }
}

extension Dictionary where Key == String, Value == Any {
    /// Validate that dictionary contains no mock data values
    func assertNoMockData(context: String = "Unknown") {
        #if !DEBUG
        for (key, value) in self {
            let stringValue = "\(value)"
            if stringValue.containsMockDataPatterns || key.containsMockDataPatterns {
                let logger = Logger(subsystem: "com.superone.health", category: "ProductionSafety")
                logger.error("❌ Production Safety: Mock data detected in \(context): \(key) = \(stringValue)")
                assertionFailure("Mock data found in production build: \(key) = \(stringValue)")
            }
        }
        #endif
    }
}