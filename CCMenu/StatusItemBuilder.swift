/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


class StatusItemBuilder {

    func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        guard let button = item.button else {
            fatalError("Expected NSStatusBar item to have a button object")
        }
        button.title = "1"
        button.image = ImageManager().image(forResult: .failure, activity: .building, asTemplate: true)
        button.imagePosition = NSControl.ImagePosition.imageLeft
        let menu = NSMenu()
        menu.identifier = NSUserInterfaceItemIdentifier("StatusItemMenu")
        item.menu = menu
        return item
    }

    func addCommandMenuItems(menu: NSMenu) {
        menu.addItem(
                NSMenuItem.separator())
        menu.addItem(
                withTitle: "Update Status of All Pipelines",
                action: #selector(AppDelegate.updatePipelineStatus(_:)),
                keyEquivalent: "")
        menu.addItem(
                withTitle: "Show Pipeline Window",
                action: #selector(AppDelegate.orderFrontPipelineWindow(_:)),
                keyEquivalent: "")
        menu.addItem(
                NSMenuItem.separator())
        menu.addItem(
                withTitle: "About CCMenu",
                action: #selector(AppDelegate.orderFrontAboutPanelWithSourceVersion(_:)),
                keyEquivalent: "")
        menu.addItem(withTitle: "Preferences...",
                action: #selector(AppDelegate.orderFrontSettingsPanel(_:)),
                keyEquivalent: "")
        menu.addItem(
                NSMenuItem.separator())
        menu.addItem(
                withTitle: "Quit CCMenu",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "")
    }

    func updateMenuWithPipelines(menu: NSMenu, pipelines pipelineList: [Pipeline]) {
        for (index, pipeline) in pipelineList.enumerated() {
            let item = menu.insertItem(
                    withTitle: pipeline.name,
                    action: #selector(AppDelegate.openPipeline(_:)),
                    keyEquivalent: "",
                    at: index)
            item.image = ImageManager().image(
                    forPipeline: pipeline,
                    asTemplate: false)
            item.representedObject = pipeline
            item.identifier = NSUserInterfaceItemIdentifier("OpenPipeline:\(pipeline.name)")
        }
    }

}

