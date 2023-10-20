import Foundation
import ChatToys
import JavaScriptCore

struct CopilotState: Equatable, Codable {
    struct Message: Equatable, Codable {
        var message: LLMMessage
        var structuredResponse: StructuredResponse? // For function-call responses
    }
    var messages: [Message] = []
    var typing = false
}

struct StructuredResponse: Equatable, Codable {
    var webSearch: WebSearchToolResponse?

    var asString: String {
        if let webSearch {
            return webSearch.asString
        }
        return "?"
    }
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

            func add(message: CopilotState.Message, removeLast: Bool) {
                if removeLast {
                    messages.removeLast()
                }
                messages.append(message)
                store.modify {
                    if removeLast { $0.messages.removeLast() }
                    $0.messages.append(message)
                }
            }

            do {
                while true {
                    // TODO: truncate prompt
                    store.modify { $0.typing = true }

                    var incoming: LLMMessage?
                    for try await partial in llm.completeStreaming(prompt: messages.map(\.message), functions: toolFunctions) {
                        let isNew = incoming == nil
                        add(message: .init(message: partial), removeLast: !isNew)
                        incoming = partial
                        if isNew { // Remove typing indicator
                            store.modify { $0.typing = false }
                        }
                    }
                    if let fn = incoming?.functionCall {
                        var didAddFunctionResponse = false
                        for try await partialResponse in self.tools.handle(functionCall: fn) {
                            if let partialResponse {
                                add(message: .init(message: LLMMessage(role: .function, content: partialResponse.string, nameOfFunctionThatProduced: fn.name), structuredResponse: partialResponse.data), removeLast: didAddFunctionResponse)
                                didAddFunctionResponse = true
                            }
                        }
                        // Some tools return a response and are finished, in which case the model can continue.
                        // Others, like interactive buttons, return control to the user before the model.
                        if !didAddFunctionResponse {
                            break
                        }
                    } else {
                        break
                    }
                }
            } catch {
                let text = "Error: \(error)"
                add(message: .init(message: LLMMessage(role: .system, content: text)), removeLast: false)
                store.modify { $0.typing = false }
            }
        }
    }
}
