/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class PipelineTests: XCTestCase {

    func testStatusWhenSleepingAndLastBuildNotAvailable() throws {
        let pipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .sleeping)

        XCTAssertEqual("Waiting for first build", pipeline.statusDescription)
    }

    func testStatusWhenSleepingAndLastBuildIsAvailable() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .sleeping)
        pipeline.status.lastBuild = Build(result: .success)
        pipeline.status.lastBuild!.label = "842"
        pipeline.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        pipeline.status.lastBuild!.duration = 53

        let description = pipeline.statusDescription
        // Check some components that should definitely be there in this form
        XCTAssertTrue(description.contains("2020")) // timestamp year
        XCTAssertTrue(description.contains("27"))   // timestamp day
        XCTAssertTrue(description.contains("47"))   // timestamp minute
        XCTAssertTrue(description.contains("842"))  // label
        XCTAssertTrue(description.contains("53"))   // duration
    }
    
    func testStatusWhenSleepingAndLastBuildIsAvailableButHasNoFurtherInformation() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .sleeping)
        pipeline.status.lastBuild = Build(result: .success)

        XCTAssertEqual("Build finished", pipeline.statusDescription)
    }

    func testStatusWhenBuildingAndCurrentBuildNotAvailable() throws { // TODO: does this even make sense?
        let pipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .building)

        XCTAssertEqual("Build started", pipeline.statusDescription)
    }

    func testStatusWhenBuildingAndCurrentBuildIsAvailable() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .building)
        pipeline.status.currentBuild = Build(result: .unknown)
        pipeline.status.currentBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")

        let description = pipeline.statusDescription
        // Check some components that should definitely be there in this form
        XCTAssertTrue(description.contains("47"))   // timestamp minute
    }

    func testStatusWhenErrorIsSet() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "http://test.org/cctray.xml", activity: .sleeping)
        pipeline.status.lastBuild = Build(result: .success)
        pipeline.connectionError = "404 Not Found"

        XCTAssertEqual("404 Not Found", pipeline.statusDescription)

    }

}
