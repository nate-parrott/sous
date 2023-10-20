import Foundation
import ChatToys
import JavaScriptCore

protocol Tool {
    var functions: [LLMFunction] { get }

    func handle(functionCall: LLMMessage.FunctionCall) -> AsyncThrowingStream<ToolResponse?, Error>

    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel?
}

enum ToolError: Error {
   case unknownTool
   case wrongArgs
   case unavailable
}

struct ToolResponse: Equatable {
    var string: String
    var data: StructuredResponse?
}


class Tools {
    init() {
        tools = [
            ApplescriptTool(),
            JavascriptTool()
        ]
    }

    var tools = [any Tool]()

    var functions: [LLMFunction] {
        tools.flatMap { $0.functions }
    }

    func handle(functionCall: LLMMessage.FunctionCall) -> AsyncThrowingStream<ToolResponse?, Error> {
        .just {
            if let tool = self.tool(forFunctionName: functionCall.name) {
                for try await partial in tool.handle(functionCall: functionCall) {
                    return partial
                }
            }
            throw ToolError.wrongArgs
        }
    }

    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel? {
        if let tool = self.tool(forFunctionName: call.name) {
            return tool.viewModel(fromFunctionCall: call)
        }
        return nil
    }

    private func tool(forFunctionName name: String) -> Tool? {
        tools.first { $0.functions.contains { $0.name == name } }
    }
}

class ApplescriptTool: Tool {
    var functions: [LLMFunction] {
        [
            LLMFunction(name: "appleScript", description: "Evaluate AppleScript to perform operations on the user's system", parameters: ["script": .string(description: nil)])
        ]
    }

    func handle(functionCall: LLMMessage.FunctionCall) -> AsyncThrowingStream<ToolResponse?, Error> {
        .just {
            switch functionCall.name {
            case "appleScript":
                if let params = functionCall.argumentsJson as? [String: String], let script = params["script"] {
                    #if os(macOS)
                    let str = try await Scripting.runAppleScript(script: script) ?? "(No result)"
                    return .init(string: str)
                    #else
                    throw ToolError.unavailable
                    #endif
                } else {
                    throw ToolError.wrongArgs
                }
            default: return nil
            }
        }
    }

    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel? {
        if let params = call.argumentsJson as? [String: String], let script = params["script"] {
            return MessageBodyViewModel.run(code: script, kind: "AppleScript")
        }
        return MessageBodyViewModel.run(code: "", kind: "AppleScript")
    }
}

class JavascriptTool: Tool {
    var functions: [LLMFunction] {
        [
            LLMFunction(name: "eval", description: "Executes a JS expression and returns the result. Use for math, text manipulation, logic, etc.", parameters: ["expr": .string(description: "JS expression or self-calling function")])
        ]
    }

    let jsCtx = JSContext()!

    func handle(functionCall: LLMMessage.FunctionCall) -> AsyncThrowingStream<ToolResponse?, Error> {
        .just {
            switch functionCall.name {
            case "eval":
                if let params = functionCall.argumentsJson as? [String: String], let expr = params["expr"] {
                    let res = self.jsCtx.evaluateScript(expr)!
                    return .init(string: res.toString())
                } else {
                    throw ToolError.wrongArgs
                }
            default: return nil
            }
        }
    }
    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel? {
        if let params = call.argumentsJson as? [String: String], let expr = params["expr"] {
            return MessageBodyViewModel.run(code: expr, kind: "JavaScript")
        }
        return MessageBodyViewModel.run(code: "", kind: "JavaScript")
    }
}

//class ButtonsTool: Tool {
//    var functions: [LLMFunction] {
//        [
//            LLMFunction(
//                name: "buttons",
//                description: "Use this tool when you need multiple-choice answers from the user, or want to suggest follow-up actions.", parameters: ["q": .string(description: "Question to ask user"), "buttons": .array(description: "Array of 1-3 concise answers", itemType: .string(description: nil))]
//            )
//        ]
//    }
//
//    let jsCtx = JSContext()!
//
//    func handle(functionCall: LLMMessage.FunctionCall) async throws -> String? {
//        switch functionCall.name {
//        case "eval":
//            if let params = functionCall.argumentsJson as? [String: String], let expr = params["expr"] {
//                let res = jsCtx.evaluateScript(expr)!
//                return res.toString()
//            } else {
//                throw ToolError.wrongArgs
//            }
//        default: return nil
//        }
//    }
//
//    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel? {
//        if let params = call.argumentsJson as? [String: String], let expr = params["expr"] {
//            return MessageBodyViewModel.run(code: expr, kind: "JavaScript")
//        }
//        return MessageBodyViewModel.run(code: "", kind: "JavaScript")
//    }
//}
