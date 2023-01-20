/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit
import Combine


class StatusItemController: NSObject, NSMenuDelegate {

    var viewModel: ViewModel
    var userSettings: UserSettings
    var statusItem: NSStatusItem
    var subscriber: AnyCancellable?

    init(model: ViewModel, settings: UserSettings) {
        viewModel = model
        userSettings = settings
        let builder = StatusItemBuilder(settings: userSettings)
        statusItem = builder.initializeItem()
        super.init()
        statusItem.menu?.delegate = self

        subscriber = userSettings.$useColorInStatusItem.receive(on: DispatchQueue.main).sink(receiveValue: { _ in self.updateButton() } )

        builder.updateButton(button: statusItem.button!)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let builder = StatusItemBuilder(settings: userSettings)
        builder.updateMenu(menu: menu, pipelines: viewModel.pipelines)
    }

    private func updateButton() {
        let builder = StatusItemBuilder(settings: userSettings)
        builder.updateButton(button: statusItem.button!)
    }


}
