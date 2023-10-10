import Foundation
import ChatToys
import JavaScriptCore

protocol Tool {
    var functions: [LLMFunction] { get }

    // Return true if handled
    func handle(functionCall: LLMMessage.FunctionCall) async throws -> String?

    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel?
}

enum ToolError: Error {
   case unknownTool
   case wrongArgs
   case unavailable
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

    func handle(functionCall: LLMMessage.FunctionCall) async throws -> String {
        if let tool = self.tool(forFunctionName: functionCall.name) {
            if let res = try await tool.handle(functionCall: functionCall) {
                return res
            }
        }
        throw ToolError.wrongArgs
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

    func handle(functionCall: LLMMessage.FunctionCall) async throws -> String? {
        switch functionCall.name {
        case "appleScript":
            if let params = functionCall.argumentsJson as? [String: String], let script = params["script"] {
                #if os(macOS)
                return try await Scripting.runAppleScript(script: script) ?? "(No result)"
                #else
                throw ToolError.unavailable
                #endif
            } else {
                throw ToolError.wrongArgs
            }
        default: return nil
        }
    }

    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel? {
        if let params = call.argumentsJson as? [String: String], let script = params["script"] {
            return MessageBodyViewModel.run(code: script, kind: "AppleScript")
        }
        return nil
    }
}

class JavascriptTool: Tool {
    var functions: [LLMFunction] {
        [
            LLMFunction(name: "eval", description: "Executes a JS expression and returns the result. Use for math, text manipulation, logic, etc.", parameters: ["expr": .string(description: "JS expression or self-calling function")])
        ]
    }

    let jsCtx = JSContext()!

    func handle(functionCall: LLMMessage.FunctionCall) async throws -> String? {
        switch functionCall.name {
        case "eval":
            if let params = functionCall.argumentsJson as? [String: String], let expr = params["expr"] {
                let res = jsCtx.evaluateScript(expr)!
                return res.toString()
            } else {
                throw ToolError.wrongArgs
            }
        default: return nil
        }
    }

    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel? {
        if let params = call.argumentsJson as? [String: String], let expr = params["expr"] {
            return MessageBodyViewModel.run(code: expr, kind: "JavaScript")
        }
        return nil
    }
}

//
//let jsCtx = JSContext()!
//
//var functions: [LLMFunction] {
//    [
//        LLMFunction(name: "eval", description: "Executes a JS expression and returns the result. Use for math, text manipulation, logic, etc.", parameters: ["expr": .string(description: "JS expression or self-calling function")]),
//        LLMFunction(name: "appleScript", description: "Evaluate AppleScript to perform operations on the user's system", parameters: ["script": .string(description: nil)])
//    ]
//}
//

//
//private func handle(functionCall: LLMMessage.FunctionCall) async throws -> String {
//    switch functionCall.name {
//    case "eval":
//        if let params = functionCall.argumentsJson as? [String: String], let expr = params["expr"] {
//            let res = jsCtx.evaluateScript(expr)!
//            return res.toString()
//        } else {
//            throw ToolError.wrongArgs
//        }
//    case "appleScript":
//        if let params = functionCall.argumentsJson as? [String: String], let script = params["script"] {
//            #if os(macOS)
//            return try await Scripting.runAppleScript(script: script) ?? "(No result)"
//            #else
//            throw ToolError.unavailable
//            #endif
//        } else {
//            throw ToolError.wrongArgs
//        }
//    default: throw ToolError.unknownTool
//    }
//}
