/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


class PipelineWindowController: NSObject, NSToolbarDelegate {

    var modelData: ModelData // TODO: do I need to keep this around?
    var window: NSWindow

    init(_ data: ModelData) {
        modelData = data
        window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
                rootView: ContentView().environmentObject(modelData))
        window.center()
        window.setFrameAutosaveName("PipelineWindow")
        window.identifier = NSUserInterfaceItemIdentifier("PipelineWindow")
        window.title = "CCMenu \u{2014} Pipelines"

        super.init()

        let toolbar = NSToolbar()
        toolbar.displayMode = .iconOnly
        toolbar.autosavesConfiguration = true
        toolbar.delegate = self
        window.toolbar = toolbar

        if #available(macOS 11, *) {
            window.toolbarStyle = .unified
        }
    }


    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.addPipeline, .removePipeline, .editPipeline, .updatePipelineStatus]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.updatePipelineStatus, .space, .addPipeline, .removePipeline, .editPipeline]
    }

    func toolbar(
            _ toolbar: NSToolbar,
            itemForItemIdentifier identifier: NSToolbarItem.Identifier,
            willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        let item = NSToolbarItem(itemIdentifier: identifier)
        switch identifier {
        case .addPipeline:
            item.image = NSImage(named: "toolbar-plus")
            item.toolTip = "Add pipeline"
            item.target = self
            item.action = #selector(addPipeline(_:))
        case .removePipeline:
            item.image = NSImage(named: "toolbar-trash")
            item.toolTip = "Remove selected pipeline(s)"
            item.target = self
            item.action = #selector(removePipeline(_:))
        case .editPipeline:
            item.image = NSImage(named: "toolbar-gear")
            item.toolTip = "Edit selected pipeline"
            item.action = #selector(editPipeline(_:))
        case .updatePipelineStatus:
            item.image = NSImage(named: "toolbar-arrow-clockwise")
            item.toolTip = "Update status of all pipelines"
            item.target = nil
            item.action = #selector(AppDelegate.updatePipelineStatus(_:))
        default:
            return nil
        }
        item.image?.isTemplate = true
        item.isBordered = true

        return item
    }
    
    
    @objc func addPipeline(_ sender: AnyObject?) {
        
    }
    
    @objc func removePipeline(_ sender: AnyObject?) {
        
    }
    
    @objc func editPipeline(_ sender: AnyObject?) {
        
    }
    
}

extension NSToolbarItem.Identifier {
    static let addPipeline: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ToolbarAddPipelineItem")
    static let removePipeline: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ToolbarRemovePipelineItem")
    static let editPipeline: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ToolbarEditPipelineItem")
    static let updatePipelineStatus: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ToolbarUpdatePipelineStatusItem")
}
