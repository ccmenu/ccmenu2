/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


class AppDelegate: NSObject, NSApplicationDelegate {
    @Environment(\.openURL) var openURL
    var viewModel: ViewModel? // TODO: get this from the app instead?
    var userSettings: UserSettings? // TODO: get this from the app instead?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    @IBAction func orderFrontAboutPanelWithSourceVersion(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        let sourceVersion = Bundle.main.infoDictionary?["CCMSourceVersion"] ?? "n/a"
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: [NSApplication.AboutPanelOptionKey.version: sourceVersion]
        )
    }

    @IBAction func orderFrontSettingsWindow(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 13, *) { 
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
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

