import Foundation

struct AnthropicProvider: LLMProvider {
    let name = "Anthropic"
    let model: String
    let apiKey: String

    init(config: ProviderConfig) throws {
        self.model = config.model
        guard let key = config.apiKey
            ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
            ?? ProcessInfo.processInfo.environment["LLM_API_KEY"] else {
            throw LLMError.apiKeyMissing(provider: "Anthropic")
        }
        self.apiKey = key
    }

    func complete(system: String, messages: [ChatMessage], responseFormat: ResponseFormat?) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 8192,
            "system": system,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        guard httpResponse.statusCode == 200 else {
            throw LLMError.requestFailed(statusCode: httpResponse.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let content = json["content"] as! [[String: Any]]
        guard let text = content.first?["text"] as? String else {
            throw LLMError.invalidResponse
        }
        return text
    }

    func completeWithVision(system: String, messages: [VisionMessage]) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let messagePayloads: [[String: Any]] = messages.map { msg in
            let contentParts: [[String: Any]] = msg.content.map { part in
                switch part {
                case .text(let text):
                    return ["type": "text", "text": text]
                case .image(let data, let mediaType):
                    return [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": mediaType,
                            "data": data.base64EncodedString()
                        ]
                    ]
                }
            }
            return ["role": msg.role.rawValue, "content": contentParts]
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 8192,
            "system": system,
            "messages": messagePayloads
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        guard httpResponse.statusCode == 200 else {
            throw LLMError.requestFailed(statusCode: httpResponse.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let content = json["content"] as! [[String: Any]]
        guard let text = content.first?["text"] as? String else {
            throw LLMError.invalidResponse
        }
        return text
    }
}
