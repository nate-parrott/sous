import Foundation
import ChatToys

class BrowserTool: Tool {
    var functions: [LLMFunction] { [] }
    func handle(functionCall: LLMMessage.FunctionCall) -> AsyncThrowingStream<ToolResponse?, Error> {
        .justThrow(ToolError.unavailable)
    }
    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel? { nil }
    func viewModel(fromToolResponse toolResponse: ToolResponse) -> MessageBodyViewModel? { nil }
    func getContext() async -> (String, [ContextData])? { nil } // TODO
}
