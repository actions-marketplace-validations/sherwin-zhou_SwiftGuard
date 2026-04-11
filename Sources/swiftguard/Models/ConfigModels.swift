import Foundation

struct SwiftGuardConfig: Codable {
    let llm: LLMConfig
    let testing: TestingConfig
    let screenshots: ScreenshotConfig
    let codeQuality: CodeQualityConfig
    let security: SecurityConfig
    let teamWorkflow: TeamWorkflowConfig
    let report: ReportConfig
    let scan: ScanConfig

    enum CodingKeys: String, CodingKey {
        case llm, testing, screenshots, security, report, scan
        case codeQuality = "code_quality"
        case teamWorkflow = "team"
    }
}

struct LLMConfig: Codable {
    let text: ProviderConfig
    let vision: ProviderConfig
}

struct ProviderConfig: Codable {
    let provider: ProviderType
    let model: String
    let apiKey: String?
    let baseURL: String?

    enum CodingKeys: String, CodingKey {
        case provider, model
        case apiKey = "api_key"
        case baseURL = "base_url"
    }
}

enum ProviderType: String, Codable {
    case anthropic
    case openai
    case openRouter = "openrouter"
    case openaiCompatible = "openai-compatible"
}

struct TestingConfig: Codable {
    let scheme: String?
    let simulator: String
    let regressionPath: String
    let timeout: Int
    let enableExecution: Bool

    enum CodingKeys: String, CodingKey {
        case scheme, simulator, timeout
        case regressionPath = "regression_path"
        case enableExecution = "enable_execution"
    }
}

struct ScreenshotConfig: Codable {
    let captureOnEveryStep: Bool
    let captureOnFailure: Bool
    let enableVisionAnalysis: Bool
    let maxScreenshotsPerTest: Int

    enum CodingKeys: String, CodingKey {
        case captureOnEveryStep = "capture_on_every_step"
        case captureOnFailure = "capture_on_failure"
        case enableVisionAnalysis = "enable_vision_analysis"
        case maxScreenshotsPerTest = "max_screenshots_per_test"
    }
}

struct CodeQualityConfig: Codable {
    let commitMessageFormat: CommitFormat
    let namingConventions: NamingConfig
    let architecturePattern: ArchitecturePattern
    let maxPRSize: PRSizeThresholds

    enum CodingKeys: String, CodingKey {
        case commitMessageFormat = "commit_format"
        case namingConventions = "naming"
        case architecturePattern = "architecture"
        case maxPRSize = "max_pr_size"
    }
}

enum CommitFormat: String, Codable {
    case conventional
    case angular
    case freeform
    case custom
}

struct NamingConfig: Codable {
    let enforceSwiftGuidelines: Bool
    let prefixRules: [PrefixRule]?
    let customRules: [NamingRule]?

    enum CodingKeys: String, CodingKey {
        case enforceSwiftGuidelines = "enforce_swift_guidelines"
        case prefixRules = "prefix_rules"
        case customRules = "custom_rules"
    }
}

struct PrefixRule: Codable {
    let prefix: String
    let scope: String
    let message: String
}

struct NamingRule: Codable {
    let pattern: String
    let scope: String
    let message: String
}

enum ArchitecturePattern: String, Codable {
    case mvvm, mvc, tca, viper, clean, custom
}

struct PRSizeThresholds: Codable {
    let small: Int
    let medium: Int
    let large: Int
}

struct SecurityConfig: Codable {
    let enabled: Bool
    let customRules: [SecurityRule]?

    enum CodingKeys: String, CodingKey {
        case enabled
        case customRules = "custom_rules"
    }
}

struct SecurityRule: Codable {
    let name: String
    let pattern: String
    let severity: Severity
    let message: String
}

struct TeamWorkflowConfig: Codable {
    let autoAssignReviewers: Bool
    let moduleOwners: [ModuleOwnership]?
    let requireDocUpdate: Bool
    let autoLabels: Bool

    enum CodingKeys: String, CodingKey {
        case autoAssignReviewers = "auto_assign_reviewers"
        case moduleOwners = "module_owners"
        case requireDocUpdate = "require_doc_update"
        case autoLabels = "auto_labels"
    }
}

struct ModuleOwnership: Codable {
    let path: String
    let owners: [String]
}

struct ReportConfig: Codable {
    let uploadScreenshots: Bool
    let showPassingTests: Bool
    let collapsibleSections: Bool
    let maxCommentLength: Int?

    enum CodingKeys: String, CodingKey {
        case uploadScreenshots = "upload_screenshots"
        case showPassingTests = "show_passing_tests"
        case collapsibleSections = "collapsible_sections"
        case maxCommentLength = "max_comment_length"
    }
}

struct ScanConfig: Codable {
    let includePaths: [String]
    let excludePaths: [String]
    let maxViews: Int

    enum CodingKeys: String, CodingKey {
        case includePaths = "include_paths"
        case excludePaths = "exclude_paths"
        case maxViews = "max_views"
    }
}
