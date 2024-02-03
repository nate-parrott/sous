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
    @State private var position: CGPoint?
    @State private var positionAtStartOfDrag: CGPoint?
    @State private var focusTime: Date?
    @State private var dockPosWhenLastShown: CGPoint?

    private func posWhenVisible(desktopSize: CGSize) -> CGPoint {
        if let position {
            return position
        }
        if let dockPosWhenLastShown {
            return CGPoint(x: dockPosWhenLastShown.x, y: desktopSize.height - 200)
        }
        return CGPoint(x: desktopSize.width / 2, y: desktopSize.height - 200)
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let visiblePos = self.posWhenVisible(desktopSize: geo.size) // CGPoint(x: defaultPos.x + positionOffset.x, y: defaultPos.y + positionOffset.y)
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
                            if let b = positionAtStartOfDrag {
                                self.position = .init(
                                    x:  b.x + val.location.x - val.startLocation.x,
                                    y: b.y + val.location.y - val.startLocation.y
                                )
                            } else {
                                positionAtStartOfDrag = pos
                            }
                        }.onEnded {  _ in positionAtStartOfDrag = nil })
                }
            }
        }
//        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 5)
        .frame(width: coordinator.windowSize.width, height: coordinator.windowSize.height)
        .onAppear {
            coordinator.show = {
                dockPosWhenLastShown = coordinator.dockRect.center
                if PrefKey.animateAppearance.currentBoolValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self.focusTime = Date()
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0.15)) {
                            self.visible = true
                        }
                    }
                } else {
                    self.focusTime = Date()
                    self.visible = true
                }
            }

            coordinator.putAway = { completion in
                if PrefKey.animateAppearance.currentBoolValue {
                    withAnimation(.snappy(duration: 0.26, extraBounce: 0.0), completionCriteria: .logicallyComplete) {
                        self.visible = false
                    } completion: {
                        completion()
                    }
                } else {
                    self.visible = false
                    completion()
                }
            }
        }  
    }

    @ViewBuilder private var thread: some View {
        ThreadView(session: coordinator.session, focusTime: focusTime)
            .frame(width: 400)
            .padding(.leading, 128 + 30)
            .padding(.bottom, (128 - 50) / 2)
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.1)
    }
}

extension OverlayViewCoordinator {
    static var stubForPreviews: OverlayViewCoordinator = {
        let c = OverlayViewCoordinator()
        c.windowSize = .init(width: 1000, height: 600)
        DispatchQueue.main.async {
            c.show?()
        }
        return c
    }()
}

#Preview {
    OverlayView(coordinator: .stubForPreviews)
        .padding(.leading, -400)
}
