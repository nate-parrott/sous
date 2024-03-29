import Foundation
import SwiftUI
import ChatToys

struct MessageViewModel: Equatable, Codable {
    var fromMe: Bool
    var body: MessageBodyViewModel

    static func from(messages: [CopilotState.Message], tools: Tools, typing: Bool, collapseToolUse: Bool = true) -> [Self] {

        var messages: [MessageViewModel] = messages.flatMap { msg in
            let bodies = MessageBodyViewModel.from(message: msg, tools: tools)
            return bodies
                .compactMap { body -> MessageBodyViewModel? in
                    if collapseToolUse {
                        switch body {
                        case .run(code: _, kind: let kind): return .toolUsePlaceholder(text: "Using \(kind)", icon: "gearshape.arrow.triangle.2.circlepath")
                        case .codeOutput: return nil
                        default: return body
                        }
                    } else {
                        return body
                    }
                }
                .map { MessageViewModel(fromMe: msg.message.role == .user, body: $0) }
        }
        if typing {
            messages.append(.init(fromMe: false, body: .typing))
        }
        return messages
    }
}

enum MessageBodyViewModel: Equatable, Codable {
    case markdown(String)
    case codeBlock(String)
    case run(code: String, kind: String)
    case codeOutput(String)
    case toolUsePlaceholder(text: String, icon: String)
    case searchResponse(WebSearchResponse)
    case unknown(String)
    case typing

    static func from(message: CopilotState.Message, tools: Tools) -> [Self] {
        if message.message.role == .function {
            if let model = tools.viewModel(fromFunctionCallResponse: message) {
                return [model]
            }
            return []
        }

        var models = [Self]()
        if message.message.content != "" {
            // Split message content on full-line code block boundaries using regex that matches ``` on its own line
//            let codeBlockRegex = try! NSRegularExpression(pattern: "^```$", options: [.anchorsMatchLines])
            let split = ("\n" + message.message.content + "\n")
                .splitOn(regex: "\n```[A-Za-z_0-9]*\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            for (i, part) in split.enumerated() {
                if i % 2 == 0 {
                    // markdown
                    models.append(.markdown(part))
                } else {
                    // code block
                    models.append(.codeBlock(part))
                }
            }
        }
        if let functionCall = message.message.functionCall {
            // TODO: Parse tool outputs into specialized view models
            if let vm = tools.viewModel(fromFunctionCall: functionCall) {
                models.append(vm)
            } else {
                models.append(.toolUsePlaceholder(text: "Using tool...", icon: "gearshape.arrow.triangle.2.circlepath"))
//                models.append(.unknown(functionCall.prettyPrintedJson()))
            }
        }
        return models
    }
}

struct MessageView: View {
    var model: MessageViewModel

    var body: some View {
        MessageBodyView(model: model.body)
            .lineLimit(nil)
            .asBubble(bgColor: model.fromMe ? Color.blue : Color.clear, fgColor: model.fromMe ? .white : Color.primary)
            .multilineTextAlignment(.leading)
//            .multilineTextAlignment(model.fromMe ? .trailing : .leading)
//            .frame(maxWidth: .infinity, alignment: model.fromMe ? .trailing : .leading)
    }
}

struct MessageBodyView: View {
    var model: MessageBodyViewModel

    var body: some View {
        switch model {
        case .markdown(let text):
            MarkdownView(markdown: text)
        case .codeBlock(let code):
            CodeBlockView(code: code, label: nil)
        case .run(let code, let kind):
            CodeBlockView(code: code, label: "Running \(kind)")
        case .codeOutput(let text):
            CodeBlockView(code: text, label: nil)
        case .unknown(let text):
            CodeBlockView(code: text, label: nil)
        case .typing:
            TypingView()
        case .toolUsePlaceholder(text: let text, icon: let icon):
            HStack {
                Image(systemName: icon).foregroundStyle(.purple)
                Text(text)
            }
            .asStandardMessageText
        case .searchResponse(let res):
            SearchResponseView(result: res)
        }
    }
}

private struct MarkdownView: View {
    var markdown: String

    var body: some View {
        Text(markdown: markdown)
            .asStandardMessageText
    }
}

extension View {
    var asStandardMessageText: some View {
        self
            .font(.system(.body))
            .textSelection(.enabled)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

private struct CodeBlockView: View {
    var code: String
    var label: String? // e.g. 'Running Javascript'

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let label = label {
                Text(label)
                    .font(.caption)
            }
            Text(code)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundColor(.white)
        .background(.black)
    }
}
//
extension String {
    func splitOn(regex: String) -> [String] {
        do {
            let toSearch: NSString = self as NSString

            let pattern = regex
            let regex = try NSRegularExpression(pattern: pattern, options: [])

            let matches = regex.matches(in: toSearch as String, range: NSRange(location: 0, length: toSearch.length))

            var results = [String]()
            var lastIndex: Int = 0
            for match in matches {
                results.append(toSearch.substring(with: .init(location: lastIndex, length: match.range.lowerBound - lastIndex)))
                lastIndex = match.range.upperBound
            }
            results.append(toSearch.substring(with: .init(location: lastIndex, length: toSearch.length - lastIndex)))
            return results
        } catch {
            print("Invalid regex: \(error.localizedDescription)")
            return [self]
        }
    }
}
