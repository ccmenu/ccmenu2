/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct MenuItemViewModel {

    private(set) var pipeline: Pipeline
    private var settings: UserSettings

    init(pipeline: Pipeline, settings: UserSettings) {
        self.pipeline = pipeline
        self.settings = settings
    }

    var title: String {
        var result = pipeline.name
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
            result.append(" \u{2014} \(detailsJoined)")
        }
        return result
    }

    var icon: NSImage {
        return NSImage(forPipeline: pipeline)
    }

}
