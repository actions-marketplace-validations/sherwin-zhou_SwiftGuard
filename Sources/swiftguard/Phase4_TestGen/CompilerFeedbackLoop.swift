import Foundation

struct CompilerFeedbackLoop {
    let maxIterations = 3
    let provider: LLMProvider

    func generateAndValidate(testCode: String, projectPath: String, scheme: String?) async throws -> (code: String, iterations: Int) {
        var currentCode = testCode

        for iteration in 1...maxIterations {
            // Try to compile
            var buildArgs = ["xcodebuild", "build-for-testing"]
            if let scheme = scheme {
                buildArgs += ["-scheme", scheme]
            }
            buildArgs += ["-destination", "platform=iOS Simulator,name=iPhone 16 Pro"]

            do {
                let result = try Shell.run(buildArgs[0], buildArgs[1], in: projectPath)
                if !result.contains("BUILD FAILED") {
                    return (currentCode, iteration)
                }

                // Feed errors back to LLM
                currentCode = try await provider.complete(
                    system: "Fix the Swift compilation errors in the XCUITest code. Respond with ONLY the complete fixed code.",
                    messages: [
                        .user("Original code:\n\(currentCode)"),
                        .assistant("Compilation failed."),
                        .user("Swift compiler errors (iteration \(iteration)/\(maxIterations)):\n\(result)\n\nFix ALL errors.")
                    ]
                )
                currentCode = TestPrompts.extractCode(from: currentCode)
            } catch {
                return (currentCode, iteration)
            }
        }

        return (currentCode, maxIterations)
    }
}
