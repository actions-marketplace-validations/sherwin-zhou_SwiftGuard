import Foundation

struct MarkdownFormatter {
    static func format(report: SwiftGuardReport, config: SwiftGuardConfig) -> String {
        var md = "## 🛡️ SwiftGuard Report\n\n"
        md += "**Verdict: \(verdictEmoji(report.summary.overallVerdict)) \(report.summary.overallVerdict.rawValue)**"
        md += " — \(report.summary.criticalIssues) critical, \(report.summary.warnings) warnings, \(report.summary.infos) infos\n\n"

        // Summary table
        md += "### Summary\n\n"
        md += "| Category | Result |\n|----------|--------|\n"
        md += "| PR size | \(sizeEmoji(report.prSize.category)) \(report.prSize.category.rawValue) (\(report.prSize.totalLines) lines, \(report.prSize.totalFiles) files) |\n"

        let validCommits = report.commitLint.filter(\.isValid).count
        md += "| Commits | \(validCommits == report.commitLint.count ? "✅" : "⚠️") \(validCommits)/\(report.commitLint.count) valid |\n"

        if !report.namingViolations.isEmpty {
            md += "| Naming | ⚠️ \(report.namingViolations.count) violations |\n"
        } else {
            md += "| Naming | ✅ No violations |\n"
        }

        if let testResults = report.testResults {
            let total = testResults.regressionResults.count + testResults.incrementalResults.count
            let passed = testResults.regressionResults.filter { $0.status == .passed }.count
                + testResults.incrementalResults.filter { $0.status == .passed }.count
            md += "| Tests | \(passed == total ? "✅" : "🔴") \(passed)/\(total) passed |\n"
        }

        if let score = report.visualAnalysis?.overallScore {
            md += "| Visual score | \(score)/100 |\n"
        }

        if !report.securityFindings.isEmpty {
            let critical = report.securityFindings.filter { $0.severity == .critical }.count
            md += "| Security | \(critical > 0 ? "🔴" : "⚠️") \(report.securityFindings.count) findings |\n"
        } else {
            md += "| Security | ✅ No issues |\n"
        }

        if !report.breakingChanges.isEmpty {
            md += "| Breaking changes | ⚠️ \(report.breakingChanges.count) detected |\n"
        } else {
            md += "| Breaking changes | ✅ None detected |\n"
        }

        md += "\n---\n\n"

        // Critical issues
        if !report.securityFindings.filter({ $0.severity == .critical }).isEmpty {
            md += "### 🔴 Critical issues\n\n"
            for finding in report.securityFindings.filter({ $0.severity == .critical }) {
                md += "<details>\n<summary><b>Security: \(finding.description) in \(finding.file)\(finding.line.map { ":\($0)" } ?? "")</b></summary>\n\n"
                md += "**Remediation:** \(finding.remediation)\n\n</details>\n\n"
            }
            md += "---\n\n"
        }

        // Warnings
        let warningFindings = report.securityFindings.filter { $0.severity == .warning }
        let perfWarnings = report.performanceFindings.filter { $0.severity == .warning }
        if !warningFindings.isEmpty || !perfWarnings.isEmpty || !report.namingViolations.isEmpty {
            md += "### ⚠️ Warnings\n\n"

            for finding in warningFindings {
                md += "<details>\n<summary><b>Security: \(finding.description)</b></summary>\n\n"
                md += "File: `\(finding.file)`\(finding.line.map { " line \($0)" } ?? "")\n\n"
                md += "**Fix:** \(finding.remediation)\n\n</details>\n\n"
            }

            for finding in perfWarnings {
                md += "<details>\n<summary><b>Performance: \(finding.description)</b></summary>\n\n"
                md += "File: `\(finding.file)`\(finding.line.map { " line \($0)" } ?? "")\n\n"
                md += "**Suggestion:** \(finding.suggestion)\n\n</details>\n\n"
            }

            if !report.namingViolations.isEmpty {
                md += "<details>\n<summary><b>Naming: \(report.namingViolations.count) violations</b></summary>\n\n"
                md += "| File | Line | Symbol | Expected | Actual |\n|------|------|--------|----------|--------|\n"
                for v in report.namingViolations {
                    md += "| \(v.file) | \(v.line) | `\(v.symbol)` | \(v.expected) | \(v.actual) |\n"
                }
                md += "\n</details>\n\n"
            }

            md += "---\n\n"
        }

        // Test results
        if let testResults = report.testResults {
            md += "### 🧪 Test results\n\n"

            if !testResults.regressionResults.isEmpty {
                let passed = testResults.regressionResults.filter { $0.status == .passed }.count
                md += "#### Regression tests (\(passed)/\(testResults.regressionResults.count))\n\n"
                md += "| Test | Status | Duration |\n|------|--------|----------|\n"
                for result in testResults.regressionResults {
                    md += "| \(result.testName) | \(result.status == .passed ? "✅" : "🔴") | \(String(format: "%.1fs", result.duration)) |\n"
                }
                md += "\n"
            }

            if !testResults.incrementalResults.isEmpty {
                let passed = testResults.incrementalResults.filter { $0.status == .passed }.count
                md += "#### Incremental tests (\(passed)/\(testResults.incrementalResults.count))\n\n"
                md += "| Test | Status | Duration |\n|------|--------|----------|\n"
                for result in testResults.incrementalResults {
                    md += "| \(result.testName) | \(result.status == .passed ? "✅" : "🔴") | \(String(format: "%.1fs", result.duration)) |\n"
                }
                md += "\n"
            }

            md += "---\n\n"
        }

        // Impact analysis
        md += "### 📊 Impact analysis\n\n"
        md += "**Blast radius: \(blastEmoji(report.impactAnalysis.blastRadius)) \(report.impactAnalysis.blastRadius.rawValue.capitalized)**\n\n"
        md += report.impactAnalysis.summary + "\n\n"

        if !report.impactAnalysis.directlyAffected.isEmpty {
            md += "Directly affected:\n"
            for module in report.impactAnalysis.directlyAffected {
                md += "- `\(module.name)` — \(module.reason)\n"
            }
            md += "\n"
        }

        md += "---\n\n"

        // Commit messages
        if !report.commitLint.isEmpty {
            md += "### 📋 Commit messages\n\n"
            md += "| SHA | Message | Valid |\n|-----|---------|-------|\n"
            for result in report.commitLint {
                let sha = String(result.commit.sha.prefix(7))
                md += "| \(sha) | \(result.commit.message) | \(result.isValid ? "✅" : "❌") |\n"
            }
            md += "\n---\n\n"
        }

        // Suggested reviewers
        if !report.suggestedReviewers.isEmpty {
            md += "### 👥 Suggested reviewers\n\n"
            md += "| Reviewer | Reason |\n|----------|--------|\n"
            for reviewer in report.suggestedReviewers {
                md += "| \(reviewer.username) | \(reviewer.reason) |\n"
            }
            md += "\n---\n\n"
        }

        md += "<sub>🛡️ SwiftGuard v1.0</sub>\n"

        // Truncate if needed
        if let maxLen = config.report.maxCommentLength, md.count > maxLen {
            md = String(md.prefix(maxLen - 50)) + "\n\n..._truncated — report too long_\n"
        }

        return md
    }

    private static func verdictEmoji(_ verdict: Verdict) -> String {
        switch verdict {
        case .clean: return "✅"
        case .warnings: return "⚠️"
        case .critical: return "🔴"
        case .blocked: return "⛔"
        }
    }

    private static func sizeEmoji(_ size: PRSizeCategory) -> String {
        switch size {
        case .small: return "🟢"
        case .medium: return "🟡"
        case .large: return "🟠"
        case .extraLarge: return "🔴"
        }
    }

    private static func blastEmoji(_ radius: BlastRadius) -> String {
        switch radius {
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🟠"
        case .critical: return "🔴"
        }
    }
}
