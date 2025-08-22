//
//  HealthKitModels.swift
//  SuperOne
//
//  Created by Claude Code on 7/24/25.
//

import Foundation
import HealthKit  
import Combine

// MARK: - Health Metric Types
enum HealthMetricType: String, CaseIterable, Codable, Sendable {
    // Vital Signs
    case bloodPressureSystolic = "blood_pressure_systolic"
    case bloodPressureDiastolic = "blood_pressure_diastolic"
    case heartRate = "heart_rate"
    case restingHeartRate = "resting_heart_rate"
    case respiratoryRate = "respiratory_rate"
    case bodyTemperature = "body_temperature"
    
    // Metabolic
    case bloodGlucose = "blood_glucose"
    case totalCholesterol = "total_cholesterol"
    case ldlCholesterol = "ldl_cholesterol"
    case hdlCholesterol = "hdl_cholesterol"
    case triglycerides = "triglycerides"
    case hba1c = "hba1c"
    
    // Physical Measurements
    case height = "height"
    case bodyMass = "body_mass"
    case bodyMassIndex = "body_mass_index"
    case bodyFatPercentage = "body_fat_percentage"
    case leanBodyMass = "lean_body_mass"
    case waistCircumference = "waist_circumference"
    
    // Activity & Fitness
    case stepCount = "step_count"
    case distanceWalkingRunning = "distance_walking_running"
    case activeEnergyBurned = "active_energy_burned"
    case basalEnergyBurned = "basal_energy_burned"
    case exerciseTime = "exercise_time"
    case standTime = "stand_time"
    case flightsClimbed = "flights_climbed"
    
    // Sleep
    case sleepAnalysis = "sleep_analysis"
    
    // Laboratory Results
    case oxygenSaturation = "oxygen_saturation"
    case peakExpiratoryFlowRate = "peak_expiratory_flow_rate"
    case forcedVitalCapacity = "forced_vital_capacity"
    case vo2Max = "vo2_max"
    
    var displayName: String {
        switch self {
        case .bloodPressureSystolic: return "Systolic Blood Pressure"
        case .bloodPressureDiastolic: return "Diastolic Blood Pressure"
        case .heartRate: return "Heart Rate"
        case .restingHeartRate: return "Resting Heart Rate"
        case .respiratoryRate: return "Respiratory Rate"
        case .bodyTemperature: return "Body Temperature"
        case .bloodGlucose: return "Blood Glucose"
        case .totalCholesterol: return "Total Cholesterol"
        case .ldlCholesterol: return "LDL Cholesterol"
        case .hdlCholesterol: return "HDL Cholesterol"
        case .triglycerides: return "Triglycerides"
        case .hba1c: return "HbA1c"
        case .height: return "Height"
        case .bodyMass: return "Weight"
        case .bodyMassIndex: return "BMI"
        case .bodyFatPercentage: return "Body Fat %"
        case .leanBodyMass: return "Lean Body Mass"
        case .waistCircumference: return "Waist Circumference"
        case .stepCount: return "Steps"
        case .distanceWalkingRunning: return "Walking + Running Distance"
        case .activeEnergyBurned: return "Active Calories"
        case .basalEnergyBurned: return "Resting Calories"
        case .exerciseTime: return "Exercise Time"
        case .standTime: return "Stand Time"
        case .flightsClimbed: return "Flights Climbed"
        case .sleepAnalysis: return "Sleep"
        case .oxygenSaturation: return "Blood Oxygen"
        case .peakExpiratoryFlowRate: return "Peak Flow"
        case .forcedVitalCapacity: return "Lung Capacity"
        case .vo2Max: return "VO₂ Max"
        }
    }
    
