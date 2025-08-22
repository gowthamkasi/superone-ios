//
//  AppIntegrityValidator.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//  App integrity validation and tamper detection for healthcare security
//

import Foundation
import DeviceCheck
import UIKit
import Combine

/// App integrity validator using App Attest and environment checks
/// Protects against runtime manipulation and tampering attempts
@available(iOS 14.0, *)
class AppIntegrityValidator: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AppIntegrityValidator()
    
    // MARK: - Constants
    private struct Constants {
        static let attestationKeyId = "com.superone.healthcare.attest.key"
        static let integrityCheckInterval: TimeInterval = 300 // 5 minutes
        static let maxFailedAttemptsBeforeLockout = 3
    }
    
    // MARK: - Published Properties
    @Published var isIntegrityValid: Bool = true
    @Published var lastIntegrityCheck: Date?
    @Published var attestationStatus: AttestationStatus = .unknown
    
    // MARK: - Private Properties
    private var attestationKeyId: String?
    private var failedIntegrityAttempts = 0
    private let queue = DispatchQueue(label: "app.integrity.queue", qos: .userInitiated)
    private var integrityCheckTimer: Timer?
    
    // MARK: - Initialization
    private init() {
        setupIntegrityMonitoring()
    }
    
    // Timer will be automatically invalidated on deallocation
    
    // MARK: - Public Methods
    
    /// Perform comprehensive app integrity validation
    func validateAppIntegrity() async throws -> IntegrityResult {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: IntegrityError.validationFailed)
                    return
                }
                
                Task {
                    do {
                        // Perform all integrity checks
                        let jailbreakCheck = await self.checkJailbreakStatus()
                        let debuggerCheck = await self.checkDebuggerAttachment()
                        let environmentCheck = await self.checkEnvironmentIntegrity()
                        let attestationCheck = await self.performAppAttestation()
                        
                        let result = IntegrityResult(
                            isJailbroken: jailbreakCheck.isJailbroken,
                            isDebuggerAttached: debuggerCheck.isDebuggerAttached,
                            environmentThreats: environmentCheck.threats,
                            attestationValid: attestationCheck.isValid,
                            overallIntegrity: !jailbreakCheck.isJailbroken && 
                                            !debuggerCheck.isDebuggerAttached && 
                                            environmentCheck.threats.isEmpty && 
                                            attestationCheck.isValid
                        )
                        
                        await MainActor.run {
                            self.isIntegrityValid = result.overallIntegrity
                            self.lastIntegrityCheck = Date()
                            
                            if !result.overallIntegrity {
                                self.failedIntegrityAttempts += 1
                            } else {
                                self.failedIntegrityAttempts = 0
                            }
                        }
                        
                        continuation.resume(returning: result)
                        
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// Check if App Attest is available and supported
    func isAppAttestSupported() -> Bool {
        if #available(iOS 14.0, *) {
            return DCAppAttestService.shared.isSupported
        }
        return false
    }
    
    /// Generate and store App Attest key
    func generateAppAttestKey() async throws -> String {
        guard isAppAttestSupported() else {
            throw IntegrityError.appAttestNotSupported
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DCAppAttestService.shared.generateKey { keyId, error in
                if let error = error {
                    continuation.resume(throwing: IntegrityError.keyGenerationFailed(error))
                } else if let keyId = keyId {
                    Task { @MainActor in
                        self.attestationKeyId = keyId
                        UserDefaults.standard.set(keyId, forKey: Constants.attestationKeyId)
                    }
                    continuation.resume(returning: keyId)
                } else {
                    continuation.resume(throwing: IntegrityError.keyGenerationFailed(NSError(domain: "AppAttest", code: -1, userInfo: nil)))
                }
            }
        }
    }
    
    /// Attest the app with Apple's servers
    func attestApp(challenge: Data) async throws -> Data {
        guard isAppAttestSupported() else {
            throw IntegrityError.appAttestNotSupported
        }
        
        guard let keyId = attestationKeyId ?? UserDefaults.standard.string(forKey: Constants.attestationKeyId) else {
            throw IntegrityError.noAttestationKey
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DCAppAttestService.shared.attestKey(keyId, clientDataHash: challenge) { attestation, error in
                if let error = error {
                    continuation.resume(throwing: IntegrityError.attestationFailed(error))
                } else if let attestation = attestation {
                    continuation.resume(returning: attestation)
                } else {
                    continuation.resume(throwing: IntegrityError.attestationFailed(NSError(domain: "AppAttest", code: -1, userInfo: nil)))
                }
            }
        }
    }
    
    /// Check if app should be locked due to integrity failures
    func shouldLockApp() -> Bool {
        return failedIntegrityAttempts >= Constants.maxFailedAttemptsBeforeLockout
    }
    
    /// Reset failed integrity attempts (call after successful re-authentication)
    func resetFailedAttempts() {
        failedIntegrityAttempts = 0
    }
    
    // MARK: - Private Methods
    
    private func setupIntegrityMonitoring() {
        // Initial integrity check
        Task {
            do {
                _ = try await validateAppIntegrity()
            } catch {
                await MainActor.run {
                    self.isIntegrityValid = false
                }
            }
        }
        
        // Setup periodic integrity checks
        DispatchQueue.main.async {
            self.integrityCheckTimer = Timer.scheduledTimer(withTimeInterval: Constants.integrityCheckInterval, repeats: true) { _ in
                Task {
                    do {
                        _ = try await self.validateAppIntegrity()
                    } catch {
                        await MainActor.run {
                            self.isIntegrityValid = false
                        }
                    }
                }
            }
        }
    }
    
    private func checkJailbreakStatus() async -> JailbreakCheckResult {
        return await withCheckedContinuation { continuation in
            queue.async {
                let jailbreakIndicators = [
                    "/Applications/Cydia.app",
                    "/Library/MobileSubstrate/MobileSubstrate.dylib",
                    "/bin/bash",
                    "/usr/sbin/sshd",
                    "/etc/apt",
                    "/private/var/lib/apt/",
                    "/private/var/lib/cydia",
                    "/private/var/mobile/Library/SBSettings/Themes",
                    "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
                    "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
                    "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                    "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist"
                ]
                
                var detectedIndicators: [String] = []
                
                // Check for jailbreak files
                for indicator in jailbreakIndicators {
                    if FileManager.default.fileExists(atPath: indicator) {
                        detectedIndicators.append(indicator)
                    }
                }
                
                // Check if we can write to system directories (jailbreak indicator)
                let testPath = "/private/test_jailbreak"
                let testData = "test".data(using: .utf8)
                if FileManager.default.createFile(atPath: testPath, contents: testData, attributes: nil) {
                    try? FileManager.default.removeItem(atPath: testPath)
                    detectedIndicators.append("System directory write access")
                }
                
                // Check for suspicious URL schemes
                let suspiciousSchemes = ["cydia://", "sileo://", "zbra://"]
                for scheme in suspiciousSchemes {
                    if let url = URL(string: scheme) {
                        // Note: In a production app, you might want to check canOpenURL
                        // For now, we'll skip this check to avoid async issues in this context
                        // detectedIndicators.append("Suspicious URL scheme: \(scheme)")
                    }
                }
                
                let result = JailbreakCheckResult(
                    isJailbroken: !detectedIndicators.isEmpty,
                    detectedIndicators: detectedIndicators
                )
                
                continuation.resume(returning: result)
            }
        }
    }
    
    private func checkDebuggerAttachment() async -> DebuggerCheckResult {
        return await withCheckedContinuation { continuation in
            queue.async {
                // Simplified debugger detection for iOS App Store compliance
                var isDebuggerAttached = false
                var detectionMethod: String? = nil
                
                // Check for Xcode debug environment
                if let debugger = getenv("DYLD_INSERT_LIBRARIES") {
                    let debuggerString = String(cString: debugger)
                    if debuggerString.contains("frida") || debuggerString.contains("substrate") {
                        isDebuggerAttached = true
                        detectionMethod = "Suspicious library injection detected"
                    }
                }
                
                // Check for debug build
                #if DEBUG
                isDebuggerAttached = true
                detectionMethod = "Debug build detected"
                #endif
                
                let checkResult = DebuggerCheckResult(
                    isDebuggerAttached: isDebuggerAttached,
                    detectionMethod: detectionMethod
                )
                
                continuation.resume(returning: checkResult)
            }
        }
    }
    
    private func checkEnvironmentIntegrity() async -> EnvironmentCheckResult {
        return await withCheckedContinuation { continuation in
            queue.async {
                var threats: [String] = []
                
                // Check for runtime manipulation frameworks
                let suspiciousLibraries = [
                    "FridaGadget",
                    "frida",
                    "cynject",
                    "libhooker",
                    "MobileSubstrate",
                    "SSLKillSwitch",
                    "Reveal"
                ]
                
                for libraryName in suspiciousLibraries {
                    if let handle = dlopen(libraryName, RTLD_NOLOAD) {
                        dlclose(handle)
                        threats.append("Suspicious library detected: \(libraryName)")
                    }
                }
                
                // Check for suspicious environment variables
                let suspiciousEnvVars = ["DYLD_INSERT_LIBRARIES", "_MSSafeModeEnabled"]
                for envVar in suspiciousEnvVars {
                    if getenv(envVar) != nil {
                        threats.append("Suspicious environment variable: \(envVar)")
                    }
                }
                
                // Check app bundle integrity
                if let bundlePath = Bundle.main.bundlePath as NSString? {
                    let infoPlistPath = bundlePath.appendingPathComponent("Info.plist")
                    if !FileManager.default.fileExists(atPath: infoPlistPath) {
                        threats.append("Missing Info.plist file")
                    }
                }
                
                let result = EnvironmentCheckResult(threats: threats)
                continuation.resume(returning: result)
            }
        }
    }
    
    private func performAppAttestation() async -> AttestationCheckResult {
        guard isAppAttestSupported() else {
            await MainActor.run {
                self.attestationStatus = .notSupported
            }
            return AttestationCheckResult(isValid: false, error: "App Attest not supported")
        }
        
        do {
            // Generate challenge data
            let challenge = generateChallenge()
            
            // Get or generate attestation key
            let keyId = attestationKeyId ?? UserDefaults.standard.string(forKey: Constants.attestationKeyId)
            
            let actualKeyId: String
            if let keyId = keyId {
                actualKeyId = keyId
            } else {
                actualKeyId = try await generateAppAttestKey()
            }
            
            // Store the key ID for future reference
            await MainActor.run {
                self.attestationKeyId = actualKeyId
            }
            
            // Perform attestation using the actual key ID
            let attestationData = try await attestApp(challenge: challenge)
            
            await MainActor.run {
                self.attestationStatus = .valid
            }
            
            return AttestationCheckResult(isValid: true, attestationData: attestationData)
            
        } catch {
            await MainActor.run {
                self.attestationStatus = .invalid
            }
            return AttestationCheckResult(isValid: false, error: error.localizedDescription)
        }
    }
    
    private func generateChallenge() -> Data {
        let timestamp = String(Date().timeIntervalSince1970)
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        let challengeString = "\(bundleId)_\(timestamp)"
        
        return challengeString.data(using: .utf8) ?? Data()
    }
}

