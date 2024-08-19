/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    @AppStorage(.showAppIcon) var showAppIcon: AppIconVisibility = .sometimes
    @AppStorage(.openWindowAtLaunch) var openWindowAtLaunch: Bool = false

    func applicationWillFinishLaunching(_ aNotification: Notification) {
        NotificationReceiver.shared.start()
        NSApp.hideApplicationIcon(showAppIcon != .always)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !openWindowAtLaunch {
            // TODO: find a better way to achieve this (cf. https://stackoverflow.com/questions/76551669)
            for w in NSApp.windows {
                if w.title == "Pipelines" {
                    w.close()
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @IBAction
    func orderFrontAboutPanelWithSourceVersion(_ sender: AnyObject?) {
        let sourceVersion = Bundle.main.infoDictionary?["CCMSourceVersion"] ?? "n/a"
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: [NSApplication.AboutPanelOptionKey.version: sourceVersion]
        )
    }

}

