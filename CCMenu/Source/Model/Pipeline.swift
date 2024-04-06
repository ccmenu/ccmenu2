/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct Pipeline: Identifiable, Decodable {

    var name: String
    var feed: Pipeline.Feed
    var status: Pipeline.Status
    var connectionError: String?
    var lastUpdated: Date?

    init(name: String, feed: Feed) {
        self.name = name
        self.feed = feed
        status = Status(activity: .other)
    }

    var id: String {
        (feed.name == nil) ? feed.url : "\(feed.url)|\(feed.name!)"
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
        return nil
    }

    mutating func update(status newStatus: Pipeline.Status) {
        status = newStatus
    }

}


extension Pipeline: Hashable {

    var hashValue: Int {
        id.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Pipeline, rhs: Pipeline) -> Bool {
        lhs.id == rhs.id
    }
      
}


extension Pipeline {

    init?(reference r: Dictionary<String, String>) {
        guard
            let name = r["name"],
            let feedTypeString = r["feedType"],
            let feedType = Pipeline.FeedType(rawValue: feedTypeString),
            let feedUrl = r["feedUrl"],
            let feedName = r["feedName"]
        else {
            return nil
        }
        self.init(name: name, feed: Pipeline.Feed(type: feedType, url: feedUrl, name: !feedName.isEmpty ? feedName : nil))
    }
    
    func reference() -> Dictionary<String, String> {
        [ "name": self.name,
          "feedType": self.feed.type.rawValue,
          "feedUrl": self.feed.url,
          "feedName": self.feed.name ?? "",
        ]
    }
    
    init?(legacyReference r: Dictionary<String, String>) {
        guard
            let projectName = r["projectName"],
            let serverUrl = r["serverUrl"]
        else {
            return nil
        }
        let name = r["displayName"] ?? projectName
        self.init(name: name, feed: Pipeline.Feed(type: .cctray, url: serverUrl, name: projectName))
    }

}
