import Foundation

struct VisualAnalysis: Codable {
    let overallScore: Int
    let findings: [VisualFinding]
    let summary: String
}

struct VisualFinding: Codable {
    let severity: Severity
    let category: VisualCategory
    let screenshot: String
    let description: String
    let suggestion: String
}

enum VisualCategory: String, Codable {
    case layout, accessibility, consistency
    case content, darkMode, deviceAdaptation
}
