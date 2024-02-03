import Foundation
import ChatToys

enum LLM {
    static func create() -> FunctionCallingLLM? {
        guard let key = UserDefaults.standard.string(forKey: PrefKey.openAIApiKey.rawValue)?.nilIfEmpty else { return nil }
        let org = UserDefaults.standard.string(forKey: PrefKey.openAIOrgId.rawValue)?.nilIfEmpty
        let gpt4 = PrefKey.useGPT4.currentBoolValue
        return ChatGPT(credentials: .init(apiKey: key, orgId: org), options: .init(model: gpt4 ? .gpt4_turbo_preview : .gpt35_turbo_0125, printToConsole: true))
    }
}
