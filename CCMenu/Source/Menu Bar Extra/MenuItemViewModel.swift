/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct MenuItemViewModel {

    var pipeline: Pipeline
    var showBuildTimesInMenu: Bool
    var showBuildLabelsInMenu: Bool

    var title: String {
        var result = pipeline.name
        var details: [String] = []
        if showBuildTimesInMenu, let buildTime = pipeline.status.lastBuild?.timestamp {
            let relative = buildTime.formatted(Date.RelativeFormatStyle(presentation: .named))
            details.append(relative)
        }
        if showBuildLabelsInMenu, let buildLabel = pipeline.status.lastBuild?.label {
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
