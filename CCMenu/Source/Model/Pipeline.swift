/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation


enum BuildResult: String, Codable {
    case
    success,
    failure,
    unknown,
    other
}

enum PipelineActivity: String, Codable {
    case
    building,
    sleeping,
    other
}


struct Pipeline: Hashable, Identifiable, Codable {

    var name: String
    var connectionDetails: ConnectionDetails
    var activity: PipelineActivity
    var lastBuild: Build?
    var webUrl: String?

    init(name: String, feedUrl: String) {
        self.name = name
        connectionDetails = ConnectionDetails(feedUrl: feedUrl)
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
        if activity == .building {
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
        if let label = build.label {
            components.append("Label: \(label)")
        }
        if components.count > 0 {
            return components.joined(separator: ", ")
        }
        return "Build finished"
    }

    struct ConnectionDetails: Hashable, Codable {
        var feedUrl: String
    }

    struct Build: Hashable, Codable {
        var result: BuildResult
        var label: String?
        var timestamp: Date?
    }

}
