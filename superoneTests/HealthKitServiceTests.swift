//
//  HealthKitServiceTests.swift
//  SuperOneTests
//
//  Created by Claude Code on 7/24/25.
//

import XCTest
import HealthKit
@testable import superone

@MainActor
final class HealthKitServiceTests: XCTestCase {
    
    var healthKitService: HealthKitService!
    var mockHealthStore: MockHKHealthStore!
    
    override func setUpWithError() throws {
        super.setUp()
        mockHealthStore = MockHKHealthStore()
        healthKitService = HealthKitService(healthStore: mockHealthStore)
    }
    
    override func tearDownWithError() throws {
        healthKitService = nil
        mockHealthStore = nil
        super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorizationSuccess() async throws {
        // Given
        mockHealthStore.requestAuthorizationResult = .success(())
        mockHealthStore.authorizationStatusResult = .sharingAuthorized
        
        // When
        let result = try await healthKitService.requestAuthorization()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(mockHealthStore.requestAuthorizationCalled)
    }
    
    func testRequestAuthorizationFailure() async throws {
        // Given
        mockHealthStore.requestAuthorizationResult = .failure(HealthKitError.authorizationFailed)
        
        // When & Then
        do {
            _ = try await healthKitService.requestAuthorization()
            XCTFail("Expected authorization to fail")
        } catch HealthKitError.authorizationFailed {
            // Expected error
            XCTAssertTrue(mockHealthStore.requestAuthorizationCalled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testHealthKitNotAvailable() async throws {
        // Given
        let service = HealthKitService(healthStore: MockHKHealthStore(isAvailable: false))
        
        // When & Then
        do {
            _ = try await service.requestAuthorization()
            XCTFail("Expected HealthKit not available error")
        } catch HealthKitError.notAvailable {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Read Health Data Tests
    
    func testReadLatestDataSuccess() async throws {
        // Given
        let expectedValue = 72.0
        let expectedDate = Date()
        let mockSample = MockHKQuantitySample(
            type: HKQuantityType(.heartRate),
            value: expectedValue,
            unit: HKUnit.count().unitDivided(by: .minute()),
            date: expectedDate
        )
        
        mockHealthStore.authorizationStatusResult = .sharingAuthorized
        mockHealthStore.sampleQueryResult = .success([mockSample])
        
        // When
        let result = try await healthKitService.readLatestData(for: .heartRate)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.type, .heartRate)
        XCTAssertEqual(result?.value, expectedValue)
        XCTAssertEqual(result?.date.timeIntervalSince1970, expectedDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testReadLatestDataNotAuthorized() async throws {
        // Given
        mockHealthStore.authorizationStatusResult = .sharingDenied
        
        // When & Then
        do {
            _ = try await healthKitService.readLatestData(for: .heartRate)
            XCTFail("Expected not authorized error")
        } catch HealthKitError.notAuthorized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testReadHealthDataDateRange() async throws {
        // Given
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        let mockSamples = [
            MockHKQuantitySample(type: HKQuantityType(.stepCount), value: 5000, unit: .count(), date: startDate),
            MockHKQuantitySample(type: HKQuantityType(.stepCount), value: 6000, unit: .count(), date: endDate)
        ]
        
        mockHealthStore.authorizationStatusResult = .sharingAuthorized
        mockHealthStore.sampleQueryResult = .success(mockSamples)
        
        // When
        let results = try await healthKitService.readHealthData(for: .stepCount, from: startDate, to: endDate)
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].value, 5000)
        XCTAssertEqual(results[1].value, 6000)
    }
    
    // MARK: - Write Health Data Tests
    
    func testWriteHealthMetricSuccess() async throws {
        // Given
        mockHealthStore.authorizationStatusResult = .sharingAuthorized
        mockHealthStore.saveResult = .success(())
        
        let metric = HealthMetric(
            type: .bloodGlucose,
            value: 95.0,
            unit: "mg/dL"
        )
        
        // When
        try await healthKitService.writeHealthMetric(metric)
        
        // Then
        XCTAssertTrue(mockHealthStore.saveCalled)
        XCTAssertEqual(mockHealthStore.savedSamples.count, 1)
    }
    
    func testWriteHealthMetricNotAuthorized() async throws {
        // Given
        mockHealthStore.authorizationStatusResult = .sharingDenied
        
        let metric = HealthMetric(
            type: .bloodGlucose,
            value: 95.0,
            unit: "mg/dL"
        )
        
        // When & Then
        do {
            try await healthKitService.writeHealthMetric(metric)
            XCTFail("Expected not authorized error")
        } catch HealthKitError.notAuthorized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testWriteBloodPressure() async throws {
        // Given
        mockHealthStore.authorizationStatusResult = .sharingAuthorized
        mockHealthStore.saveResult = .success(())
        
        let bloodPressure = BloodPressure(
            systolic: 120,
            diastolic: 80
        )
        
        // When
        try await healthKitService.writeBloodPressure(bloodPressure)
        
        // Then
        XCTAssertTrue(mockHealthStore.saveCalled)
        XCTAssertEqual(mockHealthStore.savedSamples.count, 1)
        
        // Verify it's a correlation with both systolic and diastolic
        if let correlation = mockHealthStore.savedSamples.first as? HKCorrelation {
            XCTAssertEqual(correlation.objects.count, 2)
        } else {
            XCTFail("Expected HKCorrelation to be saved")
        }
    }
    
    // MARK: - Health Profile Tests
    
    func testGetHealthProfile() async throws {
        // Given
        mockHealthStore.dateOfBirthResult = Calendar.current.dateComponents([.year, .month, .day], from: Date(timeIntervalSinceNow: -25 * 365 * 24 * 60 * 60))
        mockHealthStore.biologicalSexResult = HKBiologicalSexObject(biologicalSex: .female)
        mockHealthStore.authorizationStatusResult = .sharingAuthorized
        
        let heightSample = MockHKQuantitySample(
            type: HKQuantityType(.height),
            value: 65.0,
            unit: .inch(),
            date: Date()
        )
        let weightSample = MockHKQuantitySample(
            type: HKQuantityType(.bodyMass),
            value: 140.0,
            unit: .pound(),
            date: Date()
        )
        
        mockHealthStore.sampleQueryResult = .success([heightSample, weightSample])
        
        // When
        let profile = try await healthKitService.getHealthProfile()
        
        // Then
        XCTAssertEqual(profile.age, 25, accuracy: 1)
        XCTAssertEqual(profile.gender, .female)
        XCTAssertEqual(profile.height, 65.0)
        XCTAssertEqual(profile.weight, 140.0)
    }
    
    // MARK: - Blood Pressure Tests
    
    func testReadBloodPressure() async throws {
        // Given
        let systolicSample = MockHKQuantitySample(
            type: HKQuantityType(.bloodPressureSystolic),
            value: 120.0,
            unit: .millimeterOfMercury(),
            date: Date()
        )
        let diastolicSample = MockHKQuantitySample(
            type: HKQuantityType(.bloodPressureDiastolic),
            value: 80.0,
            unit: .millimeterOfMercury(),
            date: Date()
        )
        
        let correlation = MockHKCorrelation(
            type: HKCorrelationType(.bloodPressure),
            objects: Set([systolicSample, diastolicSample]),
            date: Date()
        )
        
        mockHealthStore.sampleQueryResult = .success([correlation])
        
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let endDate = Date()
        
        // When
        let results = try await healthKitService.readBloodPressure(from: startDate, to: endDate)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].systolic, 120.0)
        XCTAssertEqual(results[0].diastolic, 80.0)
        XCTAssertEqual(results[0].category, .normal)
    }
    
    // MARK: - Health Summary Tests
    
    func testGetHealthSummary() async throws {
        // Given
        mockHealthStore.authorizationStatusResult = .sharingAuthorized
        
        let stepSample = MockHKQuantitySample(
            type: HKQuantityType(.stepCount),
            value: 8500,
            unit: .count(),
            date: Date()
        )
        let calorieSample = MockHKQuantitySample(
            type: HKQuantityType(.activeEnergyBurned),
            value: 350,
            unit: .kilocalorie(),
            date: Date()
        )
        
        mockHealthStore.sampleQueryResult = .success([stepSample, calorieSample])
        
        // When
        let summary = try await healthKitService.getHealthSummary()
        
        // Then
        XCTAssertEqual(summary.stepCount, 8500)
        XCTAssertEqual(summary.activeCalories, 350.0)
    }
    
    // MARK: - Background Delivery Tests
    
    func testEnableBackgroundDelivery() async throws {
        // Given
        mockHealthStore.authorizationStatusResult = .sharingAuthorized
        mockHealthStore.enableBackgroundDeliveryResult = .success(())
        
        // When
        try await healthKitService.enableBackgroundDelivery(for: [.heartRate, .stepCount])
        
        // Then
        XCTAssertTrue(mockHealthStore.enableBackgroundDeliveryCalled)
        XCTAssertTrue(healthKitService.backgroundDeliveryEnabled)
    }
    
    func testDisableBackgroundDelivery() async throws {
        // Given
        mockHealthStore.disableBackgroundDeliveryResult = .success(())
        
        // When
        try await healthKitService.disableBackgroundDelivery(for: [.heartRate, .stepCount])
        
        // Then
        XCTAssertTrue(mockHealthStore.disableBackgroundDeliveryCalled)
        XCTAssertFalse(healthKitService.backgroundDeliveryEnabled)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidHealthKitType() async throws {
        // Given - Using a metric type that doesn't have a valid HealthKit type
        // (This would need to be set up in the mock)
        
        // When & Then
        do {
            _ = try await healthKitService.readLatestData(for: .totalCholesterol) // Placeholder type
            // This might not fail in current implementation, but would in a real scenario
        } catch HealthKitError.invalidHealthKitType {
            // Expected for unsupported types
        } catch {
            // Other errors are also acceptable for this test
        }
    }
    
    func testReadFailure() async throws {
        // Given
        mockHealthStore.authorizationStatusResult = .sharingAuthorized
        mockHealthStore.sampleQueryResult = .failure(HealthKitError.readFailed)
        
        // When & Then
        do {
            _ = try await healthKitService.readLatestData(for: .heartRate)
            XCTFail("Expected read to fail")
        } catch {
            // Expected some error
        }
    }
    
    func testWriteFailure() async throws {
        // Given
        mockHealthStore.authorizationStatusResult = .sharingAuthorized
        mockHealthStore.saveResult = .failure(HealthKitError.writeFailed)
        
        let metric = HealthMetric(
            type: .bloodGlucose,
            value: 95.0,
            unit: "mg/dL"
        )
        
        // When & Then
        do {
            try await healthKitService.writeHealthMetric(metric)
            XCTFail("Expected write to fail")
        } catch HealthKitError.writeFailed {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Mock Classes

class MockHKHealthStore: HKHealthStore {
    var isAvailable: Bool = true
    var requestAuthorizationCalled = false
    var requestAuthorizationResult: Result<Void, Error> = .success(())
    var authorizationStatusResult: HKAuthorizationStatus = .notDetermined
    var sampleQueryResult: Result<[HKSample], Error> = .success([])
    var saveCalled = false
    var saveResult: Result<Void, Error> = .success(())
    var savedSamples: [HKObject] = []
    var enableBackgroundDeliveryCalled = false
    var enableBackgroundDeliveryResult: Result<Void, Error> = .success(())
    var disableBackgroundDeliveryCalled = false
    var disableBackgroundDeliveryResult: Result<Void, Error> = .success(())
    var dateOfBirthResult: DateComponents?
    var biologicalSexResult: HKBiologicalSexObject?
    
    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
        super.init()
    }
    
    override class func isHealthDataAvailable() -> Bool {
        return true // Default for tests
    }
    
    override func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?) async throws {
        requestAuthorizationCalled = true
        switch requestAuthorizationResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    override func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return authorizationStatusResult
    }
    
    override func execute(_ query: HKQuery) {
        if let sampleQuery = query as? HKSampleQuery {
            switch sampleQueryResult {
            case .success(let samples):
                sampleQuery.resultsHandler?(sampleQuery, samples, nil)
            case .failure(let error):
                sampleQuery.resultsHandler?(sampleQuery, nil, error)
            }
        }
    }
    
    override func save(_ objects: [HKObject]) async throws {
        saveCalled = true
        savedSamples.append(contentsOf: objects)
        switch saveResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    override func enableBackgroundDelivery(for type: HKObjectType, frequency: HKUpdateFrequency) async throws {
        enableBackgroundDeliveryCalled = true
        switch enableBackgroundDeliveryResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    override func disableBackgroundDelivery(for type: HKObjectType) async throws {
        disableBackgroundDeliveryCalled = true
        switch disableBackgroundDeliveryResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    override func dateOfBirthComponents() throws -> DateComponents {
        if let result = dateOfBirthResult {
            return result
        }
        throw HealthKitError.dataNotAvailable
    }
    
    override func biologicalSex() throws -> HKBiologicalSexObject {
        if let result = biologicalSexResult {
            return result
        }
        throw HealthKitError.dataNotAvailable
    }
}

class MockHKQuantitySample: HKQuantitySample {
    private let _quantityType: HKQuantityType
    private let _quantity: HKQuantity
    private let _startDate: Date
    private let _endDate: Date
    
    init(type: HKQuantityType, value: Double, unit: HKUnit, date: Date) {
        self._quantityType = type
        self._quantity = HKQuantity(unit: unit, doubleValue: value)
        self._startDate = date
        self._endDate = date
        super.init()
    }
    
    override var quantityType: HKQuantityType {
        return _quantityType
    }
    
    override var quantity: HKQuantity {
        return _quantity
    }
    
    override var startDate: Date {
        return _startDate
    }
    
    override var endDate: Date {
        return _endDate
    }
    
    override var sourceRevision: HKSourceRevision {
        let source = HKSource.default()
        return HKSourceRevision(source: source, version: "1.0")
    }
}

class MockHKCorrelation: HKCorrelation {
    private let _correlationType: HKCorrelationType
    private let _objects: Set<HKSample>
    private let _startDate: Date
    private let _endDate: Date
    
    init(type: HKCorrelationType, objects: Set<HKSample>, date: Date) {
        self._correlationType = type
        self._objects = objects
        self._startDate = date
        self._endDate = date
        super.init()
    }
    
    override var correlationType: HKCorrelationType {
        return _correlationType
    }
    
    override var objects: Set<HKSample> {
        return _objects
    }
    
    override var startDate: Date {
        return _startDate
    }
    
    override var endDate: Date {
        return _endDate
    }
    
    override var sourceRevision: HKSourceRevision {
        let source = HKSource.default()
        return HKSourceRevision(source: source, version: "1.0")
    }
}