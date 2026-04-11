import Foundation

struct TestPrompts {
    static let systemPrompt = """
        You are an expert iOS test engineer. Generate XCUITest code for the given SwiftUI view.

        Rules:
        - Use XCUIApplication() for app launch
        - Add screenshot capture using XCTAttachment at key steps
        - Use accessibility identifiers when available, labels otherwise
        - Test both happy path and edge cases
        - Each test should be independent
        - Respond with ONLY Swift code, no explanation
        """

    static func buildIncrementalTestPrompt(viewInfo: ViewInfo, context: ProjectContext) -> String {
        var prompt = "Generate XCUITests for the \(viewInfo.name) view.\n\n"
        prompt += "View elements:\n"
        for element in viewInfo.elements {
            prompt += "- \(element.type.rawValue)"
            if let label = element.label { prompt += " label=\"\(label)\"" }
            if let id = element.identifier { prompt += " id=\"\(id)\"" }
            prompt += "\n"
        }

        if !viewInfo.stateProperties.isEmpty {
            prompt += "\nState properties: \(viewInfo.stateProperties.joined(separator: ", "))\n"
        }

        if !viewInfo.navigationTargets.isEmpty {
            prompt += "Navigation targets: \(viewInfo.navigationTargets.joined(separator: ", "))\n"
        }

        prompt += "\nCapture a screenshot after each significant interaction.\n"
        return prompt
    }

    static func extractCode(from response: String) -> String {
        var code = response
        if let startRange = code.range(of: "```swift") {
            code = String(code[startRange.upperBound...])
            if let endRange = code.range(of: "```") {
                code = String(code[..<endRange.lowerBound])
            }
        } else if let startRange = code.range(of: "```") {
            code = String(code[startRange.upperBound...])
            if let endRange = code.range(of: "```") {
                code = String(code[..<endRange.lowerBound])
            }
        }
        return code.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
