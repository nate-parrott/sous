import Foundation
import ChatToys

enum LLM {
    static func create() -> FunctionCallingLLM? {
        guard let key = UserDefaults.standard.string(forKey: "key")?.nilIfEmpty else { return nil }
        let org = UserDefaults.standard.string(forKey: "org")?.nilIfEmpty
        return ChatGPT(credentials: .init(apiKey: key, orgId: org), options: .init(model: .gpt35_turbo_16k))
    }
}
