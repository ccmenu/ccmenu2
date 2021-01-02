/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


class PipelineWindowController {
    
    var modelData: ModelData // TODO: do I need to keep this around?
    var window: NSWindow
    
    init(_ data: ModelData) {
        modelData = data
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: ContentView().environmentObject(modelData))
        window.center()
        window.setFrameAutosaveName("PipelineWindow")
        window.identifier = NSUserInterfaceItemIdentifier("PipelineWindow")
    }
    
}

