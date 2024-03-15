/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit
import ServiceManagement

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
    
    var openAtLogin: Bool {
        get {
            return SMAppService.mainApp.status == .enabled
        }
        set {
            let status = SMAppService.mainApp.status
            if newValue && status != .enabled {
                try? SMAppService.mainApp.register()
            }
            if !newValue && status == .enabled {
                try? SMAppService.mainApp.unregister()
            }
        }
    }
    
}
