//
//  ProcessingStatus.swift
//  SuperOne
//
//  Created by Claude Code on 7/27/25.
//

// MARK: - Model Consolidation Notice

// ProcessingStatus and related processing enums have been consolidated into BackendModels.swift
// to avoid type conflicts. Please use the following types from BackendModels.swift:
//
// - ProcessingStatus
// - ProcessingErrorType
// - ProcessingWorkflowStep
//
// These consolidated types include proper Sendable conformance and comprehensive case coverage.