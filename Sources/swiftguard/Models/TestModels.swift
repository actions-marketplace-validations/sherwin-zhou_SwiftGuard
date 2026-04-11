import Foundation

struct GeneratedTests {
    let regressionTests: [GeneratedTestFile]
    let incrementalTests: [GeneratedTestFile]
    let compilerIterations: Int
}

struct GeneratedTestFile: Codable {
    let fileName: String
    let viewName: String
    let testCount: Int
    let code: String
    let category: TestCategory
}

enum TestCategory: String, Codable {
    case regression, incremental
}

struct TestExecutionResult {
    let buildSuccess: Bool
    let buildLog: String?
    let regressionResults: [TestResult]
    let incrementalResults: [TestResult]
    let screenshots: [Screenshot]
}

struct TestResult {
    let testName: String
    let className: String
    let status: TestStatus
    let duration: TimeInterval
    let failureMessage: String?
    let screenshots: [Screenshot]
}

enum TestStatus: String, Codable {
    case passed, failed, skipped, errored
}

struct Screenshot {
    let testName: String
    let stepName: String
    let imagePath: String
    let imageData: Data
}
