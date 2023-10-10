import AppKit

class WindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.level = .floating
    }
}

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
