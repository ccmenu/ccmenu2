/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

struct PipelineRowViewModel {

    var pipeline: Pipeline
    var pollInterval: Double

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
                description = statusDescription(finishedBuild: build)
            } else {
                description = "No build information available"
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
        if let duration = lastBuild?.duration, let durationAsString = formattedDuration(duration) {
            description.append(", Last build time: ")
            if lastBuild?.result == .failure {
                description.append("failed after \(durationAsString)")
            } else {
                description.append("\(durationAsString)")
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
        if let duration = build.duration, let durationAsString = formattedDuration(duration) {
            components.append("Time: \(durationAsString)")
        }
        if let label = build.label {
            components.append("Label: \(label)")
        }
        if components.count > 0 {
            return components.joined(separator: ", ")
        }
        return "Build finished"
    }

    private func formattedDuration(_ duration: TimeInterval) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.collapsesLargestUnit = true
        formatter.maximumUnitCount = 2
        return formatter.string(from: duration)
    }

    var statusMessage: String? {
        pipeline.message
    }

    var lastUpdatedMessage: String? {
        guard let timestamp = pipeline.lastUpdated else { return nil }
        // We add a few seconds to avoid possible message flickering on and off
        if Date().timeIntervalSince(timestamp) > (max(300, pollInterval) + 5) {
            let relative = timestamp.formatted(Date.RelativeFormatStyle(presentation: .named))
            return "(status last updated \(relative))"
        }
        return nil
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
