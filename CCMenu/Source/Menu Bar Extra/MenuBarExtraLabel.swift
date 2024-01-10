/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct MenuBarExtraLabel: View {
    @ObservedObject var model: PipelineModel
    @AppStorage(.useColorInMenuBar) var useColorInMenuBar: Bool = true
    @AppStorage(.useColorInMenuBarFailedOnly) var useColorInMenuBarFailedOnly: Bool = false
    @AppStorage(.showBuildTimerInMenuBar) var showBuildTimerInMenuBar: Bool = false

    var body: some View {
        let viewModel = MenuExtraViewModel(pipelines: model.pipelines, useColorInMenuBar: useColorInMenuBar, useColorInMenuBarFailedOnly: useColorInMenuBarFailedOnly, showBuildTimerInMenuBar: showBuildTimerInMenuBar)
        Label(title: { Text(viewModel.title) }, icon: { Image(nsImage: viewModel.icon) })
        .labelStyle(.titleAndIcon)
        .accessibilityIdentifier("CCMenuMenuExtra")
        .monospacedDigit() // TODO: this doesn't work; why not?
    }

}


struct MenuBarExtraLabel_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarExtraLabel(model: viewModelForPreview())
    }

    static func viewModelForPreview() -> PipelineModel {
        let model = PipelineModel()

        var p0 = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "", name: ""))
        p0.status.activity = .building
        p0.status.currentBuild = Build(result: .unknown)
        p0.status.currentBuild?.timestamp = Date.now
        p0.status.lastBuild = Build(result: .failure)
        p0.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p0.status.lastBuild!.duration = 90

        var p1 = Pipeline(name: "erikdoe/ccmenu", feed: Pipeline.Feed(type: .cctray, url: "", name: ""))
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
