import Foundation

struct DiffAnalyzer {
    func analyze(projectPath: String, baseSha: String) throws -> [ChangedFile] {
        let output = try Shell.run("git", "diff", "--name-status", baseSha, "HEAD", in: projectPath)
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }

        var files: [ChangedFile] = []
        for line in lines {
            let parts = line.components(separatedBy: "\t")
            guard parts.count >= 2 else { continue }
            let status = parts[0]
            let path = parts[1]

            let isNewFile = status.hasPrefix("A")
            let isDeleted = status.hasPrefix("D")

            let fullPath = (projectPath as NSString).appendingPathComponent(path)
            let content: String
            if isDeleted {
                content = ""
            } else {
                content = (try? String(contentsOfFile: fullPath, encoding: .utf8)) ?? ""
            }

            let diff = (try? Shell.run("git", "diff", baseSha, "HEAD", "--", path, in: projectPath)) ?? ""
            let linesAdded = diff.components(separatedBy: "\n").filter { $0.hasPrefix("+") && !$0.hasPrefix("+++") }.count
            let linesDeleted = diff.components(separatedBy: "\n").filter { $0.hasPrefix("-") && !$0.hasPrefix("---") }.count

            files.append(ChangedFile(
                path: path,
                content: content,
                diff: diff,
                linesAdded: linesAdded,
                linesDeleted: linesDeleted,
                isNewFile: isNewFile,
                isDeleted: isDeleted
            ))
        }
        return files
    }
}
