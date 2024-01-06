/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct MenuBarExtraMenu: View {
    @ObservedObject var model: PipelineModel
    @ObservedObject var settings: UserSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ForEach(model.pipelines) { p in
            let viewModel = MenuItemViewModel(pipeline: p, settings: settings)
            Button() {
                WorkspaceController().openWebPage(pipeline: p)
            } label: {
                Label(title: { Text(viewModel.title) }, icon: { Image(nsImage: viewModel.icon) } )
                .labelStyle(.titleAndIcon)
            }
        }
        Divider()
        Button("Pipelines") {
            WorkspaceController().activateThisApp()
            openWindow(id: "pipeline-list")
        }
        Divider()
        Button("About CCMenu") {
            WorkspaceController().activateThisApp()
            NSApp.sendAction(#selector(AppDelegate.orderFrontAboutPanelWithSourceVersion(_:)), to: nil, from: self)
        }
        if #available(macOS 14.0, *) {
            SettingsLink {
                Button("Settings...") { }
            }
        } else {
            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        Divider()
        Button("Quit CCMenu") {
            NSApplication.shared.terminate(nil)
        }
    }

}


struct MenuBarExtraContent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) { // TODO: Can I render this as a menu somehow?
            MenuBarExtraMenu(model: viewModelForPreview(), settings: settingsForPreview())
        }
        .buttonStyle(.borderless)
        .padding(4)
        .frame(maxWidth: 300)
    }

    static func viewModelForPreview() -> PipelineModel {
        let model = PipelineModel(settings: settingsForPreview())

        var p0 = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "", name: ""))
        p0.status.activity = .building
        p0.status.lastBuild = Build(result: .failure)
        p0.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")

        var p1 = Pipeline(name: "ccmenu2 (build-and-run)", feed: Pipeline.Feed(type: .github, url: "", name: ""))
        p1.status.activity = .sleeping
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
