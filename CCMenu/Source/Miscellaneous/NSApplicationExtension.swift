/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit

extension NSApplication {

    func activateThisApp() {
        // TODO: There must be a better way...
        if #available(macOS 14.0, *) {
            NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func hideApplicationIcon(_ flag: Bool) {
        self.setActivationPolicy(flag ? .accessory : .regular)
    }

}
