/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class PipelineTests: XCTestCase {

    private func makePipeline(name: String = "connectfour", activity: Pipeline.Activity = .other) -> Pipeline {
        var p = Pipeline(name: name, feed: Pipeline.Feed(type: .cctray, url: "", name: name))
        p.status.activity = activity
        return p
    }

}
