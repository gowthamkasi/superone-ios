//
//  HealthKitPermissions.swift
//  SuperOne
//
//  Created by Claude Code on 7/24/25.
//

import Foundation
import HealthKit
import Combine

/// Manages HealthKit authorization and permissions
@MainActor
class HealthKitPermissions: ObservableObject {
    
    // MARK: - Properties
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var permissionStatuses: [HealthMetricType: HealthPermission] = [:]
    @Published var isAuthorized: Bool = false
    
    private let healthStore: HKHealthStore
    
    // MARK: - Initialization
    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
        checkInitialAuthorization()
    }
    
    // MARK: - Authorization Status
    private func checkInitialAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .notDetermined
            return
        }
        
        updateAuthorizationStatus()
    }
    
    private func updateAuthorizationStatus() {
        let readTypes = getReadHealthKitTypes()
        let writeTypes = getWriteHealthKitTypes()
        let allTypes = Set(readTypes).union(Set(writeTypes))
        
        // Check if we have authorization for any of the types
        var hasAnyAuthorization = false
        var allPermissions: [HealthMetricType: HealthPermission] = [:]
        
        for metricType in HealthMetricType.allCases {
            guard let hkType = metricType.healthKitType else { continue }
            
            let readStatus = healthStore.authorizationStatus(for: hkType)
            let writeStatus = healthStore.authorizationStatus(for: hkType)
            
            let isAuthorized = readStatus == .sharingAuthorized || writeStatus == .sharingAuthorized
            let canRead = readStatus == .sharingAuthorized
            let canWrite = writeStatus == .sharingAuthorized
            
            if isAuthorized {
                hasAnyAuthorization = true
            }
            
            allPermissions[metricType] = HealthPermission(
                type: metricType,
                isAuthorized: isAuthorized,
                canRead: canRead,
                canWrite: canWrite,
                requestedDate: Date(),
                grantedDate: isAuthorized ? Date() : nil
            )
        }
        
        permissionStatuses = allPermissions
        isAuthorized = hasAnyAuthorization
        
        // Determine overall authorization status
        if allPermissions.values.allSatisfy({ $0.isAuthorized }) {
            authorizationStatus = .sharingAuthorized
        } else if allPermissions.values.contains(where: { $0.isAuthorized }) {
            authorizationStatus = .sharingAuthorized // Partial authorization
        } else {
            authorizationStatus = .sharingDenied
        }
    }
    
    // MARK: - Permission Request
    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let readTypes = getReadHealthKitTypes()
        let writeTypes = getWriteHealthKitTypes()
        
        do {
            try await healthStore.requestAuthorization(toShare: Set(writeTypes), read: Set(readTypes))
            updateAuthorizationStatus()
            return isAuthorized
        } catch {
            throw HealthKitError.authorizationFailed
        }
    }
    
    // MARK: - Specific Permission Checks
    func hasReadPermission(for type: HealthMetricType) -> Bool {
        guard let hkType = type.healthKitType else { return false }
        return healthStore.authorizationStatus(for: hkType) == .sharingAuthorized
    }
    
    func hasWritePermission(for type: HealthMetricType) -> Bool {
        guard let hkType = type.healthKitType else { return false }
        return healthStore.authorizationStatus(for: hkType) == .sharingAuthorized
    }
    
    func getAuthorizationStatus(for type: HealthMetricType) -> HKAuthorizationStatus {
        guard let hkType = type.healthKitType else { return .notDetermined }
        return healthStore.authorizationStatus(for: hkType)
    }
    
    // MARK: - Health Data Types
    private func getReadHealthKitTypes() -> [HKSampleType] {
        let readTypes: [HealthMetricType] = [
            // Vital Signs
            .bloodPressureSystolic, .bloodPressureDiastolic, .heartRate, .restingHeartRate,
            .respiratoryRate, .bodyTemperature,
            
            // Metabolic
            .bloodGlucose,
            
            // Physical Measurements
            .height, .bodyMass, .bodyMassIndex, .bodyFatPercentage, .leanBodyMass, .waistCircumference,
            
            // Activity & Fitness
            .stepCount, .distanceWalkingRunning, .activeEnergyBurned, .basalEnergyBurned,
            .exerciseTime, .standTime, .flightsClimbed,
            
            // Sleep
            .sleepAnalysis,
            
            // Laboratory Results
            .oxygenSaturation, .peakExpiratoryFlowRate, .forcedVitalCapacity, .vo2Max
        ]
        
        return readTypes.compactMap { $0.healthKitType }
    }
    
    private func getWriteHealthKitTypes() -> [HKSampleType] {
        let writeTypes: [HealthMetricType] = [
            // Allow writing for user-entered data
            .bloodPressureSystolic, .bloodPressureDiastolic, .bloodGlucose,
            .bodyMass, .bodyFatPercentage, .waistCircumference
        ]
        
        return writeTypes.compactMap { $0.healthKitType }
    }
    
    // MARK: - Permission Categories
    var vitalSignsPermissions: [HealthMetricType: HealthPermission] {
        let vitalTypes: [HealthMetricType] = [
            .bloodPressureSystolic, .bloodPressureDiastolic, .heartRate, .restingHeartRate,
            .respiratoryRate, .bodyTemperature
        ]
        return permissionStatuses.filter { vitalTypes.contains($0.key) }
    }
    
    var metabolicPermissions: [HealthMetricType: HealthPermission] {
        let metabolicTypes: [HealthMetricType] = [
            .bloodGlucose, .totalCholesterol, .ldlCholesterol, .hdlCholesterol, .triglycerides, .hba1c
        ]
        return permissionStatuses.filter { metabolicTypes.contains($0.key) }
    }
    
    var physicalPermissions: [HealthMetricType: HealthPermission] {
        let physicalTypes: [HealthMetricType] = [
            .height, .bodyMass, .bodyMassIndex, .bodyFatPercentage, .leanBodyMass, .waistCircumference
        ]
        return permissionStatuses.filter { physicalTypes.contains($0.key) }
    }
    
    var activityPermissions: [HealthMetricType: HealthPermission] {
        let activityTypes: [HealthMetricType] = [
            .stepCount, .distanceWalkingRunning, .activeEnergyBurned, .basalEnergyBurned,
            .exerciseTime, .standTime, .flightsClimbed
        ]
        return permissionStatuses.filter { activityTypes.contains($0.key) }
    }
    
    var sleepPermissions: [HealthMetricType: HealthPermission] {
        let sleepTypes: [HealthMetricType] = [.sleepAnalysis]
        return permissionStatuses.filter { sleepTypes.contains($0.key) }
    }
    
    var laboratoryPermissions: [HealthMetricType: HealthPermission] {
        let labTypes: [HealthMetricType] = [
            .oxygenSaturation, .peakExpiratoryFlowRate, .forcedVitalCapacity, .vo2Max
        ]
        return permissionStatuses.filter { labTypes.contains($0.key) }
    }
    
    // MARK: - Permission Summary
    var permissionSummary: PermissionSummary {
        let total = permissionStatuses.count
        let authorized = permissionStatuses.values.filter { $0.isAuthorized }.count
        let canRead = permissionStatuses.values.filter { $0.canRead }.count
        let canWrite = permissionStatuses.values.filter { $0.canWrite }.count
        
        return PermissionSummary(
            totalRequested: total,
            authorized: authorized,
            canRead: canRead,
            canWrite: canWrite,
            percentage: total > 0 ? Double(authorized) / Double(total) : 0.0
        )
    }
    
    // MARK: - Background Delivery
    func enableBackgroundDelivery(for types: [HealthMetricType]) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        for type in types {
            guard let hkType = type.healthKitType as? HKQuantityType else { continue }
            
            do {
                try await healthStore.enableBackgroundDelivery(
                    for: hkType,
                    frequency: .immediate
                )
            } catch {
                throw HealthKitError.backgroundDeliveryFailed
            }
        }
    }
    
    func disableBackgroundDelivery(for types: [HealthMetricType]) async throws {
        for type in types {
            guard let hkType = type.healthKitType as? HKQuantityType else { continue }
            
            do {
                try await healthStore.disableBackgroundDelivery(for: hkType)
            } catch {
            }
        }
    }
    
    // MARK: - Privacy Information
    func getPrivacyInfoForPermissionRequest() -> PrivacyInfo {
        return PrivacyInfo(
            title: "Health Data Access",
            description: "Super One would like to access your health data to provide personalized health insights and recommendations.",
            dataTypes: [
                "Vital signs (heart rate, blood pressure)",
                "Physical measurements (weight, height, BMI)",
                "Activity data (steps, exercise, sleep)",
                "Laboratory results (glucose, cholesterol)",
                "Health metrics and trends"
            ],
            purposes: [
                "Generate personalized health insights",
                "Track health trends over time",
                "Provide AI-powered health recommendations",
                "Integrate with your lab reports",
                "Monitor health goals progress"
            ],
            dataHandling: [
                "Your health data stays on your device",
                "Only anonymized insights are sent to our servers",
                "You can revoke access anytime in Settings",
                "Data is encrypted and secure"
            ]
        )
    }
}

