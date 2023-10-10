import Foundation
import ChatToys
import JavaScriptCore

struct CopilotState: Equatable, Codable {
    struct Message: Equatable, Codable {
        var message: LLMMessage
    }
    var messages: [Message] = []
    var typing = false
}

class CopilotDataStore: DataStore<CopilotState> {}

@MainActor
class CopilotSession: ObservableObject {
    let store = CopilotDataStore(persistenceKey: "Default", defaultModel: .init())
    let tools = Tools()

    func send(message: String) async {
        let initialMessages = await store.asyncWrite {
            $0.messages.append(.init(message: LLMMessage(role: .user, content: message)))
            $0.typing = true
            return $0.messages
        }

        // TODO: Prompt packer should take function calls into account
        guard let llm = LLM.create() else {
            store.modify { $0.messages.append(.init(message: .init(role: .system, content: "No api key"))) }
            return
        }
        let toolFunctions = tools.functions

        Task {
            var messages = initialMessages
            func append(message: LLMMessage) {
                messages.append(.init(message: message))
                store.modify { $0.messages.append(.init(message: message)) }
            }

            do {
                while true {
                    // TODO: truncate prompt
                    let resp = try await llm.complete(prompt: messages.map(\.message), functions: toolFunctions)
                    append(message: resp)
                    if let fn = resp.functionCall {
                        let res = try await self.tools.handle(functionCall: fn)
                        append(message: .init(role: .function, content: res, nameOfFunctionThatProduced: fn.name))
                    } else {
                        break
                    }
                }
                store.modify { $0.typing = false }
            } catch {
                let text = "Error: \(error)"
                append(message: .init(role: .system, content: text))
                store.modify { $0.typing = false }
            }
        }
    }
}
