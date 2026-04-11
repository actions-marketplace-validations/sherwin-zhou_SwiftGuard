import Foundation

struct DependencyResolver {
    func resolve(changedFiles: [ChangedFile], projectPath: String) throws -> [DependencyFile] {
        var dependencies: [DependencyFile] = []

        for file in changedFiles where file.path.hasSuffix(".swift") && !file.isDeleted {
            let importPattern = try NSRegularExpression(pattern: #"import\s+(\w+)"#)
            let content = file.content
            let matches = importPattern.matches(in: content, range: NSRange(content.startIndex..., in: content))

            for match in matches {
                guard let range = Range(match.range(at: 1), in: content) else { continue }
                let moduleName = String(content[range])
                // Skip system frameworks
                let systemModules = ["Foundation", "SwiftUI", "UIKit", "Combine", "CoreData", "XCTest"]
                if systemModules.contains(moduleName) { continue }

                // Try to find local files matching the module
                let possiblePath = "Sources/\(moduleName)/"
                let fullPath = (projectPath as NSString).appendingPathComponent(possiblePath)
                if FileManager.default.fileExists(atPath: fullPath) {
                    dependencies.append(DependencyFile(
                        path: possiblePath,
                        content: "",
                        referencedBy: file.path
                    ))
                }
            }
        }

        return dependencies
    }
}
