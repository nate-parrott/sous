//
//  ViewController.swift
//  Sous
//
//  Created by nate parrott on 10/8/23.
//

import Cocoa
import SwiftUI

class ViewController: NSViewController {
    let session = CopilotSession()
    
    lazy var hostingView = NSHostingView(rootView: ContentView(session: session))

    override func viewDidLoad() {
        super.viewDidLoad()

        hostingView.sizingOptions = [.standardBounds]
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func clear(_ sender: Any?) {
        session.store.modify { $0.messages.removeAll() }
    }
}
