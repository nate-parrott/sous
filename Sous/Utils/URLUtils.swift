import Foundation

extension URL {
    init(googleQuery: String) {
        // Use URLComps
        var components = URLComponents(string: "https://www.google.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: googleQuery)]
        self.init(string: components.url!.absoluteString)!
    }

    var hostWithoutWWW: String {
        guard let host = host else { return "" }
        return host.withoutPrefix("www.")
    }
}
