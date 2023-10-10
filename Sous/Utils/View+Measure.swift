import SwiftUI

private struct ContentSizePreferenceKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

extension View {
    func measureSize(_ callback: @escaping (CGSize) -> Void) -> some View {
        self.background(GeometryReader(content: { geo in
            Color.clear
                .preference(key: ContentSizePreferenceKey.self, value: geo.size)
        }))
        .onPreferenceChange(ContentSizePreferenceKey.self) { size in
            callback(size)
        }
    }
}

private struct ContentFramePreferenceKey: PreferenceKey {
  static var defaultValue: CGRect = .zero
  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {}
}

extension View {
    func measureFrame(coordinateSpace: CoordinateSpace, _ callback: @escaping (CGRect) -> Void) -> some View {
        self.background(GeometryReader(content: { geo in
            Color.clear
                .preference(key: ContentFramePreferenceKey.self, value: geo.frame(in: coordinateSpace))
        }))
        .onPreferenceChange(ContentFramePreferenceKey.self) { rect in
            callback(rect)
        }
    }
}
