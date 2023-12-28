/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


struct MenuItemModel: Identifiable {

    var pipeline: Pipeline
    var title: String
    var icon: NSImage

    var id: String {
        pipeline.id
    }

    init(pipeline: Pipeline, settings: UserSettings) {
        self.pipeline = pipeline
        self.title = pipeline.name
        var details: [String] = []
        if settings.showBuildTimesInMenu, let buildTime = pipeline.status.lastBuild?.timestamp {
            let relative = buildTime.formatted(Date.RelativeFormatStyle(presentation: .named))
            details.append(relative)
        }
        if settings.showBuildLabelsInMenu, let buildLabel = pipeline.status.lastBuild?.label {
            details.append(buildLabel)
        }
        if details.count > 0 {
            let detailsJoined = details.joined(separator: ", ")
            title.append(" \u{2014} \(detailsJoined)")
        }
        self.icon = ImageManager().image(forPipeline: pipeline)
    }

}
