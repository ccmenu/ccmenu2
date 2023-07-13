/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit

struct MenuExtraModel {
    var title: String
    var icon: NSImage

    init(pipelines: [Pipeline], settings: UserSettings) {
        self.icon = MenuExtraModel.chooseImage(pipelines, settings)
        self.title = MenuExtraModel.makeLabel(pipelines)
    }


    private static func chooseImage(_ pipelines: [Pipeline], _ settings: UserSettings) -> NSImage {
        guard let pipeline = pipelineForMenuBar(pipelines: pipelines) else {
            return ImageManager().defaultImage
        }
        return ImageManager().image(forPipeline: pipeline, asTemplate: !settings.useColorInMenuBar)
    }

    private static func makeLabel(_ pipelines: [Pipeline]) -> String {
        guard let pipeline = pipelineForMenuBar(pipelines: pipelines) else {
            return ""
        }

        var newText = ""
        if pipeline.status.activity == .building {
            if let completionTime = pipeline.estimatedBuildComplete {
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

    private static func pipelineForMenuBar(pipelines: [Pipeline]) -> Pipeline? {
        try! pipelines.sorted(by: compareMenuBarPriority(lhs:rhs:)).first
    }

    private static func compareMenuBarPriority(lhs: Pipeline, rhs: Pipeline) throws -> Bool {

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

    private static func priority(hasBuild pipeline: Pipeline) -> Int {
        return (pipeline.status.lastBuild != nil) ? 1 : 0
    }

    private static func priority(isBuilding pipeline: Pipeline) -> Int {
        return (pipeline.status.activity == .building) ? 1 : 0
    }

    private static func priority(buildResult pipeline: Pipeline) -> Int {
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

    private static func priority(estimatedComplete pipeline: Pipeline) -> Int {
        let date = pipeline.estimatedBuildComplete ?? Date.distantFuture
        assert(Date.distantFuture.timeIntervalSinceReferenceDate < Double(Int.max))
        // Multiplying all intervals with -1 makes shorter intervals higher priority.
        return Int(date.timeIntervalSinceReferenceDate) * -1
    }
}

