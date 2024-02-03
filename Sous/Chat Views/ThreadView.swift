import SwiftUI

struct ThreadView: View {
    @ObservedObject var session: CopilotSession
    var focusTime: Date?

    @State private var input = ""
    @State private var inputSize: CGSize = .init(width: 200, height: 21)
    var padding: CGFloat = 16

    @State private var messages = [CopilotState.Message]()
    @State private var typing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            answer

            HStack {
                InputTextField(text: $input, options: options, focusDate: focusTime, onEvent: onEvent(_:), contentSize: $inputSize)
                InputAccessories(session: session)
                    .colorScheme(.dark)
            }
                .frame(height: inputSize.height)
                .asBubble(bgColor: Color.blue, fgColor: .white)
        }
        .onReceive(session.store.publisher.map(\.messages).removeDuplicates(), perform: { self.messages = $0 })
        .onReceive(session.store.publisher.map(\.typing).removeDuplicates(), perform: { self.typing = $0 })
        .edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder private var answer: some View {
        let maxHeight: CGFloat = 500

        if messagesToShow.count > 0 {
            ExpandingScrollView(maxHeight: maxHeight) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEachUnidentifiable(items: messageViewModels) { vm in
                        MessageView(model: vm)
//                            .transition(.scale)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .mask(alignment: .bottom) {
                LinearGradient(stops: [
                    .init(color: Color.clear, location: 0),
                    .init(color: Color.black, location: 0.1),
                    .init(color: Color.black, location: 0.97),
                    .init(color: Color.clear, location: 1)
                ], startPoint: .top, endPoint: .bottom)
                .frame(height: maxHeight)
            }
            .padding(-20)
            .background(Color.white.opacity(0.01))
//            .animation(.snappy, value: messagesToShow)
        }
    }

    private var messageViewModels: [MessageViewModel] {
        MessageViewModel.from(messages: messages, tools: session.tools, typing: typing)
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
            font: .chatFont,
            color: NSColor.white,
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
    ThreadView(session: OverlayViewCoordinator.stubForPreviews.session, focusTime: Date())
        .frame(width: 300, height: 500)
        .padding(40)
}
