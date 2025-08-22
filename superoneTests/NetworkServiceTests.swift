import XCTest
import Alamofire
@testable import superone

/// Comprehensive test suite for NetworkService
@MainActor
final class NetworkServiceTests: XCTestCase {
    
    var networkService: NetworkService!
    var mockSession: MockSession!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Reset keychain for clean tests
        try? KeychainHelper.deleteAllAuthData()
        
        // Create fresh network service instance for testing
        networkService = NetworkService.shared
        
        // Mock network availability
        await setNetworkAvailable(true)
    }
    
    override func tearDown() async throws {
        // Clean up tokens
        try? KeychainHelper.deleteAllAuthData()
        
        networkService = nil
        mockSession = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Authentication Tests
    
    func testAuthenticate_Success() async throws {
        // Given
        let email = "test@example.com"
        let password = "password123"
        let expectedToken = "test-access-token"
        let expectedRefreshToken = "test-refresh-token"
        
        // Create mock auth response
        let mockUser = User(
            id: "user123",
            email: email,
            name: "Test User",
            profileImageURL: nil,
            phoneNumber: nil,
            dateOfBirth: nil,
            createdAt: Date(),
            updatedAt: Date(),
            emailVerified: true,
            phoneVerified: false,
            twoFactorEnabled: false,
            healthProfile: nil
        )
        
        let mockAuthResponse = AuthResponse(
            accessToken: expectedToken,
            refreshToken: expectedRefreshToken,
            expiresIn: 3600,
            tokenType: "Bearer",
            user: mockUser,
            permissions: ["read", "write"],
            firstLogin: false
        )
        
        // Mock the API response
        setupMockAuthResponse(success: true, data: mockAuthResponse)
        
        // When
        let result = try await networkService.authenticate(email: email, password: password)
        
        // Then
        XCTAssertEqual(result.accessToken, expectedToken)
        XCTAssertEqual(result.refreshToken, expectedRefreshToken)
        XCTAssertEqual(result.user.email, email)
        XCTAssertTrue(await networkService.isAuthenticated)
        
        // Verify tokens are stored in keychain
        let storedAccessToken = try KeychainHelper.retrieveAuthToken()
        let storedRefreshToken = try KeychainHelper.retrieveRefreshToken()
        XCTAssertEqual(storedAccessToken, expectedToken)
        XCTAssertEqual(storedRefreshToken, expectedRefreshToken)
    }
    
    func testAuthenticate_InvalidCredentials() async throws {
        // Given
        let email = "invalid@example.com"
        let password = "wrongpassword"
        
        // Mock failed auth response
        setupMockAuthResponse(success: false, data: nil, statusCode: 401)
        
        // When & Then
        do {
            _ = try await networkService.authenticate(email: email, password: password)
            XCTFail("Should have thrown authentication error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .unauthorized(message: nil))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        XCTAssertFalse(await networkService.isAuthenticated)
    }
    
    func testRefreshToken_Success() async throws {
        // Given
        let newAccessToken = "new-access-token"
        let newRefreshToken = "new-refresh-token"
        
        // Store initial refresh token
        try KeychainHelper.storeRefreshToken("old-refresh-token")
        
        let mockUser = User(
            id: "user123",
            email: "test@example.com",
            name: "Test User",
            profileImageURL: nil,
            phoneNumber: nil,
            dateOfBirth: nil,
            createdAt: Date(),
            updatedAt: Date(),
            emailVerified: true,
            phoneVerified: false,
            twoFactorEnabled: false,
            healthProfile: nil
        )
        
        let mockAuthResponse = AuthResponse(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            expiresIn: 3600,
            tokenType: "Bearer",
            user: mockUser,
            permissions: ["read", "write"],
            firstLogin: false
        )
        
        // Mock successful refresh response
        setupMockAuthResponse(success: true, data: mockAuthResponse)
        
        // When
        let result = try await networkService.refreshToken()
        
        // Then
        XCTAssertEqual(result.accessToken, newAccessToken)
        XCTAssertEqual(result.refreshToken, newRefreshToken)
        
        // Verify new tokens are stored
        let storedAccessToken = try KeychainHelper.retrieveAuthToken()
        let storedRefreshToken = try KeychainHelper.retrieveRefreshToken()
        XCTAssertEqual(storedAccessToken, newAccessToken)
        XCTAssertEqual(storedRefreshToken, newRefreshToken)
    }
    
    func testRefreshToken_ExpiredRefreshToken() async throws {
        // Given - no stored refresh token
        
        // When & Then
        do {
            _ = try await networkService.refreshToken()
            XCTFail("Should have thrown token invalid error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .tokenInvalid)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Generic Request Tests
    
    func testRequest_Success() async throws {
        // Given
        let endpoint = APIEndpoint(
            path: "/test",
            method: .get,
            requiresAuth: false
        )
        
        let expectedData = TestResponse(id: "123", name: "Test")
        setupMockDataResponse(data: expectedData, statusCode: 200)
        
        // When
        let result: TestResponse = try await networkService.request(endpoint)
        
        // Then
        XCTAssertEqual(result.id, "123")
        XCTAssertEqual(result.name, "Test")
    }
    
    func testRequest_WithAuthentication() async throws {
        // Given
        let endpoint = APIEndpoint(
            path: "/protected",
            method: .get,
            requiresAuth: true
        )
        
        // Store valid auth token
        try KeychainHelper.storeAuthToken("valid-token")
        
        let expectedData = TestResponse(id: "456", name: "Protected Data")
        setupMockDataResponse(data: expectedData, statusCode: 200)
        
        // When
        let result: TestResponse = try await networkService.request(endpoint)
        
        // Then
        XCTAssertEqual(result.id, "456")
        XCTAssertEqual(result.name, "Protected Data")
    }
    
    func testRequest_NetworkUnavailable() async throws {
        // Given
        await setNetworkAvailable(false)
        
        let endpoint = APIEndpoint(
            path: "/test",
            method: .get,
            requiresAuth: false
        )
        
        // When & Then
        do {
            let _: TestResponse = try await networkService.request(endpoint)
            XCTFail("Should have thrown no internet connection error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .noInternetConnection)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testRequest_ServerError() async throws {
        // Given
        let endpoint = APIEndpoint(
            path: "/test",
            method: .get,
            requiresAuth: false
        )
        
        setupMockErrorResponse(statusCode: 500, message: "Internal Server Error")
        
        // When & Then
        do {
            let _: TestResponse = try await networkService.request(endpoint)
            XCTFail("Should have thrown server error")
        } catch let error as NetworkError {
            if case .serverError(let code, let message) = error {
                XCTAssertEqual(code, 500)
                XCTAssertEqual(message, "Internal Server Error")
            } else {
                XCTFail("Expected server error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testRequest_DecodingError() async throws {
        // Given
        let endpoint = APIEndpoint(
            path: "/test",
            method: .get,
            requiresAuth: false
        )
        
        // Setup response with invalid JSON structure
        let invalidJSON = ["invalid": "structure"]
        setupMockDataResponse(data: invalidJSON, statusCode: 200)
        
        // When & Then
        do {
            let _: TestResponse = try await networkService.request(endpoint)
            XCTFail("Should have thrown decoding error")
        } catch let error as NetworkError {
            if case .decodingError = error {
                // Expected error
            } else {
                XCTFail("Expected decoding error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - File Upload Tests
    
    func testUploadFile_Success() async throws {
        // Given
        let testData = "Test file content".data(using: .utf8)!
        let endpoint = APIEndpoint(
            path: "/upload",
            method: .post,
            requiresAuth: true
        )
        
        // Store valid auth token
        try KeychainHelper.storeAuthToken("valid-token")
        
        // Mock successful upload response
        let responseData = "Upload successful".data(using: .utf8)!
        setupMockUploadResponse(data: responseData, statusCode: 200)
        
        // When
        let result = try await networkService.uploadFile(
            data: testData,
            endpoint: endpoint,
            fileName: "test.txt",
            mimeType: "text/plain"
        )
        
        // Then
        XCTAssertEqual(result, responseData)
    }
    
    func testUploadFile_NetworkUnavailable() async throws {
        // Given
        await setNetworkAvailable(false)
        
        let testData = "Test file content".data(using: .utf8)!
        let endpoint = APIEndpoint(
            path: "/upload",
            method: .post,
            requiresAuth: false
        )
        
        // When & Then
        do {
            _ = try await networkService.uploadFile(
                data: testData,
                endpoint: endpoint,
                fileName: "test.txt",
                mimeType: "text/plain"
            )
            XCTFail("Should have thrown no internet connection error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .noInternetConnection)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Download Tests
    
    func testDownloadFile_Success() async throws {
        // Given
        let testURL = URL(string: "https://example.com/test-file.pdf")!
        let expectedData = "Test file content".data(using: .utf8)!
        
        // Mock successful download response
        setupMockDownloadResponse(data: expectedData, statusCode: 200)
        
        // When
        let result = try await networkService.downloadFile(from: testURL)
        
        // Then
        XCTAssertEqual(result, expectedData)
    }
    
    func testDownloadFile_NetworkUnavailable() async throws {
        // Given
        await setNetworkAvailable(false)
        
        let testURL = URL(string: "https://example.com/test-file.pdf")!
        
        // When & Then
        do {
            _ = try await networkService.downloadFile(from: testURL)
            XCTFail("Should have thrown no internet connection error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .noInternetConnection)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Authentication Status Tests
    
    func testIsAuthenticated_WithValidToken() async throws {
        // Given
        try KeychainHelper.storeAuthToken("valid-token")
        
        // Force reload tokens
        await networkService.loadStoredTokens()
        
        // When & Then
        XCTAssertTrue(await networkService.isAuthenticated)
    }
    
    func testIsAuthenticated_NoToken() async throws {
        // Given - no stored token
        
        // When & Then
        XCTAssertFalse(await networkService.isAuthenticated)
    }
    
    // MARK: - Error Mapping Tests
    
    func testErrorMapping_HTTPStatusCodes() async throws {
        let testCases: [(Int, NetworkError)] = [
            (400, .badRequest(message: nil)),
            (401, .unauthorized(message: nil)),
            (403, .forbidden(message: nil)),
            (404, .notFound(message: nil)),
            (409, .conflict(message: nil)),
            (422, .unprocessableEntity(message: nil)),
            (429, .tooManyRequests(retryAfter: nil)),
            (500, .serverError(code: 500, message: nil))
        ]
        
        for (statusCode, expectedError) in testCases {
            // Given
            let endpoint = APIEndpoint(
                path: "/test",
                method: .get,
                requiresAuth: false
            )
            
            setupMockErrorResponse(statusCode: statusCode)
            
            // When & Then
            do {
                let _: TestResponse = try await networkService.request(endpoint)
                XCTFail("Should have thrown error for status code \(statusCode)")
            } catch let error as NetworkError {
                XCTAssertEqual(error, expectedError, "Status code \(statusCode) should map to \(expectedError)")
            } catch {
                XCTFail("Unexpected error type for status code \(statusCode): \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setNetworkAvailable(_ available: Bool) async {
        // This would need to be implemented based on how we expose network monitoring in NetworkService
        // For now, we'll assume the service can be configured for testing
    }
    
    private func setupMockAuthResponse(success: Bool, data: AuthResponse?, statusCode: Int = 200) {
        // Mock implementation would go here
        // This would configure the mock session to return the specified response
    }
    
    private func setupMockDataResponse<T: Codable>(data: T, statusCode: Int = 200) {
        // Mock implementation would go here
    }
    
    private func setupMockErrorResponse(statusCode: Int, message: String? = nil) {
        // Mock implementation would go here
    }
    
    private func setupMockUploadResponse(data: Data, statusCode: Int = 200) {
        // Mock implementation would go here
    }
    
    private func setupMockDownloadResponse(data: Data, statusCode: Int = 200) {
        // Mock implementation would go here
    }
}

// MARK: - Test Models

private struct TestResponse: Codable, Equatable {
    let id: String
    let name: String
}

// MARK: - Mock Session

private class MockSession {
    var mockedResponses: [String: MockResponse] = [:]
    
    func addMockResponse(url: String, response: MockResponse) {
        mockedResponses[url] = response
    }
}

private struct MockResponse {
    let data: Data?
    let statusCode: Int
    let headers: [String: String]
    let error: Error?
}

// MARK: - NetworkService Test Extensions

extension NetworkService {
    /// Test-only method to load stored tokens
    func loadStoredTokens() async {
        await self.loadStoredTokens()
    }
}

// MARK: - Performance Tests

extension NetworkServiceTests {
    
    func testPerformance_ConcurrentRequests() async throws {
        // Given
        let requestCount = 10
        let endpoint = APIEndpoint(
            path: "/test",
            method: .get,
            requiresAuth: false
        )
        
        let expectedData = TestResponse(id: "123", name: "Test")
        setupMockDataResponse(data: expectedData, statusCode: 200)
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<requestCount {
                group.addTask {
                    do {
                        let _: TestResponse = try await self.networkService.request(endpoint)
                    } catch {
                        XCTFail("Request failed: \(error)")
                    }
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // Then
        XCTAssertLessThan(totalTime, 5.0, "Concurrent requests should complete within 5 seconds")
    }
    
    func testPerformance_LargeDataDecoding() async throws {
        // Given
        let largeArray = Array(0..<1000).map { TestResponse(id: "\($0)", name: "Item \($0)") }
        let endpoint = APIEndpoint(
            path: "/large-data",
            method: .get,
            requiresAuth: false
        )
        
        setupMockDataResponse(data: largeArray, statusCode: 200)
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result: [TestResponse] = try await networkService.request(endpoint)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then
        let totalTime = endTime - startTime
        XCTAssertEqual(result.count, 1000)
        XCTAssertLessThan(totalTime, 1.0, "Large data decoding should complete within 1 second")
    }
}

// MARK: - Integration Tests

extension NetworkServiceTests {
    
    func testIntegration_FullAuthenticationFlow() async throws {
        // Given
        let email = "integration@example.com"
        let password = "password123"
        
        // Setup mock responses for full flow
        setupMockAuthFlowResponses()
        
        // When - Authenticate
        let authResponse = try await networkService.authenticate(email: email, password: password)
        
        // Then - Should be authenticated
        XCTAssertTrue(await networkService.isAuthenticated)
        XCTAssertNotNil(authResponse.accessToken)
        
        // When - Make authenticated request
        let protectedEndpoint = APIEndpoint(
            path: "/protected-resource",
            method: .get,
            requiresAuth: true
        )
        
        let protectedResult: TestResponse = try await networkService.request(protectedEndpoint)
        
        // Then - Should succeed
        XCTAssertEqual(protectedResult.name, "Protected Data")
        
        // When - Simulate token expiry and refresh
        let refreshResponse = try await networkService.refreshToken()
        
        // Then - Should have new tokens
        XCTAssertNotEqual(refreshResponse.accessToken, authResponse.accessToken)
        XCTAssertTrue(await networkService.isAuthenticated)
    }
    
    private func setupMockAuthFlowResponses() {
        // This would setup all the mock responses needed for the full authentication flow
    }
}