/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class ViewModelTests: XCTestCase {

    func testDisplaysDefaultImageAndNoTextWhenNoPipelinesAreMonitored() throws {
        let model = makeModel()

        XCTAssertEqual(ImageManager().defaultImage, model.imageForMenuBar)
        XCTAssertEqual("", model.textForMenuBar)
    }

    func testDisplaysDefaultImageAndNoTextWhenNoStatusIsKnown() throws {
        let model = makeModel()
        model.pipelines = [makePipeline(name: "connectfour")]

        XCTAssertEqual(ImageManager().defaultImage, model.imageForMenuBar)
        XCTAssertEqual("", model.textForMenuBar)
    }

    func testDisplaysSuccessAndNoTextWhenAllProjectsWithStatusAreSleepingAndSuccessful() throws {
        let model = makeModel()
        let p0 = makePipeline(name: "connectfour")
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .success)
        model.pipelines = [p0, p1]

        XCTAssertEqual(ImageManager().image(forResult: .success, activity: .sleeping), model.imageForMenuBar)
        XCTAssertEqual("", model.textForMenuBar)
    }

    func testDisplaysFailureAndNumberOfFailuresWhenAllAreSleepingAndAtLeastOneIsFailed() throws {
        let model = makeModel()
        let p0 = makePipeline(name: "p0", activity: .sleeping, lastBuildResult: .success)
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .failure)
        let p2 = makePipeline(name: "p2", activity: .sleeping, lastBuildResult: .failure)
        model.pipelines = [p0, p1, p2]

        XCTAssertEqual(ImageManager().image(forResult: .failure, activity: .sleeping), model.imageForMenuBar)
        XCTAssertEqual("2", model.textForMenuBar)
    }

    func testDisplaysBuildingWhenAtLeastOneProjectIsBuilding() throws {
        let model = makeModel()
        let p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .failure)
        let p2 = makePipeline(name: "p2", activity: .sleeping, lastBuildResult: .failure)
        model.pipelines = [p0, p1, p2]

        XCTAssertEqual(ImageManager().image(forResult: .success, activity: .building), model.imageForMenuBar)
    }

    func testDisplaysFixingWhenAtLeastOneProjectWithLastStatusFailedIsBuilding() throws {
        let model = makeModel()
        let p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .failure)
        let p2 = makePipeline(name: "p2", activity: .building, lastBuildResult: .failure)
        model.pipelines = [p0, p1, p2]

        XCTAssertEqual(ImageManager().image(forResult: .failure, activity: .building), model.imageForMenuBar)
    }

    func testDoesNotDisplayBuildingTimerWhenSettingIsOff() throws {
        let model = makeModel()
        var p0 = makePipeline(name: "p0", activity: .sleeping, lastBuildResult: .success)
        p0.status.lastBuild!.duration = 90
        p0.status.lastBuild!.timestamp = Date.now
        model.pipelines = [p0]

        XCTAssertEqual("", model.textForMenuBar)
    }

    func testDisplaysShortestTimingForBuildingProjectsWithEstimatedCompleteTime() throws {
        let model = makeModel()
        let p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        var p1 = makePipeline(name: "p1", activity: .building, lastBuildResult: .success)
        p1.status.lastBuild!.duration = 70
        p1.status.currentBuild!.timestamp = Date.now
        var p2 = makePipeline(name: "p2", activity: .building, lastBuildResult: .success)
        p2.status.lastBuild!.duration = 30
        p2.status.currentBuild!.timestamp = Date.now
        model.pipelines = [p0, p1, p2]

        XCTAssertEqual("-29s", model.textForMenuBar)
    }

    func testDisplaysTimingForFixingEvenIfItsLongerThanForBuilding() throws {
        let model = makeModel()
        var p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        p0.status.lastBuild!.duration = 30
        p0.status.currentBuild!.timestamp = Date.now
        var p1 = makePipeline(name: "p1", activity: .building, lastBuildResult: .failure)
        p1.status.lastBuild!.duration = 90
        p1.status.currentBuild!.timestamp = Date.now
        model.pipelines = [p0, p1]

        XCTAssertEqual("-01:29", model.textForMenuBar)
    }

    func testUsesPipelineNameInMenuAsDefault() throws {
        let model = makeModel()
        model.pipelines = [makePipeline(name: "connectfour")]

        let lp = model.pipelinesForMenu[0]
        XCTAssertEqual("connectfour", lp.label)
    }

    func testAppendsBuildLabelToPipelineNameInMenuBasedOnSetting() throws {
        let model = makeModel()
        model.settings.showLabelsInMenu = true
        var pipeline = makePipeline(name: "connectfour")
        pipeline.status.lastBuild = Build(result: .success, label: "build.1")
        model.pipelines = [pipeline]

        let lp = model.pipelinesForMenu[0]
        XCTAssertEqual("connectfour \u{2014} build.1", lp.label)
    }


    private func makeModel() -> ViewModel {
        let m = ViewModel(settings: UserSettings())
        m.settings.useColorInMenuBar = true // otherwise we can't compare the images
        return m
    }

    private func makePipeline(name: String, activity: Pipeline.Activity = .other, lastBuildResult: BuildResult? = nil) -> Pipeline {
        var p = Pipeline(name: name, feedUrl: "")
        p.status.activity = activity
        if activity == .building {
            p.status.currentBuild = Build(result: .unknown)
        }
        if let lastBuildResult = lastBuildResult {
            p.status.lastBuild = Build(result: lastBuildResult)
        }
        return p
    }

}