    var healthKitType: HKSampleType? {
        switch self {
        case .bloodPressureSystolic:
            return HKQuantityType(.bloodPressureSystolic)
        case .bloodPressureDiastolic:
            return HKQuantityType(.bloodPressureDiastolic)
        case .heartRate:
            return HKQuantityType(.heartRate)
        case .restingHeartRate:
            return HKQuantityType(.restingHeartRate)
        case .respiratoryRate:
            return HKQuantityType(.respiratoryRate)
        case .bodyTemperature:
            return HKQuantityType(.bodyTemperature)
        case .bloodGlucose:
            return HKQuantityType(.bloodGlucose)
        case .totalCholesterol:
            return HKQuantityType(.bloodGlucose) // Placeholder - need proper cholesterol types
        case .ldlCholesterol:
            return HKQuantityType(.bloodGlucose) // Placeholder
        case .hdlCholesterol:
            return HKQuantityType(.bloodGlucose) // Placeholder
        case .triglycerides:
            return HKQuantityType(.bloodGlucose) // Placeholder
        case .hba1c:
            return HKQuantityType(.bloodGlucose) // Placeholder
        case .height:
            return HKQuantityType(.height)
        case .bodyMass:
            return HKQuantityType(.bodyMass)
        case .bodyMassIndex:
            return HKQuantityType(.bodyMassIndex)
        case .bodyFatPercentage:
            return HKQuantityType(.bodyFatPercentage)
        case .leanBodyMass:
            return HKQuantityType(.leanBodyMass)
        case .waistCircumference:
            return HKQuantityType(.waistCircumference)
        case .stepCount:
            return HKQuantityType(.stepCount)
        case .distanceWalkingRunning:
            return HKQuantityType(.distanceWalkingRunning)
        case .activeEnergyBurned:
            return HKQuantityType(.activeEnergyBurned)
        case .basalEnergyBurned:
            return HKQuantityType(.basalEnergyBurned)
        case .exerciseTime:
            return HKQuantityType(.appleExerciseTime)
        case .standTime:
            return HKQuantityType(.appleStandTime)
        case .flightsClimbed:
            return HKQuantityType(.flightsClimbed)
        case .sleepAnalysis:
            return HKCategoryType(.sleepAnalysis)
        case .oxygenSaturation:
            return HKQuantityType(.oxygenSaturation)
        case .peakExpiratoryFlowRate:
            return HKQuantityType(.peakExpiratoryFlowRate)
        case .forcedVitalCapacity:
            return HKQuantityType(.forcedVitalCapacity)
        case .vo2Max:
            return HKQuantityType(.vo2Max)
        }
    }
    
    var defaultUnit: HKUnit {
        switch self {
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return HKUnit.millimeterOfMercury()
        case .heartRate, .restingHeartRate:
            return HKUnit.count().unitDivided(by: .minute())
        case .respiratoryRate:
            return HKUnit.count().unitDivided(by: .minute())
        case .bodyTemperature:
            return HKUnit.degreeFahrenheit()
        case .bloodGlucose:
            return HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        case .totalCholesterol, .ldlCholesterol, .hdlCholesterol, .triglycerides:
            return HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        case .hba1c:
            return HKUnit.percent()
        case .height:
            return HKUnit.inch()
        case .bodyMass, .leanBodyMass:
            return HKUnit.pound()
        case .bodyMassIndex:
            return HKUnit.count()
        case .bodyFatPercentage:
            return HKUnit.percent()
        case .waistCircumference:
            return HKUnit.inch()
        case .stepCount, .flightsClimbed:
            return HKUnit.count()
        case .distanceWalkingRunning:
            return HKUnit.mile()
        case .activeEnergyBurned, .basalEnergyBurned:
            return HKUnit.kilocalorie()
        case .exerciseTime, .standTime:
            return HKUnit.minute()
        case .sleepAnalysis:
            return HKUnit.minute()
        case .oxygenSaturation:
            return HKUnit.percent()
        case .peakExpiratoryFlowRate, .forcedVitalCapacity:
            return HKUnit.liter().unitDivided(by: .minute())
        case .vo2Max:
            return HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute()))
        }
    }
}

// MARK: - Health Metric Model
struct HealthKitMetric: Codable, Identifiable, Equatable {
    let id: String
    let type: HealthMetricType
    let value: Double
    let unit: String
    let date: Date
    let source: String?
    let notes: String?
    
    init(id: String = UUID().uuidString, type: HealthMetricType, value: Double, unit: String, date: Date = Date(), source: String? = nil, notes: String? = nil) {
        self.id = id
        self.type = type
        self.value = value
        self.unit = unit
        self.date = date
        self.source = source
        self.notes = notes
    }
    
    init(from sample: HKQuantitySample, type: HealthMetricType) {
        self.id = sample.uuid.uuidString
        self.type = type
        self.value = sample.quantity.doubleValue(for: type.defaultUnit)
        self.unit = type.defaultUnit.unitString
        self.date = sample.startDate
        self.source = sample.sourceRevision.source.name
        self.notes = nil
    }
    
    init(from sample: HKCategorySample, type: HealthMetricType) {
        self.id = sample.uuid.uuidString
        self.type = type
        self.value = Double(sample.value)
        self.unit = type.defaultUnit.unitString
        self.date = sample.startDate
        self.source = sample.sourceRevision.source.name
        self.notes = nil
    }
}

// MARK: - Blood Pressure Model
struct BloodPressure: Codable, Identifiable, Sendable {
    let id: String
    let systolic: Double
    let diastolic: Double
    let date: Date
    let source: String?
    
    nonisolated init(id: String = UUID().uuidString, systolic: Double, diastolic: Double, date: Date = Date(), source: String? = nil) {
        self.id = id
        self.systolic = systolic
        self.diastolic = diastolic
        self.date = date
        self.source = source
    }
    
    var category: BloodPressureCategory {
        if systolic < 120 && diastolic < 80 {
            return .normal
        } else if systolic < 130 && diastolic < 80 {
            return .elevated
        } else if systolic < 140 || diastolic < 90 {
            return .stage1Hypertension
        } else if systolic < 180 || diastolic < 120 {
            return .stage2Hypertension
        } else {
            return .hypertensiveCrisis
        }
    }
}

