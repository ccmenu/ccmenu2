/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class PipelineTests: XCTestCase {

    func testStatusWhenSleepingAndLastBuildNotAvailable() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .sleeping)

        XCTAssertEqual("Waiting for first build", pipeline.statusDescription)
    }

    func testStatusWhenSleepingAndLastBuildIsAvailable() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .sleeping)
        pipeline.status.lastBuild = Build(result: .success)
        pipeline.status.lastBuild!.label = "151"
        pipeline.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        pipeline.status.lastBuild!.duration = 80.8

        // TODO: Basically duplicated from actual code...
        let timestamp = pipeline.status.lastBuild!.timestamp!
        let absolute = timestamp.formatted(date: .numeric, time: .shortened)
        let relative = timestamp.formatted(Date.RelativeFormatStyle(presentation: .named))
        let formattedTimestamp = "\(absolute) (\(relative))"

        let durationFormatter = DateComponentsFormatter()
        durationFormatter.allowedUnits = [.day, .hour, .minute, .second]
        durationFormatter.unitsStyle = .abbreviated
        durationFormatter.collapsesLargestUnit = true
        durationFormatter.maximumUnitCount = 2
        let formattedDuration = durationFormatter.string(from: 80.8)!

        XCTAssertEqual("Last build: \(formattedTimestamp), Duration: \(formattedDuration), Label: 151", pipeline.statusDescription)
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

        // TODO: Basically duplicated from actual code...
        let timestamp = pipeline.status.currentBuild!.timestamp!
        let absolute = timestamp.formatted(date: .omitted, time: .shortened)
        let relative = timestamp.formatted(Date.RelativeFormatStyle(presentation: .named, unitsStyle: .narrow))
        let expected = "Started: \(absolute) (\(relative))"

        XCTAssertEqual(expected, pipeline.statusDescription)
    }

    func testStatusWhenErrorIsSet() throws {
        var pipeline = Pipeline(name: "connectfour", feedUrl: "http://test.org/cctray.xml", activity: .sleeping)
        pipeline.status.lastBuild = Build(result: .success)
        pipeline.connectionError = "404 Not Found"

        XCTAssertEqual("404 Not Found", pipeline.statusDescription)

    }

}
