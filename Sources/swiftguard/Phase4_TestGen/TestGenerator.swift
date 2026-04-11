import Foundation

struct TestGenerator {
    let provider: LLMProvider

    func generate(context: ProjectContext, viewInfos: [ViewInfo], config: SwiftGuardConfig) async throws -> GeneratedTests {
        let regressionTests: [GeneratedTestFile] = []
        var incrementalTests: [GeneratedTestFile] = []
        let totalIterations = 0

        for viewInfo in viewInfos where !viewInfo.isDependency {
            let prompt = TestPrompts.buildIncrementalTestPrompt(viewInfo: viewInfo, context: context)
            let system = TestPrompts.systemPrompt

            let code = try await provider.complete(system: system, messages: [.user(prompt)])
            let cleanCode = TestPrompts.extractCode(from: code)

            incrementalTests.append(GeneratedTestFile(
                fileName: "Incremental\(viewInfo.name)Tests.swift",
                viewName: viewInfo.name,
                testCount: cleanCode.components(separatedBy: "func test").count - 1,
                code: cleanCode,
                category: .incremental
            ))
        }

        return GeneratedTests(
            regressionTests: regressionTests,
            incrementalTests: incrementalTests,
            compilerIterations: totalIterations
        )
    }
}
