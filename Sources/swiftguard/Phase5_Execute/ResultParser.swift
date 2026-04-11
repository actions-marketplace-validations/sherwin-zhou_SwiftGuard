import Foundation

struct ResultParser {
    static func parse(output: String) -> [TestResult] {
        var results: [TestResult] = []
        let lines = output.components(separatedBy: "\n")

        for line in lines {
            // Match test results: "Test Case '-[ClassName testMethod]' passed (0.123 seconds)."
            let pattern = #"Test Case '-\[(\w+) (\w+)\]' (passed|failed) \((\d+\.\d+) seconds\)"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
                continue
            }

            let className = match.range(at: 1).location != NSNotFound ?
                String(line[Range(match.range(at: 1), in: line)!]) : ""
            let testName = match.range(at: 2).location != NSNotFound ?
                String(line[Range(match.range(at: 2), in: line)!]) : ""
            let statusStr = match.range(at: 3).location != NSNotFound ?
                String(line[Range(match.range(at: 3), in: line)!]) : ""
            let duration = match.range(at: 4).location != NSNotFound ?
                Double(String(line[Range(match.range(at: 4), in: line)!])) ?? 0 : 0

            let status: TestStatus = statusStr == "passed" ? .passed : .failed

            results.append(TestResult(
                testName: testName,
                className: className,
                status: status,
                duration: duration,
                failureMessage: status == .failed ? "Test failed" : nil,
                screenshots: []
            ))
        }

        return results
    }
}
