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
    @Environment(\.openURL) private var openUrl

    var body: some View {
        ForEach(model.pipelines) { p in
            let viewModel = MenuItemModel(pipeline: p, settings: settings)
            Button() {
                openPipeline(pipeline: viewModel.pipeline)
            } label: {
                Label(title: { Text(viewModel.title) }, icon: { Image(nsImage: viewModel.icon) } )
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
            NSApplication.shared.terminate(nil)
        }
    }

    private func openPipeline(pipeline: Pipeline) {
        if let error = pipeline.connectionError {
            // TODO: Consider adding a UI test for this case
           alertPipelineFeedError(error)
         } else if let urlString = pipeline.status.webUrl, let url = URL(string: urlString), url.host != nil {
            openUrl(url)
        } else if (pipeline.status.webUrl ?? "").isEmpty {
            alertCannotOpenPipeline("The continuous integration server did not provide a link for this pipeline.")
        } else {
            alertCannotOpenPipeline("The continuous integration server provided a malformed link for this pipeline:\n\(pipeline.status.webUrl ?? "")")
        }
    }

    private func alertPipelineFeedError(_ errorString: String) {
        let alert = NSAlert()
        alert.messageText = "Error loading pipeline satus"
        alert.informativeText = errorString + "\n\nPlease check the URL, make sure you're logged in if neccessary. Otherwise contact the server administrator."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Cancel")
        alert.runModal()
    }

    private func alertCannotOpenPipeline(_ informativeText: String) {
        let alert = NSAlert()
        alert.messageText = "Cannot open pipeline"
        alert.informativeText = informativeText + "\n\nPlease contact the server administrator."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel")
        alert.runModal()
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
