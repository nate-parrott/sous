import AppKit
import SwiftUI

enum PrefKey: String {
    case openAIApiKey
    case openAIOrgId
    case animateAppearance
}

extension PrefKey {
    var currentBoolValue: Bool {
        UserDefaults.standard.bool(forKey: rawValue)
    }

    var currentStringValue: String {
        UserDefaults.standard.string(forKey: rawValue) ?? ""
    }
}

// A normal window embedding a SwiftUI form that allows the user to edit preferences.
class PreferenceWindow: NSWindow {
    let hostingView = NSHostingView(rootView: PreferenceView())

    init() {
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        super.init(contentRect: hostingView.frame, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        self.contentView = hostingView
        self.center()
        self.isReleasedWhenClosed = false
        self.makeKeyAndOrderFront(nil)
    }
}

// A SwiftUI form that allows the user to edit preferences.
struct PreferenceView: View {
    @AppStorage(PrefKey.openAIApiKey.rawValue) var openAIApiKey = ""
    @AppStorage(PrefKey.openAIOrgId.rawValue) var openAIOrgId = ""
    @AppStorage(PrefKey.animateAppearance.rawValue) var animateAppearance = true

    var body: some View {
        Form {
            Section(header: Text("OpenAI")) {
                TextField("API Key", text: $openAIApiKey)
                TextField("Organization ID", text: $openAIOrgId)
            }
            Section(header: Text("Appearance")) {
                Toggle("Animate show and hide", isOn: $animateAppearance)
            }
        }
        .formStyle(.grouped)
    }
}
