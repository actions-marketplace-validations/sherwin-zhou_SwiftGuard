import Foundation

struct OpenAIProvider: LLMProvider {
    let name = "OpenAI"
    let model: String
    let apiKey: String

    init(config: ProviderConfig) throws {
        self.model = config.model
        guard let key = config.apiKey
            ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            ?? ProcessInfo.processInfo.environment["LLM_VISION_API_KEY"] else {
            throw LLMError.apiKeyMissing(provider: "OpenAI")
        }
        self.apiKey = key
    }

    func complete(system: String, messages: [ChatMessage], responseFormat: ResponseFormat?) async throws -> String {
        var allMessages: [[String: Any]] = [
            ["role": "system", "content": system]
        ]
        allMessages += messages.map { ["role": $0.role.rawValue, "content": $0.content] }

        var body: [String: Any] = [
            "model": model,
            "messages": allMessages
        ]

        if responseFormat == .json {
            body["response_format"] = ["type": "json_object"]
        }

        return try await callOpenAI(body: body)
    }

    func completeWithVision(system: String, messages: [VisionMessage]) async throws -> String {
        var allMessages: [[String: Any]] = [
            ["role": "system", "content": system]
        ]

        for msg in messages {
            let contentParts: [[String: Any]] = msg.content.map { part in
                switch part {
                case .text(let text):
                    return ["type": "text", "text": text]
                case .image(let data, let mediaType):
                    return [
                        "type": "image_url",
                        "image_url": ["url": "data:\(mediaType);base64,\(data.base64EncodedString())"]
                    ]
                }
            }
            allMessages.append(["role": msg.role.rawValue, "content": contentParts])
        }

        let body: [String: Any] = [
            "model": model,
            "messages": allMessages
        ]

        return try await callOpenAI(body: body)
    }

    private func callOpenAI(body: [String: Any]) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        guard httpResponse.statusCode == 200 else {
            throw LLMError.requestFailed(statusCode: httpResponse.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let choices = json["choices"] as! [[String: Any]]
        let message = choices.first?["message"] as! [String: Any]
        guard let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }
        return content
    }
}
