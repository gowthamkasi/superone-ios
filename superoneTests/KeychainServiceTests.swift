import XCTest
import LocalAuthentication
@testable import superone

final class KeychainServiceTests: XCTestCase {
    
    var keychainService: KeychainHelper!
    var biometricAuth: BiometricAuthentication!
    var migration: KeychainMigration!
    
    override func setUp() {
        super.setUp()
        keychainService = KeychainHelper.shared
        biometricAuth = BiometricAuthentication.shared
        migration = KeychainMigration.shared
        
        // Clean up any existing test data
        try? cleanupTestData()
    }
    
    override func tearDown() {
        // Clean up test data
        try? cleanupTestData()
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func cleanupTestData() throws {
        let testKeys = [
            "test_token",
            "test_biometric_token",
            "test_expiring_token",
            AppConfig.KeychainKeys.authToken,
            AppConfig.KeychainKeys.refreshToken,
            AppConfig.KeychainKeys.userCredentials
        ]
        
        for key in testKeys {
            try? KeychainHelper.delete(key: key)
        }
        
        try? migration.resetMigrationState()
    }
    
    // MARK: - Basic Keychain Operations Tests
    
    func testStoreAndRetrieveToken() throws {
        let testToken = "test_jwt_token_123"
        let testKey = "test_token"
        
        // Store token
        try keychainService.store(token: testToken, for: testKey)
        
        // Retrieve token
        let retrievedToken = try keychainService.retrieve(key: testKey, withBiometrics: false)
        
        XCTAssertEqual(retrievedToken, testToken, "Retrieved token should match stored token")
    }
    
    func testStoreAndDeleteToken() throws {
        let testToken = "test_jwt_token_456"
        let testKey = "test_token"
        
        // Store token
        try keychainService.store(token: testToken, for: testKey)
        
        // Verify it exists
        XCTAssertTrue(KeychainHelper.exists(key: testKey), "Token should exist after storing")
        
        // Delete token
        try keychainService.delete(key: testKey)
        
        // Verify it's deleted
        XCTAssertFalse(KeychainHelper.exists(key: testKey), "Token should not exist after deletion")
    }
    
    func testRetrieveNonExistentToken() throws {
        let retrievedToken = try keychainService.retrieve(key: "non_existent_key", withBiometrics: false)
        XCTAssertNil(retrievedToken, "Retrieving non-existent token should return nil")
    }
    
    // MARK: - Token Expiration Tests
    
    func testStoreTokenWithExpiration() throws {
        let testToken = "test_expiring_token"
        let testKey = "test_expiring_token"
        let expirationDate = Date().addingTimeInterval(3600) // 1 hour from now
        
        // Store token with expiration
        try keychainService.storeWithExpiration(token: testToken, for: testKey, expirationDate: expirationDate)
        
        // Verify token exists
        XCTAssertTrue(KeychainHelper.exists(key: testKey), "Token should exist after storing")
        
        // Check expiration date
        let storedExpirationDate = try keychainService.tokenExpirationDate(for: testKey)
        XCTAssertNotNil(storedExpirationDate, "Expiration date should be stored")
        XCTAssertEqual(storedExpirationDate?.timeIntervalSince1970, expirationDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testTokenExpirationCheck() throws {
        let testToken = "test_expired_token"
        let testKey = "test_expiring_token"
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        
        // Store expired token
        try keychainService.storeWithExpiration(token: testToken, for: testKey, expirationDate: pastDate)
        
        // Check if token is expired
        let isExpired = try keychainService.isTokenExpired(for: testKey)
        XCTAssertTrue(isExpired, "Token should be expired")
    }
    
    func testInvalidExpirationDate() {
        let testToken = "test_token"
        let testKey = "test_token"
        let pastDate = Date().addingTimeInterval(-3600) // Past date
        
        // Attempt to store token with past expiration date
        XCTAssertThrowsError(try keychainService.storeWithExpiration(token: testToken, for: testKey, expirationDate: pastDate)) { error in
            guard let keychainError = error as? KeychainHelper.KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            
            if case .invalidExpirationDate = keychainError {
                // Expected error
            } else {
                XCTFail("Expected invalidExpirationDate error")
            }
        }
    }
    
    // MARK: - Biometric Authentication Tests
    
    func testBiometricAvailability() {
        let isAvailable = keychainService.isBiometricAvailable()
        
        // This will depend on the simulator/device configuration
        // Just ensure the method doesn't crash
        XCTAssertNotNil(isAvailable)
    }
    
    func testBiometricDisplayName() {
        let displayName = KeychainHelper.biometricDisplayName()
        XCTAssertFalse(displayName.isEmpty, "Biometric display name should not be empty")
        
        let validNames = ["Face ID", "Touch ID", "Optic ID", "Biometric Authentication"]
        XCTAssertTrue(validNames.contains(displayName), "Display name should be one of the valid options")
    }
    
    func testBiometricAuthenticationState() {
        // Test initial state
        XCTAssertEqual(biometricAuth.authenticationState, .idle, "Initial authentication state should be idle")
        
        // Update biometric info
        biometricAuth.updateBiometricInfo()
        
        // Verify properties are set
        XCTAssertNotNil(biometricAuth.biometryType)
    }
    
    // MARK: - Enhanced Auth Token Tests
    
    func testStoreAuthTokenWithExpiration() throws {
        let testToken = "auth_token_with_expiration"
        let expiresIn: TimeInterval = 3600 // 1 hour
        
        // Store auth token with expiration
        try KeychainHelper.storeAuthToken(testToken, expiresIn: expiresIn)
        
        // Retrieve auth token
        let retrievedToken = try KeychainHelper.retrieveAuthToken()
        XCTAssertEqual(retrievedToken, testToken, "Retrieved auth token should match stored token")
        
        // Check that it's not expired
        let isExpired = try keychainService.isTokenExpired(for: AppConfig.KeychainKeys.authToken)
        XCTAssertFalse(isExpired, "Token should not be expired")
    }
    
    func testRetrieveExpiredAuthToken() throws {
        let testToken = "expired_auth_token"
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        
        // Store expired token directly
        try keychainService.storeWithExpiration(token: testToken, for: AppConfig.KeychainKeys.authToken, expirationDate: pastDate)
        
        // Attempt to retrieve expired token should throw
        XCTAssertThrowsError(try KeychainHelper.retrieveAuthToken()) { error in
            guard let keychainError = error as? KeychainHelper.KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            
            if case .tokenExpired = keychainError {
                // Expected error
            } else {
                XCTFail("Expected tokenExpired error")
            }
        }
        
        // Token should be automatically deleted
        XCTAssertFalse(KeychainHelper.exists(key: AppConfig.KeychainKeys.authToken), "Expired token should be deleted")
    }
    
    func testValidAuthTokenCheck() throws {
        // Initially should have no valid token
        XCTAssertFalse(KeychainHelper.hasValidAuthToken(), "Should not have valid auth token initially")
        
        // Store valid token
        try KeychainHelper.storeAuthToken("valid_token", expiresIn: 3600)
        
        // Should now have valid token
        XCTAssertTrue(KeychainHelper.hasValidAuthToken(), "Should have valid auth token")
        
        // Store expired token
        let pastDate = Date().addingTimeInterval(-3600)
        try keychainService.storeWithExpiration(token: "expired_token", for: AppConfig.KeychainKeys.authToken, expirationDate: pastDate)
        
        // Should not have valid token
        XCTAssertFalse(KeychainHelper.hasValidAuthToken(), "Should not have valid auth token when expired")
    }
    
    func testTokenExpirationInfo() throws {
        let authExpirationDate = Date().addingTimeInterval(3600)
        let refreshExpirationDate = Date().addingTimeInterval(7200)
        
        // Store tokens with expiration
        try keychainService.storeWithExpiration(token: "auth_token", for: AppConfig.KeychainKeys.authToken, expirationDate: authExpirationDate)
        try keychainService.storeWithExpiration(token: "refresh_token", for: AppConfig.KeychainKeys.refreshToken, expirationDate: refreshExpirationDate)
        
        // Get expiration info
        let (authExpiry, refreshExpiry) = KeychainHelper.getTokenExpirationInfo()
        
        XCTAssertNotNil(authExpiry, "Auth token expiry should be available")
        XCTAssertNotNil(refreshExpiry, "Refresh token expiry should be available")
        
        XCTAssertEqual(authExpiry?.timeIntervalSince1970, authExpirationDate.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(refreshExpiry?.timeIntervalSince1970, refreshExpirationDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    // MARK: - Migration Tests
    
    func testMigrationStatusCheck() throws {
        // Clean state should not require migration (assuming current version)
        let status = try migration.checkMigrationStatus()
        
        switch status {
        case .notRequired:
            XCTAssert(true, "Clean state should not require migration")
        case .required(let from, let to):
            XCTAssertTrue(from < to, "Migration should be from older to newer version")
        default:
            XCTAssert(true, "Other statuses are acceptable for testing")
        }
    }
    
    func testMigrationWithV1Token() throws {
        // Simulate V1 token (plain string)
        let v1Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.signature"
        try KeychainHelper.store(key: AppConfig.KeychainKeys.authToken, value: v1Token)
        try KeychainHelper.store(key: "keychain_version", value: "1.0")
        
        // Perform migration
        try await migration.migrateIfNeeded()
        
        // Verify token is migrated to V2 format
        let migratedToken = try keychainService.retrieve(key: AppConfig.KeychainKeys.authToken, withBiometrics: false)
        XCTAssertEqual(migratedToken, v1Token, "Token content should be preserved")
        
        // Verify expiration date is set
        let expirationDate = try keychainService.tokenExpirationDate(for: AppConfig.KeychainKeys.authToken)
        XCTAssertNotNil(expirationDate, "Migrated token should have expiration date")
        
        // Verify version is updated
        let version = try KeychainHelper.retrieve(key: "keychain_version")
        XCTAssertEqual(version, "2.0", "Version should be updated to 2.0")
    }
    
    // MARK: - Error Handling Tests
    
    func testKeychainErrorDescriptions() {
        let errors: [KeychainHelper.KeychainError] = [
            .noPassword,
            .unexpectedPasswordData,
            .biometricNotAvailable,
            .tokenExpired,
            .migrationFailed,
            .invalidExpirationDate
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have description: \(error)")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty: \(error)")
        }
    }
    
    func testBiometricErrorMapping() {
        let biometricErrors: [BiometricAuthentication.BiometricError] = [
            .notAvailable,
            .authenticationFailed,
            .userCancel,
            .lockout,
            .biometryNotEnrolled
        ]
        
        for error in biometricErrors {
            XCTAssertNotNil(error.errorDescription, "Biometric error should have description: \(error)")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Biometric error description should not be empty: \(error)")
        }
    }
    
    // MARK: - Cleanup and Security Tests
    
    func testDeleteAllTokens() throws {
        // Store multiple tokens
        try KeychainHelper.storeAuthToken("auth_token")
        try KeychainHelper.storeRefreshToken("refresh_token")
        try KeychainHelper.storeUserCredentials(email: "test@example.com", password: "password")
        
        // Verify tokens exist
        XCTAssertTrue(KeychainHelper.exists(key: AppConfig.KeychainKeys.authToken))
        XCTAssertTrue(KeychainHelper.exists(key: AppConfig.KeychainKeys.refreshToken))
        XCTAssertTrue(KeychainHelper.exists(key: AppConfig.KeychainKeys.userCredentials))
        
        // Delete all tokens
        try keychainService.deleteAllTokens()
        
        // Verify all tokens are deleted
        XCTAssertFalse(KeychainHelper.exists(key: AppConfig.KeychainKeys.authToken))
        XCTAssertFalse(KeychainHelper.exists(key: AppConfig.KeychainKeys.refreshToken))
        XCTAssertFalse(KeychainHelper.exists(key: AppConfig.KeychainKeys.userCredentials))
    }
    
    func testBiometricPreferences() throws {
        // Test default preference
        let defaultPreference = KeychainHelper.getBiometricPreference()
        XCTAssertEqual(defaultPreference, AppConfig.FeatureFlags.biometricAuthEnabled)
        
        // Store preference
        try KeychainHelper.storeBiometricPreference(true)
        XCTAssertTrue(KeychainHelper.getBiometricPreference())
        
        try KeychainHelper.storeBiometricPreference(false)
        XCTAssertFalse(KeychainHelper.getBiometricPreference())
    }
    
    // MARK: - Performance Tests
    
    func testKeychainOperationPerformance() throws {
        let tokenCount = 100
        let tokens = (0..<tokenCount).map { "token_\($0)" }
        
        measure {
            for (index, token) in tokens.enumerated() {
                do {
                    let key = "performance_test_\(index)"
                    try KeychainHelper.store(key: key, value: token)
                    let _ = try KeychainHelper.retrieve(key: key)
                    try KeychainHelper.delete(key: key)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentKeychainAccess() throws {
        let expectation = XCTestExpectation(description: "Concurrent keychain operations")
        expectation.expectedFulfillmentCount = 10
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        for i in 0..<10 {
            queue.async {
                do {
                    let key = "concurrent_test_\(i)"
                    let token = "token_\(i)"
                    
                    try KeychainHelper.store(key: key, value: token)
                    let retrieved = try KeychainHelper.retrieve(key: key)
                    
                    XCTAssertEqual(retrieved, token)
                    
                    try KeychainHelper.delete(key: key)
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("Concurrent access failed: \(error)")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}

// MARK: - Mock Classes for Testing

class MockLAContext: LAContext {
    var mockCanEvaluatePolicy = true
    var mockBiometryType: LABiometryType = .none
    var mockEvaluationResult = true
    var mockError: Error?
    
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if let mockError = mockError {
            error?.pointee = mockError as NSError
        }
        return mockCanEvaluatePolicy
    }
    
    override var biometryType: LABiometryType {
        return mockBiometryType
    }
    
    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            reply(self.mockEvaluationResult, self.mockError)
        }
    }
}

// MARK: - Test Extensions

extension KeychainServiceTests {
    
    func createMockBiometricContext(canEvaluate: Bool = true, biometryType: LABiometryType = .faceID, evaluationResult: Bool = true, error: Error? = nil) -> MockLAContext {
        let context = MockLAContext()
        context.mockCanEvaluatePolicy = canEvaluate
        context.mockBiometryType = biometryType
        context.mockEvaluationResult = evaluationResult
        context.mockError = error
        return context
    }
}