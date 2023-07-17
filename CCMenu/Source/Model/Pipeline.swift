/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import AppKit


struct Pipeline: Hashable, Identifiable, Codable {

    var name: String
    var feed: Pipeline.Feed
    var status: Pipeline.Status
    var connectionError: String?

    init(name: String, feed: Feed) {
        self.name = name
        self.feed = feed
        status = Status(activity: .other)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(feed.url) // TODO: why? id already contains feedUrl...
    }

    var id: String {
        name + "|" + feed.url
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
        guard
            let name = dict["name"],
            let feedTypeString = dict["feedType"],
            let feedType = Pipeline.FeedType(rawValue: feedTypeString),
            let feedUrl = dict["feedUrl"]
        else {
            return nil
        }
        let feedName = dict["feedName"] ?? ""
        let authToken = dict["authToken"] ?? ""
        return Pipeline(name: name, feed: Pipeline.Feed(type: feedType, url: feedUrl, name: feedName.isEmpty ? nil : feedName, authToken: authToken.isEmpty ? nil : authToken))
    }

    public func asDictionaryForPersisting() -> Dictionary<String, String> {
        [ "name": self.name,
          "feedType": String(describing: self.feed.type),
          "feedUrl": self.feed.url,
          "feedName": self.feed.name ?? "",
          "authToken": self.feed.authToken ?? ""
        ]
    }

}
