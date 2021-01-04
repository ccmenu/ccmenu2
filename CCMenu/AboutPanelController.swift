/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


class AboutPanelController {

    func openAboutPanelWithSourceVersion() {
        let infoDictionary = Bundle.main.infoDictionary!
        let sourceVersion = infoDictionary["CCMSourceVersion"] ?? "n/a"
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: [NSApplication.AboutPanelOptionKey.version: sourceVersion]
        )
    }

}
