//
//  HealthKitService.swift
//  SuperOne
//
//  Created by Claude Code on 7/24/25.
//

import Foundation
import HealthKit
import Combine

// MARK: - Internal Profile Builder

/// Internal mutable profile builder for constructing HealthProfile from HealthKit data
private struct HealthProfileBuilder {
    var age: Int?
    var gender: Gender?
    var height: Double?
    var weight: Double?
    var bloodType: BloodType?
    var goals: [HealthGoal] = []
    var medicalConditions: [String] = []
    var medications: [String] = []
    var allergies: [String] = []
    var emergencyContact: EmergencyContact?
    
    func build(id: String, userId: String) -> HealthProfile {
        return HealthProfile(
            id: id,
            userId: userId,
            age: age,
            gender: gender,
            height: height,
            weight: weight,
            bloodType: bloodType,
            goals: goals,
            medicalConditions: medicalConditions,
            medications: medications,
            allergies: allergies,
            emergencyContact: emergencyContact,
            lastUpdated: Date()
        )
    }
}

// MARK: - Type Conversion Extensions

extension HealthKitMetric {
    /// Convert HealthKitMetric to HealthMetric for network models
    func toHealthMetric() -> HealthMetric {
        return HealthMetric(
            id: id,
            type: type,
            value: value,
            unit: unit,
            date: date,
            source: source ?? "HealthKit",
            notes: notes,
            isVerified: true // HealthKit data is considered verified
        )
    }
}

// MARK: - HealthKit Service Protocol
protocol HealthKitServiceProtocol {
    func requestAuthorization() async throws -> Bool
    func readHealthData(for types: [HKSampleType]) async throws -> [HKSample]
    func writeHealthData(_ samples: [HKSample]) async throws
    func readLatestData(for type: HealthMetricType) async throws -> HealthKitMetric?
    func readHealthData(for type: HealthMetricType, from startDate: Date, to endDate: Date) async throws -> [HealthKitMetric]
    func writeHealthMetric(_ metric: HealthKitMetric) async throws
    func getHealthProfile() async throws -> HealthProfile
    func updateHealthProfile(_ profile: HealthProfile) async throws
}

// MARK: - HealthKit Service Implementation
@MainActor
class HealthKitService: ObservableObject, HealthKitServiceProtocol {
    
    // MARK: - Properties
    private let healthStore: HKHealthStore
    private let permissions: HealthKitPermissions
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var backgroundDeliveryEnabled: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
        self.permissions = HealthKitPermissions(healthStore: healthStore)
        
