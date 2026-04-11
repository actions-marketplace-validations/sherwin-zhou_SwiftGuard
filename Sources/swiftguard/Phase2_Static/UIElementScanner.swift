import Foundation

struct UIElementScanner {
    static func scan(changedFiles: [ChangedFile]) -> [ViewInfo] {
        var viewInfos: [ViewInfo] = []

        for file in changedFiles where file.path.hasSuffix(".swift") && !file.isDeleted {
            let content = file.content

            // Check if this is a SwiftUI View
            guard content.contains(": View") || content.contains(": some View") else { continue }

            var elements: [UIElement] = []
            let lines = content.components(separatedBy: "\n")

            let patterns: [(ElementType, String)] = [
                (.button, #"Button\s*\("([^"]*)"#),
                (.textField, #"TextField\s*\("([^"]*)"#),
                (.secureField, #"SecureField\s*\("([^"]*)"#),
                (.navigationLink, #"NavigationLink\s*\("([^"]*)"#),
                (.toggle, #"Toggle\s*\("([^"]*)"#),
                (.picker, #"Picker\s*\("([^"]*)"#),
                (.text, #"Text\s*\("([^"]*)"#),
                (.image, #"Image\s*\("([^"]*)"#),
            ]

            for (lineIndex, line) in lines.enumerated() {
                for (type, pattern) in patterns {
                    if let regex = try? NSRegularExpression(pattern: pattern),
                       let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                       let labelRange = Range(match.range(at: 1), in: line) {
                        elements.append(UIElement(
                            type: type,
                            label: String(line[labelRange]),
                            identifier: nil,
                            lineNumber: lineIndex + 1
                        ))
                    }
                }

                // Check for accessibility identifiers
                if let idRegex = try? NSRegularExpression(pattern: #"\.accessibilityIdentifier\s*\("([^"]*)"#),
                   let match = idRegex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                   let range = Range(match.range(at: 1), in: line) {
                    if let last = elements.last {
                        elements.removeLast()
                        elements.append(UIElement(
                            type: last.type,
                            label: last.label,
                            identifier: String(line[range]),
                            lineNumber: last.lineNumber
                        ))
                    }
                }
            }

            // Extract view name
            let viewNamePattern = try? NSRegularExpression(pattern: #"struct\s+(\w+)\s*:\s*View"#)
            let viewName: String
            if let match = viewNamePattern?.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
               let range = Range(match.range(at: 1), in: content) {
                viewName = String(content[range])
            } else {
                viewName = (file.path as NSString).deletingPathExtension.components(separatedBy: "/").last ?? "Unknown"
            }

            // Extract @State properties
            let statePattern = try? NSRegularExpression(pattern: #"@(?:State|StateObject|ObservedObject|Binding)\s+(?:private\s+)?var\s+(\w+)"#)
            let stateProperties = statePattern?.matches(in: content, range: NSRange(content.startIndex..., in: content)).compactMap { match -> String? in
                guard let range = Range(match.range(at: 1), in: content) else { return nil }
                return String(content[range])
            } ?? []

            // Extract navigation targets
            let navPattern = try? NSRegularExpression(pattern: #"NavigationLink.*destination:\s*(\w+)"#)
            let navTargets = navPattern?.matches(in: content, range: NSRange(content.startIndex..., in: content)).compactMap { match -> String? in
                guard let range = Range(match.range(at: 1), in: content) else { return nil }
                return String(content[range])
            } ?? []

            if !elements.isEmpty {
                viewInfos.append(ViewInfo(
                    name: viewName,
                    filePath: file.path,
                    elements: elements,
                    stateProperties: stateProperties,
                    navigationTargets: navTargets,
                    isDependency: false
                ))
            }
        }

        return viewInfos
    }
}
