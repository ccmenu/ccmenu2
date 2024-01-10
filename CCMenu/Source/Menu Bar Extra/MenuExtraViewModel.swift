/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct MenuExtraViewModel {

    private var pipelines: [Pipeline]
    private var settings: UserSettings

    init(pipelines: [Pipeline], settings: UserSettings) {
        self.pipelines = pipelines
        self.settings = settings
    }

    var icon: NSImage {
        guard let pipeline = pipelineForMenuBar() else {
            return NSImage(forPipeline: nil)
        }
        let useColor = settings.useColorInMenuBar && 
            (!settings.useColorInMenuBarFailedOnly || pipeline.status.lastBuild?.result == .failure)
        return NSImage(forPipeline: pipeline, asTemplate: !useColor)
    }

    var title: String {
        guard let pipeline = pipelineForMenuBar() else {
            return ""
        }
        var newText = ""
        if pipeline.status.activity == .building {
            if settings.showBuildTimerInMenuBar, let completionTime = pipeline.estimatedBuildComplete {
                newText = Date.now.formatted(.compactRelative(reference: completionTime))
            }
        } else {
            let failCount = pipelines.filter({ p in p.status.lastBuild?.result == .failure}).count
            if failCount > 0 {
                newText = "\(failCount)"
            }
        }
        return newText
    }

    private func pipelineForMenuBar() -> Pipeline? {
        try! pipelines.sorted(by: compareMenuBarPriority(lhs:rhs:)).first
    }

    private func compareMenuBarPriority(lhs: Pipeline, rhs: Pipeline) throws -> Bool {
        let priorities = [
            priority(hasBuild:),
            priority(isBuilding:),
            priority(buildResult:),
            priority(estimatedComplete:)
        ]
        for p in priorities {
            if p(lhs) > p(rhs) {
                return true
            }
            if p(lhs) < p(rhs) {
                return false
            }
        }
        return false
    }

    private func priority(hasBuild pipeline: Pipeline) -> Int {
        return (pipeline.status.lastBuild != nil) ? 1 : 0
    }

    private func priority(isBuilding pipeline: Pipeline) -> Int {
        return (pipeline.status.activity == .building) ? 1 : 0
    }

    private func priority(buildResult pipeline: Pipeline) -> Int {
        switch pipeline.status.lastBuild?.result {
        case .failure:
            return 3
        case .success:
            return 2
        case .unknown, .other:
            return 1
        case nil:
            return 0
        }
    }

    private func priority(estimatedComplete pipeline: Pipeline) -> Int {
        let date = pipeline.estimatedBuildComplete ?? Date.distantFuture
        assert(Date.distantFuture.timeIntervalSinceReferenceDate < Double(Int.max))
        // Multiplying all intervals with -1 makes shorter intervals higher priority.
        return Int(date.timeIntervalSinceReferenceDate) * -1
    }
}

