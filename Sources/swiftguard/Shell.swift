import Foundation

struct Shell {
    @discardableResult
    static func run(_ args: String..., in directory: String? = nil) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args

        if let dir = directory {
            process.currentDirectoryURL = URL(fileURLWithPath: dir)
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
