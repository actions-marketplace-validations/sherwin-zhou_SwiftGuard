import Foundation

struct AnalysisResponseParser {
    static func parse(_ response: String) throws -> LLMAnalysisResult {
        // Extract JSON from response (handle markdown code blocks)
        var jsonString = response
        if let startRange = response.range(of: "```json") {
            jsonString = String(response[startRange.upperBound...])
            if let endRange = jsonString.range(of: "```") {
                jsonString = String(jsonString[..<endRange.lowerBound])
            }
        } else if let startRange = response.range(of: "```") {
            jsonString = String(response[startRange.upperBound...])
            if let endRange = jsonString.range(of: "```") {
                jsonString = String(jsonString[..<endRange.lowerBound])
            }
        }

        let data = jsonString.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8)!
        return try JSONDecoder().decode(LLMAnalysisResult.self, from: data)
    }
}
