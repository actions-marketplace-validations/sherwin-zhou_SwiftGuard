import Foundation

struct SwiftGuardPipeline {
    let arguments: SwiftGuardCLI

    func run() async throws {
        let projectPath = (arguments.projectPath as NSString).standardizingPath
        print("🛡️ SwiftGuard v1.0.0")
        print("   Project: \(projectPath)")
        print("   Mode: \(arguments.mode.rawValue)")
        print("")

        // Load config
        print("📋 Loading configuration...")
        let config = try ConfigLoader.load(from: projectPath, overridePath: arguments.config)

        // Phase 1: Context Gathering
        print("📦 Phase 1: Gathering context...")
        let context = try await gatherContext(projectPath: projectPath, config: config)

        // Phase 2: Static Analysis
        print("🔍 Phase 2: Static analysis...")
        let staticResult = try performStaticAnalysis(context: context)

        // Print Phase 1+2 summary
        print("   Found \(context.changedFiles.count) changed files, \(context.commits.count) commits")
        print("   PR size: \(staticResult.prSize.category.rawValue) (\(staticResult.prSize.totalLines) lines, \(staticResult.prSize.totalFiles) files)")
        if !staticResult.commitLint.isEmpty {
            let valid = staticResult.commitLint.filter(\.isValid).count
            print("   Commit lint: \(valid)/\(staticResult.commitLint.count) valid")
        }
        if !staticResult.namingViolations.isEmpty {
            print("   Naming violations: \(staticResult.namingViolations.count)")
            for v in staticResult.namingViolations {
                print("     - \(v.file):\(v.line) \(v.symbol) (expected \(v.expected))")
            }
        }
        if !staticResult.docUpdateNeeded.isEmpty {
            print("   Missing docs: \(staticResult.docUpdateNeeded.count)")
            for d in staticResult.docUpdateNeeded {
                print("     - \(d.file): \(d.symbol)")
            }
        }
        if !staticResult.viewInfos.isEmpty {
            print("   SwiftUI views found: \(staticResult.viewInfos.map(\.name).joined(separator: ", "))")
        }
        print("")

        // Phase 3: LLM Analysis
        var llmResult: LLMAnalysisResult
        if arguments.dryRun {
            print("⏭️ Phase 3: Skipped (dry-run mode)")
            llmResult = LLMAnalysisResult(
                architectureFindings: [], securityFindings: [], performanceFindings: [],
                breakingChanges: [],
                impactAnalysis: ImpactAnalysis(directlyAffected: [], transitivelyAffected: [], blastRadius: .low, summary: "Dry run — LLM analysis skipped"),
                splitSuggestion: nil
            )
        } else {
            print("🤖 Phase 3: LLM-powered analysis...")
            llmResult = try await performLLMAnalysis(context: context, config: config)
        }

        // Phase 4: Test Generation
        var generatedTests: GeneratedTests
        if arguments.dryRun {
            print("⏭️ Phase 4: Skipped (dry-run mode)")
            generatedTests = GeneratedTests(regressionTests: [], incrementalTests: [], compilerIterations: 0)
        } else {
            print("🧪 Phase 4: Generating tests...")
            generatedTests = try await generateTests(context: context, staticResult: staticResult, config: config)
        }

        // Phase 5: Test Execution
        var testExecution: TestExecutionResult? = nil
        if !arguments.dryRun && config.testing.enableExecution {
            print("▶️ Phase 5: Executing tests...")
            testExecution = try await executeTests(generatedTests: generatedTests, projectPath: projectPath, config: config)
        } else {
            print("⏭️ Phase 5: Skipped\(arguments.dryRun ? " (dry-run mode)" : " (execution disabled)")")
        }

        // Phase 6: Visual Analysis
        var visualResult: VisualAnalysis? = nil
        if !arguments.dryRun, config.screenshots.enableVisionAnalysis, let execution = testExecution, !execution.screenshots.isEmpty {
            print("👁️ Phase 6: Visual analysis...")
            visualResult = try await performVisualAnalysis(screenshots: execution.screenshots, config: config)
        } else {
            print("⏭️ Phase 6: Skipped\(arguments.dryRun ? " (dry-run mode)" : " (no screenshots or vision disabled)")")
        }

        // Phase 7: Report
        print("📊 Phase 7: Assembling report...")
        let report = assembleReport(
            context: context,
            staticResult: staticResult,
            llmResult: llmResult,
            generatedTests: generatedTests,
            testExecution: testExecution,
            visualResult: visualResult,
            config: config
        )

        try await deliverReport(report: report, context: context, config: config)

        print("")
        print("🛡️ SwiftGuard complete — \(report.summary.overallVerdict.rawValue)")
    }

    // MARK: - Phase implementations (stubs for now)

