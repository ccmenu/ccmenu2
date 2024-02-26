/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct Pipeline: Identifiable, Codable {

    var name: String
    var feed: Pipeline.Feed
    var status: Pipeline.Status
    var connectionError: String?

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

extension Pipeline: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
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
        return Pipeline(name: name, feed: Pipeline.Feed(type: feedType, url: feedUrl, name: feedName.isEmpty ? nil : feedName))
    }

    public func asDictionaryForPersisting() -> Dictionary<String, String> {
        [ "name": self.name,
          "feedType": String(describing: self.feed.type),
          "feedUrl": self.feed.url,
          "feedName": self.feed.name ?? "",
        ]
    }

}
