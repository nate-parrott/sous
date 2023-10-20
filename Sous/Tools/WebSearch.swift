import Foundation

struct WebSearchToolResponse: Equatable, Codable {
    var asString: String {
        return "" // TODO
    }
}

//class WebSearchTool: Tool {
//    var functions: [LLMFunction] {
//        [
//            LLMFunction(name: "webSearch", description: "Use when asked questions about specific, local or timely information.", parameters: ["query": .string(description: nil)])
//        ]
//    }
//
//    func handle(functionCall: LLMMessage.FunctionCall) async throws -> String? {
//        switch functionCall.name {
//        case "webSearch":
//            if let params = functionCall.argumentsJson as? [String: String], let expr = params["query"] {
//            } else {
//                throw ToolError.wrongArgs
//            }
//        default: return nil
//        }
//    }
//
////    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel? {
////        if let params = call.argumentsJson as? [String: String], let expr = params["expr"] {
////            return MessageBodyViewModel.run(code: expr, kind: "JavaScript")
////        }
////        return MessageBodyViewModel.run(code: "", kind: "JavaScript")
////    }
//}