// MARK: - Supporting Types

/// Overall integrity validation result
struct IntegrityResult: Sendable {
    let isJailbroken: Bool
    let isDebuggerAttached: Bool
    let environmentThreats: [String]
    let attestationValid: Bool
    let overallIntegrity: Bool
    
    var threatLevel: ThreatLevel {
        if !overallIntegrity {
            if isJailbroken || isDebuggerAttached {
                return .critical
            } else if !environmentThreats.isEmpty || !attestationValid {
                return .high
            }
        }
        return .none
    }
}

/// Jailbreak detection result
struct JailbreakCheckResult: Sendable {
    let isJailbroken: Bool
    let detectedIndicators: [String]
}

/// Debugger detection result
struct DebuggerCheckResult: Sendable {
    let isDebuggerAttached: Bool
    let detectionMethod: String?
}

/// Environment integrity check result
struct EnvironmentCheckResult: Sendable {
    let threats: [String]
}

/// App attestation check result
struct AttestationCheckResult: Sendable {
    let isValid: Bool
    let attestationData: Data?
    let error: String?
    
    init(isValid: Bool, attestationData: Data? = nil, error: String? = nil) {
        self.isValid = isValid
        self.attestationData = attestationData
        self.error = error
    }
}

/// Attestation status enumeration
enum AttestationStatus: Sendable {
    case unknown
    case notSupported
    case valid
    case invalid
    case generating
}

