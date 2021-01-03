/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


class PipelineWindowController: NSObject, NSToolbarDelegate {

    var viewModel: ViewModel
    var window: NSWindow

    init(_ model: ViewModel) {
        viewModel = model
        window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)

        super.init()

        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ContentView().environmentObject(viewModel))
        window.center()
        window.setFrameAutosaveName("PipelineWindow")
        window.identifier = NSUserInterfaceItemIdentifier("PipelineWindow")
        window.title = "CCMenu \u{2014} Pipelines"

        let toolbar = NSToolbar()
        toolbar.displayMode = .iconOnly
        toolbar.delegate = self
        window.toolbar = toolbar
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
        item.isBordered = true
        switch identifier {
        case .addPipeline:
            item.image = NSImage(named: "toolbar-plus")
            item.label = "Add"
            item.toolTip = "Add pipeline"
            item.target = self
            item.action = #selector(addPipeline(_:))
        case .removePipeline:
            item.image = NSImage(named: "toolbar-trash")
            item.label = "Remove"
            item.toolTip = "Remove selected pipeline(s)"
            item.target = self
            item.action = #selector(removePipeline(_:))
        case .editPipeline:
            item.image = NSImage(named: "toolbar-gear")
            item.label = "Edit"
            item.toolTip = "Edit selected pipeline"
            item.target = self
            item.action = #selector(editPipeline(_:))
        case .updatePipelineStatus:
            item.image = NSImage(named: "toolbar-arrow-clockwise")
            item.label = "Update"
            item.toolTip = "Update status of all pipelines"
            item.target = nil
            item.action = #selector(AppDelegate.updatePipelineStatus(_:))
        default:
            return nil
        }
        return item
    }


    @objc func addPipeline(_ sender: AnyObject?) {
    }

    @objc func removePipeline(_ sender: AnyObject?) {
        /*  This method and the next one should actually be in the pipeline view. Then it would be unnecessary to have
            the selection ids in the view model, where they don't really belong. It would also disable the item when
            there is no selection.
            Unfortunately, though, I have not found a way to wire the toolbar item's action to the pipeline view. My
            suspicion is that this would only work with the .toolbar construct, but that is not available in Catalina.
        */
        let selectedIds = viewModel.selection
        var indexSet = IndexSet()
        for (i, p) in viewModel.pipelines.enumerated() {
            if selectedIds.contains(p.id) {
                indexSet.insert(i)
            }
        }
        viewModel.pipelines.remove(atOffsets: indexSet)
        
    }

    @objc func editPipeline(_ sender: AnyObject?) {
        NSLog("selection = \(viewModel.selection)")
    }

}

extension NSToolbarItem.Identifier {
    static let addPipeline: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ToolbarAddPipelineItem")
    static let removePipeline: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ToolbarRemovePipelineItem")
    static let editPipeline: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ToolbarEditPipelineItem")
    static let updatePipelineStatus: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "ToolbarUpdatePipelineStatusItem")
}
