/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


struct ListRowModel {

    var pipeline: Pipeline
    var title: String
    var statusIcon: NSImage
    var statusDescription: String
    var feedTypeIconName: String

    init(pipeline: Pipeline, settings: UserSettings) {
        self.pipeline = pipeline
        self.title = pipeline.name
        self.statusIcon = ImageManager().image(forPipeline: pipeline)
        self.statusDescription = ListRowModel.describeStatus(pipeline: pipeline)
        if settings.showMessagesInPipelineWindow, let message = pipeline.message {
            self.statusDescription.append("\n\(message)")
        }
        self.feedTypeIconName = "feed-\(pipeline.feed.type)-template"
    }

    var feedUrl: String {
        var result = pipeline.feed.url
        if pipeline.feed.type == .cctray, let name = pipeline.feed.name, name != pipeline.name {
            result.append(" (\(name))")
        }
        return result
    }

    private static func describeStatus(pipeline: Pipeline) -> String {
        if let error = pipeline.connectionError {
            return "\u{1F53A} " + error
        } else if pipeline.status.activity == .building {
            if let build = pipeline.status.currentBuild, let timestamp = build.timestamp {
                return statusForActiveBuild(build, timestamp)
            } else {
                return "Build started"
            }
        } else {
            if let build = pipeline.status.lastBuild {
                return statusForFinishedBuild(build)
            } else {
                return "Waiting for first build"
            }
        }
    }

    private static func statusForActiveBuild(_ build: Build, _ timestamp: Date) -> String {
        let absolute = timestamp.formatted(date: .omitted, time: .shortened)
        let status = "Started: \(absolute)"
        return status
    }

    private static func statusForFinishedBuild(_ build: Build) -> String {
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
}
