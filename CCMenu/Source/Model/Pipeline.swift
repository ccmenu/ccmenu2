/*
 *  Copyright (c) Erik Doernenburg and contributors
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
    var connectionDetails: ConnectionDetails // TODO: make optional (for parsers)
    var status: Pipeline.Status
    var connectionError: String?

    init(name: String, feedUrl: String) {
        self.name = name
        connectionDetails = ConnectionDetails(feedType: .cctray, feedUrl: feedUrl)
        status = Status(activity: .other)
    }

    init(name: String, feedUrl: String, activity: PipelineActivity) {
        self.name = name
        connectionDetails = ConnectionDetails(feedType: .cctray, feedUrl: feedUrl)
        status = Status(activity: activity)
    }

    init(name: String, feedType: FeedType, feedUrl: String) {
        self.name = name
        connectionDetails = ConnectionDetails(feedType: feedType, feedUrl: feedUrl)
        status = Status(activity: .other)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(connectionDetails.feedUrl) // TODO: why? id already contains feedUrl...
    }

    var id: String {
        name + "|" + connectionDetails.feedUrl
    }

    var statusDescription: String {
        if let error = connectionError {
            return error
        } else if status.activity == .building {
            if let build = status.currentBuild, let timestamp = build.timestamp {
                return statusForActiveBuild(build, timestamp)
            } else {
                return "Build started"
            }
        } else {
            if let build = status.lastBuild {
                return statusForFinishedBuild(build)
            } else {
                return "Waiting for first build"
            }
        }
    }

    private func statusForActiveBuild(_ build: Build, _ timestamp: Date) -> String {
        let formatter = DateFormatter() // TODO: check newer APIs
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let formattedTimestamp = formatter.string(from: timestamp)
        let status = "Started: \(formattedTimestamp)" // TODO: make relative? optional? both, absolute and relative?
        return status
    }

    private func statusForFinishedBuild(_ build: Build) -> String {
        var components: [String] = []
        if let timestamp = build.timestamp {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let formattedTimestamp = formatter.string(from: timestamp)
            components.append("Built: \(formattedTimestamp)") // TODO: make relative? optional? both, absolute and relative?
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
        return status.activity == .building ? status.currentBuild?.message : status.lastBuild?.message
    }

    var avatar: URL? {
        return status.activity == .building ? status.currentBuild?.avatar : status.lastBuild?.avatar
    }

    var estimatedBuildComplete: Date? {
        if status.activity == .building, let duration = status.lastBuild?.duration {
            return status.currentBuild?.timestamp?.advanced(by: duration)
        }
        return nil;
    }

}


struct LabeledPipeline: Hashable, Identifiable {
    var pipeline: Pipeline
    var label: String
    var id: String {
        pipeline.id
    }

}
