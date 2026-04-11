import Foundation

struct ProjectContext {
    let changedFiles: [ChangedFile]
    let dependencyFiles: [DependencyFile]
    let existingTests: [ExistingTest]
    let commits: [CommitInfo]
    let prMetadata: PRMetadata
    let config: SwiftGuardConfig
    let moduleMap: [ModuleOwnership]
}

struct ChangedFile {
    let path: String
    let content: String
    let diff: String
    let linesAdded: Int
    let linesDeleted: Int
    let isNewFile: Bool
    let isDeleted: Bool
}

struct DependencyFile {
    let path: String
    let content: String
    let referencedBy: String
}

struct CommitInfo: Codable {
    let sha: String
    let message: String
    let author: String
}

struct PRMetadata {
    let number: Int
    let title: String
    let description: String?
    let baseBranch: String
    let headBranch: String
    let author: String
    let totalLinesChanged: Int
    let totalFilesChanged: Int
}

struct ExistingTest {
    let fileName: String
    let className: String
    let testMethods: [String]
    let targetView: String?
}
