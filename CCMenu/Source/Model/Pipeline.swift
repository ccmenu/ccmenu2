/*
 *  Copyright (c) ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


enum PipelineActivity: String, Codable {
    case
    building,
    sleeping,
    other
}

enum FeedType: String, Codable {
    case
    cctray,
    github
}

struct ConnectionDetails: Hashable, Codable {
    var feedType: FeedType
    var feedUrl: String
}


struct Pipeline: Hashable, Identifiable, Codable {

    var name: String
    var connectionDetails: ConnectionDetails
    var connectionError: String?
    var activity: PipelineActivity
    var lastBuild: Build?
    var webUrl: String?

    init(name: String, feedUrl: String) {
        self.name = name
        connectionDetails = ConnectionDetails(feedType: .cctray, feedUrl: feedUrl)
        activity = .other
    }

    init(name: String, feedType: FeedType, feedUrl: String) {
        self.name = name
        connectionDetails = ConnectionDetails(feedType: feedType, feedUrl: feedUrl)
        activity = .other
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(connectionDetails.feedUrl)
    }

    var id: String {
        name + "|" + connectionDetails.feedUrl
    }

    var status: String {
        if let error = connectionError {
            return error
        } else if activity == .building {
            if let build = lastBuild, let timestamp = build.timestamp {
                return statusForActiveBuild(build, timestamp)
            } else {
                return "Build started"
            }
        } else {
            if let build = lastBuild {
                return statusForFinishedBuild(build)
            } else {
                return "Waiting for first build"
            }
        }
    }

    private func statusForActiveBuild(_ build: Build, _ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let formattedTimestamp = formatter.string(from: timestamp)
        let status = "Started: \(formattedTimestamp)"
        return status
    }

    private func statusForFinishedBuild(_ build: Build) -> String {
        var components: [String] = []
        if let timestamp = build.timestamp {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let formattedTimestamp = formatter.string(from: timestamp)
            components.append("Built: \(formattedTimestamp)")
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

    var statusImage: NSImage {
        return ImageManager().image(forPipeline: self)
    }

    var message: String? {
        return lastBuild?.comment
    }

}


struct LabeledPipeline: Hashable, Identifiable {
    var pipeline: Pipeline
    var label: String
    var id: String {
        pipeline.id
    }

}
