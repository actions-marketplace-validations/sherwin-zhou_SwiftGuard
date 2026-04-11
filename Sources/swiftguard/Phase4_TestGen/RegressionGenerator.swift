import Foundation

struct RegressionGenerator {
    let provider: LLMProvider

    func generate(existingTests: [ExistingTest], viewInfos: [ViewInfo]) async throws -> [GeneratedTestFile] {
        // Stub: regression test generation
        return []
    }
}
