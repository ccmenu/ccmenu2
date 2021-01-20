/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AppCommands: Commands {

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
        }
        CommandGroup(replacing: .saveItem) {
        }
        CommandGroup(replacing: .importExport) {
            FileMenuItems()
        }
        CommandGroup(before: .toolbar) {
            ViewModeMenuItems()
        }
        CommandMenu("Pipeline") {
            PipelineMenuContent()
        }
        CommandGroup(before: .windowList) {
            WindowMenuItems()
        }
    }

    private struct FileMenuItems: View {
        var body: some View {
            Button("Import...") {
                // TODO: how to use file selector
                // TODO: how to access view model
            }
            Button("Export...") {
                // TODO: how to use file selector
                // TODO: how to access view model
            }
        }
    }
    
    private struct ViewModeMenuItems: View {
        @FocusedBinding(\.viewSettings) var viewSettings
        
        var body: some View {
            Button("Show Build Status") {
                viewSettings?.detailMode = .buildStatus
            }
            .keyboardShortcut("1")
            
            Button("Show Feed URL") {
                viewSettings?.detailMode = .feedUrl
            }
            .keyboardShortcut("2")
        }
    }
    
    private struct PipelineMenuContent: View {
        var body: some View {
            Button("Update Status of All Pipelines") {
                NSApp.sendAction(#selector(AppDelegate.updatePipelineStatus(_:)), to: nil, from: self)
            }
            .keyboardShortcut("u")
        }
    }
    
    private struct WindowMenuItems: View {
        var body: some View {
            Button("Show Pipeline Window") {
                NSApp.sendAction(#selector(AppDelegate.orderFrontPipelineWindow(_:)), to: nil, from: self)
            }
            .keyboardShortcut("0")
            Divider()
        }
    }

}


private struct ViewSettingsKey: FocusedValueKey {
    typealias Value = Binding<ViewSettings>
}

extension FocusedValues {
    var viewSettings: Binding<ViewSettings>? {
        get { self[ViewSettingsKey.self] }
        set { self[ViewSettingsKey.self] = newValue }
    }
}

