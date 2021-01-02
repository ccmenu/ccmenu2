/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItemController: StatusItemController?
    var pipelineWindowController: PipelineWindowController?

    private var modelData = ModelData()

    func applicationDidFinishLaunching(_ aNotification: Notification) {


        statusItemController = StatusItemController(modelData)
        pipelineWindowController = PipelineWindowController(modelData)
        pipelineWindowController!.window.makeKeyAndOrderFront(nil)
    }

    @IBAction func orderFrontAboutPanelWithSourceVersion(_ sender: AnyObject?) {
        let infoDictionary = Bundle.main.infoDictionary!
        let sourceVersion = infoDictionary["CCMSourceVersion"] ?? "n/a"
        NSApplication.shared.orderFrontStandardAboutPanel(
                options: [NSApplication.AboutPanelOptionKey.version: sourceVersion]
        )
    }

    @IBAction func orderFrontSettingsPanel(_ sender: AnyObject?) {
    }

    @IBAction func orderFrontPipelineWindow(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        pipelineWindowController?.window.makeKeyAndOrderFront(nil)
    }

    @IBAction func updatePipelineStatus(_ sender: AnyObject?) {
    }

    @IBAction func openPipeline(_ sender: AnyObject?) {
        if let sender = sender as? NSMenuItem, let pipeline = sender.representedObject as? Pipeline {
            NSApp.activate(ignoringOtherApps: true)
            WorkspaceController().openPipeline(pipeline)
        }
    }

}

