import Foundation

struct SwiftGuardReport {
    let summary: ReportSummary
    let prSize: PRSizeAssessment
    let commitLint: [CommitLintResult]
    let namingViolations: [NamingViolation]
    let docUpdates: [DocUpdateNeeded]
    let architectureFindings: [ArchitectureFinding]
    let securityFindings: [SecurityFinding]
    let performanceFindings: [PerformanceFinding]
    let breakingChanges: [BreakingChange]
    let impactAnalysis: ImpactAnalysis
    let splitSuggestion: SplitSuggestion?
    let testResults: TestExecutionResult?
    let generatedCode: [GeneratedTestFile]
    let visualAnalysis: VisualAnalysis?
    let screenshots: [Screenshot]
    let suggestedReviewers: [ReviewerAssignment]
    let suggestedLabels: [String]
}

struct ReportSummary {
    let criticalIssues: Int
    let warnings: Int
    let infos: Int
    let testsRun: Int
    let testsPassed: Int
    let visualScore: Int?
    let prSizeCategory: PRSizeCategory
    let overallVerdict: Verdict
}

enum Verdict: String {
    case clean = "Clean"
    case warnings = "Needs attention"
    case critical = "Critical issues found"
    case blocked = "Blocked - must fix before merge"
}

struct ReviewerAssignment {
    let username: String
    let reason: String
    let modules: [String]
}

enum Severity: String, Codable {
    case info, warning, critical
}
