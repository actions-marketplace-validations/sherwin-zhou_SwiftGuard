import Foundation

struct CodeAnalyzer {
    let provider: LLMProvider

    func analyze(context: ProjectContext) async throws -> LLMAnalysisResult {
        let prompt = AnalysisPrompts.buildAnalysisPrompt(context: context)
        let system = AnalysisPrompts.systemPrompt(architecture: context.config.codeQuality.architecturePattern)

        let response = try await provider.complete(
            system: system,
            messages: [.user(prompt)],
            responseFormat: .json
        )

        return try AnalysisResponseParser.parse(response)
    }
}
