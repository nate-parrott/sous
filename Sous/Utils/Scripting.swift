import Foundation

#if os(macOS)
import AppKit

enum Scripting {
    enum ScriptError: Error {
        case scriptError([String: AnyObject])
        case invalidScript
    }

    private static let scriptQueue = DispatchQueue(label: "Scripting", qos: .userInitiated, attributes: .concurrent)

    static func runAppleScript(script: String) async throws -> String? {
        try await withCheckedThrowingContinuation { cont in
            self.scriptQueue.async {
                var error: NSDictionary?
                guard let scriptObject = NSAppleScript(source: script) else {
                    cont.resume(throwing: ScriptError.invalidScript)
                    return
                }
                let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error)
                if let error {
                    cont.resume(throwing: ScriptError.scriptError(error as? [String: AnyObject] ?? [:]))
                    return
                }
                cont.resume(returning: output.asString)
            }
        }
    }

    static func arcTitle() async throws -> String? {
        try await runAppleScript(script: """
        tell application "Arc"
            return title of active tab of window 1
        end tell
        """)
    }

    static func arcURL() async throws -> String? {
        try await runAppleScript(script: """
        tell application "Arc"
            return URL of active tab of window 1
        end tell
        """)
    }

    static func arcHTML() async throws -> String? {
        guard let html = try await runAppleScript(script: """
            tell application "Arc"
                tell the active tab of its first window
                    set pageHTML to execute javascript "document.documentElement.outerHTML"
                end tell
            end tell
""") else { return nil }
        let data = "[\(html)]".data(using: .utf8)!
        return try JSONDecoder().decode([String].self, from: data).first
    }

    static func openLinkInBigArc(url: URL) async throws {
        _ = try await runAppleScript(script: """
    tell application "Arc"
      tell front window
        make new tab with properties {URL:"\(url.absoluteString)"}
      end tell

      activate
    end tell

""")
    }

    static func open(url: URL) {
        Task {
            do {
                try await openLinkInBigArc(url: url)
            } catch {
                DispatchQueue.main.async {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

extension NSAppleEventDescriptor {

    var asString: String? {
        switch descriptorType {
        case typeUnicodeText, typeUTF8Text:
            return stringValue
        case typeSInt32:
            return String(int32Value)
        case typeBoolean:
            return String(booleanValue)
        case typeAEList:
            let listCount = numberOfItems
            var listItems: [String] = []
            if listCount > 0 {
                for i in 1...listCount { // AppleScript lists are 1-indexed
                    if let itemString = self.atIndex(i)?.asString {
                        listItems.append(itemString)
                    }
                }
                return listItems.joined(separator: ", ")
            } else {
                return "(empty list)"
            }
        case typeAERecord:
            // Assuming you want key-value pairs for records
            var recordItems: [String] = []
            for i in 1...numberOfItems {
                let key = self.atIndex(i)?.stringValue ?? "UnknownKey"
                let value = self.atIndex(i + 1)?.asString ?? "UnknownValue"
                recordItems.append("\(key): \(value)")
            }
            return recordItems.joined(separator: ", ")
        default:
            return nil // Handle other descriptor types as needed
        }
    }
}

#endif
