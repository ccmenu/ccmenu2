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

    init(name: String, feedUrl: String) {
        self.name = name
        self.connectionDetails = ConnectionDetails(feedUrl: feedUrl)
        self.statusSummary = ""
        self.webUrl = ""
    }

    init(name: String, feedUrl: String, status: Status) {
        self.init(name: name, feedUrl: feedUrl)
        self.status = status
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(connectionDetails.feedUrl)
    }

    var id: String {
        name + "|" + connectionDetails.feedUrl
    }
    
    var name: String
    
    var connectionDetails: ConnectionDetails
    
    struct ConnectionDetails: Hashable, Codable {
        var feedUrl: String
    }
    
    var status: Status?
    
    struct Status: Hashable, Codable {
        var buildResult: BuildResult
        var pipelineActivity: PipelineActivity
    }
    
    var statusSummary: String
    
    var webUrl: String 
    
}
