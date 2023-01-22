/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

extension Pipeline {

    // TODO: Should this be inside Status?
    enum Activity: String, Codable {
        case
        building,
        sleeping,
        other
    }

    struct Status: Hashable, Codable {
        var activity: Activity
        var currentBuild: Build? // build if pipeline is currently building
        var lastBuild: Build?    // last completed build
        var webUrl: String?
    }

}