    private func gatherContext(projectPath: String, config: SwiftGuardConfig) async throws -> ProjectContext {
        let diffAnalyzer = DiffAnalyzer()
        let baseSha = arguments.baseSha ?? "HEAD~1"
        let changedFiles = try diffAnalyzer.analyze(projectPath: projectPath, baseSha: baseSha)

        let dependencyResolver = DependencyResolver()
        let dependencyFiles = try dependencyResolver.resolve(changedFiles: changedFiles, projectPath: projectPath)

        let testScanner = ExistingTestScanner()
        let existingTests = try testScanner.scan(projectPath: projectPath, config: config)

        let commitCollector = CommitCollector()
        let commits = try commitCollector.collect(projectPath: projectPath, baseSha: baseSha)

        let moduleMapper = ModuleMapper()
        let moduleMap = try moduleMapper.map(projectPath: projectPath, config: config)

        let prMetadata = PRMetadata(
            number: arguments.prNumber ?? 0,
            title: "",
            description: nil,
            baseBranch: "main",
            headBranch: "",
            author: "",
            totalLinesChanged: changedFiles.reduce(0) { $0 + $1.linesAdded + $1.linesDeleted },
            totalFilesChanged: changedFiles.count
        )

        return ProjectContext(
            changedFiles: changedFiles,
            dependencyFiles: dependencyFiles,
            existingTests: existingTests,
            commits: commits,
            prMetadata: prMetadata,
            config: config,
            moduleMap: moduleMap
        )
    }

    private func performStaticAnalysis(context: ProjectContext) throws -> StaticAnalysisResult {
        let prSize = PRSizeChecker.check(context: context)
        let commitLint = CommitLinter.lint(commits: context.commits, format: context.config.codeQuality.commitMessageFormat)
        let namingViolations = NamingChecker.check(changedFiles: context.changedFiles, config: context.config.codeQuality.namingConventions)
        let docUpdates = DocUpdateChecker.check(changedFiles: context.changedFiles, config: context.config)
        let viewInfos = UIElementScanner.scan(changedFiles: context.changedFiles)

        return StaticAnalysisResult(
            prSize: prSize,
            commitLint: commitLint,
            namingViolations: namingViolations,
            docUpdateNeeded: docUpdates,
            viewInfos: viewInfos
        )
    }

    private func performLLMAnalysis(context: ProjectContext, config: SwiftGuardConfig) async throws -> LLMAnalysisResult {
        let textProvider = try LLMProviderFactory.create(from: config.llm.text)
        let analyzer = CodeAnalyzer(provider: textProvider)
        return try await analyzer.analyze(context: context)
    }

    private func generateTests(context: ProjectContext, staticResult: StaticAnalysisResult, config: SwiftGuardConfig) async throws -> GeneratedTests {
        let textProvider = try LLMProviderFactory.create(from: config.llm.text)
        let generator = TestGenerator(provider: textProvider)
        return try await generator.generate(context: context, viewInfos: staticResult.viewInfos, config: config)
    }

    private func executeTests(generatedTests: GeneratedTests, projectPath: String, config: SwiftGuardConfig) async throws -> TestExecutionResult {
        let runner = TestRunner()
        return try await runner.run(tests: generatedTests, projectPath: projectPath, config: config)
    }

    private func performVisualAnalysis(screenshots: [Screenshot], config: SwiftGuardConfig) async throws -> VisualAnalysis {
        let visionProvider = try LLMProviderFactory.create(from: config.llm.vision)
        let analyzer = VisionAnalyzer(provider: visionProvider)
        return try await analyzer.analyze(screenshots: screenshots, config: config)
    }

    private func assembleReport(
        context: ProjectContext,
        staticResult: StaticAnalysisResult,
        llmResult: LLMAnalysisResult,
        generatedTests: GeneratedTests,
        testExecution: TestExecutionResult?,
        visualResult: VisualAnalysis?,
        config: SwiftGuardConfig
    ) -> SwiftGuardReport {
        let assembler = ReportAssembler()
        return assembler.assemble(
            context: context,
            staticResult: staticResult,
            llmResult: llmResult,
            generatedTests: generatedTests,
            testExecution: testExecution,
            visualResult: visualResult,
            config: config
        )
    }

    private func deliverReport(report: SwiftGuardReport, context: ProjectContext, config: SwiftGuardConfig) async throws {
        let markdown = MarkdownFormatter.format(report: report, config: config)

        switch arguments.mode {
        case .githubAction:
            guard let repo = arguments.repo, let prNumber = arguments.prNumber else {
                print("⚠️ Missing --repo or --pr-number for github-action mode. Printing locally.")
                print(markdown)
                return
            }
            let client = GitHubClient()
            try await client.postComment(markdown: markdown, repo: repo, prNumber: prNumber)

            if config.teamWorkflow.autoAssignReviewers && !report.suggestedReviewers.isEmpty {
                try await client.requestReviewers(
                    reviewers: report.suggestedReviewers.map(\.username),
                    repo: repo,
                    prNumber: prNumber
                )
            }

            if config.teamWorkflow.autoLabels && !report.suggestedLabels.isEmpty {
                try await client.addLabels(labels: report.suggestedLabels, repo: repo, prNumber: prNumber)
            }
        case .local:
            print(markdown)
        }

        // Save results locally
        let resultsDir = (arguments.projectPath as NSString).appendingPathComponent(".build/swiftguard/results")
        try FileManager.default.createDirectory(atPath: resultsDir, withIntermediateDirectories: true)
        try markdown.write(toFile: "\(resultsDir)/report.md", atomically: true, encoding: .utf8)
    }
}
