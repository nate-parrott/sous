import SwiftUI

extension View {
    func onAppearOrChange<T: Equatable>(of value: T, perform action: @escaping (T) -> Void) -> some View {
        onAppear {
            action(value)
        }
        .onChange(of: value, perform: action)
    }
}

struct EnumeratedIdentifiable<T>: Identifiable {
    let index: Int
    let value: T

    var id: Int { index }
}

extension Array {
    func enumeratedIdentifiable() -> [EnumeratedIdentifiable<Element>] {
        enumerated().map { EnumeratedIdentifiable(index: $0, value: $1) }
    }
}

// From https://stackoverflow.com/questions/57860840/any-swiftui-button-equivalent-to-uikits-touch-down-i-e-activate-button-when
extension View {
    func onTouchDownGesture(_ perform: @escaping (Bool /* down */) -> Void) -> some View {
        modifier(TouchDownGestureModifier(perform: perform))
    }
}

private struct TouchDownGestureModifier: ViewModifier {
    @State private var tapped = false
    let perform: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { val in
                    let isTapped = true // todo: handle moving finger outside
                    if tapped != isTapped {
                        tapped = isTapped
                        perform(isTapped)
                    }
                }
                .onEnded { _ in
                    tapped = false
                    perform(false)
                })
    }
}

extension View {
    var asAny: AnyView { AnyView(self) }

    func frame(both: CGFloat, alignment: Alignment = .center) -> some View {
        self.frame(width: both, height: both, alignment: alignment)
    }

    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
}

extension String {
    var asText: Text {
        Text(self)
    }
}

struct IdentifiableWithIndex<Item: Identifiable>: Identifiable {
    let id: Item.ID
    let item: Item
    let index: Int
}

extension Array where Element: Identifiable {
    var identifiableWithIndices: [IdentifiableWithIndex<Element>] {
        return enumerated().map { tuple in
            let (index, item) = tuple
            return IdentifiableWithIndex(id: item.id, item: item, index: index)
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .displayP3,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct ForEachUnidentifiable<Element, Content: View>: View {
    var items: [Element]
    @ViewBuilder var content: (Element) -> Content

    var body: some View {
        ForEach(itemsAsIdentifiable) {
            content($0.element)
        }
    }

    private var itemsAsIdentifiable: [CustomIdentifiable<Element>] {
        items.enumerated().map { CustomIdentifiable(id: $0.offset, element: $0.element) }
    }
}

private struct CustomIdentifiable<Element>: Identifiable {
    var id: Int
    var element: Element
}

// A @StateObject that remembers its first initial value
class FrozenInitialValue<T>: ObservableObject {
    private var value: T?
    func readOriginalOrStore(initial: () -> T) -> T {
        let val = value ?? initial()
        self.value = val
        return val
    }
}

public extension Text {
    init(markdown: String) {
        self = .init(LocalizedStringKey(markdown))
    }
}
