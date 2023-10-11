import SwiftUI

class OverlayViewCoordinator: ObservableObject {
    @Published var windowSize = CGSize.zero
    @Published var dockRect = CGRect.zero

    typealias Completion = () -> Void
    var putAway: ((@escaping Completion) -> Void)? // param is a completion
    var show: (() -> Void)?
}

struct OverlayView: View {
    @ObservedObject var coordinator: OverlayViewCoordinator

    @State private var visible = false
    @State private var positionOffset: CGPoint = .zero

    var body: some View {
        ZStack {
//            Circle().fill(.blue).frame(width: 500, height: 500)

            GeometryReader { geo in
                let defaultPos = CGPoint(x: geo.size.width / 2, y: geo.size.height - 200)
                let visiblePos = CGPoint(x: defaultPos.x + positionOffset.x, y: defaultPos.y + positionOffset.y)
                let pos = visible ? visiblePos : coordinator.dockRect.center
                let scale = visible ? 1 : (max(1, coordinator.dockRect.height) / 128)

                ZStack {
                    Image("Chef")
                        .resizable()
                        .interpolation(.high)
                        .frame(both: 128)
                        .scaleEffect(scale)
                        .position(pos)
//                        .position(.init(x: 200, y: 200))

//                    Color.red.opacity(0.1)
                }


//                Text("Visible: \(visible ? "vis" : "not")")
            }
//            .border(.green)
        }
        .frame(width: coordinator.windowSize.width, height: coordinator.windowSize.height)
        .onAppear {
            coordinator.show = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.snappy) {
                        self.visible = true
                    }
                }
            }

            coordinator.putAway = { completion in
                withAnimation(.snappy, completionCriteria: .logicallyComplete) {
                    self.visible = false
                } completion: {
                    completion()
                }
            }
        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        Circle().fill(.blue)
//            .frame(width: 500, height: 500)
//            .padding(100)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
//
//    func display(fromPos pos: CGRect) {
//        dockRect = pos
//        self.visible = false
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//            withAnimation(.snappy) {
//                self.visible = true
//            }
//        }
//    }
//
//    func putAway(toPos pos: CGRect, onDone: @escaping () -> Void) {
//        dockRect = pos
//        withAnimation(.snappy, completionCriteria: .logicallyComplete) {
//            self.visible = false
//        } completion: {
//            onDone()
//        }
//    }
}
