//
//  AppDelegate.swift
//  Sous
//
//  Created by nate parrott on 10/8/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    // when dock icon is clicked, get or creare main window from storyboard
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let win = NSApp.windows.last(where: { ($0 as? FloatingPanel) != nil }) {
            win.makeKeyAndOrderFront(nil)
        } else {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateInitialController() as! WindowController
            controller.showWindow(self)
        }
        return true
    }
}
