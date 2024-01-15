/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationWillFinishLaunching(_ aNotification: Notification) {
        NotificationReceiver.shared.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @IBAction 
    func orderFrontAboutPanelWithSourceVersion(_ sender: AnyObject?) {
        NSWorkspace.shared.activateThisApp()
        let sourceVersion = Bundle.main.infoDictionary?["CCMSourceVersion"] ?? "n/a"
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: [NSApplication.AboutPanelOptionKey.version: sourceVersion]
        )
    }

}

