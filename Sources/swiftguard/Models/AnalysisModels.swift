import Foundation

struct StaticAnalysisResult {
    let prSize: PRSizeAssessment
    let commitLint: [CommitLintResult]
    let namingViolations: [NamingViolation]
    let docUpdateNeeded: [DocUpdateNeeded]
    let viewInfos: [ViewInfo]
}

struct PRSizeAssessment {
    let category: PRSizeCategory
    let totalLines: Int
    let totalFiles: Int
    let shouldSplit: Bool
}

enum PRSizeCategory: String, Codable {
    case small = "S"
    case medium = "M"
    case large = "L"
    case extraLarge = "XL"
}

struct CommitLintResult {
    let commit: CommitInfo
    let isValid: Bool
    let violations: [String]
}

struct NamingViolation {
    let file: String
    let line: Int
    let symbol: String
    let expected: String
    let actual: String
    let rule: String
}

struct DocUpdateNeeded {
    let file: String
    let reason: String
    let symbol: String
}

struct ViewInfo: Codable {
    let name: String
    let filePath: String
    let elements: [UIElement]
    let stateProperties: [String]
    let navigationTargets: [String]
    let isDependency: Bool
}

struct UIElement: Codable {
    let type: ElementType
    let label: String?
    let identifier: String?
    let lineNumber: Int?
}

enum ElementType: String, Codable {
    case button, textField, secureField, navigationLink
    case toggle, picker, slider, alert, sheet
    case fullScreenCover, text, image, list
    case scrollView, tabView, menu
}

struct LLMAnalysisResult: Codable {
    let architectureFindings: [ArchitectureFinding]
    let securityFindings: [SecurityFinding]
    let performanceFindings: [PerformanceFinding]
    let breakingChanges: [BreakingChange]
    let impactAnalysis: ImpactAnalysis
    let splitSuggestion: SplitSuggestion?
}

struct ArchitectureFinding: Codable {
    let severity: Severity
    let file: String
    let line: Int?
    let description: String
    let suggestion: String
    let pattern: String
}

struct SecurityFinding: Codable {
    let severity: Severity
    let category: SecurityCategory
    let file: String
    let line: Int?
    let description: String
    let remediation: String
}

enum SecurityCategory: String, Codable {
    case hardcodedSecret
    case insecureNetwork
    case inputValidation
    case forceUnwrap
    case keychainMisuse
    case dataExposure
    case injection
}

struct PerformanceFinding: Codable {
    let severity: Severity
    let category: PerformanceCategory
    let file: String
    let line: Int?
    let description: String
    let suggestion: String
}

enum PerformanceCategory: String, Codable {
    case mainThreadBlocking
    case unnecessaryRerender
    case missingCache
    case retainCycle
    case nPlusOne
    case heavyComputation
    case missingLazy
}

struct BreakingChange: Codable {
    let type: BreakingChangeType
    let symbol: String
    let file: String
    let line: Int?
    let description: String
    let migrationHint: String?
}

enum BreakingChangeType: String, Codable {
    case removedPublicAPI
    case changedSignature
    case addedProtocolRequirement
    case removedEnumCase
    case changedReturnType
    case removedDefaultValue
}

struct ImpactAnalysis: Codable {
    let directlyAffected: [AffectedModule]
    let transitivelyAffected: [AffectedModule]
    let blastRadius: BlastRadius
    let summary: String
}

struct AffectedModule: Codable {
    let name: String
    let path: String
    let reason: String
}

enum BlastRadius: String, Codable {
    case low, medium, high, critical
}

struct SplitSuggestion: Codable {
    let reason: String
    let suggestedPRs: [SuggestedPR]
}

struct SuggestedPR: Codable {
    let title: String
    let files: [String]
    let rationale: String
    let order: Int
}
