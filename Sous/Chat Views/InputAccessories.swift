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
        }
        .padding(.trailing)
    }
}
