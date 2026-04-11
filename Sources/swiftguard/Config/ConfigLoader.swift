import Foundation
import Yams

struct ConfigLoader {
    static func load(from projectPath: String, overridePath: String? = nil) throws -> SwiftGuardConfig {
        let configPath: String
        if let override = overridePath {
            configPath = override
        } else {
            configPath = (projectPath as NSString).appendingPathComponent(".swiftguard.yml")
        }

        guard FileManager.default.fileExists(atPath: configPath) else {
            return Self.defaultConfig()
        }

        let yamlString = try String(contentsOfFile: configPath, encoding: .utf8)
        let decoder = YAMLDecoder()
        return try decoder.decode(SwiftGuardConfig.self, from: yamlString)
    }

    static func defaultConfig() -> SwiftGuardConfig {
        SwiftGuardConfig(
            llm: LLMConfig(
                text: ProviderConfig(provider: .anthropic, model: "claude-sonnet-4-20250514", apiKey: nil, baseURL: nil),
                vision: ProviderConfig(provider: .openai, model: "gpt-4o", apiKey: nil, baseURL: nil)
            ),
            testing: TestingConfig(scheme: nil, simulator: "iPhone 16 Pro", regressionPath: "UITests/Regression/", timeout: 300, enableExecution: true),
            screenshots: ScreenshotConfig(captureOnEveryStep: true, captureOnFailure: true, enableVisionAnalysis: true, maxScreenshotsPerTest: 10),
            codeQuality: CodeQualityConfig(
                commitMessageFormat: .conventional,
                namingConventions: NamingConfig(enforceSwiftGuidelines: true, prefixRules: nil, customRules: nil),
                architecturePattern: .mvvm,
                maxPRSize: PRSizeThresholds(small: 100, medium: 300, large: 500)
            ),
            security: SecurityConfig(enabled: true, customRules: nil),
            teamWorkflow: TeamWorkflowConfig(autoAssignReviewers: true, moduleOwners: nil, requireDocUpdate: true, autoLabels: true),
            report: ReportConfig(uploadScreenshots: true, showPassingTests: true, collapsibleSections: true, maxCommentLength: nil),
            scan: ScanConfig(includePaths: ["Sources/"], excludePaths: ["Pods/", ".build/", "DerivedData/"], maxViews: 20)
        )
    }
}
