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
        statusItem = builder.makeStatusItem()
        super.init()
        builder.addCommandMenuItems(menu: statusItem.menu!)
        builder.updateMenuWithPipelines(menu: statusItem.menu!, pipelines: viewModel.pipelines)
        statusItem.menu?.delegate = self
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let builder = StatusItemBuilder()
        builder.updateMenuWithPipelines(menu: menu, pipelines: viewModel.pipelines)
    }

}
