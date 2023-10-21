import Foundation
import ChatToys

struct WebSearchToolResponse: Equatable, Codable {
    var response: WebSearchResponse
    var contents = [PageContent]()

    struct PageContent: Equatable, Codable {
        var result: WebSearchResult
        var text: String
    }

    var asContextData: [ContextData] {
        var ctx = [ContextData]()
        if let info = response.infoBox {
            ctx.append(.init(text: "> (i) \(info)", includeInLastMessageOnly: false, isToolOutput: true))
        }
        for res in response.results.prefix(3) {
            ctx.append(
                ContextData(text: "#\(res.title)\n\(res.snippet ?? "")", includeInLastMessageOnly: false, isToolOutput: true)
            )
            if let content = contents.first(where: { $0.result.id == res.id }) {
                ctx.append(ContextData(text: "##START PAGE CONTENT\n\(content.text)", includeInLastMessageOnly: true, isToolOutput: true, suffix: "##END PAGE CONTENT"))
            }
        }
        return ctx
    }
}

class WebSearchTool: Tool {
    
    var functions: [LLMFunction] {
        [
            LLMFunction(name: "webSearch", description: "Use when asked questions about specific, local or timely information.", parameters: ["query": .string(description: nil)])
        ]
    }

    func handle(functionCall: LLMMessage.FunctionCall) -> AsyncThrowingStream<ToolResponse?, Error> {
        guard functionCall.name == "webSearch",
                let params = functionCall.argumentsJson as? [String: String],
                let query = params["query"]
        else {
            return .justThrow(ToolError.wrongArgs)
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let webResponse = try await GoogleSearchEngine().search(query: query)
                    var toolResponse = WebSearchToolResponse(response: webResponse)
                    continuation.yield(.webSearch(toolResponse))

                    toolResponse.contents = await webResponse.results.prefix(2).concurrentMap { res in
                        try? await withTimeout(3, work: { () -> WebSearchToolResponse.PageContent in
                            let text = try await fetchPageContent(url: res.url, charLimit: 2000)
                            return .init(result: res, text: text)
                        })
                    }.compactMap { $0 }

                    continuation.yield(.webSearch(toolResponse))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func viewModel(fromFunctionCall call: LLMMessage.FunctionCall) -> MessageBodyViewModel? {
        guard call.name == "webSearch",
                let params = call.argumentsJson as? [String: String],
                let query = params["query"]
        else {
            return nil
        }
        return .toolUsePlaceholder(text: query, icon: "magnifyingglass")
    }

    func viewModel(fromToolResponse toolResponse: ToolResponse) -> MessageBodyViewModel? {
        if case .webSearch(let webSearchToolResponse) = toolResponse {
            return .searchResponse(webSearchToolResponse.response)
        }
        return nil
    }
}

func fetchPageContent(url: URL, charLimit: Int) async throws -> String {
    let resp = try await URLSession.shared.data(from: url)

    enum FetchError: Error {
        case invalidData
    }

    guard let html = String(data: resp.0, encoding: .utf8) else {
        throw FetchError.invalidData
    }

    let proc = try HTMLProcessor(html: html, baseURL: resp.1.url ?? url)
    try proc.isolateContent()
    try proc.simplify(truncateTextNodes: nil)
    return try proc.convertToMarkdown_doNotUseObjectAfter(hideUrls: true).truncateTail(maxLen: charLimit)
}
