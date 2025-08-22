import Foundation
import Security

/// Handles keychain data migration between app versions
class KeychainMigration {
    
    // MARK: - Migration Versions
    enum MigrationVersion: String, CaseIterable, Comparable {
        case v1_0 = "1.0"
        case v2_0 = "2.0"
        
        nonisolated var versionNumber: Double {
            switch self {
            case .v1_0:
                return 1.0
            case .v2_0:
                return 2.0
            }
        }
        
        nonisolated static func < (lhs: MigrationVersion, rhs: MigrationVersion) -> Bool {
            return lhs.versionNumber < rhs.versionNumber
        }
    }
    
    // MARK: - Migration Errors
    enum MigrationError: Error, @preconcurrency LocalizedError {
        case unsupportedVersion(String)
        case migrationFailed(from: String, to: String, underlying: Error?)
        case dataCorruption(key: String)
        case backupFailed
        case rollbackFailed
        case insufficientStorage
        case migrationInProgress
        
        var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let version):
                return "Unsupported keychain version: \(version)"
            case .migrationFailed(let from, let to, let underlying):
                let underlyingMsg = underlying?.localizedDescription ?? "unknown error"
                return "Migration failed from \(from) to \(to): \(underlyingMsg)"
            case .dataCorruption(let key):
                return "Data corruption detected for key: \(key)"
            case .backupFailed:
                return "Failed to create migration backup"
            case .rollbackFailed:
                return "Failed to rollback migration"
            case .insufficientStorage:
                return "Insufficient storage space for migration"
            case .migrationInProgress:
                return "Migration is already in progress"
            }
        }
        
        var failureReason: String? {
            switch self {
            case .unsupportedVersion(let version):
                return "Keychain version \(version) is not supported by this app version"
            case .migrationFailed(let from, let to, let underlying):
                return "Migration process from version \(from) to \(to) encountered an error: \(underlying?.localizedDescription ?? "unknown")"
            case .dataCorruption(let key):
                return "Keychain data for key '\(key)' appears to be corrupted or invalid"
            case .backupFailed:
                return "Unable to create backup of existing keychain data before migration"
            case .rollbackFailed:
                return "Migration failed and rollback to previous state was unsuccessful"
            case .insufficientStorage:
                return "Device does not have enough storage space to complete migration"
            case .migrationInProgress:
                return "Another migration process is currently running"
            }
        }
        
        var helpAnchor: String? {
            switch self {
            case .unsupportedVersion:
                return "unsupported-version-help"
            case .migrationFailed:
                return "migration-failed-help"
            case .dataCorruption:
                return "data-corruption-help"
            case .backupFailed:
                return "backup-failed-help"
            case .rollbackFailed:
                return "rollback-failed-help"
            case .insufficientStorage:
                return "insufficient-storage-help"
            case .migrationInProgress:
                return "migration-in-progress-help"
            }
        }
    }
    
    // MARK: - Migration Status
    enum MigrationStatus: Equatable {
        case notRequired
        case required(from: MigrationVersion, to: MigrationVersion)
        case inProgress
        case completed
        case failed(Error)
        
        static func == (lhs: MigrationStatus, rhs: MigrationStatus) -> Bool {
            switch (lhs, rhs) {
            case (.notRequired, .notRequired),
                 (.inProgress, .inProgress),
                 (.completed, .completed):
                return true
            case (.required(let from1, let to1), .required(let from2, let to2)):
                return from1 == from2 && to1 == to2
            case (.failed, .failed):
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Private Properties
    private let queue = DispatchQueue(label: "keychain.migration", qos: .utility)
    private let versionKey = "keychain_version"
    private let migrationLockKey = "migration_in_progress"
    private let backupPrefix = "backup_"
    
    // MARK: - Singleton
    static let shared = KeychainMigration()
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check if migration is needed
    nonisolated func checkMigrationStatus() throws -> MigrationStatus {
        let currentVersionString: String = try KeychainHelper.retrieve(key: versionKey) ?? "1.0"
        let targetVersionString = KeychainHelper.keychainVersion
        
        guard let currentVersion = MigrationVersion(rawValue: currentVersionString) else {
            throw MigrationError.unsupportedVersion(currentVersionString)
        }
        
        guard let targetVersion = MigrationVersion(rawValue: targetVersionString) else {
            throw MigrationError.unsupportedVersion(targetVersionString)
        }
        
        // Check if migration is already in progress
        if KeychainHelper.exists(key: migrationLockKey) {
            return .inProgress
        }
        
        if currentVersion < targetVersion {
            return .required(from: currentVersion, to: targetVersion)
        } else {
            return .notRequired
        }
    }
    
    /// Perform migration if needed
    func migrateIfNeeded() async throws {
        let status = try checkMigrationStatus()
        
        switch status {
        case .notRequired, .completed:
            return
        case .inProgress:
            throw MigrationError.migrationInProgress
        case .required(let from, let to):
            try await performMigration(from: from, to: to)
        case .failed(let error):
            throw error
        }
    }
    
    /// Force migration (for debugging/testing)
    func forceMigration(from: MigrationVersion, to: MigrationVersion) async throws {
        try await performMigration(from: from, to: to)
    }
    
    /// Reset migration state (for debugging/testing)
    nonisolated func resetMigrationState() throws {
        try KeychainHelper.delete(key: migrationLockKey)
        
        // Clean up any backup keys
        let allKeys = getAllKeychainKeys()
        for key in allKeys where key.hasPrefix(backupPrefix) {
            try? KeychainHelper.delete(key: key)
        }
    }
    
    // MARK: - Private Migration Methods
    
    private func performMigration(from: MigrationVersion, to: MigrationVersion) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                do {
                    try self?.executeMigration(from: from, to: to)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    nonisolated private func executeMigration(from: MigrationVersion, to: MigrationVersion) throws {
        // Set migration lock
        try KeychainHelper.store(key: migrationLockKey, value: "true")
        
        do {
            // Create backup
            try createBackup()
            
            // Perform version-specific migrations
            try executeMigrationSteps(from: from, to: to)
            
            // Update version
            try KeychainHelper.store(key: versionKey, value: to.rawValue)
            
            // Clean up backup and lock
            try cleanupMigration()
            
            if AppConfiguration.isDebug {
            }
            
        } catch {
            // Attempt rollback
            do {
                try rollbackMigration()
            } catch {
                if AppConfiguration.isDebug {
                }
            }
            
            throw MigrationError.migrationFailed(from: from.rawValue, to: to.rawValue, underlying: error)
        }
    }
    
    nonisolated private func executeMigrationSteps(from: MigrationVersion, to: MigrationVersion) throws {
        let allVersions = MigrationVersion.allCases.sorted()
        
        guard let fromIndex = allVersions.firstIndex(of: from),
              let toIndex = allVersions.firstIndex(of: to) else {
            throw MigrationError.unsupportedVersion("Invalid version range")
        }
        
        // Execute migrations in sequence
        for i in fromIndex..<toIndex {
            let currentVersion = allVersions[i]
            let nextVersion = allVersions[i + 1]
            
            try executeSingleMigration(from: currentVersion, to: nextVersion)
        }
    }
    
    nonisolated private func executeSingleMigration(from: MigrationVersion, to: MigrationVersion) throws {
        switch (from, to) {
        case (.v1_0, .v2_0):
            try migrateV1ToV2()
        default:
            if AppConfiguration.isDebug {
            }
        }
    }
    
    // MARK: - Version-Specific Migrations
    
    /// Migrate from version 1.0 to 2.0
    /// - Changes: Convert plain string tokens to TokenData structure with expiration
    nonisolated private func migrateV1ToV2() throws {
        let keysToMigrate = [
            AppConfig.KeychainKeys.authToken,
            AppConfig.KeychainKeys.refreshToken
        ]
        
        for key in keysToMigrate {
            if let existingToken: String = try KeychainHelper.retrieve(key: key) {
                // Validate that it's a plain string (not already TokenData)
                if isValidV1Token(existingToken) {
                    // Use KeychainHelper's shared instance to store with expiration
                    let expirationDate = getDefaultExpirationDate(for: key)
                    
                    // Delete the old token first
                    try KeychainHelper.delete(key: key)
                    
                    // Store with the new format using the enhanced method
                    if let expirationDate = expirationDate {
                        try KeychainHelper.shared.storeWithExpiration(
                            token: existingToken, 
                            for: key, 
                            expirationDate: expirationDate
                        )
                    } else {
                        try KeychainHelper.shared.store(token: existingToken, for: key)
                    }
                    
                    if AppConfiguration.isDebug {
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    nonisolated private func createBackup() throws {
        let keysToBackup = [
            AppConfig.KeychainKeys.authToken,
            AppConfig.KeychainKeys.refreshToken,
            AppConfig.KeychainKeys.userCredentials,
            AppConfig.KeychainKeys.biometricData,
            versionKey
        ]
        
        for key in keysToBackup {
            if let data: Data = try KeychainHelper.retrieve(key: key) {
                let backupKey = backupPrefix + key
                try KeychainHelper.store(key: backupKey, data: data)
            }
        }
    }
    
    nonisolated private func rollbackMigration() throws {
        let allKeys = getAllKeychainKeys()
        let backupKeys = allKeys.filter { $0.hasPrefix(backupPrefix) }
        
        for backupKey in backupKeys {
            let originalKey = String(backupKey.dropFirst(backupPrefix.count))
            
            if let backupData: Data = try KeychainHelper.retrieve(key: backupKey) {
                try KeychainHelper.delete(key: originalKey)
                try KeychainHelper.store(key: originalKey, data: backupData)
            }
        }
        
        // Clean up
        try cleanupMigration()
    }
    
    nonisolated private func cleanupMigration() throws {
        // Remove migration lock
        try KeychainHelper.delete(key: migrationLockKey)
        
        // Remove backup keys
        let allKeys = getAllKeychainKeys()
        for key in allKeys where key.hasPrefix(backupPrefix) {
            try KeychainHelper.delete(key: key)
        }
    }
    
    nonisolated private func getAllKeychainKeys() -> [String] {
        // This is a simplified implementation
        // In practice, you might want to maintain a registry of keys
        // or use a more sophisticated approach to enumerate keychain items
        return [
            AppConfig.KeychainKeys.authToken,
            AppConfig.KeychainKeys.refreshToken,
            AppConfig.KeychainKeys.userCredentials,
            AppConfig.KeychainKeys.biometricData,
            versionKey,
            migrationLockKey,
            "biometric_preference"
        ]
    }
    
    nonisolated private func isValidV1Token(_ token: String) -> Bool {
        // Check if it's a JWT token (basic validation)
        let components = token.components(separatedBy: ".")
        return components.count == 3 && !token.contains("{")
    }
    
    nonisolated private func getDefaultExpirationDate(for key: String) -> Date? {
        switch key {
        case AppConfig.KeychainKeys.authToken:
            // Auth tokens typically expire in 15 minutes
            return Date().addingTimeInterval(15 * 60)
        case AppConfig.KeychainKeys.refreshToken:
            // Refresh tokens typically expire in 7 days
            return Date().addingTimeInterval(7 * 24 * 60 * 60)
        default:
            return nil
        }
    }
}

// MARK: - Migration Reporting
extension KeychainMigration {
    
    /// Get migration history (for debugging/analytics)
    nonisolated func getMigrationHistory() -> [MigrationRecord] {
        // This could be enhanced to track migration history
        // For now, just return current version info
        let currentVersion: String = (try? KeychainHelper.retrieve(key: versionKey)) ?? "1.0"
        
        return [
            MigrationRecord(
                fromVersion: "unknown",
                toVersion: currentVersion,
                timestamp: Date(),
                success: true,
                duration: 0
            )
        ]
    }
    
    struct MigrationRecord {
        let fromVersion: String
        let toVersion: String
        let timestamp: Date
        let success: Bool
        let duration: TimeInterval
    }
}

// MARK: - KeychainHelper Extension for Migration Support
extension KeychainHelper {
    
}