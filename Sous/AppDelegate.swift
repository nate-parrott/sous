//
//  AppDelegate.swift
//  Sous
//
//  Created by nate parrott on 10/8/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate {
        NSApp.delegate as! AppDelegate
    }

    let overlayWindowCoordinator = OverlayWindowCoordinator()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        overlayWindowCoordinator.initialSetup()
        overlayWindowCoordinator.setVisible(true)

        HotkeySetup.registerGlobalHotkey { [weak self] in
            DispatchQueue.main.async {
                self?.overlayWindowCoordinator.toggleVisible()
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
        overlayWindowCoordinator.dockIconClicked()
        return true
    }

    @IBAction func showPreferences(_ sender: Any?) {
        NSApp.activate()
        if let existing = NSApp.windows.compactMap({ $0 as? PreferenceWindow }).first {
            existing.makeKeyAndOrderFront(sender)
        } else {
            let window = PreferenceWindow()
            window.makeKeyAndOrderFront(sender)
        }
    }
}

class OverlayWindowCoordinator {
    // MARK: - Lifecycle
    @MainActor
    func initialSetup() {
        if let screen = NSScreen.main {
            overlayWin.coordinator.dockRect = .init(center: CGPoint(x: screen.frame.midX, y: screen.frame.maxY + 100), size: CGSize(width: 60, height: 60))
        }

        overlayWin.coordinator.overlayViewWantsToDismiss = { [weak self] in
            self?.setVisible(false)
        }
    }

    @MainActor
    func dockIconClicked() {
        guard let screen = NSScreen.main, let window = overlayWin.window else { return }

        overlayWin.coordinator.dockRect = screen.inferredRectOfHoveredDockIcon
        setVisible(!window.isVisible)
    }

    @MainActor func toggleVisible() {
        setVisible(!isVisible)
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

    var isVisible: Bool {
        overlayWin.window?.isVisible ?? false
    }

    let overlayWin = OverlayWindowController()

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
