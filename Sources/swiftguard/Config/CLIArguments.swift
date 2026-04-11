import ArgumentParser
import Foundation

@main
struct SwiftGuardCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftguard",
        abstract: "AI-powered PR review agent for Swift projects",
        version: "1.0.0"
    )

    @Argument(help: "Path to the project root")
    var projectPath: String = "."

    @Option(name: .long, help: "Run mode: github-action or local")
    var mode: RunMode = .local

    @Option(name: .long, help: "Base commit SHA for diff (github-action mode)")
    var baseSha: String?

    @Option(name: .long, help: "PR number (github-action mode)")
    var prNumber: Int?

    @Option(name: .long, help: "Repository in owner/repo format (github-action mode)")
    var repo: String?

    @Option(name: .long, help: "Simulator device ID")
    var simulator: String?

    @Option(name: .long, help: "Path to .swiftguard.yml config file")
    var config: String?

    @Flag(name: .long, help: "Skip LLM phases (3, 4, 6) — only run static analysis")
    var dryRun: Bool = false

    mutating func run() async throws {
        let pipeline = SwiftGuardPipeline(arguments: self)
        try await pipeline.run()
    }
}

enum RunMode: String, ExpressibleByArgument {
    case githubAction = "github-action"
    case local
}
