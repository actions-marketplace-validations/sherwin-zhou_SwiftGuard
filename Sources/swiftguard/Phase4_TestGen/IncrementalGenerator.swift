import Foundation

struct IncrementalGenerator {
    let provider: LLMProvider

    func generate(viewInfo: ViewInfo, context: ProjectContext) async throws -> GeneratedTestFile {
        let prompt = TestPrompts.buildIncrementalTestPrompt(viewInfo: viewInfo, context: context)
        let code = try await provider.complete(system: TestPrompts.systemPrompt, messages: [.user(prompt)])
        let cleanCode = TestPrompts.extractCode(from: code)

        return GeneratedTestFile(
            fileName: "Incremental\(viewInfo.name)Tests.swift",
            viewName: viewInfo.name,
            testCount: cleanCode.components(separatedBy: "func test").count - 1,
            code: cleanCode,
            category: .incremental
        )
    }
}
