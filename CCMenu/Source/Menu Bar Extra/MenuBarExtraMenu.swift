/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct MenuBarExtraMenu: View {
    @ObservedObject var model: ViewModel
    @Environment(\.openWindow) var openWindow

    var body: some View {
        ForEach(model.pipelinesForMenu) { pvm in
            Button() {
                openPipeline(pipeline: pvm.pipeline)
            } label: {
                Label(title: { Text(pvm.title) }, icon: { Image(nsImage: pvm.icon) } )
                .labelStyle(.titleAndIcon)
            }
        }
        Divider()
        Button("Pipelines") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "pipeline-list")
        }
        Divider()
        Button("About CCMenu") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(#selector(AppDelegate.orderFrontAboutPanelWithSourceVersion(_:)), to: nil, from: self)
        }
        Button("Settings...") {
            // If/when this stops working in Sonoma: https://stackoverflow.com/questions/65355696/how-to-programatically-open-settings-preferences-window-in-a-macos-swiftui-app
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        Divider()
        Button("Quit CCMenu") {
            NSApp.sendAction(#selector(NSApplication.terminate(_:)), to: nil, from: self)
        }
    }

    private func openPipeline(pipeline: Pipeline) {
        if let error = pipeline.connectionError {
            // TODO: Consider adding a UI test for this case
            let alert = NSAlert()
            alert.messageText = "Error loading pipeline satus"
            alert.informativeText = error + "\n\nPlease check the URL, make sure you're logged in if neccessary. Otherwise contact the server administrator."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Cancel")
            alert.runModal()
        } else {
            WorkspaceController().openPipeline(pipeline)
        }
    }

}


struct MenuBarExtraContent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) { // TODO: Can I render this as a menu somehow?
            MenuBarExtraMenu(model: viewModelForPreview())
        }
        .buttonStyle(.borderless)
        .padding(4)
        .frame(maxWidth: 300)
    }

    static func viewModelForPreview() -> ViewModel {
        let model = ViewModel(settings: settingsForPreview())

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
