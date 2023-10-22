import SwiftUI
import AppKit

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
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        self
        .background(bgColor.opacity(0.8))
        .background(.regularMaterial)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(fgColor.opacity(0.12), lineWidth: 0.5)
        }
        .foregroundColor(fgColor)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)
    }
}