// MARK: - Supporting Models
struct PermissionSummary {
    let totalRequested: Int
    let authorized: Int
    let canRead: Int
    let canWrite: Int
    let percentage: Double
    
    var isFullyAuthorized: Bool {
        return authorized == totalRequested
    }
    
    var hasPartialAuthorization: Bool {
        return authorized > 0 && authorized < totalRequested
    }
}

struct PrivacyInfo {
    let title: String
    let description: String
    let dataTypes: [String]
    let purposes: [String]
    let dataHandling: [String]
}

// MARK: - Permission Request Categories
enum PermissionCategory: String, CaseIterable, Identifiable {
    case essential = "Essential"
    case fitness = "Fitness & Activity"
    case health = "Health Metrics"
    case laboratory = "Lab Results"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .essential:
            return "Basic health data like height, weight, and vital signs"
        case .fitness:
            return "Activity data including steps, exercise, and sleep"
        case .health:
            return "Health metrics like blood pressure and heart rate"
        case .laboratory:
            return "Laboratory results and clinical data"
        }
    }
    
    var types: [HealthMetricType] {
        switch self {
        case .essential:
            return [.height, .bodyMass, .bodyMassIndex, .heartRate]
        case .fitness:
            return [.stepCount, .activeEnergyBurned, .exerciseTime, .sleepAnalysis]
        case .health:
            return [.bloodPressureSystolic, .bloodPressureDiastolic, .bloodGlucose, .restingHeartRate]
        case .laboratory:
            return [.oxygenSaturation, .vo2Max, .peakExpiratoryFlowRate]
        }
    }
    
    var isOptional: Bool {
        switch self {
        case .essential:
            return false
        case .fitness, .health, .laboratory:
            return true
        }
    }
}