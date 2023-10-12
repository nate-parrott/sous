import SwiftUI

@MainActor
class OverlayViewCoordinator: ObservableObject {
    @Published var windowSize = CGSize.zero
    @Published var dockRect = CGRect.zero

    let session = CopilotSession()

    typealias Completion = () -> Void

    // Overlay view sets; NSWindow calls
    var putAway: ((@escaping Completion) -> Void)? // param is a completion
    var show: (() -> Void)?

    // NSWindow sets; overlay window calls:
    var overlayViewWantsToDismiss: (() -> Void)?
}

struct OverlayView: View {
    @ObservedObject var coordinator: OverlayViewCoordinator

    @State private var visible = false
    @State private var positionOffset: CGPoint = .zero
    @State private var positionOffsetAtStartOfDrag: CGPoint?

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
                        .onTapGesture {
                            coordinator.overlayViewWantsToDismiss?()
                        }
                        .overlay(alignment: .bottomLeading) { thread }
                        .scaleEffect(scale)
                        .position(pos)
                        .gesture(DragGesture().onChanged { val in
                            if let b = positionOffsetAtStartOfDrag {
                                self.positionOffset.x = b.x + val.location.x - val.startLocation.x
                                self.positionOffset.y = b.y + val.location.y - val.startLocation.y
                            } else {
                                positionOffsetAtStartOfDrag = positionOffset
                            }
                        }.onEnded {  _ in positionOffsetAtStartOfDrag = nil })
                }
            }
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
                withAnimation(.snappy(duration: 0.3, extraBounce: 0.1), completionCriteria: .logicallyComplete) {
                    self.visible = false
                } completion: {
                    completion()
                }
            }
        }  
    }

    @ViewBuilder private var thread: some View {
        ThreadView(session: coordinator.session)
            .frame(width: 300)
            .padding(.leading, 128 + 30)
            .padding(.bottom, (128 - 50) / 2)
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.1)
    }
}
