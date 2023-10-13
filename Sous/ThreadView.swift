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

            InputTextField(text: $input, options: options, focusDate: focusTime, onEvent: onEvent(_:), contentSize: $inputSize)
                .frame(height: inputSize.height)
                .asBubble(bgColor: Color.blue, fgColor: .white)
        }
        .onReceive(session.store.publisher.map(\.messages).removeDuplicates(), perform: { self.messages = $0 })
        .onReceive(session.store.publisher.map(\.typing).removeDuplicates(), perform: { self.typing = $0 })
        .edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder private var answer: some View {
        if messagesToShow.count > 0 {
            ExpandingScrollView(maxHeight: 500) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEachUnidentifiable(items: messageViewModels) { vm in
                        MessageView(model: vm)
//                            .transition(.scale)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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

extension Font {
    static var chatFont: Font {
        .system(size: 15)
    }
}

extension NSFont {
    static var chatFont: NSFont {
        .systemFont(ofSize: 15)
    }
}

extension View {
    @ViewBuilder func asBubble(bgColor: Color, fgColor: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)

        self
        .background(bgColor.opacity(0.8))
        .background(.regularMaterial)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(fgColor.opacity(0.1), lineWidth: 0.5)
        }
        .foregroundColor(fgColor)
    }
}
