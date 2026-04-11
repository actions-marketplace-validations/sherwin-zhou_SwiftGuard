import Foundation

struct PRSizeChecker {
    static func check(context: ProjectContext) -> PRSizeAssessment {
        let totalLines = context.changedFiles.reduce(0) { $0 + $1.linesAdded + $1.linesDeleted }
        let totalFiles = context.changedFiles.count
        let thresholds = context.config.codeQuality.maxPRSize

        let category: PRSizeCategory
        if totalLines <= thresholds.small {
            category = .small
        } else if totalLines <= thresholds.medium {
            category = .medium
        } else if totalLines <= thresholds.large {
            category = .large
        } else {
            category = .extraLarge
        }

        return PRSizeAssessment(
            category: category,
            totalLines: totalLines,
            totalFiles: totalFiles,
            shouldSplit: category == .extraLarge
        )
    }
}
