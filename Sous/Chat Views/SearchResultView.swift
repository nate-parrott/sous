import SwiftUI
import ChatToys

struct SearchResponseView: View {
    var result: WebSearchResponse

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let infoBox = result.infoBox {
                Label(infoBox, systemImage: "info.circle")
            }
            ForEach(result.results.prefix(WebSearchConstants.resultsToFetchContentFor)) { res in
                ResultCell(result: res)
            }
            Label("Show More", systemImage: "arrow.up.right")
                .onTapGesture {
                    openURL(URL(googleQuery: result.query))
                }
                .font(.caption.bold())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

private struct ResultCell: View {
    var result: WebSearchResult

    @Environment(\.openURL) private var openURL

    var body: some View {
        let txt = "\(result.url.host() ?? "") – \(result.snippet ?? "")"
        VStack(alignment: .leading) {
            Text(result.title).font(.headline)
                .lineLimit(2)
            Text(txt)
                .font(.caption)
                .lineLimit(1)
        }
        .multilineTextAlignment(.leading)
        .contentShape(Rectangle())
        .onTapGesture {
            openURL(result.url)
        }
    }
}
