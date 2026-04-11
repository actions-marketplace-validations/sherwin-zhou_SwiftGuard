import Foundation

struct CommitCollector {
    func collect(projectPath: String, baseSha: String) throws -> [CommitInfo] {
        let output = try Shell.run("git", "log", "--format=%H\t%s\t%an", "\(baseSha)..HEAD", in: projectPath)
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }

        return lines.compactMap { line in
            let parts = line.components(separatedBy: "\t")
            guard parts.count >= 3 else { return nil }
            return CommitInfo(sha: parts[0], message: parts[1], author: parts[2])
        }
    }
}
