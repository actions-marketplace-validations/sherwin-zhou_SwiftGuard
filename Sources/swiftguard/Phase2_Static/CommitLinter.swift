import Foundation

struct CommitLinter {
    static func lint(commits: [CommitInfo], format: CommitFormat) -> [CommitLintResult] {
        commits.map { commit in
            switch format {
            case .conventional, .angular:
                let pattern = #"^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?: .+"#
                let regex = try? NSRegularExpression(pattern: pattern)
                let range = NSRange(commit.message.startIndex..., in: commit.message)
                let isValid = regex?.firstMatch(in: commit.message, range: range) != nil
                let violations = isValid ? [] : ["Commit message does not follow conventional format: type(scope): message"]
                return CommitLintResult(commit: commit, isValid: isValid, violations: violations)
            case .freeform:
                return CommitLintResult(commit: commit, isValid: true, violations: [])
            case .custom:
                return CommitLintResult(commit: commit, isValid: true, violations: [])
            }
        }
    }
}
