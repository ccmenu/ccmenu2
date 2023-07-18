/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

final class ListRowModelTests: XCTestCase {

    private func makePipeline(name: String = "connectfour", activity: Pipeline.Activity = .other) -> Pipeline {
        var p = Pipeline(name: name, feed: Pipeline.Feed(type: .cctray, url: "http://localhost:4567/cc.xml", name: name))
        p.status.activity = activity
        return p
    }

    func testStatusWhenSleepingAndLastBuildNotAvailable() throws {
        let pipeline = makePipeline(activity: .sleeping)
        let pvm = ListRowModel(pipeline: pipeline, settings: UserSettings())

        XCTAssertEqual("Waiting for first build", pvm.statusDescription)
    }

    func testStatusWhenSleepingAndLastBuildIsAvailable() throws {
        var pipeline = makePipeline(activity: .sleeping)
        pipeline.status.lastBuild = Build(result: .success)
        pipeline.status.lastBuild!.label = "842"
        pipeline.status.lastBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        pipeline.status.lastBuild!.duration = 53
        let pvm = ListRowModel(pipeline: pipeline, settings: UserSettings())

        // Check some components that should definitely be there in this form
        XCTAssertTrue(pvm.statusDescription.contains("2020")) // timestamp year
        XCTAssertTrue(pvm.statusDescription.contains("27"))   // timestamp day
        XCTAssertTrue(pvm.statusDescription.contains("47"))   // timestamp minute
        XCTAssertTrue(pvm.statusDescription.contains("842"))  // label
        XCTAssertTrue(pvm.statusDescription.contains("53"))   // duration
    }

    func testStatusWhenSleepingAndLastBuildIsAvailableButHasNoFurtherInformation() throws {
        var pipeline = makePipeline(activity: .sleeping)
        pipeline.status.lastBuild = Build(result: .success)
        let pvm = ListRowModel(pipeline: pipeline, settings: UserSettings())

        XCTAssertEqual("Build finished", pvm.statusDescription)
    }

    func testStatusWhenBuildingAndCurrentBuildNotAvailable() throws { // TODO: does this even make sense?
        let pipeline = makePipeline(activity: .building)
        let pvm = ListRowModel(pipeline: pipeline, settings: UserSettings())

        XCTAssertEqual("Build started", pvm.statusDescription)
    }

    func testStatusWhenBuildingAndCurrentBuildIsAvailable() throws {
        var pipeline = makePipeline(activity: .building)
        pipeline.status.currentBuild = Build(result: .unknown)
        pipeline.status.currentBuild!.timestamp = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")
        let pvm = ListRowModel(pipeline: pipeline, settings: UserSettings())

        // Check some components that should definitely be there in this form
        XCTAssertTrue(pvm.statusDescription.contains("47"))   // timestamp minute
    }

    func testStatusWhenErrorIsSet() throws {
        var pipeline = makePipeline(activity: .sleeping)
        pipeline.status.lastBuild = Build(result: .success)
        pipeline.connectionError = "404 Not Found"
        let pvm = ListRowModel(pipeline: pipeline, settings: UserSettings())

        XCTAssertEqual("\u{1F53A} 404 Not Found", pvm.statusDescription)
    }

    func testUrlWhenCCTrayHasUserAssignedName() throws {
        var pipeline = makePipeline(activity: .sleeping)
        pipeline.name = "Connect4"
        let pvm = ListRowModel(pipeline: pipeline, settings: UserSettings())

        XCTAssertEqual("http://localhost:4567/cc.xml (connectfour)", pvm.feedUrl)
    }

}
