import SwiftUI
import ChatToys

struct SearchResponseView: View {
    var result: WebSearchResponse

    var body: some View {
        VStack(alignment: .leading) {
            if let infoBox = result.infoBox {
                Label(infoBox, systemImage: "info.circle")
            }
            ForEach(result.results.prefix(3)) { res in
                ResultCell(result: res)
            }
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
