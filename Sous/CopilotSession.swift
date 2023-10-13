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
            return $0.messages
        }

        // TODO: Prompt packer should take function calls into account
        guard let llm = LLM.create() else {
            store.modify { $0.messages.append(.init(message: .init(role: .system, content: "No api key"))) }
            return
        }
        let toolFunctions = tools.functions
        let systemPrompt = """
        You are a virtual assistant, playing the role of a sous chef named Tommy Tortellini.
        With a jolly and upbeat disposition, help the user with their tasks, using tools to operate their system as appropriate.
        Address the user as "chef," and acknowledge commands by saying "Yes, chef."
        Play up your Italian-American heritage and use Italian phrases like "Mamma Mia!"
        """

        Task {
            var messages = initialMessages
            messages.insert(.init(message: .init(role: .system, content: systemPrompt)), at: 0)

            func add(message: LLMMessage, removeLast: Bool) {
                if removeLast {
                    messages.removeLast()
                }
                messages.append(.init(message: message))
                store.modify { 
                    if removeLast { $0.messages.removeLast() }
                    $0.messages.append(.init(message: message))
                }
            }

            do {
                while true {
                    // TODO: truncate prompt
                    store.modify { $0.typing = true }

                    var incoming: LLMMessage?
                    for try await partial in llm.completeStreaming(prompt: messages.map(\.message), functions: toolFunctions) {
                        let isNew = incoming == nil
                        add(message: partial, removeLast: !isNew)
                        incoming = partial
                        if isNew { // Remove typing indicator
                            store.modify { $0.typing = false }
                        }
                    }
                    if let fn = incoming?.functionCall {
                        let res = try await self.tools.handle(functionCall: fn)
                        add(message: .init(role: .function, content: res, nameOfFunctionThatProduced: fn.name), removeLast: false)
                    } else {
                        break
                    }
                }
            } catch {
                let text = "Error: \(error)"
                add(message: .init(role: .system, content: text), removeLast: false)
                store.modify { $0.typing = false }
            }
        }
    }
}
