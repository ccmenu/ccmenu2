/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


class AppDelegate: NSObject, NSApplicationDelegate {
    @Environment(\.openURL) var openURL
    var statusItemController: StatusItemController?
    var viewModel: ViewModel?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard let viewModel = viewModel else {
            fatalError("View model unavailable when creating status item controller")
        }
        statusItemController = StatusItemController(viewModel)
    }

    @IBAction func orderFrontAboutPanelWithSourceVersion(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        let sourceVersion = Bundle.main.infoDictionary?["CCMSourceVersion"] ?? "n/a"
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: [NSApplication.AboutPanelOptionKey.version: sourceVersion]
        )
    }

    @IBAction func orderFrontPreferencesWindow(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: self)
    }

    @IBAction func orderFrontPipelineWindow(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        openURL(URL(string: "ccmenu://pipelines")!)
    }

    @IBAction func updatePipelineStatus(_ sender: AnyObject?) {
        print("Should update status from servers")
    }

    @IBAction func openPipeline(_ sender: AnyObject?) {
        if let sender = sender as? NSMenuItem, let pipeline = sender.representedObject as? Pipeline {
            NSApp.activate(ignoringOtherApps: true)
            WorkspaceController().openPipeline(pipeline)
        }
    }

}

