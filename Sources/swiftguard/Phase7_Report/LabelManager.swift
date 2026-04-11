import Foundation

struct LabelManager {
    static func labels(
        prSize: PRSizeAssessment,
        hasSecurity: Bool,
        needsDocs: Bool,
        shouldSplit: Bool
    ) -> [String] {
        var labels: [String] = []

        // Size label
        labels.append("size/\(prSize.category.rawValue)")

        if hasSecurity {
            labels.append("security-review")
        }

        if needsDocs {
            labels.append("needs-docs")
        }

        if shouldSplit {
            labels.append("needs-split")
        }

        return labels
    }
}
