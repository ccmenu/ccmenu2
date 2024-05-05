/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import SettingsAccess


struct MenuBarExtraMenu: View {
    @ObservedObject var model: PipelineModel
    @AppStorage(.orderInMenu) var orderInMenu = .asArranged
    @AppStorage(.showBuildTimesInMenu) private var showBuildTimesInMenu = false
    @AppStorage(.showBuildLabelsInMenu) private var showBuildLabelsInMenu = false
    @AppStorage(.hideSuccessfulBuildsInMenu) private var hideSuccessfulBuildsInMenu = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let filteredPipelines = filteredAndSortedPipelines(model.pipelines)
        ForEach(filteredPipelines) { p in
            let viewModel = MenuItemViewModel(pipeline: p, showBuildTimesInMenu: showBuildTimesInMenu, showBuildLabelsInMenu: showBuildLabelsInMenu)
            Button() {
                NSWorkspace.shared.openWebPage(pipeline: p)
            } label: {
                Label(title: { Text(viewModel.title) }, icon: { Image(nsImage: viewModel.icon) } )
                .labelStyle(.titleAndIcon)
            }
        }
        let hiddenCount = model.pipelines.count - filteredPipelines.count
        if hiddenCount > 0 {
            let text = (hiddenCount == 1) ? "1 pipeline" : "\(hiddenCount) pipelines"
            Button("(\(text) hidden)") { }
            .disabled(true)
        }
        Divider()
        Button("Pipelines") {
            NSApp.activateThisApp()
            openWindow(id: "pipeline-list")
        }
        Divider()
        Button("About CCMenu") {
            NSApp.activateThisApp()
            NSApp.sendAction(#selector(AppDelegate.orderFrontAboutPanelWithSourceVersion(_:)), to: nil, from: self)
        }
        SettingsLink {
            Text("Settings...")
        } preAction: { NSApp.activateThisApp()
        } postAction: { }
        Divider()
        Button("Quit CCMenu") {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func filteredAndSortedPipelines(_ pipelines: [Pipeline]) -> [Pipeline] {
        let filtered = model.pipelines.filter({ !hideSuccessfulBuildsInMenu || $0.status.currentBuild != nil || $0.status.lastBuild?.result != .success })
        switch orderInMenu {
        case .asArranged: 
            return filtered
        case .sortedAlphabetically:
            return filtered.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        case .sortedByBuildTime:
            return filtered.sorted(by: { $0.status.lastBuild?.timestamp ?? Date.distantPast >
                $1.status.lastBuild?.timestamp ?? Date.distantPast})
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

    static func viewModelForPreview() -> PipelineModel {
        let model = PipelineModel()

        var p0 = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: URL(string: "http://localhost")!, name: ""))
        p0.status.activity = .building
        p0.status.lastBuild = Build(result: .failure)
        p0.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")

        var p1 = Pipeline(name: "ccmenu2 (build-and-run)", feed: Pipeline.Feed(type: .github, url: URL(string: "http://localhost")!, name: ""))
        p1.status.activity = .sleeping
        p1.status.lastBuild = Build(result: .success)
        p1.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p1.status.lastBuild!.label = "build.151"

        model.pipelines = [p0, p1]

        model.update(pipeline: p0)
        model.update(pipeline: p1)

        return model
    }

}
