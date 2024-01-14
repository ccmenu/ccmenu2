/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct PipelineRowViewModel {

    var pipeline: Pipeline

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
            if let build = pipeline.status.currentBuild {
                description = statusDecription(activeBuild: build, lastBuild: pipeline.status.lastBuild)
            }
        } else {
            if let build = pipeline.status.lastBuild {
                description =  statusDescription(finishedBuild: build)
            } else {
                description =  "Waiting for first build"
            }
        }
        return description
    }

    private func statusDecription(activeBuild build: Build, lastBuild: Build?) -> String {
        var description: String
        if let timestamp = build.timestamp {
            let absolute = timestamp.formatted(date: .omitted, time: .shortened)
            description = "Started: \(absolute)"
        } else {
            description =  "Started"
        }
        if let duration = lastBuild?.duration {
            description.append(", Last build: ")
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .abbreviated
            formatter.collapsesLargestUnit = true
            formatter.maximumUnitCount = 2
            if let durationAsString = formatter.string(from: duration) {
                if lastBuild?.result == .failure {
                    description.append("failed after \(durationAsString)")
                } else {
                    description.append("took \(durationAsString)")
                }
            }

        }

        return description
    }

    private func statusDescription(finishedBuild build: Build) -> String {
        var components: [String] = []
        if let timestamp = build.timestamp {
            let absolute = timestamp.formatted(date: .numeric, time: .shortened)
            components.append("Last build: \(absolute)")
        }
        if let duration = build.duration {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
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

    var statusMessage: String? {
        pipeline.message
    }

    var feedTypeIconName: String {
        "feed-\(pipeline.feed.type)-template"
    }

    var feedUrl: String {
        var result = pipeline.feed.url
        if pipeline.feed.type == .cctray, let name = pipeline.feed.name, name != pipeline.name {
            result.append(" (\(name))")
        }
        return result
    }

}
