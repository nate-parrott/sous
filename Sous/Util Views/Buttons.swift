import SwiftUI

// background: rounded rect, fg color at 0.1 opacity
// text: fg color at 1.0 opacity
struct LargeAccessoryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled ? 1.0 : 0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(fgColor)
                    .opacity(configuration.isPressed ? 0.25 : 0.15)
            )
            .foregroundColor(fgColor)
    }

    private var fgColor: Color {
        colorScheme == .dark ? .white : .black.opacity(0.8)
    }
}
