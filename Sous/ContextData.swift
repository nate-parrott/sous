import Foundation

struct ContextData: Equatable, Codable {
    var text: String
    var includeInLastMessageOnly: Bool = false
    var isToolOutput: Bool = false
    var suffix: String? = nil

    var allText: String {
        var t = text
        if let suffix {
            t += suffix
        }
        return t
    }
}
