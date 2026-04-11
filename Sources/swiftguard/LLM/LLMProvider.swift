import Foundation

protocol LLMProvider {
    var name: String { get }

    func complete(
        system: String,
        messages: [ChatMessage],
        responseFormat: ResponseFormat?
    ) async throws -> String

    func completeWithVision(
        system: String,
        messages: [VisionMessage]
    ) async throws -> String
}

extension LLMProvider {
    func complete(system: String, messages: [ChatMessage]) async throws -> String {
        try await complete(system: system, messages: messages, responseFormat: nil)
    }
}

struct ChatMessage {
    let role: MessageRole
    let content: String

    static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: .user, content: content)
    }

    static func assistant(_ content: String) -> ChatMessage {
        ChatMessage(role: .assistant, content: content)
    }
}

struct VisionMessage {
    let role: MessageRole
    let content: [ContentPart]
}

enum ContentPart {
    case text(String)
    case image(data: Data, mediaType: String)
}

enum ResponseFormat {
    case json
    case text
}

enum MessageRole: String {
    case user
    case assistant
    case system
}

enum LLMError: Error, LocalizedError {
    case apiKeyMissing(provider: String)
    case requestFailed(statusCode: Int, body: String)
    case invalidResponse
    case visionNotSupported

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing(let provider):
            return "API key not found for \(provider). Set it via config or environment variable."
        case .requestFailed(let code, let body):
            return "LLM request failed with status \(code): \(body)"
        case .invalidResponse:
            return "Failed to parse LLM response"
        case .visionNotSupported:
            return "Vision is not supported by this provider"
        }
    }
}
