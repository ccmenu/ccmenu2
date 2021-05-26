/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class PipelineTests: XCTestCase {

    func testStatusWhenSleepingAndLastBuildNotAvailable() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "")
        pipeline.activity = .sleeping

        XCTAssertEqual("Waiting for first build", pipeline.status)
    }

    func testStatusWhenSleepingAndLastBuildIsAvailable() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "")
        pipeline.activity = .sleeping
        pipeline.lastBuild = Pipeline.Build(result: .success)
        pipeline.lastBuild!.label = "151"
        pipeline.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        pipeline.lastBuild!.duration = 80.8

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let formattedTimestamp = dateFormatter.string(from: pipeline.lastBuild!.timestamp!)

        let durationFormatter = DateComponentsFormatter()
        durationFormatter.allowedUnits = [.day, .hour, .minute, .second]
        durationFormatter.unitsStyle = .abbreviated
        durationFormatter.collapsesLargestUnit = true
        durationFormatter.maximumUnitCount = 2
        let formattedDuration = durationFormatter.string(from: 80.8)!

        XCTAssertEqual("Built: \(formattedTimestamp), Duration: \(formattedDuration), Label: 151", pipeline.status)
    }
    
    func testStatusWhenSleepingAndLastBuildIsAvailableButHasNoFurtherInformation() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "")
        pipeline.activity = .sleeping
        pipeline.lastBuild = Pipeline.Build(result: .success)

        XCTAssertEqual("Build finished", pipeline.status)
    }

    func testStatusWhenBuildingAndLastBuildNotAvailable() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "")
        pipeline.activity = .building

        XCTAssertEqual("Build started", pipeline.status)
    }

    func testStatusWhenBuildingAndLastBuildIsAvailable() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "")
        pipeline.activity = .building
        pipeline.lastBuild = Pipeline.Build(result: .success)
        pipeline.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let formattedTimestamp = formatter.string(from: pipeline.lastBuild!.timestamp!)

        XCTAssertEqual("Started: \(formattedTimestamp)", pipeline.status)
    }

}
