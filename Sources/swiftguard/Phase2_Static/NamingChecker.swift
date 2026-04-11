import Foundation

struct NamingChecker {
    static func check(changedFiles: [ChangedFile], config: NamingConfig) -> [NamingViolation] {
        guard config.enforceSwiftGuidelines else { return [] }

        var violations: [NamingViolation] = []

        for file in changedFiles where file.path.hasSuffix(".swift") && !file.isDeleted {
            let lines = file.content.components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                let lineNum = index + 1

                // Check type names (should be PascalCase)
                if let match = line.range(of: #"(?:class|struct|enum|protocol|actor)\s+([a-z_]\w*)"#, options: .regularExpression) {
                    let symbol = String(line[match]).components(separatedBy: .whitespaces).last ?? ""
                    violations.append(NamingViolation(
                        file: file.path, line: lineNum, symbol: symbol,
                        expected: "PascalCase", actual: "starts with lowercase",
                        rule: "swift_type_naming"
                    ))
                }

                // Check variable/function names (should be camelCase, not snake_case)
                if let match = line.range(of: #"(?:var|let|func)\s+(\w*_\w+)"#, options: .regularExpression) {
                    let symbol = String(line[match]).components(separatedBy: .whitespaces).last ?? ""
                    // Skip if it's a constant pattern like SCREAMING_SNAKE
                    if symbol != symbol.uppercased() {
                        violations.append(NamingViolation(
                            file: file.path, line: lineNum, symbol: symbol,
                            expected: "camelCase", actual: "snake_case",
                            rule: "swift_var_naming"
                        ))
                    }
                }
            }
        }

        return violations
    }
}
