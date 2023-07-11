/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class ViewModelTests: XCTestCase {

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