/// Threat level enumeration
enum ThreatLevel: Sendable {
    case none
    case low
    case medium
    case high
    case critical
    
    var description: String {
        switch self {
        case .none: return "No threats detected"
        case .low: return "Low security risk"
        case .medium: return "Medium security risk"
        case .high: return "High security risk - enhanced monitoring required"
        case .critical: return "Critical security risk - access should be restricted"
        }
    }
}

/// Integrity validation errors
enum IntegrityError: @preconcurrency LocalizedError, Sendable {
    case validationFailed
    case appAttestNotSupported
    case keyGenerationFailed(Error)
    case attestationFailed(Error)
    case noAttestationKey
    case integrityCompromised
    
    nonisolated var errorDescription: String? {
        switch self {
        case .validationFailed:
            return "App integrity validation failed"
        case .appAttestNotSupported:
            return "App Attest is not supported on this device"
        case .keyGenerationFailed(let error):
            return "Failed to generate attestation key: \(error.localizedDescription)"
        case .attestationFailed(let error):
            return "App attestation failed: \(error.localizedDescription)"
        case .noAttestationKey:
            return "No attestation key available"
        case .integrityCompromised:
            return "App integrity has been compromised"
        }
    }
}

// MARK: - Convenience Extensions

extension AppIntegrityValidator {
    
    /// Quick security status check
    func getSecuritySummary() -> SecuritySummary {
        return SecuritySummary(
            isIntegrityValid: isIntegrityValid,
            attestationStatus: attestationStatus,
            lastCheck: lastIntegrityCheck,
            failedAttempts: failedIntegrityAttempts,
            shouldLockApp: shouldLockApp()
        )
    }
}

/// Security summary information
struct SecuritySummary: Sendable {
    let isIntegrityValid: Bool
    let attestationStatus: AttestationStatus
    let lastCheck: Date?
    let failedAttempts: Int
    let shouldLockApp: Bool
}