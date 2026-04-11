import Foundation

struct TestRunner {
    func run(tests: GeneratedTests, projectPath: String, config: SwiftGuardConfig) async throws -> TestExecutionResult {
        // Write test files to a temporary location
        let testDir = (projectPath as NSString).appendingPathComponent(".build/swiftguard/generated_tests")
        try FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)

        let allTests = tests.regressionTests + tests.incrementalTests
        for test in allTests {
            let filePath = (testDir as NSString).appendingPathComponent(test.fileName)
            try test.code.write(toFile: filePath, atomically: true, encoding: .utf8)
        }

        // Build for testing
        let scheme = config.testing.scheme ?? ""
        let simulator = config.testing.simulator
        let buildResult = try Shell.run(
            "xcodebuild", "build-for-testing",
            "-scheme", scheme,
            "-destination", "platform=iOS Simulator,name=\(simulator)",
            in: projectPath
        )

        let buildSuccess = !buildResult.contains("BUILD FAILED")

        guard buildSuccess else {
            return TestExecutionResult(
                buildSuccess: false,
                buildLog: buildResult,
                regressionResults: [],
                incrementalResults: [],
                screenshots: []
            )
        }

        // Run tests
        let testResult = try Shell.run(
            "xcodebuild", "test-without-building",
            "-scheme", scheme,
            "-destination", "platform=iOS Simulator,name=\(simulator)",
            in: projectPath
        )

        let results = ResultParser.parse(output: testResult)
        let screenshots = try ScreenshotExtractor.extract(projectPath: projectPath)

        return TestExecutionResult(
            buildSuccess: true,
            buildLog: nil,
            regressionResults: results.filter { $0.className.contains("Regression") },
            incrementalResults: results.filter { $0.className.contains("Incremental") },
            screenshots: screenshots
        )
    }
}
