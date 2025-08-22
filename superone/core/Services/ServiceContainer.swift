//
//  ServiceContainer.swift
//  SuperOne
//
//  Created by Claude Code on 1/29/25.
//

/// Dependency injection container for managing service instances
@MainActor
class ServiceContainer {
    
    // MARK: - Singleton
    
    static let shared = ServiceContainer()
    
    // MARK: - Service Instances
    
    private lazy var _networkService: NetworkService = {
        return NetworkService.shared
    }()
    
    private lazy var _authAPIService: AuthenticationAPIService = {
        return AuthenticationAPIService(networkService: _networkService)
    }()
    
    private lazy var _keychainHelper: KeychainHelper = {
        return KeychainHelper.shared
    }()
    
    private lazy var _biometricAuth: BiometricAuthentication = {
        return BiometricAuthentication.shared
    }()
    
    // MARK: - Initialization
    
    private init() {
        setupLogging()
    }
    
    // MARK: - Service Access
    
    /// Get network service instance
    var networkService: NetworkService {
        return _networkService
    }
    
    /// Get authentication API service instance
    var authAPIService: AuthenticationAPIService {
        return _authAPIService
    }
    
    /// Get keychain helper instance
    var keychainHelper: KeychainHelper {
        return _keychainHelper
    }
    
    /// Get biometric authentication instance
    var biometricAuth: BiometricAuthentication {
        return _biometricAuth
    }
    
    // MARK: - Service Factory Methods
    
    /// Create authentication view model with injected dependencies
    func createAuthenticationViewModel() -> AuthenticationViewModel {
        return AuthenticationViewModel(
            authAPIService: _authAPIService,
            keychainService: _keychainHelper,
            biometricAuth: _biometricAuth
        )
    }
    
    /// Create dashboard view model with injected dependencies
    func createDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModel()
    }
    
    // MARK: - Configuration
    
    private func setupLogging() {
        #if DEBUG
        #endif
    }
    
    /// Reset all services (useful for testing)
    func reset() {
        // This would clear any cached state if needed
    }
}

// MARK: - SwiftUI Environment Key

import SwiftUI

struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue: ServiceContainer = ServiceContainer.shared
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}