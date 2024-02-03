import AppKit
import SwiftUI

enum PrefKey: String {
    case openAIApiKey
    case openAIOrgId
    case animateAppearance
    case systemInstructions
    case hotkey
    case useGPT4
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
    @AppStorage(PrefKey.systemInstructions.rawValue) var systemInstructions = ""
    @AppStorage(PrefKey.animateAppearance.rawValue) var animateAppearance = true
    @AppStorage(PrefKey.useGPT4.rawValue) var useGPT4 = false
    @AppStorage(PrefKey.hotkey.rawValue) var hotkey = false

    var body: some View {
        Form {
            Section(header: Text("OpenAI")) {
                TextField("API Key", text: $openAIApiKey)
                TextField("Organization ID", text: $openAIOrgId)
                Toggle("Use GPT 4", isOn: $useGPT4)
            }
            Section(header: Text("Appearance")) {
                Toggle("Animate show and hide", isOn: $animateAppearance)
                Toggle("Press Option+Space to open", isOn: $hotkey)
            }
            Section(header: Text("System Instructions")) {
                TextEditor(text: $systemInstructions)
            }
        }
        .formStyle(.grouped)
    }
}
