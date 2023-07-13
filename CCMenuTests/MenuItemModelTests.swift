/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

final class MenuItemModelTests: XCTestCase {

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

    func testUsesPipelineNameInMenuAsDefault() throws {
        let pipeline = makePipeline(name: "connectfour")
        let pvm = MenuItemModel(pipeline: pipeline, settings: UserSettings())
        XCTAssertEqual("connectfour", pvm.title)
    }

    func testAppendsBuildLabelToPipelineNameInMenuBasedOnSetting() throws {
        var pipeline = makePipeline(name: "connectfour")
        pipeline.status.lastBuild = Build(result: .success, label: "build.1")
        var settings = UserSettings()
        settings.showLabelsInMenu = true
        let pvm = MenuItemModel(pipeline: pipeline, settings: settings)

        XCTAssertEqual("connectfour \u{2014} build.1", pvm.title)
    }


}
