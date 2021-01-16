/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AppCommands: Commands {

    private struct PipelineMenuContent: View {
        var body: some View {
            Button("Update Status of All Pipelines") {
                NSApp.sendAction(#selector(AppDelegate.updatePipelineStatus(_:)), to: nil, from: self)
            }
            .disabled(false)
        }
    }

    private struct ViewModeMenuItems: View {
        var body: some View {
            Button("Show Build Status") {
                // TODO: how to wire this to the view?
            }
            .keyboardShortcut("1")
            
            Button("Show Feed URL") {
                // TODO: how to wire this to the view?
            }
            .keyboardShortcut("2")
        }
    }
    
    var body: some Commands {
        CommandGroup(before: .toolbar) {
            ViewModeMenuItems()
        }
        CommandMenu("Pipeline") {
            PipelineMenuContent()
        }
    }

}
