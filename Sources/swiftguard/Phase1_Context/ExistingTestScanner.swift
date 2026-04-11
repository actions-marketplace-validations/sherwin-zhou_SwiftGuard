import Foundation

struct ExistingTestScanner {
    func scan(projectPath: String, config: SwiftGuardConfig) throws -> [ExistingTest] {
        var tests: [ExistingTest] = []
        let testPath = (projectPath as NSString).appendingPathComponent(config.testing.regressionPath)

        guard FileManager.default.fileExists(atPath: testPath) else { return [] }

        let enumerator = FileManager.default.enumerator(atPath: testPath)
        while let file = enumerator?.nextObject() as? String {
            guard file.hasSuffix(".swift") else { continue }
            let filePath = (testPath as NSString).appendingPathComponent(file)
            let content = try String(contentsOfFile: filePath, encoding: .utf8)

            let classPattern = try NSRegularExpression(pattern: #"class\s+(\w+)\s*:\s*XCTestCase"#)
            let methodPattern = try NSRegularExpression(pattern: #"func\s+(test\w+)\s*\("#)

            let classMatches = classPattern.matches(in: content, range: NSRange(content.startIndex..., in: content))
            let methodMatches = methodPattern.matches(in: content, range: NSRange(content.startIndex..., in: content))

            for classMatch in classMatches {
                guard let classRange = Range(classMatch.range(at: 1), in: content) else { continue }
                let className = String(content[classRange])
                let methods = methodMatches.compactMap { match -> String? in
                    guard let range = Range(match.range(at: 1), in: content) else { return nil }
                    return String(content[range])
                }

                tests.append(ExistingTest(
                    fileName: file,
                    className: className,
                    testMethods: methods,
                    targetView: nil
                ))
            }
        }

        return tests
    }
}
