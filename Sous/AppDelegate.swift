//
//  AppDelegate.swift
//  Sous
//
//  Created by nate parrott on 10/8/23.
//

import Cocoa

/*
 TODO:
 - Streaming
 - SwiftTerm support: https://github.com/migueldeicaza/SwiftTerm
 - Web search support
 - Scroll to bottom
 - Fix shadow
 */
@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let overlayWin = OverlayWindowController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        overlayWin.window!.makeKeyAndOrderFront(nil)

        if let screen = NSScreen.main {
            overlayWin.coordinator.dockRect = .init(center: CGPoint(x: screen.frame.midX, y: screen.frame.maxY + 100), size: CGSize(width: 60, height: 60))
        }

        overlayWin.coordinator.overlayViewWantsToDismiss = { [weak self] in
            self?.setVisible(false)
        }

        setVisible(true)

        HotkeySetup.registerGlobalHotkey { [weak self] in
            DispatchQueue.main.async {
                self?.toggleVisible()
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    // when dock icon is clicked, get or creare main window from storyboard
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        dockIconClicked()
//        if let win = overlayWin.window {
//            win.setIsVisible(!win.isVisible)
//        }
//        if let win = NSApp.windows.last(where: { ($0 as? FloatingPanel) != nil }) {
//            win.makeKeyAndOrderFront(nil)
//        } else {
//            let storyboard = NSStoryboard(name: "Main", bundle: nil)
//            let controller = storyboard.instantiateInitialController() as! WindowController
//            controller.showWindow(self)
//        }
        return true
    }

    // MARK: - Lifecycle
    @MainActor
    func dockIconClicked() {
        guard let screen = NSScreen.main, let window = overlayWin.window else { return }

        overlayWin.coordinator.dockRect = screen.inferredRectOfHoveredDockIcon
        setVisible(!window.isVisible)
    }

    @MainActor func toggleVisible() {
        setVisible(!isVisible)
    }

    var isVisible: Bool {
        overlayWin.window?.isVisible ?? false
    }

    @MainActor
    func setVisible(_ willShow: Bool) {
        guard let window = overlayWin.window else { return }

        if !willShow {
            overlayWin.coordinator.putAway? {
                self.showPutBackIcon = false
                window.setIsVisible(false)
            }
            return
        }

        showPutBackIcon = true
        window.setIsVisible(true)
        overlayWin.updateWindowSize()
        overlayWin.coordinator.show?()
    }

    // MARK: - Dock icon
    private var showPutBackIcon = false {
        didSet {
            if showPutBackIcon {
                NSApp.dockTile.contentView = putBackDockView
            } else {
                NSApp.dockTile.contentView = nil
            }
            NSApp.dockTile.display()
        }
    }
    private let putBackDockView = NSImageView(image: NSImage(named: "PutBack")!)

}
