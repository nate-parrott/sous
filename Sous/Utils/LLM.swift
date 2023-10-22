import Foundation
import ChatToys

enum LLM {
    static func create() -> FunctionCallingLLM? {
        guard let key = UserDefaults.standard.string(forKey: PrefKey.openAIApiKey.rawValue)?.nilIfEmpty else { return nil }
        let org = UserDefaults.standard.string(forKey: PrefKey.openAIOrgId.rawValue)?.nilIfEmpty
        return ChatGPT(credentials: .init(apiKey: key, orgId: org), options: .init(model: .gpt35_turbo_16k, printToConsole: true))
    }
}
