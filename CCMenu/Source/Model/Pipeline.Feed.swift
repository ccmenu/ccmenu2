/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

extension Pipeline {

    // TODO: Should this be inside Feed?
    enum FeedType: String, Codable {
        case
        cctray,
        github
    }

    struct Feed: Hashable, Codable {
        var type: FeedType
        var url: String
        var name: String? // for cctray only: name of the project in the feed
        var authToken: String? // for GitHub only: bearer token for authentication
    }
    
}
