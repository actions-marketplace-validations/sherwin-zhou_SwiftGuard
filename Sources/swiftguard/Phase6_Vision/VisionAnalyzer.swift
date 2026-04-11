import Foundation

struct VisionAnalyzer {
    let provider: LLMProvider

    func analyze(screenshots: [Screenshot], config: SwiftGuardConfig) async throws -> VisualAnalysis {
        guard !screenshots.isEmpty else {
            return VisualAnalysis(overallScore: 100, findings: [], summary: "No screenshots to analyze")
        }

        let system = VisionPrompts.systemPrompt
        var contentParts: [ContentPart] = [.text(VisionPrompts.analysisPrompt)]

        for screenshot in screenshots.prefix(config.screenshots.maxScreenshotsPerTest) {
            contentParts.append(.text("Screenshot: \(screenshot.testName) - \(screenshot.stepName)"))
            contentParts.append(.image(data: screenshot.imageData, mediaType: "image/png"))
        }

        let message = VisionMessage(role: .user, content: contentParts)
        let response = try await provider.completeWithVision(system: system, messages: [message])

        // Parse response
        return try parseVisualAnalysis(response)
    }

    private func parseVisualAnalysis(_ response: String) throws -> VisualAnalysis {
        var jsonString = response
        if let startRange = response.range(of: "```json") {
            jsonString = String(response[startRange.upperBound...])
            if let endRange = jsonString.range(of: "```") {
                jsonString = String(jsonString[..<endRange.lowerBound])
            }
        }

        let data = jsonString.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8)!
        return try JSONDecoder().decode(VisualAnalysis.self, from: data)
    }
}
