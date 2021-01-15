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
        AboutPanelController().openAboutPanelWithSourceVersion()
    }

    @IBAction func orderFrontSettingsPanel(_ sender: AnyObject?) {
    }

    @IBAction func orderFrontPipelineWindow(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
    }

    @IBAction func updatePipelineStatus(_ sender: AnyObject?) {
        viewModel.pipelines[1].statusSummary = "Built 03 Dec 2020, 13:14pm\nLabel: 152"
    }

    @IBAction func openPipeline(_ sender: AnyObject?) {
        if let sender = sender as? NSMenuItem, let pipeline = sender.representedObject as? Pipeline {
            NSApp.activate(ignoringOtherApps: true)
            WorkspaceController().openPipeline(pipeline)
        }
    }

}

