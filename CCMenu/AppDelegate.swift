/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItemController: StatusItemController?
    var viewModel: ViewModel!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItemController = StatusItemController(viewModel)
    }

    @IBAction func orderFrontAboutPanelWithSourceVersion(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        AboutPanelController().orderFrontAboutPanelWithSourceVersion()
    }

    @IBAction func orderFrontPreferencesWindow(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: self)
    }

    @IBAction func orderFrontPipelineWindow(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        // TODO: This will not work for users who have chosen a language other than English
        // CCMenu.PipelineListView-1-AppWindow-1
        if let item = NSApp.menu?.item(withTitle: "Window")?.submenu?.item(withTitle: "Pipelines") {
            NSApp.sendAction(item.action!, to: item.target, from: item)
        } else if let item = NSApp.menu?.item(withTitle: "File")?.submenu?.item(withTitle: "New Pipelines Window") {
            NSApp.sendAction(item.action!, to: item.target, from: item)
        }
    }

    @IBAction func updatePipelineStatus(_ sender: AnyObject?) {
        let timestamp = Date.init(timeIntervalSinceNow: -5).description  // TODO: figure out how to format descriptions
        viewModel.pipelines[1].statusSummary = "Built: \(timestamp), Label: 152"
    }

    @IBAction func openPipeline(_ sender: AnyObject?) {
        if let sender = sender as? NSMenuItem, let pipeline = sender.representedObject as? Pipeline {
            NSApp.activate(ignoringOtherApps: true)
            WorkspaceController().openPipeline(pipeline)
        }
    }

}

