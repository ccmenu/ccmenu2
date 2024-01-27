/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit

extension NSImage {

    convenience init(forPipeline pipeline: Pipeline?, asTemplate: Bool = false) {
        let result = pipeline?.status.lastBuild?.result ?? BuildResult.other
        let activity = pipeline?.status.activity ?? Pipeline.Activity.other
        self.init(forResult: result, activity: activity, asTemplate: asTemplate)
    }

    convenience init(forResult result: BuildResult, activity: Pipeline.Activity, asTemplate: Bool = false) {
        self.init(named: Self.name(forResult: result, activity: activity, asTemplate: asTemplate))!
        // not strictly necessary; it's automatically set for names ending with "template"
        isTemplate = asTemplate
    }

    convenience init(forActivity activity: Pipeline.Activity) {
        assert(activity == .building)
        self.init(named: "build-any+building")!
    }

    private static func name(forResult result: BuildResult, activity: Pipeline.Activity, asTemplate: Bool) -> String {
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
        return name
    }

}
