import SwiftUI

struct ContentView: View {
    @ObservedObject var session: CopilotSession
    @State private var input = ""
    @State private var focusDate: Date?
    @State private var contentSize: CGSize = .init(width: 200, height: 21)
    var padding: CGFloat = 12

    @State private var messages = [CopilotState.Message]()

    var body: some View {
        VStack(spacing: 0) {
            answer

            HStack(alignment: .top, spacing: 0) {
                Image("Chef")
                    .resizable()
                    .interpolation(.high)
                    .padding(padding)
                    .frame(width: 45, height: 45)

                InputTextField(text: $input, options: options, focusDate: focusDate, onEvent: onEvent(_:), contentSize: $contentSize)
                    .frame(height: contentSize.height)
                    .padding(.leading, -padding)
            }
            .frame(width: 500)
        }
        .onReceive(session.store.publisher.map(\.messages).removeDuplicates(), perform: { self.messages = $0 })
    }

    @ViewBuilder private var answer: some View {
        if messagesToShow.count > 0 {
            ExpandingScrollView(maxHeight: 500) {
                VStack(alignment: .leading) {
                    ForEachUnidentifiable(items: messageViewModels) { vm in
                        MessageView(model: vm)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(padding)
            }
            Divider()
        }
    }

    private var messageViewModels: [MessageViewModel] {
        MessageViewModel.from(messages: messages, tools: session.tools)
    }

    private var messagesToShow: [CopilotState.Message] {
        var messages = [CopilotState.Message]()
        for msg in self.messages.reversed() {
            messages.insert(msg, at: 0)
            if msg.message.role == .user {
                return messages
            }
        }
        return messages
    }

    private var options: InputTextFieldOptions {
        .init(
            placeholder: "What can I do for you?",
            font: .systemFont(ofSize: 18, weight: .medium),
            color: .textColor,
            insets: .init(width: padding, height: padding)
        )
    }

    private func onEvent(_ event: TextFieldEvent) {
        switch event {
            case .focus, .blur: ()
        case .key(let key):
            switch key {
            case .downArrow, .upArrow: ()
            case .enter:
                if let text = input.nilIfEmpty {
                    input = ""
                    Task {
                        await session.send(message: text)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView(session: CopilotSession())
}
