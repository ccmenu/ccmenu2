/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


struct MenuItemModel: Hashable, Identifiable {

    var pipeline: Pipeline
    var title: String
    var icon: NSImage

    var id: String {
        pipeline.id
    }

    init(pipeline: Pipeline, settings: UserSettings) {
        self.pipeline = pipeline
        self.title = pipeline.name
        if settings.showLabelsInMenu, let buildLabel = pipeline.status.lastBuild?.label {
            title.append(" \u{2014} \(buildLabel)")
        }
        self.icon = ImageManager().image(forPipeline: pipeline)
    }

}
