import Foundation

struct LLMProviderFactory {
    static func create(from config: ProviderConfig) throws -> LLMProvider {
        switch config.provider {
        case .anthropic:
            return try AnthropicProvider(config: config)
        case .openai:
            return try OpenAIProvider(config: config)
        case .openRouter:
            return try OpenRouterProvider(config: config)
        case .openaiCompatible:
            return try OpenAICompatibleProvider(config: config)
        }
    }

    static func createProviders(from config: LLMConfig) throws -> (text: LLMProvider, vision: LLMProvider) {
        let textProvider = try create(from: config.text)
        let visionProvider = try create(from: config.vision)
        return (textProvider, visionProvider)
    }
}
