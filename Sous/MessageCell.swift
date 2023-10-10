import Foundation
import SwiftUI
import ChatToys

struct MessageViewModel: Equatable, Codable {
    var fromMe: Bool
    var body: MessageBodyViewModel

    static func from(messages: [CopilotState.Message], tools: Tools) -> [Self] {
        messages.flatMap { msg in
            let bodies = MessageBodyViewModel.from(message: msg, tools: tools)
            return bodies.map { MessageViewModel(fromMe: msg.message.role == .user, body: $0) }
        }
    }
}

enum MessageBodyViewModel: Equatable, Codable {
    case markdown(String)
    case codeBlock(String)
    case run(code: String, kind: String)
    case codeOutput(String)
    case unknown(String)

    static func from(message: CopilotState.Message, tools: Tools) -> [Self] {
        var models = [Self]()
        if message.message.content != "" {
            // Split message content on full-line code block boundaries using regex that matches ``` on its own line
//            let codeBlockRegex = try! NSRegularExpression(pattern: "^```$", options: [.anchorsMatchLines])
            let split = ("\n" + message.message.content + "\n")
                .components(separatedBy: "\n```\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            // .splitOn(regex: try! NSRegularExpression(pattern: "^```$", options: .anchorsMatchLines)) // message.message.content.split(separator: /[^\n]```[$\n]/)
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
            if let vm = tools.viewModel(fromFunctionCall: functionCall) {
                models.append(vm)
            } else {
                models.append(.unknown(functionCall.prettyPrintedJson()))
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
            .background(model.fromMe ? Color.blue : Color.primary.opacity(0.1))
            .foregroundColor(model.fromMe ? .white : nil)
            .cornerRadius(16)
            .frame(maxWidth: .infinity, alignment: model.fromMe ? .trailing : .leading)
            .multilineTextAlignment(model.fromMe ? .trailing : .leading)
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
        }
    }
}

private struct MarkdownView: View {
    var markdown: String

    var body: some View {
        Text(markdown: markdown)
            .font(.system(.body))
            .textSelection(.enabled)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
//extension String {
//    func splitOn(regex: NSRegularExpression) -> [String] {
//        do {
//            let regex = try NSRegularExpression(pattern: "[^\\n]```[$\\n]")
//            let ranges = regex.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count)).map { $0.range }
//
//            var lastEnd = startIndex
//            var results: [Substring] = []
//
//            for range in ranges {
//                let rangeStart = Range(range, in: self)!.lowerBound
//                results.append(self[lastEnd..<rangeStart])
//                lastEnd = Range(range, in: self)!.upperBound
//            }
//            results.append(self[lastEnd..<endIndex])
//
//            return results.map { String($0) }
//        } catch {
//            print("Invalid regex: \(error.localizedDescription)")
//            return [self]
//        }
//    }
//}
