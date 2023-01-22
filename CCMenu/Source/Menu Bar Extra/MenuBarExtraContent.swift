/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct MenuBarExtraContent: View {
    @ObservedObject var model: ViewModel

    var body: some View {
        ForEach(model.pipelinesForMenu) { lp in
            Button() {
                WorkspaceController().openPipeline(lp.pipeline)
            } label: {
                Label(title: { Text(lp.label) }, icon: { Image(nsImage: lp.pipeline.statusImage) } )
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
        Button("Settings...") {
            NSApp.sendAction(#selector(AppDelegate.orderFrontSettingsWindow(_:)), to: nil, from: self)
        }
//        .keyboardShortcut(",")
        Divider()
        Button("Quit CCMenu") {
            NSApp.sendAction(#selector(NSApplication.terminate(_:)), to: nil, from: self)
        }
    }

}


struct MenuBarExtraContent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) { // TODO: Can I render this as a menu somehow?
            MenuBarExtraContent(model: viewModelForPreview())
        }
        .buttonStyle(.borderless)
        .padding(4)
        .frame(maxWidth: 300)
    }

    static func viewModelForPreview() -> ViewModel {
        let model = ViewModel(settings: settingsForPreview())

        var p0 = Pipeline(name: "connectfour", feedUrl: "http://localhost:4567/cctray.xml", activity: .building)
        p0.status.lastBuild = Build(result: .failure)
        p0.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")

        var p1 = Pipeline(name: "erikdoe/ccmenu", feedUrl: "https://api.travis-ci.org/repositories/erikdoe/ccmenu/cc.xml", activity: .sleeping)
        p1.status.lastBuild = Build(result: .success)
        p1.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p1.status.lastBuild!.label = "build.151"

        model.pipelines = [p0, p1]

        model.update(pipeline: p0)
        model.update(pipeline: p1)

        return model
    }

    private static func settingsForPreview() -> UserSettings {
        let s = UserSettings()
        return s
    }

}
