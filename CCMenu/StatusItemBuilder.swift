/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


class StatusItemBuilder {
    
    @AppStorage("UseColorInMenuBar")
    private var useColorInMenuBar: Bool = false

    func initializeItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        guard let button = item.button else {
            fatalError("Expected NSStatusBar item to have a button object")
        }
        button.image = ImageManager().image(forResult: .other, activity: .other, asTemplate: !useColorInMenuBar)
        button.imagePosition = NSControl.ImagePosition.imageLeft
        let menu = NSMenu()
        menu.identifier = NSUserInterfaceItemIdentifier("StatusItemMenu")
        addCommandMenuItems(menu: menu)
        item.menu = menu
        return item
    }

    func addCommandMenuItems(menu: NSMenu) {
        menu.addItem(
            NSMenuItem.separator())
        menu.addItem(
            withTitle: "Show Pipeline Window",
            action: #selector(AppDelegate.orderFrontPipelineWindow(_:)),
            keyEquivalent: "")
        menu.addItem(
            withTitle: "Update Status of All Pipelines",
            action: #selector(AppDelegate.updatePipelineStatus(_:)),
            keyEquivalent: "")
        menu.addItem(
            NSMenuItem.separator())
        menu.addItem(
            withTitle: "About CCMenu",
            action: #selector(AppDelegate.orderFrontAboutPanelWithSourceVersion(_:)),
            keyEquivalent: "")
        menu.addItem(
            withTitle: "Preferences...",
            action: #selector(AppDelegate.orderFrontPreferencesWindow(_:)),
            keyEquivalent: "")
        menu.addItem(
            NSMenuItem.separator())
        menu.addItem(
            withTitle: "Quit CCMenu",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "")
    }
    
    func updateButton(button: NSStatusBarButton) {
        button.image = ImageManager().image(forResult: .failure, activity: .building, asTemplate: !useColorInMenuBar)
        button.title = "1"
    }

    func updateMenu(menu: NSMenu, pipelines pipelineList: [Pipeline]) {
        while menu.items.count > 0 && isPipelineItem(menu.item(at: 0)) {
            menu.removeItem(at: 0)
        }
        for (index, pipeline) in pipelineList.enumerated() {
            let item = menu.insertItem(
                withTitle: pipeline.name,
                action: #selector(AppDelegate.openPipeline(_:)),
                keyEquivalent: "",
                at: index)
            item.image = ImageManager().image(forPipeline: pipeline, asTemplate: false)
            item.representedObject = pipeline
            item.identifier = NSUserInterfaceItemIdentifier("OpenPipeline:\(pipeline.name)")
        }
    }

    private func isPipelineItem(_ item: NSMenuItem?) -> Bool {
        item?.action == #selector(AppDelegate.openPipeline(_:))
    }

}

