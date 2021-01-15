/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


class StatusItemController: NSObject, NSMenuDelegate {

    var viewModel: ViewModel
    var statusItem: NSStatusItem

    init(_ model: ViewModel) {
        viewModel = model
        let builder = StatusItemBuilder()
        statusItem = builder.initializeItem()
        super.init()
        statusItem.menu?.delegate = self
        UserDefaults.standard.addObserver(self, forKeyPath: "UseColorInMenuBar", options: [], context: nil)
        builder.updateButton(button: statusItem.button!)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let builder = StatusItemBuilder()
        builder.updateMenu(menu: menu, pipelines: viewModel.pipelines)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        let builder = StatusItemBuilder()
        builder.updateButton(button: statusItem.button!)
    }

}
