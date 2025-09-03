import XCTest
import SwiftUI
import Combine
@testable import superone

/// Comprehensive unit tests for authentication UI components
@MainActor
final class AuthenticationViewTests: XCTestCase {
    
    var viewModel: AuthenticationViewModel!
    var mockNetworkService: MockNetworkService!
    var mockKeychainService: MockKeychainService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockKeychainService = MockKeychainService()
        viewModel = AuthenticationViewModel(
            networkService: mockNetworkService,
            keychainService: mockKeychainService
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockNetworkService = nil
        mockKeychainService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Authentication Models Tests
    
    func testLoginFormDataValidation() {
        var loginForm = LoginFormData()
        
        // Test empty form
        XCTAssertFalse(loginForm.isFormValid)
        XCTAssertFalse(loginForm.isEmailValid)
        XCTAssertFalse(loginForm.isPasswordValid)
        
        // Test with valid email but empty password
        loginForm.email = "user@test.local"
        XCTAssertTrue(loginForm.isEmailValid)
        XCTAssertFalse(loginForm.isPasswordValid)
        XCTAssertFalse(loginForm.isFormValid)
        
        // Test with invalid email
        loginForm.email = "invalid-email"
        XCTAssertFalse(loginForm.isEmailValid)
        XCTAssertFalse(loginForm.isFormValid)
        
        // Test with valid email and password
        loginForm.email = "user@test.local"
        loginForm.password = "password123"
        XCTAssertTrue(loginForm.isEmailValid)
        XCTAssertTrue(loginForm.isPasswordValid)
        XCTAssertTrue(loginForm.isFormValid)
    }
    
    func testRegistrationFormDataValidation() {
        var registrationForm = RegistrationFormData()
        
        // Test empty form
        XCTAssertFalse(registrationForm.isFormValid)
        
        // Test with valid basic info
        registrationForm.name = "Sample User"
        registrationForm.email = "user@test.local"
        registrationForm.password = "password123"
        registrationForm.confirmPassword = "password123"
        registrationForm.acceptedTerms = true
        registrationForm.acceptedPrivacy = true
        
        XCTAssertTrue(registrationForm.isFormValid)
        
        // Test password mismatch
        registrationForm.confirmPassword = "different-password"
        XCTAssertFalse(registrationForm.isConfirmPasswordValid)
        XCTAssertFalse(registrationForm.isFormValid)
        
        // Test terms not accepted
        registrationForm.confirmPassword = "password123"
        registrationForm.acceptedTerms = false
        XCTAssertFalse(registrationForm.areTermsAccepted)
        XCTAssertFalse(registrationForm.isFormValid)
    }
    
    func testValidationHelper() {
        // Test email validation
        XCTAssertTrue(ValidationHelper.isValidEmail("user@test.local"))
        XCTAssertTrue(ValidationHelper.isValidEmail("user.name+tag@domain.co.uk"))
        XCTAssertFalse(ValidationHelper.isValidEmail("invalid-email"))
        XCTAssertFalse(ValidationHelper.isValidEmail("@test.local"))
        XCTAssertFalse(ValidationHelper.isValidEmail("test@"))
        
        // Test password validation
        XCTAssertTrue(ValidationHelper.isValidPassword("password123"))
        XCTAssertTrue(ValidationHelper.isValidPassword("P@ssw0rd"))
        XCTAssertFalse(ValidationHelper.isValidPassword("short"))
        XCTAssertFalse(ValidationHelper.isValidPassword("12345678"))
        XCTAssertFalse(ValidationHelper.isValidPassword("password"))
        
        // Test name validation
        XCTAssertTrue(ValidationHelper.isValidName("Sample User"))
        XCTAssertTrue(ValidationHelper.isValidName("Jane"))
        XCTAssertFalse(ValidationHelper.isValidName("A"))
        XCTAssertFalse(ValidationHelper.isValidName(""))
        XCTAssertFalse(ValidationHelper.isValidName(String(repeating: "A", count: 51)))
        
        // Test phone number validation
        XCTAssertTrue(ValidationHelper.isValidPhoneNumber("(555) 123-4567"))
        XCTAssertTrue(ValidationHelper.isValidPhoneNumber("555-123-4567"))
        XCTAssertTrue(ValidationHelper.isValidPhoneNumber("5551234567"))
        XCTAssertFalse(ValidationHelper.isValidPhoneNumber("123"))
        XCTAssertFalse(ValidationHelper.isValidPhoneNumber("invalid"))
        
        // Test date of birth validation
        let calendar = Calendar.current
        let validAge = calendar.date(byAdding: .year, value: -20, to: Date())!
        let invalidAge = calendar.date(byAdding: .year, value: -10, to: Date())!
        let tooOld = calendar.date(byAdding: .year, value: -150, to: Date())!
        
        XCTAssertTrue(ValidationHelper.isValidDateOfBirth(validAge))
        XCTAssertFalse(ValidationHelper.isValidDateOfBirth(invalidAge))
        XCTAssertFalse(ValidationHelper.isValidDateOfBirth(tooOld))
    }
    
    func testPasswordStrength() {
        let (weakStrength, _) = ValidationHelper.passwordStrength("weak")
        XCTAssertEqual(weakStrength, .weak)
        
        let (mediumStrength, _) = ValidationHelper.passwordStrength("medium123")
        XCTAssertEqual(mediumStrength, .medium)
        
        let (strongStrength, _) = ValidationHelper.passwordStrength("StrongP@ssw0rd123")
        XCTAssertEqual(strongStrength, .strong)
    }
    
    // MARK: - Authentication ViewModel Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.currentFlow, .login)
        XCTAssertEqual(viewModel.authenticationState, .idle)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "")
    }
    
    func testSwitchAuthenticationFlow() {
        viewModel.switchToFlow(.registration)
        XCTAssertEqual(viewModel.currentFlow, .registration)
        
        viewModel.switchToFlow(.login)
        XCTAssertEqual(viewModel.currentFlow, .login)
    }
    
    func testLoginFormValidation() {
        viewModel.loginForm.email = ""
        viewModel.loginForm.password = ""
        viewModel.validateLoginForm()
        
        XCTAssertEqual(viewModel.validationStates.email, .invalid("Email address is required"))
        XCTAssertEqual(viewModel.validationStates.password, .invalid("Password is required"))
        
        viewModel.loginForm.email = "user@test.local"
        viewModel.loginForm.password = "password123"
        viewModel.validateLoginForm()
        
        XCTAssertEqual(viewModel.validationStates.email, .valid)
        XCTAssertEqual(viewModel.validationStates.password, .valid)
    }
    
    func testRegistrationFormValidation() {
        viewModel.registrationForm.name = ""
        viewModel.registrationForm.email = ""
        viewModel.registrationForm.password = ""
        viewModel.registrationForm.confirmPassword = ""
        viewModel.validateRegistrationForm()
        
        XCTAssertEqual(viewModel.validationStates.name, .invalid("Name is required"))
        XCTAssertEqual(viewModel.validationStates.email, .invalid("Email address is required"))
        XCTAssertEqual(viewModel.validationStates.password, .invalid("Password is required"))
        XCTAssertEqual(viewModel.validationStates.confirmPassword, .invalid("Please confirm your password"))
        
        viewModel.registrationForm.name = "John Doe"
        viewModel.registrationForm.email = "john@example.com"
        viewModel.registrationForm.password = "password123"
        viewModel.registrationForm.confirmPassword = "password123"
        viewModel.validateRegistrationForm()
        
        XCTAssertEqual(viewModel.validationStates.name, .valid)
        XCTAssertEqual(viewModel.validationStates.email, .valid)
        XCTAssertEqual(viewModel.validationStates.password, .valid)
        XCTAssertEqual(viewModel.validationStates.confirmPassword, .valid)
    }
    
    func testSuccessfulLogin() async {
        let expectation = XCTestExpectation(description: "Login success")
        
        viewModel.loginForm.email = "user@test.local"
        viewModel.loginForm.password = "password123"
        
        viewModel.$authenticationState
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.login()
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        if case .success(let authResponse) = viewModel.authenticationState {
            XCTAssertEqual(authResponse.user.email, "test@example.com")
            XCTAssertFalse(authResponse.accessToken.isEmpty)
        } else {
            XCTFail("Expected success state")
        }
    }
    
    func testFailedLogin() async {
        let expectation = XCTestExpectation(description: "Login failure")
        
        mockNetworkService.shouldFailLogin = true
        viewModel.loginForm.email = "error@test.local"
        viewModel.loginForm.password = "wrongpassword"
        
        viewModel.$authenticationState
            .sink { state in
                if case .error = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.login()
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        if case .error(let error) = viewModel.authenticationState {
            XCTAssertEqual(error, .invalidCredentials)
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func testSuccessfulRegistration() async {
        let expectation = XCTestExpectation(description: "Registration success")
        
        viewModel.registrationForm.name = "John Doe"
        viewModel.registrationForm.email = "john@example.com"
        viewModel.registrationForm.password = "password123"
        viewModel.registrationForm.confirmPassword = "password123"
        viewModel.registrationForm.acceptedTerms = true
        viewModel.registrationForm.acceptedPrivacy = true
        
        viewModel.$authenticationState
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.register()
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        if case .success(let authResponse) = viewModel.authenticationState {
            XCTAssertEqual(authResponse.user.name, "John Doe")
            XCTAssertFalse(authResponse.accessToken.isEmpty)
        } else {
            XCTFail("Expected success state")
        }
    }
    
    func testPasswordVisibilityToggle() {
        XCTAssertFalse(viewModel.isPasswordVisible)
        
        viewModel.togglePasswordVisibility()
        XCTAssertTrue(viewModel.isPasswordVisible)
        
        viewModel.togglePasswordVisibility()
        XCTAssertFalse(viewModel.isPasswordVisible)
    }
    
    func testConfirmPasswordVisibilityToggle() {
        XCTAssertFalse(viewModel.isConfirmPasswordVisible)
        
        viewModel.toggleConfirmPasswordVisibility()
        XCTAssertTrue(viewModel.isConfirmPasswordVisible)
        
        viewModel.toggleConfirmPasswordVisibility()
        XCTAssertFalse(viewModel.isConfirmPasswordVisible)
    }
    
    func testBiometricAuthentication() async {
        mockKeychainService.hasBiometricData = true
        
        let expectation = XCTestExpectation(description: "Biometric authentication")
        
        viewModel.$biometricState
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.authenticateWithBiometrics()
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.biometricState, .success)
    }
    
    func testPasswordReset() async {
        viewModel.loginForm.email = "user@test.local"
        
        let expectation = XCTestExpectation(description: "Password reset")
        
        viewModel.$authenticationState
            .sink { state in
                if case .idle = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await viewModel.requestPasswordReset()
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.authenticationState, .idle)
    }
    
    func testLogout() async {
        // First login
        viewModel.loginForm.email = "user@test.local"
        viewModel.loginForm.password = "password123"
        await viewModel.login()
        
        // Then logout
        await viewModel.logout()
        
        XCTAssertEqual(viewModel.authenticationState, .idle)
        XCTAssertTrue(viewModel.loginForm.email.isEmpty)
        XCTAssertTrue(viewModel.loginForm.password.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessageHandling() {
        let testError = AuthenticationError.invalidCredentials
        viewModel.authenticationState = .error(testError)
        
        // Simulate showing error
        viewModel.showError = true
        viewModel.errorMessage = testError.errorDescription ?? ""
        
        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
    }
    
    func testNetworkErrorMapping() async {
        mockNetworkService.networkError = .unauthorized
        viewModel.loginForm.email = "user@test.local"
        viewModel.loginForm.password = "wrongpassword"
        
        await viewModel.login()
        
        if case .error(let error) = viewModel.authenticationState {
            XCTAssertEqual(error, .invalidCredentials)
        } else {
            XCTFail("Expected error state")
        }
    }
    
    // MARK: - Form Reset Tests
    
    func testFormReset() {
        // Set some form data
        viewModel.loginForm.email = "user@test.local"
        viewModel.loginForm.password = "password123"
        viewModel.registrationForm.name = "John Doe"
        viewModel.authenticationState = .error(.invalidCredentials)
        
        // Reset forms
        viewModel.resetForms()
        
        XCTAssertTrue(viewModel.loginForm.email.isEmpty)
        XCTAssertTrue(viewModel.loginForm.password.isEmpty)
        XCTAssertTrue(viewModel.registrationForm.name.isEmpty)
        XCTAssertEqual(viewModel.authenticationState, .idle)
    }
    
    // MARK: - Validation State Tests
    
    func testFieldValidationStates() {
        let validState = FieldValidationState.valid
        let invalidState = FieldValidationState.invalid("Error message")
        let idleState = FieldValidationState.idle
        
        XCTAssertTrue(validState.isValid)
        XCTAssertFalse(invalidState.isValid)
        XCTAssertFalse(idleState.isValid)
        
        XCTAssertNil(validState.errorMessage)
        XCTAssertEqual(invalidState.errorMessage, "Error message")
        XCTAssertNil(idleState.errorMessage)
    }
    
    // MARK: - Authentication State Tests
    
    func testAuthenticationStateEquality() {
        let error1 = AuthenticationError.invalidCredentials
        let error2 = AuthenticationError.invalidCredentials
        let error3 = AuthenticationError.accountLocked
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
        
        let networkError1 = AuthenticationError.networkError("Connection failed")
        let networkError2 = AuthenticationError.networkError("Connection failed")
        let networkError3 = AuthenticationError.networkError("Timeout")
        
        XCTAssertEqual(networkError1, networkError2)
        XCTAssertNotEqual(networkError1, networkError3)
    }
    
    // MARK: - UI Configuration Tests
    
    func testUIConfiguration() {
        XCTAssertEqual(AuthenticationUIConfig.animationDuration, 0.3)
        XCTAssertEqual(AuthenticationUIConfig.errorDisplayDuration, 5.0)
        XCTAssertEqual(AuthenticationUIConfig.maxLoginAttempts, 5)
        XCTAssertEqual(AuthenticationUIConfig.passwordMinLength, 8)
    }
    
    func testBiometricConfiguration() {
        XCTAssertFalse(BiometricConfig.promptReason.isEmpty)
        XCTAssertEqual(BiometricConfig.lockoutDuration, 300)
    }
}

// MARK: - Mock Services for Testing

class MockNetworkService: NetworkServiceProtocol {
    var shouldFailLogin = false
    var networkError: NetworkError?
    
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T {
        if let error = networkError {
            throw error
        }
        
        if shouldFailLogin && endpoint.path.contains("/login") {
            throw NetworkError.unauthorized
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Return mock response based on endpoint
        if endpoint.path.contains("/login") || endpoint.path.contains("/register") {
            let mockUser = User(
                id: "test-user-id",
                email: "user@test.local",
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
            
            let authResponse = AuthResponse(
                accessToken: "mock-access-token",
                refreshToken: "mock-refresh-token",
                expiresIn: 3600,
                tokenType: "Bearer",
                user: mockUser,
                permissions: ["read", "write"],
                firstLogin: false
            )
            
            let apiResponse = APIResponse<AuthResponse>(
                success: true,
                data: authResponse,
                message: "Success",
                error: nil,
                timestamp: Date(),
                requestId: "mock-request-id"
            )
            
            return apiResponse as! T
        }
        
        throw NetworkError.notFound
    }
    
    func authenticate(email: String, password: String) async throws -> AuthResponse {
        if shouldFailLogin || email == "error@test.local" {
            throw NetworkError.unauthorized
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let mockUser = User(
            id: "test-user-id",
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
        
        return AuthResponse(
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token",
            expiresIn: 3600,
            tokenType: "Bearer",
            user: mockUser,
            permissions: ["read", "write"],
            firstLogin: false
        )
    }
    
    func refreshToken() async throws -> AuthResponse {
        throw NetworkError.notImplemented
    }
    
    func uploadFile(data: Data, endpoint: APIEndpoint, fileName: String, mimeType: String) async throws -> Data {
        return Data()
    }
    
    func downloadFile(from url: URL) async throws -> Data {
        return Data()
    }
    
    var isAuthenticated: Bool = false
}

class MockKeychainService: KeychainServiceProtocol {
    private var storage: [String: String] = [:]
    var hasBiometricData = false
    
    func store(token: String, for key: String) throws {
        storage[key] = token
    }
    
    func retrieve(key: String, withBiometrics: Bool) throws -> String? {
        if withBiometrics && !hasBiometricData {
            return nil
        }
        return storage[key]
    }
    
    func delete(key: String) throws {
        storage.removeValue(forKey: key)
    }
    
    func isBiometricAvailable() -> Bool {
        return true
    }
}

// MARK: - Test Extensions

extension FieldValidationState: Equatable {
    public static func == (lhs: FieldValidationState, rhs: FieldValidationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.valid, .valid):
            return true
        case (.invalid(let lhsMessage), .invalid(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}