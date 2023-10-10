import SwiftUI

struct ExpandingScrollView<C: View>: View {
    var maxHeight: CGFloat?
    @ViewBuilder var content: () -> C

    @State private var height: CGFloat?

    var body: some View {
        ScrollView(.vertical) {
            content()
                .measureSize { self.height = $0.height }
        }
        .frame(height: constrainToHeight)
    }

    private var constrainToHeight: CGFloat? {
        if let maxHeight, let height {
            return min(maxHeight, height)
        }
        if let height { return height }
        return nil
    }
}
