/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


class ImageManager {

    func image(forPipeline pipeline: Pipeline, asTemplate: Bool = false) -> NSImage {
        let result = pipeline.status?.buildResult ?? BuildResult.other
        let activity = pipeline.status?.pipelineActivity ?? PipelineActivity.other
        return image(forResult: result, activity: activity)
    }

    func image(forResult result: BuildResult, activity: PipelineActivity, asTemplate: Bool = false) -> NSImage {
        var name = "build"
        switch result {
        case .success:
            name += "-success"
        case .failure:
            name += "-failure"
        case .unknown:
            name += (activity == .building) ? "-success" : "-paused"
        case .other:
            name += (activity == .building) ? "-success" : "-unknown"
        }
        if activity == .building {
            name += "+building"
        }
        if asTemplate {
            name += "-template"
        }
        guard let image = NSImage(named: name) else {
            fatalError("Missing asset \(name)")
        }
        // not strictly necessary; it's automatically set for names ending with "template"
        image.isTemplate = asTemplate
        return image
    }


}
