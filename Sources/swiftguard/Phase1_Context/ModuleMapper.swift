import Foundation

struct ModuleMapper {
    func map(projectPath: String, config: SwiftGuardConfig) throws -> [ModuleOwnership] {
        // Use config-defined owners if present
        if let owners = config.teamWorkflow.moduleOwners, !owners.isEmpty {
            return owners
        }

        // Try CODEOWNERS
        let codeownersPath = (projectPath as NSString).appendingPathComponent("CODEOWNERS")
        let githubCodeownersPath = (projectPath as NSString).appendingPathComponent(".github/CODEOWNERS")

        let path = FileManager.default.fileExists(atPath: codeownersPath) ? codeownersPath :
                   FileManager.default.fileExists(atPath: githubCodeownersPath) ? githubCodeownersPath : nil

        guard let ownersPath = path else { return [] }

        let content = try String(contentsOfFile: ownersPath, encoding: .utf8)
        let lines = content.components(separatedBy: "\n")
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        return lines.compactMap { line in
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 2 else { return nil }
            let linePath = parts[0]
            let owners = Array(parts[1...])
            return ModuleOwnership(path: linePath, owners: owners)
        }
    }
}
