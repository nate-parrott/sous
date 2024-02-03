import SwiftUI

struct InputAccessories: View {
    var session: CopilotSession
    @AppStorage(PrefKey.openAIApiKey.rawValue) private var apiKey: String = ""

    var body: some View {
        Group {
            if apiKey == "" {
                Button("Add API Key") {
                    AppDelegate.shared.showPreferences(nil)
                }
                .buttonStyle(LargeAccessoryButtonStyle())
            } else {
                // TODO
                EmptyView()
            }
            WithSnapshot(dataStore: session.store, snapshot: { $0.messages.count > 0 }) { hasMessages in
                if hasMessages {
                    Button(action: {
                        session.store.modify { $0.messages.removeAll() }
                    }) {
                        Image(systemName: "minus")
                            .frame(both: 30)
                            .contentShape(Rectangle())
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.trailing)
    }
}