enum BloodPressureCategory: String, CaseIterable {
    case normal = "Normal"
    case elevated = "Elevated"
    case stage1Hypertension = "Stage 1 Hypertension"
    case stage2Hypertension = "Stage 2 Hypertension"
    case hypertensiveCrisis = "Hypertensive Crisis"
    
    var color: String {
        switch self {
        case .normal: return "green"
        case .elevated: return "yellow"
        case .stage1Hypertension: return "orange"
        case .stage2Hypertension: return "red"
        case .hypertensiveCrisis: return "darkred"
        }
    }
}

// MARK: - Health Profile Model
struct LocalHealthProfile: Codable {
    var age: Int?
    var gender: Gender?
    var height: Double?
    var weight: Double?
    var goals: [HealthGoal]
    var medicalConditions: [String]
    var medications: [String]
    var allergies: [String]
    var emergencyContact: EmergencyContact?
    
    init(age: Int? = nil, gender: Gender? = nil, height: Double? = nil, weight: Double? = nil, goals: [HealthGoal] = [], medicalConditions: [String] = [], medications: [String] = [], allergies: [String] = [], emergencyContact: EmergencyContact? = nil) {
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.goals = goals
        self.medicalConditions = medicalConditions
        self.medications = medications
        self.allergies = allergies
        self.emergencyContact = emergencyContact
    }
    
    var bmi: Double? {
        guard let height = height, let weight = weight, height > 0 else { return nil }
        let heightInMeters = height * 0.0254 // Convert inches to meters
        let weightInKg = weight * 0.453592 // Convert pounds to kg
        return weightInKg / (heightInMeters * heightInMeters)
    }
    
    var bmiCategory: BMICategory? {
        guard let bmi = bmi else { return nil }
        if bmi < 18.5 {
            return .underweight
        } else if bmi < 25 {
            return .normal
        } else if bmi < 30 {
            return .overweight
        } else {
            return .obese
        }
    }
}

// Gender enum is now defined in BackendModels.swift to avoid duplication
// Use the consolidated version with Sendable conformance

enum BMICategory: String, CaseIterable {
    case underweight = "Underweight"
    case normal = "Normal"
    case overweight = "Overweight"
    case obese = "Obese"
}

// MARK: - Model Consolidation Notice
// HealthGoal and EmergencyContact are now defined in BackendModels.swift to avoid duplication
// Use the consolidated versions with proper Sendable conformance

// MARK: - Health Data Summary
struct HealthDataSummary: Codable {
    let date: Date
    let stepCount: Int?
    let activeCalories: Double?
    let exerciseMinutes: Int?
    let sleepHours: Double?
    let averageHeartRate: Double?
    let restingHeartRate: Double?
    let bloodPressure: BloodPressure?
    let weight: Double?
    
    init(date: Date = Date(), stepCount: Int? = nil, activeCalories: Double? = nil, exerciseMinutes: Int? = nil, sleepHours: Double? = nil, averageHeartRate: Double? = nil, restingHeartRate: Double? = nil, bloodPressure: BloodPressure? = nil, weight: Double? = nil) {
        self.date = date
        self.stepCount = stepCount
        self.activeCalories = activeCalories
        self.exerciseMinutes = exerciseMinutes
        self.sleepHours = sleepHours
        self.averageHeartRate = averageHeartRate
        self.restingHeartRate = restingHeartRate
        self.bloodPressure = bloodPressure
        self.weight = weight
    }
}

// MARK: - Health Permission Model
struct HealthPermission: Codable {
    let type: HealthMetricType
    let isAuthorized: Bool
    let canRead: Bool
    let canWrite: Bool
    let requestedDate: Date
    let grantedDate: Date?
    
    init(type: HealthMetricType, isAuthorized: Bool = false, canRead: Bool = false, canWrite: Bool = false, requestedDate: Date = Date(), grantedDate: Date? = nil) {
        self.type = type
        self.isAuthorized = isAuthorized
        self.canRead = canRead
        self.canWrite = canWrite
        self.requestedDate = requestedDate
        self.grantedDate = grantedDate
    }
}

// MARK: - Health Error Types
enum HealthKitError: @preconcurrency LocalizedError {
    case notAvailable
    case notAuthorized
    case dataNotAvailable
    case invalidData
    case writeFailed
    case readFailed
    case authorizationFailed
    case backgroundDeliveryFailed
    case invalidHealthKitType
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .dataNotAvailable:
            return "Requested health data is not available"
        case .invalidData:
            return "Invalid health data provided"
        case .writeFailed:
            return "Failed to write health data"
        case .readFailed:
            return "Failed to read health data"
        case .authorizationFailed:
            return "HealthKit authorization failed"
        case .backgroundDeliveryFailed:
            return "Failed to enable background delivery"
        case .invalidHealthKitType:
            return "Invalid HealthKit data type"
        }
    }
}