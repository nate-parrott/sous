import Foundation
import ChatToys

class TerminalTool: Tool {
    var functions: [LLMFunction] {
        [.init(name: "terminal", description: "Runs a terminal command in the user's current terminal window.", parameters: ["script": .string(description: "zsh command")])]
    }
    func handle(functionCall: LLMMessage.FunctionCall) -> AsyncThrowingStream<ToolResponse?, Error> {
        print("Terminal call: \(functionCall)")
        guard let params = functionCall.argumentsJson as? [String: String], let script = params["script"] else {
            return .justThrow(ToolError.wrongArgs)
        }
        return .just {
            let text = try await self.runScript(script)
            return .text(text)
        }
    }
    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel? {
        .toolUsePlaceholder(text: "Using Terminal", icon: "terminal")
    }
    func viewModel(fromToolResponse toolResponse: ToolResponse) -> MessageBodyViewModel? {
        .codeBlock(toolResponse.asString)
    }
    func getContext() async -> (String, [ContextData])? {
        // TODO
        nil
    }

    // MARK: - Scripting

    // If nil, no terminal window
    func getTerminalContents() async throws -> String? {
        // If fails, no terminal win (or no permissions)
        try? await Scripting.runAppleScript(script: "tell application \"Terminal\" to get the contents of the front window")?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func openTerminalWindow() async throws {
        _ = try await Scripting.runAppleScript(script: "open new terminal window")
    }

    func runScript(_ script: String) async throws -> String {
        var beforeText: String = ""
        if let content = try? await getTerminalContents() {
            beforeText = content
        } else {
            try await openTerminalWindow()
        }
        let run = try await Scripting.runAppleScript(script: "tell application \"Terminal\" to do script \(script.quotedForApplescript) in front window")
        print("Run script response: \(run ?? "none")")
        _ = try await waitForTerminalNotBusy(interval: 1, maxCount: 20)
        let afterText = try await getTerminalContents() ?? ""
        return afterText.withoutPrefix(beforeText)
    }

    func waitForTerminalNotBusy(interval: TimeInterval, maxCount: Int) async throws -> Bool {
        for _ in 0..<maxCount {
            try await Task.sleep(seconds: interval)
            let isRunning = try await pollScriptIsRunning()
            if !isRunning { return true }
        }
        return false
    }

    func pollScriptIsRunning() async throws -> Bool {
        let busy = try await Scripting.runAppleScript(script: "tell application \"Terminal\" to get busy of tab of front window")
        return busy == "true"
        // tell application \"Terminal\" to get busy of tab of front window
    }
}

// tell application "Terminal" to do script "echo 'hello world'" in front window
