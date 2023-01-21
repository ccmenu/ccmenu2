/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class ViewModelTests: XCTestCase {

    func testDisplaysNoTextAndDefaultImageWhenNoPipelinesAreMonitored() throws {
        let model = makeModel()

        XCTAssertEqual("", model.textForMenuBar)
        XCTAssertEqual(ImageManager().defaultImage, model.imageForMenuBar)
    }

    func testDisplaysNoTextAndDefaultImageWhenNoStatusIsKnown() throws {
        let model = makeModel()
        model.pipelines = [makePipeline(name: "connectfour")]

        XCTAssertEqual("", model.textForMenuBar)
    }

    func testDisplaysSuccessAndNoTextWhenAllProjectsWithStatusAreSleepingAndSuccessful() throws {
        let model = makeModel()
        let p0 = makePipeline(name: "connectfour")
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .success)
        model.pipelines = [p0, p1]

        XCTAssertEqual("", model.textForMenuBar)
        XCTAssertEqual(ImageManager().image(forResult: .success, activity: .sleeping), model.imageForMenuBar)
    }

    func testDisplaysFailureAndNumberOfFailuresWhenAllAreSleepingAndAtLeastOneIsFailed() throws {
        let model = makeModel()
        let p0 = makePipeline(name: "p0", activity: .sleeping, lastBuildResult: .success)
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .failure)
        let p2 = makePipeline(name: "p2", activity: .sleeping, lastBuildResult: .failure)
        model.pipelines = [p0, p1, p2]

//        XCTAssertEqual("2", model.textForMenuBar)
        XCTAssertEqual(ImageManager().image(forResult: .failure, activity: .sleeping), model.imageForMenuBar)

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
        pipeline.lastBuild = Build(result: .success, label: "build.1")
        model.pipelines = [pipeline]

        let lp = model.pipelinesForMenu[0]
        XCTAssertEqual("connectfour \u{2014} build.1", lp.label)
    }


    private func makeModel() -> ViewModel {
        var m = ViewModel(settings: UserSettings())
        m.settings.useColorInMenuBar = true // otherwise we can't compare the images
        return m
    }

    private func makePipeline(name: String, activity: PipelineActivity = .other, lastBuildResult: BuildResult? = nil) -> Pipeline {
        var p = Pipeline(name: name, feedUrl: "")
        p.activity = activity
        if let lastBuildResult = lastBuildResult {
            p.lastBuild = Build(result: lastBuildResult)
        }
        return p
    }

}

