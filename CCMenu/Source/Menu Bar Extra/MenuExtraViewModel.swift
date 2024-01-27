/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct MenuExtraViewModel {

    var pipelines: [Pipeline]
    var useColorInMenuBar: Bool
    var useColorInMenuBarFailedOnly: Bool
    var showBuildTimerInMenuBar: Bool

    var icon: NSImage {
        guard let pipeline = pipelineForMenuBar() else {
            return NSImage(forPipeline: nil)
        }
        return NSImage(forPipeline: pipeline, asTemplate: !shouldUseColorForPipeline(pipeline))
    }

    var title: String {
        guard let pipeline = pipelineForMenuBar() else {
            return ""
        }
        var newText = ""
        if pipeline.status.activity == .building {
            if showBuildTimerInMenuBar, let completionTime = pipeline.estimatedBuildComplete {
                newText = Date.now.formatted(.compactRelative(reference: completionTime))
            }
        } else {
            let failCount = pipelines.filter({ p in p.status.lastBuild?.result == .failure}).count
            if failCount > 1 {
                newText = "\(failCount)"
            }
        }
        return newText
    }

    var color: Color? {
        guard let pipeline = pipelineForMenuBar() else {
            return nil
        }
        if !shouldUseColorForPipeline(pipeline) {
            return nil
        }
        let result = pipeline.status.lastBuild?.result ?? BuildResult.other
        if result == .failure {
            return Color(nsColor: (pipeline.status.activity == .building) ? .statusOrange : .statusRed)
        } else {
            // TODO: Reconsider this simplification when an unknown status can have a label
            return Color(nsColor: .statusGreen)
        }
    }

    private func shouldUseColorForPipeline(_ pipeline: Pipeline) -> Bool {
        useColorInMenuBar && (!useColorInMenuBarFailedOnly || pipeline.status.lastBuild?.result == .failure)
    }

    private func pipelineForMenuBar() -> Pipeline? {
        // TODO: consider caching the result
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

