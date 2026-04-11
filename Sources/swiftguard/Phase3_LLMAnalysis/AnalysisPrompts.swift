import Foundation

struct AnalysisPrompts {
    static func systemPrompt(architecture: ArchitecturePattern) -> String {
        """
        You are a senior Swift/iOS engineer performing a comprehensive code review on a pull request. \
        You have deep expertise in Swift 6.0, SwiftUI, Combine, async/await, iOS architecture patterns \
        (MVVM, TCA, Clean), iOS security best practices, performance optimization, and API design.

        Analyze the provided code changes and respond with JSON matching this exact schema:

        {
          "architectureFindings": [{"severity": "critical|warning|info", "file": "path", "line": null, "description": "what", "suggestion": "fix", "pattern": "which pattern"}],
          "securityFindings": [{"severity": "critical|warning|info", "category": "hardcodedSecret|insecureNetwork|inputValidation|forceUnwrap|keychainMisuse|dataExposure|injection", "file": "path", "line": null, "description": "desc", "remediation": "fix"}],
          "performanceFindings": [{"severity": "critical|warning|info", "category": "mainThreadBlocking|unnecessaryRerender|missingCache|retainCycle|nPlusOne|heavyComputation|missingLazy", "file": "path", "line": null, "description": "desc", "suggestion": "fix"}],
          "breakingChanges": [{"type": "removedPublicAPI|changedSignature|addedProtocolRequirement|removedEnumCase|changedReturnType|removedDefaultValue", "symbol": "name", "file": "path", "line": null, "description": "desc", "migrationHint": "hint"}],
          "impactAnalysis": {"directlyAffected": [{"name": "mod", "path": "p", "reason": "r"}], "transitivelyAffected": [], "blastRadius": "low|medium|high|critical", "summary": "text"},
          "splitSuggestion": null
        }

        Project architecture pattern: \(architecture.rawValue)
        Respond ONLY with valid JSON. No markdown, no explanation.
        """
    }

    static func buildAnalysisPrompt(context: ProjectContext) -> String {
        var prompt = "## PR: \(context.prMetadata.title)\n"
        if let desc = context.prMetadata.description {
            prompt += "## Description: \(desc)\n"
        }
        prompt += "## Changed files:\n\n"

        for file in context.changedFiles {
            prompt += "### \(file.path) (+\(file.linesAdded) -\(file.linesDeleted))\n"
            prompt += "```diff\n\(file.diff)\n```\n\n"
            if !file.isDeleted {
                prompt += "Full file content:\n```swift\n\(file.content)\n```\n\n"
            }
        }

        if !context.dependencyFiles.isEmpty {
            prompt += "## Dependency context:\n"
            for dep in context.dependencyFiles {
                prompt += "### \(dep.path) (referenced by \(dep.referencedBy))\n"
                prompt += "```swift\n\(dep.content)\n```\n\n"
            }
        }

        return prompt
    }
}
