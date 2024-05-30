/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

struct StatusChange {

    enum Kind {
        case
        start,
        completion,
        other,
        noChange
    }

    var pipeline: Pipeline
    var previousStatus: PipelineStatus

    var kind: Kind {
        if previousStatus.activity == .sleeping && pipeline.status.activity != .sleeping {
            return .start
        }
        if previousStatus.activity == .building && pipeline.status.activity == .sleeping {
            return .completion
        }
        if previousStatus.activity == pipeline.status.activity {
            if pipeline.status.lastBuild?.label != previousStatus.lastBuild?.label {
                return .completion
            } else {
                return .noChange
            }
        }
        return .other
    }

}

