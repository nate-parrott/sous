import AppKit
import SwiftUI

class OverlayWindowController: NSWindowController, NSWindowDelegate {
    let coordinator = OverlayViewCoordinator()
    lazy var contentVC = NSHostingController(rootView: OverlayView(coordinator: coordinator))

    override init(window: NSWindow?) {
        super.init(window: nil)
        loadWindow()
        windowDidLoad()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class Window: NSWindow {
        override var canBecomeKey: Bool { true }
    }

    override func loadWindow() {
        let window = Window(contentRect: NSScreen.main?.frame ?? .init(x: 0, y: 0, width: 500, height: 500), styleMask: [], backing: .buffered, defer: false)
        window.backgroundColor = NSColor.clear // NSColor.red.withAlphaComponent(0.5)
        window.isOpaque = false
        window.delegate = self
//        window.acceptsMouseMovedEvents = false
//        window.ignoresMouseEvents = true
        window.level = .screenSaver
        self.window = window
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        let window = self.window!
        contentVC.sizingOptions = []
        contentVC.view.translatesAutoresizingMaskIntoConstraints = false
        window.contentViewController = contentVC
        updateWindowSize()
    }

    func windowDidChangeScreen(_ notification: Notification) {
        updateWindowSize()
    }

    func windowDidChangeScreenProfile(_ notification: Notification) {
        updateWindowSize()
    }

    func updateWindowSize() {
        guard let screen = window?.screen ?? NSScreen.main else { return }
        let frame = CGRect(x: screen.frame.minX, y: screen.frame.minY, width: screen.frame.width, height: screen.frame.height)
        coordinator.windowSize = frame.size
        window?.setFrame(frame, display: true)
    }
}
