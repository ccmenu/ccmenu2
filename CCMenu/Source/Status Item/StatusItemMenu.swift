/*
 *  Copyright (c) ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct StatusItemMenu: View {
    @ObservedObject var model: ViewModel
    @ObservedObject var settings: UserSettings

    var body: some View {
        ForEach(model.pipelines) { p in
            Button() {
                WorkspaceController().openPipeline(p)
            } label: {
                Label(title: { Text(p.name) }, icon: { Image(nsImage: pipelineImage(p)) } )
                .labelStyle(.titleAndIcon)

            }
        }
        Divider()
        Button("Show Pipeline Window") {
            NSApp.sendAction(#selector(AppDelegate.orderFrontPipelineWindow(_:)), to: nil, from: self)
        }
        Button("Update Status of All Pipelines") {
            NSApp.sendAction(#selector(AppDelegate.updatePipelineStatus(_:)), to: nil, from: self)
        }
        Divider()
        Button("About CCMenu") {
            NSApp.sendAction(#selector(AppDelegate.orderFrontAboutPanelWithSourceVersion(_:)), to: nil, from: self)
        }
        .accessibilityIdentifier("AboutCCMenu")
        Button("Settings...") {
            NSApp.sendAction(#selector(AppDelegate.orderFrontSettingsWindow(_:)), to: nil, from: self)
        }
//        .keyboardShortcut(",")
        Divider()
        Button("Quit CCMenu") {
            NSApp.sendAction(#selector(NSApplication.terminate(_:)), to: nil, from: self)
        }

    }

    private func pipelineImage(_ pipeline: Pipeline) -> NSImage {
        return ImageManager().image(forPipeline: pipeline, asTemplate: false)
    }
}
