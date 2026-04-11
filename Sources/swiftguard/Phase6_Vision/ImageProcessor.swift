import Foundation

struct ImageProcessor {
    static func loadImage(at path: String) throws -> Data {
        guard let data = FileManager.default.contents(atPath: path) else {
            throw ImageError.fileNotFound(path)
        }
        return data
    }

    static func mediaType(for path: String) -> String {
        if path.hasSuffix(".png") { return "image/png" }
        if path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") { return "image/jpeg" }
        return "image/png"
    }
}

enum ImageError: Error, LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Image file not found: \(path)"
        }
    }
}