        setupBindings()
        // PERFORMANCE: Defer HealthKit availability check to prevent main thread blocking during onboarding navigation
        // checkHealthKitAvailability() will be called lazily when HealthKit is actually needed
    }
    
    private func setupBindings() {
        permissions.$isAuthorized
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthorized, on: self)
            .store(in: &cancellables)
        
        permissions.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.authorizationStatus, on: self)
            .store(in: &cancellables)
    }
    
    private func checkHealthKitAvailability() {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
    }
    
    private func checkHealthKitAvailabilityIfNeeded() {
        // Only check availability when HealthKit is actually being used
        // This prevents blocking the main thread during app/view initialization
        checkHealthKitAvailability()
    }
    
    // MARK: - Authorization
    func requestAuthorization() async throws -> Bool {
        // Check availability lazily when actually needed
        checkHealthKitAvailabilityIfNeeded()
        
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        return try await permissions.requestAuthorization()
    }
    
    func requestCategoryAuthorization(_ category: PermissionCategory) async throws -> Bool {
        // Check availability lazily when actually needed
        checkHealthKitAvailabilityIfNeeded()
        
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let readTypes = category.types.compactMap { $0.healthKitType }
        let writeTypes = category.types.filter { type in
            // Only allow writing for certain types
            [.bloodPressureSystolic, .bloodPressureDiastolic, .bloodGlucose, .bodyMass].contains(type)
        }.compactMap { $0.healthKitType }
        
        do {
            try await healthStore.requestAuthorization(toShare: Set(writeTypes), read: Set(readTypes))
            return permissions.isAuthorized
        } catch {
            throw HealthKitError.authorizationFailed
        }
    }
    
    // MARK: - Read Health Data
    func readHealthData(for types: [HKSampleType]) async throws -> [HKSample] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        var allSamples: [HKSample] = []
        
        for type in types {
            do {
                let samples = try await readSamples(for: type)
                allSamples.append(contentsOf: samples)
            } catch {
                // Continue with other types even if one fails
            }
        }
        
        return allSamples
    }
    
    func readLatestData(for type: HealthMetricType) async throws -> HealthKitMetric? {
        guard let hkType = type.healthKitType else {
            throw HealthKitError.invalidHealthKitType
        }
        
        guard permissions.hasReadPermission(for: type) else {
            throw HealthKitError.notAuthorized
        }
        
        let samples = try await readSamples(for: hkType, limit: 1)
        guard let latestSample = samples.first else { return nil }
        
        if let quantitySample = latestSample as? HKQuantitySample {
            return HealthKitMetric(from: quantitySample, type: type)
        } else if let categorySample = latestSample as? HKCategorySample {
            return HealthKitMetric(from: categorySample, type: type)
        }
        
        return nil
    }
    
    func readHealthData(for type: HealthMetricType, from startDate: Date, to endDate: Date) async throws -> [HealthKitMetric] {
        guard let hkType = type.healthKitType else {
            throw HealthKitError.invalidHealthKitType
        }
        
        guard permissions.hasReadPermission(for: type) else {
            throw HealthKitError.notAuthorized
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samples = try await readSamples(for: hkType, predicate: predicate)
        
        return samples.compactMap { sample in
            if let quantitySample = sample as? HKQuantitySample {
                return HealthKitMetric(from: quantitySample, type: type)
            } else if let categorySample = sample as? HKCategorySample {
                return HealthKitMetric(from: categorySample, type: type)
            }
            return nil
        }
    }
    
    private func readSamples(for type: HKSampleType, predicate: NSPredicate? = nil, limit: Int = HKObjectQueryNoLimit) async throws -> [HKSample] {
        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: samples ?? [])
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Write Health Data
    func writeHealthData(_ samples: [HKSample]) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        do {
            try await healthStore.save(samples)
        } catch {
            throw HealthKitError.writeFailed
        }
    }
    
    func writeHealthMetric(_ metric: HealthKitMetric) async throws {
        guard let hkType = metric.type.healthKitType else {
            throw HealthKitError.invalidHealthKitType
        }
        
        guard permissions.hasWritePermission(for: metric.type) else {
            throw HealthKitError.notAuthorized
        }
        
        let sample: HKSample
        
        if let quantityType = hkType as? HKQuantityType {
            let quantity = HKQuantity(unit: metric.type.defaultUnit, doubleValue: metric.value)
            sample = HKQuantitySample(
                type: quantityType,
                quantity: quantity,
                start: metric.date,
                end: metric.date
            )
        } else if let categoryType = hkType as? HKCategoryType {
            sample = HKCategorySample(
                type: categoryType,
                value: Int(metric.value),
                start: metric.date,
                end: metric.date
            )
        } else {
            throw HealthKitError.invalidHealthKitType
        }
        
        try await writeHealthData([sample])
    }
    
    func writeBloodPressure(_ bloodPressure: BloodPressure) async throws {
        guard permissions.hasWritePermission(for: .bloodPressureSystolic) &&
              permissions.hasWritePermission(for: .bloodPressureDiastolic) else {
            throw HealthKitError.notAuthorized
        }
        
        let systolicSample = HKQuantitySample(
            type: HKQuantityType(.bloodPressureSystolic),
            quantity: HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: bloodPressure.systolic),
            start: bloodPressure.date,
            end: bloodPressure.date
        )
        
        let diastolicSample = HKQuantitySample(
            type: HKQuantityType(.bloodPressureDiastolic),
            quantity: HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: bloodPressure.diastolic),
            start: bloodPressure.date,
            end: bloodPressure.date
        )
        
        // Create correlation to link systolic and diastolic readings
        let correlationType = HKCorrelationType(.bloodPressure)
        let correlation = HKCorrelation(
            type: correlationType,
            start: bloodPressure.date,
            end: bloodPressure.date,
            objects: Set([systolicSample, diastolicSample])
        )
        
        try await writeHealthData([correlation])
    }
    
    // MARK: - Health Profile Management
    func getHealthProfile() async throws -> HealthProfile {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        // Create a mutable profile builder
        var profileBuilder = HealthProfileBuilder()
        
        // Get basic characteristics
        do {
            if let dateOfBirth = try healthStore.dateOfBirthComponents().date {
                let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year
                profileBuilder.age = age
            }
        } catch {
        }
        
        do {
            let biologicalSex = try healthStore.biologicalSex()
            switch biologicalSex.biologicalSex {
            case .male:
                profileBuilder.gender = .male
            case .female:
                profileBuilder.gender = .female
            case .other:
                profileBuilder.gender = .other
            case .notSet:
                profileBuilder.gender = .notSpecified
            @unknown default:
                profileBuilder.gender = .notSpecified
            }
        } catch {
        }
        
        // Get latest height and weight
        if let heightMetric = try await readLatestData(for: .height) {
            profileBuilder.height = heightMetric.value
        }
        
        if let weightMetric = try await readLatestData(for: .bodyMass) {
            profileBuilder.weight = weightMetric.value
        }
        
        // Build the final profile
        let profile = profileBuilder.build(
            id: UUID().uuidString,
            userId: "current_user" // This should come from authentication context
        )
        
        return profile
    }
    
    func updateHealthProfile(_ profile: HealthProfile) async throws {
        // HealthKit doesn't allow writing characteristics like age/gender
        // This method would primarily handle goals and preferences
        // The actual implementation would store goals locally or in backend
    }
    
    // MARK: - Blood Pressure Operations
    func readBloodPressure(from startDate: Date, to endDate: Date) async throws -> [BloodPressure] {
        let correlationType = HKCorrelationType(.bloodPressure)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: correlationType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let correlations = samples as? [HKCorrelation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let bloodPressureReadings = correlations.compactMap { correlation -> BloodPressure? in
                    var systolic: Double?
                    var diastolic: Double?
                    
                    for sample in correlation.objects {
                        if let quantitySample = sample as? HKQuantitySample {
                            if quantitySample.quantityType == HKQuantityType(.bloodPressureSystolic) {
                                systolic = quantitySample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                            } else if quantitySample.quantityType == HKQuantityType(.bloodPressureDiastolic) {
                                diastolic = quantitySample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                            }
                        }
                    }
                    
                    guard let sys = systolic, let dia = diastolic else { return nil }
                    
                    return BloodPressure(
                        systolic: sys,
                        diastolic: dia,
                        date: correlation.startDate,
                        source: correlation.sourceRevision.source.name
                    )
                }
                
                continuation.resume(returning: bloodPressureReadings)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Background Delivery
    func enableBackgroundDelivery(for types: [HealthMetricType]) async throws {
        try await permissions.enableBackgroundDelivery(for: types)
        backgroundDeliveryEnabled = true
    }
    
    func disableBackgroundDelivery(for types: [HealthMetricType]) async throws {
        try await permissions.disableBackgroundDelivery(for: types)
        backgroundDeliveryEnabled = false
    }
    
    // MARK: - Observer Queries
    func startObserving(type: HealthMetricType, updateHandler: @escaping @Sendable (HealthMetric?) -> Void) throws -> HKObserverQuery? {
        guard let hkType = type.healthKitType else {
            throw HealthKitError.invalidHealthKitType
        }
        
        guard permissions.hasReadPermission(for: type) else {
            throw HealthKitError.notAuthorized
        }
        
        let typeDisplayName = type.displayName  // Capture before closure
        let query = HKObserverQuery(sampleType: hkType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                return
            }
            
            Task { @MainActor in
                do {
                    let latestData = try await self?.readLatestData(for: type)
                    let healthMetric = latestData?.toHealthMetric()
                    updateHandler(healthMetric)
                } catch {
                    updateHandler(nil)
                }
            }
        }
        
        healthStore.execute(query)
        return query
    }
    
    func stopObserving(_ query: HKObserverQuery) {
        healthStore.stop(query)
    }
    
    // MARK: - Health Summary
    func getHealthSummary(for date: Date = Date()) async throws -> HealthDataSummary {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        var summary = HealthDataSummary(date: date)
        
        // Get step count
        if let stepData = try? await readHealthData(for: .stepCount, from: startOfDay, to: endOfDay).first {
            summary = HealthDataSummary(
                date: summary.date,
                stepCount: Int(stepData.value),
                activeCalories: summary.activeCalories,
                exerciseMinutes: summary.exerciseMinutes,
                sleepHours: summary.sleepHours,
                averageHeartRate: summary.averageHeartRate,
                restingHeartRate: summary.restingHeartRate,
                bloodPressure: summary.bloodPressure,
                weight: summary.weight
            )
        }
        
        // Get active calories
        if let calorieData = try? await readHealthData(for: .activeEnergyBurned, from: startOfDay, to: endOfDay).first {
            summary = HealthDataSummary(
                date: summary.date,
                stepCount: summary.stepCount,
                activeCalories: calorieData.value,
                exerciseMinutes: summary.exerciseMinutes,
                sleepHours: summary.sleepHours,
                averageHeartRate: summary.averageHeartRate,
                restingHeartRate: summary.restingHeartRate,
                bloodPressure: summary.bloodPressure,
                weight: summary.weight
            )
        }
        
        // Get exercise time
        if let exerciseData = try? await readHealthData(for: .exerciseTime, from: startOfDay, to: endOfDay).first {
            summary = HealthDataSummary(
                date: summary.date,
                stepCount: summary.stepCount,
                activeCalories: summary.activeCalories,
                exerciseMinutes: Int(exerciseData.value),
                sleepHours: summary.sleepHours,
                averageHeartRate: summary.averageHeartRate,
                restingHeartRate: summary.restingHeartRate,
                bloodPressure: summary.bloodPressure,
                weight: summary.weight
            )
        }
        
        // Get heart rate data
        if let heartRateData = try? await readHealthData(for: .heartRate, from: startOfDay, to: endOfDay) {
            let averageHR = heartRateData.isEmpty ? nil : heartRateData.map { $0.value }.reduce(0, +) / Double(heartRateData.count)
            summary = HealthDataSummary(
                date: summary.date,
                stepCount: summary.stepCount,
                activeCalories: summary.activeCalories,
                exerciseMinutes: summary.exerciseMinutes,
                sleepHours: summary.sleepHours,
                averageHeartRate: averageHR,
                restingHeartRate: summary.restingHeartRate,
                bloodPressure: summary.bloodPressure,
                weight: summary.weight
            )
        }
        
        // Get resting heart rate
        if let restingHRData = try? await readLatestData(for: .restingHeartRate) {
            summary = HealthDataSummary(
                date: summary.date,
                stepCount: summary.stepCount,
                activeCalories: summary.activeCalories,
                exerciseMinutes: summary.exerciseMinutes,
                sleepHours: summary.sleepHours,
                averageHeartRate: summary.averageHeartRate,
                restingHeartRate: restingHRData.value,
                bloodPressure: summary.bloodPressure,
                weight: summary.weight
            )
        }
        
        // Get latest weight
        if let weightData = try? await readLatestData(for: .bodyMass) {
            summary = HealthDataSummary(
                date: summary.date,
                stepCount: summary.stepCount,
                activeCalories: summary.activeCalories,
                exerciseMinutes: summary.exerciseMinutes,
                sleepHours: summary.sleepHours,
                averageHeartRate: summary.averageHeartRate,
                restingHeartRate: summary.restingHeartRate,
                bloodPressure: summary.bloodPressure,
                weight: weightData.value
            )
        }
        
        // Get blood pressure
        if let bpReadings = try? await readBloodPressure(from: startOfDay, to: endOfDay), let latestBP = bpReadings.first {
            summary = HealthDataSummary(
                date: summary.date,
                stepCount: summary.stepCount,
                activeCalories: summary.activeCalories,
                exerciseMinutes: summary.exerciseMinutes,
                sleepHours: summary.sleepHours,
                averageHeartRate: summary.averageHeartRate,
                restingHeartRate: summary.restingHeartRate,
                bloodPressure: latestBP,
                weight: summary.weight
            )
        }
        
        return summary
    }
    
    // MARK: - Utility Methods
    var permissionsManager: HealthKitPermissions {
        return permissions
    }
    
    func getAvailableDataTypes() -> [HealthMetricType] {
        return HealthMetricType.allCases.filter { type in
            permissions.hasReadPermission(for: type) || permissions.hasWritePermission(for: type)
        }
    }
    
    func deleteHealthData(for type: HealthMetricType, from startDate: Date, to endDate: Date) async throws {
        guard let hkType = type.healthKitType else {
            throw HealthKitError.invalidHealthKitType
        }
        
        guard permissions.hasWritePermission(for: type) else {
            throw HealthKitError.notAuthorized
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let typeDisplayName = type.displayName  // Capture before closure
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.deleteObjects(of: hkType, predicate: predicate) { success, deletedObjectsCount, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}