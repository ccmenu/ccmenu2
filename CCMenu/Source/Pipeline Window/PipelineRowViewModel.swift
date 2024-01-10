/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

class PipelineRowViewModel {

    private(set) var pipeline: Pipeline
    private var settings: UserSettings

    init(pipeline: Pipeline, settings: UserSettings) {
        self.pipeline = pipeline
        self.settings = settings
    }

    var title: String {
        return pipeline.name
    }

    var statusIcon: NSImage {
        return NSImage(forPipeline: pipeline)
    }

    var statusDescription: String {
        var description = ""
        if let error = pipeline.connectionError {
            description = "\u{1F53A} \(error)"
        } else if pipeline.status.activity == .building {
            if let build = pipeline.status.currentBuild, let timestamp = build.timestamp {
                description = statusDecription(activeBuild: build, timestamp: timestamp)
            } else {
                description =  "Build started"
            }
        } else {
            if let build = pipeline.status.lastBuild {
                description =  statusDescription(finishedBuild: build)
            } else {
                description =  "Waiting for first build"
            }
        }
        if settings.showMessagesInPipelineWindow, let message = pipeline.message {
            description.append("\n\(message)")
        }
        return description
    }

    private func statusDecription(activeBuild build: Build, timestamp: Date) -> String {
        let absolute = timestamp.formatted(date: .omitted, time: .shortened)
        let status = "Started: \(absolute)"
        return status
    }

    private func statusDescription(finishedBuild build: Build) -> String {
        var components: [String] = []
        if let timestamp = build.timestamp {
            let absolute = timestamp.formatted(date: .numeric, time: .shortened)
            components.append("Last build: \(absolute)")
        }
        if let duration = build.duration {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute, .second]
            formatter.unitsStyle = .abbreviated
            formatter.collapsesLargestUnit = true
            formatter.maximumUnitCount = 2
            if let durationAsString = formatter.string(from: duration) {
                components.append("Duration: \(durationAsString)")
            }
        }
        if let label = build.label {
            components.append("Label: \(label)")
        }
        if components.count > 0 {
            return components.joined(separator: ", ")
        }
        return "Build finished"
    }

    var feedTypeIconName: String {
        return "feed-\(pipeline.feed.type)-template"
    }

    var feedUrl: String {
        var result = pipeline.feed.url
        if pipeline.feed.type == .cctray, let name = pipeline.feed.name, name != pipeline.name {
            result.append(" (\(name))")
        }
        return result
    }

}
