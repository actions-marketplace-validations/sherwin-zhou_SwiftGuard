import Foundation

struct ScreenshotExtractor {
    static func extract(projectPath: String) throws -> [Screenshot] {
        // Find xcresult bundles
        let derivedDataPath = (projectPath as NSString).appendingPathComponent("DerivedData")
        guard FileManager.default.fileExists(atPath: derivedDataPath) else { return [] }

        // In a real implementation, we'd use xcresulttool to extract screenshots
        // For now, look for screenshots in the build directory
        let screenshotDir = (projectPath as NSString).appendingPathComponent(".build/swiftguard/screenshots")
        try FileManager.default.createDirectory(atPath: screenshotDir, withIntermediateDirectories: true)

        var screenshots: [Screenshot] = []
        if let files = FileManager.default.enumerator(atPath: screenshotDir) {
            while let file = files.nextObject() as? String {
                if file.hasSuffix(".png") || file.hasSuffix(".jpg") {
                    let fullPath = (screenshotDir as NSString).appendingPathComponent(file)
                    if let data = FileManager.default.contents(atPath: fullPath) {
                        screenshots.append(Screenshot(
                            testName: (file as NSString).deletingPathExtension,
                            stepName: "captured",
                            imagePath: fullPath,
                            imageData: data
                        ))
                    }
                }
            }
        }

        return screenshots
    }
}
