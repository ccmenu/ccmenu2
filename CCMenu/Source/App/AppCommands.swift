/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
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
            ViewMenuItems()
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
    
    private struct ViewMenuItems: View {
        @FocusedBinding(\.pipelineDisplayStyle) var style
        
        var body: some View {
            Button("Show Build Status") {
                style?.detailMode = .buildStatus
            }
            .keyboardShortcut("1")
            .disabled(style == nil) // TODO: how else...?
            
            Button("Show Feed URL") {
                style?.detailMode = .feedUrl
            }
            .keyboardShortcut("2")
            .disabled(style == nil) // TODO: how else...?
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


private struct PipelineDisplayStyleKey: FocusedValueKey {
    typealias Value = Binding<PipelineDisplayStyle>
}

extension FocusedValues {
    var pipelineDisplayStyle: Binding<PipelineDisplayStyle>? {
        get { self[PipelineDisplayStyleKey.self] }
        set { self[PipelineDisplayStyleKey.self] = newValue }
    }
}

