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
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)

        self
        .background(bgColor.opacity(0.8))
        .background(.regularMaterial)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(fgColor.opacity(0.2), lineWidth: 0.5)
        }
        .foregroundColor(fgColor)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
    }
}
