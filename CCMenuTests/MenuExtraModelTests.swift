/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class MenuExtraModelTests: XCTestCase {

    private func makeModel(pipelines: [Pipeline]) -> MenuExtraModel {
        let settings = UserSettings()
        settings.useColorInMenuBar = true // otherwise we can't compare the images
        return MenuExtraModel(pipelines: pipelines, settings: settings)
    }

    private func makePipeline(name: String, activity: Pipeline.Activity = .other, lastBuildResult: BuildResult? = nil) -> Pipeline {
        var p = Pipeline(name: name, feed: Pipeline.Feed(type: .cctray, url: "", name: ""))
        p.status.activity = activity
        if activity == .building {
            p.status.currentBuild = Build(result: .unknown)
        }
        if let lastBuildResult = lastBuildResult {
            p.status.lastBuild = Build(result: lastBuildResult)
        }
        return p
    }
    
    func testDisplaysDefaultImageAndNoTextWhenNoPipelinesAreMonitored() throws {
        let model = makeModel(pipelines: [])

        XCTAssertEqual(ImageManager().defaultImage, model.icon)
        XCTAssertEqual("", model.title)
    }

    func testDisplaysDefaultImageAndNoTextWhenNoStatusIsKnown() throws {
        let model = makeModel(pipelines: [makePipeline(name: "connectfour")])

        XCTAssertEqual(ImageManager().defaultImage, model.icon)
        XCTAssertEqual("", model.title)
    }

    func testDisplaysSuccessAndNoTextWhenAllProjectsWithStatusAreSleepingAndSuccessful() throws {
        let p0 = makePipeline(name: "connectfour")
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .success)
        let model = makeModel(pipelines: [p0, p1])

        XCTAssertEqual(ImageManager().image(forResult: .success, activity: .sleeping), model.icon)
        XCTAssertEqual("", model.title)
    }

    func testDisplaysFailureAndNumberOfFailuresWhenAllAreSleepingAndAtLeastOneIsFailed() throws {
        let p0 = makePipeline(name: "p0", activity: .sleeping, lastBuildResult: .success)
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .failure)
        let p2 = makePipeline(name: "p2", activity: .sleeping, lastBuildResult: .failure)
        let model = makeModel(pipelines: [p0, p1, p2])

        XCTAssertEqual(ImageManager().image(forResult: .failure, activity: .sleeping), model.icon)
        XCTAssertEqual("2", model.title)
    }

    func testDisplaysBuildingWhenAtLeastOneProjectIsBuilding() throws {
        let p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .failure)
        let p2 = makePipeline(name: "p2", activity: .sleeping, lastBuildResult: .failure)
        let model = makeModel(pipelines: [p0, p1, p2])

        XCTAssertEqual(ImageManager().image(forResult: .success, activity: .building), model.icon)
    }

    func testDisplaysFixingWhenAtLeastOneProjectWithLastStatusFailedIsBuilding() throws {
        let p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .failure)
        let p2 = makePipeline(name: "p2", activity: .building, lastBuildResult: .failure)
        let model = makeModel(pipelines: [p0, p1, p2])

        XCTAssertEqual(ImageManager().image(forResult: .failure, activity: .building), model.icon)
    }

    func testDoesNotDisplayBuildingTimerWhenSettingIsOff() throws {
        var p0 = makePipeline(name: "p0", activity: .sleeping, lastBuildResult: .success)
        p0.status.lastBuild!.duration = 90
        p0.status.lastBuild!.timestamp = Date.now
        let model = makeModel(pipelines: [p0])

        XCTAssertEqual("", model.title)
    }

    func testDisplaysShortestTimingForBuildingProjectsWithEstimatedCompleteTime() throws {
        let p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        var p1 = makePipeline(name: "p1", activity: .building, lastBuildResult: .success)
        p1.status.lastBuild!.duration = 70
        p1.status.currentBuild!.timestamp = Date.now
        var p2 = makePipeline(name: "p2", activity: .building, lastBuildResult: .success)
        p2.status.lastBuild!.duration = 30
        p2.status.currentBuild!.timestamp = Date.now
        let model = makeModel(pipelines: [p0, p1, p2])

        XCTAssertEqual("-29s", model.title)
    }

    func testDisplaysTimingForFixingEvenIfItsLongerThanForBuilding() throws {
        var p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        p0.status.lastBuild!.duration = 30
        p0.status.currentBuild!.timestamp = Date.now
        var p1 = makePipeline(name: "p1", activity: .building, lastBuildResult: .failure)
        p1.status.lastBuild!.duration = 90
        p1.status.currentBuild!.timestamp = Date.now
        let model = makeModel(pipelines: [p0, p1])

        XCTAssertEqual("-01:29", model.title)
    }

}


