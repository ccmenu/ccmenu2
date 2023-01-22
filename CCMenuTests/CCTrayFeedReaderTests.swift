/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class CCTrayFeedReaderTests: XCTestCase {

    func testUpdatesAllRelevantFieldsOnPipelineWithNoBuildsWhenSleeping() throws {
        let basePipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .sleeping)
        let reader = CCTrayFeedReader(for: basePipeline)

        var status = Pipeline.Status(activity: .sleeping)
        status.webUrl = "http://localhost/"
        status.lastBuild = Build(result: .success)
        status.lastBuild!.label = "testlabel"
        status.lastBuild!.timestamp = Date.now

        reader.updatePipeline(name: basePipeline.name, newStatus: status)
        let pipeline = reader.pipelines[0]

        XCTAssertEqual(.sleeping, pipeline.status.activity)
        XCTAssertEqual("http://localhost/", pipeline.status.webUrl)
        XCTAssertNotNil(pipeline.status.lastBuild)
        XCTAssertEqual(.success, pipeline.status.lastBuild?.result)
        XCTAssertEqual("testlabel", pipeline.status.lastBuild?.label)
        XCTAssertNotNil(pipeline.status.lastBuild!.timestamp)
    }

    func testUpdatesAllRelevantFieldsOnPipelineWithNoBuildsWhenBuilding() throws {
        let basePipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .building)
        let reader = CCTrayFeedReader(for: basePipeline)

        var status = Pipeline.Status(activity: .building)
        status.lastBuild = Build(result: .failure)
        status.lastBuild!.label = "testlabel"
        status.lastBuild!.timestamp = Date.now
        status.currentBuild = Build(result: .unknown)

        reader.updatePipeline(name: basePipeline.name, newStatus: status)
        let pipeline = reader.pipelines[0]

        XCTAssertEqual(.building, pipeline.status.activity)
        XCTAssertNotNil(pipeline.status.lastBuild)
        XCTAssertEqual(.failure, pipeline.status.lastBuild?.result)
        XCTAssertEqual("testlabel", pipeline.status.lastBuild?.label)
        XCTAssertNotNil(pipeline.status.lastBuild?.timestamp)
        XCTAssertNotNil(pipeline.status.currentBuild)
        XCTAssertEqual(.unknown, pipeline.status.currentBuild?.result)
        XCTAssertNil(pipeline.status.currentBuild?.timestamp)
    }

    func testSetsBuildTimestampOnCurrentBuildWhenTransitioningToBuilding() throws {
        let basePipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .sleeping)
        let reader = CCTrayFeedReader(for: basePipeline)

        var status = Pipeline.Status(activity: .building)
        status.currentBuild = Build(result: .unknown)

        reader.updatePipeline(name: basePipeline.name, newStatus: status)
        let pipeline = reader.pipelines[0]

        let timestamp = pipeline.status.currentBuild!.timestamp!
        XCTAssertTrue(DateInterval(start: timestamp, end: Date.now).duration < 1)
    }

    func testBuildTimestampOnCurrentBuild() throws {
        var basePipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .building)
        basePipeline.status.lastBuild = Build(result: .unknown)
        basePipeline.status.currentBuild = Build(result: .unknown)
        basePipeline.status.currentBuild!.timestamp = Date.now
        let reader = CCTrayFeedReader(for: basePipeline)

        var status = Pipeline.Status(activity: .building)
        status.lastBuild = Build(result: .success)
        status.currentBuild = Build(result: .unknown)

        reader.updatePipeline(name: basePipeline.name, newStatus: status)
        let pipeline = reader.pipelines[0]

        XCTAssertNotNil(pipeline.status.currentBuild)
        XCTAssertNotNil(pipeline.status.currentBuild?.timestamp)
    }

    func testSetsBuildDurationOnLastBuildWhenTransitioningFromBuildingAndCurrentBuildTimestampAvailable() throws {
        var basePipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .building)
        basePipeline.status.currentBuild = Build(result: .unknown)
        basePipeline.status.currentBuild!.timestamp = Date.now
        let reader = CCTrayFeedReader(for: basePipeline)

        var status = Pipeline.Status(activity: .sleeping)
        status.lastBuild = Build(result: .success)

        reader.updatePipeline(name: basePipeline.name, newStatus: status)
        let pipeline = reader.pipelines[0]
        let duration = pipeline.status.lastBuild!.duration!

        XCTAssertTrue(duration < 1)
    }

    func testKeepsDurationOnLastBuild() throws {
        var basePipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .sleeping)
        basePipeline.status.lastBuild = Build(result: .success)
        basePipeline.status.lastBuild!.label = "label.1"
        basePipeline.status.lastBuild!.duration = 90
        let reader = CCTrayFeedReader(for: basePipeline)

        var status = Pipeline.Status(activity: .sleeping)
        status.lastBuild = Build(result: .success)
        status.lastBuild!.label = "label.1"

        reader.updatePipeline(name: basePipeline.name, newStatus: status)
        let pipeline = reader.pipelines[0]

        XCTAssertNotNil(pipeline.status.lastBuild)
        XCTAssertEqual("label.1", pipeline.status.lastBuild?.label)
        XCTAssertEqual(90, pipeline.status.lastBuild?.duration)
    }

    func testSetsErrorWhenNoStatusIsProvided() throws {
        let basePipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .sleeping)
        let reader = CCTrayFeedReader(for: basePipeline)

        reader.updatePipeline(name: basePipeline.name, newStatus: nil)
        let pipeline = reader.pipelines[0]

        XCTAssertTrue(pipeline.connectionError!.starts(with: "The server did not"))
    }

    func testClearsErrorWhenUpdatedWithStatus() throws {
        var basePipeline = Pipeline(name: "connectfour", feedUrl: "", activity: .sleeping)
        basePipeline.connectionError = "error message for testing"
        let reader = CCTrayFeedReader(for: basePipeline)

        let status = Pipeline.Status(activity: .building)

        reader.updatePipeline(name: basePipeline.name, newStatus: status)
        let pipeline = reader.pipelines[0]

        XCTAssertNil(pipeline.connectionError)
    }



}
