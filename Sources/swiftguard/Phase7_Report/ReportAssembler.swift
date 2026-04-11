import Foundation

struct ReportAssembler {
    func assemble(
        context: ProjectContext,
        staticResult: StaticAnalysisResult,
        llmResult: LLMAnalysisResult,
        generatedTests: GeneratedTests,
        testExecution: TestExecutionResult?,
        visualResult: VisualAnalysis?,
        config: SwiftGuardConfig
    ) -> SwiftGuardReport {
        let criticalCount = llmResult.securityFindings.filter { $0.severity == .critical }.count
            + llmResult.performanceFindings.filter { $0.severity == .critical }.count
            + llmResult.architectureFindings.filter { $0.severity == .critical }.count

        let warningCount = llmResult.securityFindings.filter { $0.severity == .warning }.count
            + llmResult.performanceFindings.filter { $0.severity == .warning }.count
            + llmResult.architectureFindings.filter { $0.severity == .warning }.count
            + staticResult.namingViolations.count
            + staticResult.docUpdateNeeded.count

        let infoCount = llmResult.securityFindings.filter { $0.severity == .info }.count
            + llmResult.performanceFindings.filter { $0.severity == .info }.count
            + llmResult.architectureFindings.filter { $0.severity == .info }.count

        let testsRun = (testExecution?.regressionResults.count ?? 0) + (testExecution?.incrementalResults.count ?? 0)
        let testsPassed = (testExecution?.regressionResults.filter { $0.status == .passed }.count ?? 0)
            + (testExecution?.incrementalResults.filter { $0.status == .passed }.count ?? 0)

        let verdict: Verdict
        if criticalCount > 0 {
            verdict = .critical
        } else if warningCount > 0 {
            verdict = .warnings
        } else {
            verdict = .clean
        }

        let summary = ReportSummary(
            criticalIssues: criticalCount,
            warnings: warningCount,
            infos: infoCount,
            testsRun: testsRun,
            testsPassed: testsPassed,
            visualScore: visualResult?.overallScore,
            prSizeCategory: staticResult.prSize.category,
            overallVerdict: verdict
        )

        // Determine reviewers
        let reviewerAssigner = ReviewerAssigner()
        let reviewers = reviewerAssigner.assign(
            changedFiles: context.changedFiles,
            moduleMap: context.moduleMap
        )

        // Determine labels
        let labels = LabelManager.labels(
            prSize: staticResult.prSize,
            hasSecurity: !llmResult.securityFindings.isEmpty,
            needsDocs: !staticResult.docUpdateNeeded.isEmpty,
            shouldSplit: staticResult.prSize.shouldSplit
        )

        return SwiftGuardReport(
            summary: summary,
            prSize: staticResult.prSize,
            commitLint: staticResult.commitLint,
            namingViolations: staticResult.namingViolations,
            docUpdates: staticResult.docUpdateNeeded,
            architectureFindings: llmResult.architectureFindings,
            securityFindings: llmResult.securityFindings,
            performanceFindings: llmResult.performanceFindings,
            breakingChanges: llmResult.breakingChanges,
            impactAnalysis: llmResult.impactAnalysis,
            splitSuggestion: llmResult.splitSuggestion,
            testResults: testExecution,
            generatedCode: generatedTests.regressionTests + generatedTests.incrementalTests,
            visualAnalysis: visualResult,
            screenshots: testExecution?.screenshots ?? [],
            suggestedReviewers: reviewers,
            suggestedLabels: labels
        )
    }
}
