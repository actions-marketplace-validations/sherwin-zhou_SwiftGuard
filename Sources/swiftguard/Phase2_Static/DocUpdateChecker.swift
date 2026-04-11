import Foundation

struct DocUpdateChecker {
    static func check(changedFiles: [ChangedFile], config: SwiftGuardConfig) -> [DocUpdateNeeded] {
        guard config.teamWorkflow.requireDocUpdate else { return [] }

        var needed: [DocUpdateNeeded] = []

        for file in changedFiles where file.path.hasSuffix(".swift") && !file.isDeleted {
            let lines = file.content.components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                // Check for public API without doc comment
                if trimmed.hasPrefix("public func ") || trimmed.hasPrefix("public var ") ||
                   trimmed.hasPrefix("public class ") || trimmed.hasPrefix("public struct ") {
                    // Check if previous line has a doc comment
                    let prevLine = index > 0 ? lines[index - 1].trimmingCharacters(in: .whitespaces) : ""
                    if !prevLine.hasPrefix("///") && !prevLine.hasPrefix("*/") {
                        let symbol = trimmed.components(separatedBy: .whitespaces).prefix(3).joined(separator: " ")
                        needed.append(DocUpdateNeeded(
                            file: file.path,
                            reason: "Public API added without documentation comment",
                            symbol: symbol
                        ))
                    }
                }
            }
        }

        return needed
    }
}
