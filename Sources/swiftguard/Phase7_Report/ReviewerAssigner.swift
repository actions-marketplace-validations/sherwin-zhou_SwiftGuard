import Foundation

struct ReviewerAssigner {
    func assign(changedFiles: [ChangedFile], moduleMap: [ModuleOwnership]) -> [ReviewerAssignment] {
        var assignments: [String: (reasons: Set<String>, modules: Set<String>)] = [:]

        for file in changedFiles {
            for ownership in moduleMap {
                if file.path.hasPrefix(ownership.path) {
                    for owner in ownership.owners {
                        var entry = assignments[owner] ?? (reasons: [], modules: [])
                        entry.reasons.insert("Owns \(ownership.path)")
                        entry.modules.insert(ownership.path)
                        assignments[owner] = entry
                    }
                }
            }
        }

        return assignments.map { (username, info) in
            ReviewerAssignment(
                username: username,
                reason: info.reasons.joined(separator: ", "),
                modules: Array(info.modules)
            )
        }.sorted { $0.username < $1.username }
    }
}
