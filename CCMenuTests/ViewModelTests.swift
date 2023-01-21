/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class ViewModelTests: XCTestCase {

    func testShowsNoTextInMenuBarByDefault() throws {
        let model = makeModelWithPipeline()
        let t = model.textForMenuBar
        XCTAssertEqual("", t)
    }

    func testUsesPipelineNameInMenuAsDefault() throws {
        let model = makeModelWithPipeline()
        let lp = model.pipelinesForMenu[0]
        XCTAssertEqual("connectfour", lp.label)
    }

    func testAppendsBuildLabelToPipelineNameInMenuBasedOnSetting() throws {
        let model = makeModelWithPipeline()
        model.settings.showLabelsInMenu = true
        var pipeline = Pipeline(name: "connectfour", feedUrl: "")
        pipeline.lastBuild = Build(result: .success, label: "build.1")
        model.update(pipeline: pipeline)

        let lp = model.pipelinesForMenu[0]
        XCTAssertEqual("connectfour \u{2014} build.1", lp.label)
    }

    private func makeModelWithPipeline() -> ViewModel {
        let settings = UserSettings()
        let model = ViewModel(settings: settings)
        let pipeline = Pipeline(name: "connectfour", feedUrl: "")
        model.pipelines.append(pipeline)
        model.update(pipeline: pipeline)
        return model
    }

}

