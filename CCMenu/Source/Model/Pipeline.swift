/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


struct Pipeline: Hashable, Identifiable, Codable {

    var name: String
    var assignedName: String?
    var feed: Pipeline.Feed
    var status: Pipeline.Status
    var connectionError: String?

    init(name: String, feedUrl: String) {
        self.name = name
        feed = Feed(type: .cctray, url: feedUrl)
        status = Status(activity: .other)
    }

    init(name: String, feedUrl: String, activity: Activity) {
        self.name = name
        feed = Feed(type: .cctray, url: feedUrl)
        status = Status(activity: activity)
    }

    init(name: String, feedType: FeedType, feedUrl: String) {
        self.name = name
        feed = Feed(type: feedType, url: feedUrl)
        status = Status(activity: .other)
    }

    var displayName: String {
        set {
            assignedName = newValue
        }
        get {
            assignedName ?? name
        }
    }

    mutating func resetDisplayName() {
        assignedName = nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(feed.url) // TODO: why? id already contains feedUrl...
    }

    var id: String {
        name + "|" + feed.url
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
        let absolute = timestamp.formatted(date: .omitted, time: .shortened)
        let status = "Started: \(absolute)"
        return status
    }

    private func statusForFinishedBuild(_ build: Build) -> String {
        var components: [String] = []
        if let timestamp = build.timestamp {
            // TODO: figure out how to use "today" and "yesterday"
            let absolute = timestamp.formatted(date: .numeric, time: .shortened)
//            let relative = timestamp.formatted(Date.RelativeFormatStyle(presentation: .named))
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


extension Pipeline {

    public static func fromPersistedDictionary(dict: Dictionary<String, String>) -> Pipeline? {
        // TODO: this looks ugly and isn't helpful
        if let name = dict["name"],
           let feedTypeString = dict["feedType"],
           let feedType = Pipeline.FeedType(rawValue: feedTypeString),
           let feedUrlString = dict["feedUrl"] {

            var p = Pipeline(name: name, feedType: feedType, feedUrl: feedUrlString)
            if let displayName = dict["displayName"] {
                p.displayName = displayName
            }
            return p
        }
        return nil
    }

    public func asDictionaryForPersisting() -> Dictionary<String, String> {
        [ "name": self.name,
          "displayName": self.displayName,
          "feedType": String(describing: self.feed.type),
          "feedUrl": self.feed.url
        ]
    }

}
