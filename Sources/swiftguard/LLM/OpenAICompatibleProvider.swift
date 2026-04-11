import Foundation

struct OpenAICompatibleProvider: LLMProvider {
    let name = "OpenAI-Compatible"
    let model: String
    let apiKey: String
    let baseURL: String

    init(config: ProviderConfig) throws {
        self.model = config.model
        self.baseURL = config.baseURL ?? "http://localhost:11434/v1"
        guard let key = config.apiKey
            ?? ProcessInfo.processInfo.environment["LLM_API_KEY"] else {
            throw LLMError.apiKeyMissing(provider: "OpenAI-Compatible")
        }
        self.apiKey = key
    }

    func complete(system: String, messages: [ChatMessage], responseFormat: ResponseFormat?) async throws -> String {
        var allMessages: [[String: Any]] = [
            ["role": "system", "content": system]
        ]
        allMessages += messages.map { ["role": $0.role.rawValue, "content": $0.content] }

        let body: [String: Any] = [
            "model": model,
            "messages": allMessages
        ]

        return try await callAPI(body: body)
    }

    func completeWithVision(system: String, messages: [VisionMessage]) async throws -> String {
        throw LLMError.visionNotSupported
    }

    private func callAPI(body: [String: Any]) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
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
