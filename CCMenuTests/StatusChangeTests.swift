/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class StatusChangeTests: XCTestCase {

    private func makeStatusChange(previous: Pipeline.Status, current: Pipeline.Status) -> StatusChange {
        var p = Pipeline(name: "foo", feed: Pipeline.Feed(type: .cctray, url: "", name: ""))
        p.status = current
        return StatusChange(pipeline: p, previousStatus: previous)
    }

    // MARK: - no change

    func testKindIsNoChangeWhenPreviousWasSleepingAndCurrentIsSleeping() throws {
        let change = makeStatusChange(previous: Pipeline.Status(activity: .sleeping), current: Pipeline.Status(activity: .sleeping))
        XCTAssertEqual(.noChange, change.kind)
    }

    func testKindIsNoChangeWhenPreviousWasBuildingAndCurrentIsBuilding() throws {
        let change = makeStatusChange(previous: Pipeline.Status(activity: .building), current: Pipeline.Status(activity: .building))
        XCTAssertEqual(.noChange, change.kind)
    }

    func testKindIsNoChangeWhenPreviousWasOtherAndCurrentIsOther() throws {
        let change = makeStatusChange(previous: Pipeline.Status(activity: .other), current: Pipeline.Status(activity: .other))
        XCTAssertEqual(.noChange, change.kind)
    }

    // MARK: - start

    func testKindIsStartWhenPreviousWasSleepingAndCurrentIsBuilding() throws {
        let change = makeStatusChange(previous: Pipeline.Status(activity: .sleeping), current: Pipeline.Status(activity: .building))
        XCTAssertEqual(.start, change.kind)
    }

    func testKindIsStartWhenPreviousWasSleepingAndCurrentIsOther() throws {
        let change = makeStatusChange(previous: Pipeline.Status(activity: .sleeping), current: Pipeline.Status(activity: .other))
        XCTAssertEqual(.start, change.kind)
    }

    // MARK: - completion

    func testKindIsCompletionWhenPreviousWasBuildingAndCurrentIsSleeping() throws {
        let change = makeStatusChange(previous: Pipeline.Status(activity: .building), current: Pipeline.Status(activity: .sleeping))
        XCTAssertEqual(.completion, change.kind)
    }

    func testKindIsCompletionWhenPreviousWasSleepingAndCurrentIsSleepingButBuildIsDifferent() throws {
        let previous = Pipeline.Status(activity: .sleeping, lastBuild: Build(result: .success, label: "1"))
        let current = Pipeline.Status(activity: .sleeping, lastBuild: Build(result: .success, label: "2"))
        let change = makeStatusChange(previous: previous, current: current)
        XCTAssertEqual(.completion, change.kind)
    }

    func testKindIsCompletionWhenPreviousWasBuildingAndCurrentIsBuildingButBuildIsDifferent() throws {
        let previous = Pipeline.Status(activity: .building, lastBuild: Build(result: .success, label: "1"))
        let current = Pipeline.Status(activity: .building, lastBuild: Build(result: .success, label: "2"))
        let change = makeStatusChange(previous: previous, current: current)
        XCTAssertEqual(.completion, change.kind)
    }

    // MARK: other

    func testKindIsOtherWhenPreviousWasBuildingAndCurrentIsOther() throws {
        let change = makeStatusChange(previous: Pipeline.Status(activity: .building), current: Pipeline.Status(activity: .other))
        XCTAssertEqual(.other, change.kind)
    }

    func testKindIsOtherWhenPreviousWasOtherAndCurrentIsBuilding() throws {
        let change = makeStatusChange(previous: Pipeline.Status(activity: .other), current: Pipeline.Status(activity: .building))
        XCTAssertEqual(.other, change.kind)
    }

    func testKindIsOtherWhenPreviousWasOtherAndCurrentIsSleeping() throws {
        let change = makeStatusChange(previous: Pipeline.Status(activity: .other), current: Pipeline.Status(activity: .sleeping))
        XCTAssertEqual(.other, change.kind)
    }


}
