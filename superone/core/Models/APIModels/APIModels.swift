//
//  APIModels.swift
//  SuperOne
//
//  Created by Claude Code on 2/2/25.
//

// MARK: - API Model Hub
// This file serves as a central import for API models to avoid circular dependencies
// Individual model definitions are in their respective specialized files:
// - UploadModels.swift: Upload request/response models
// - HealthAnalysisModels.swift: Health analysis models (removed to avoid conflicts)
// - UploadHistoryModels.swift: Upload history and filtering models
// - HealthAnalysisPreferences.swift: User preference models

// Note: Actual model definitions have been moved to specialized files to resolve
// duplicate type declaration conflicts with existing models in:
// - APIResponseModels.swift
// - BackendModels.swift
// - NetworkModels.swift

// This file is kept minimal to avoid type conflicts while maintaining import structure