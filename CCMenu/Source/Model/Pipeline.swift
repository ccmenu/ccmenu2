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
    var status: String

    init(name: String, feedUrl: String) {
        self.name = name
        connectionDetails = ConnectionDetails(feedUrl: feedUrl)
        activity = .other
        status = "unknown"

    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(connectionDetails.feedUrl)
    }

    var id: String {
        name + "|" + connectionDetails.feedUrl
    }

    
    struct ConnectionDetails: Hashable, Codable {
        var feedUrl: String
    }

    struct Build: Hashable, Codable {
        var result: BuildResult
    }
  
}
