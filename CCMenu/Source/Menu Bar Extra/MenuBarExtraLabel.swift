/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct MenuBarExtraLabel: View {
    @ObservedObject var model: ViewModel

    var body: some View {
        Label(title: { Text(model.textForMenuBar) }, icon: { Image(nsImage: model.imageForMenuBar) })
        .labelStyle(.titleAndIcon)
        .accessibilityIdentifier("CCMenuStatusItem")
    }

}


struct MenuBarExtraLabel_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarExtraLabel(model: viewModelForPreview())
    }

    static func viewModelForPreview() -> ViewModel {
        let model = ViewModel(settings: settingsForPreview())

        var p0 = Pipeline(name: "connectfour", feedUrl: "http://localhost:4567/cctray.xml")
        p0.activity = .building
        p0.lastBuild = Build(result: .failure)
        p0.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")

        var p1 = Pipeline(name: "erikdoe/ccmenu", feedUrl: "https://api.travis-ci.org/repositories/erikdoe/ccmenu/cc.xml")
        p1.activity = .sleeping
        p1.lastBuild = Build(result: .success)
        p1.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        p1.lastBuild!.label = "build.151"

        model.pipelines = [p0, p1]

        model.update(pipeline: p0)
        model.update(pipeline: p1)

        return model
    }

    private static func settingsForPreview() -> UserSettings {
        let s = UserSettings()
        s.useColorInMenuBar = true
        return s
    }

}
