/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


class StatusItemController {
    
    var viewModel: ViewModel
    var statusItem: NSStatusItem
    
    init(_ model: ViewModel) {
        viewModel = model
        let builder = StatusItemBuilder()
        statusItem = builder.makeStatusItem()
        builder.addCommandMenuItems(menu: statusItem.menu!)
        builder.updateMenuWithPipelines(menu: statusItem.menu!, pipelines:viewModel.pipelines)
    }


    
}
