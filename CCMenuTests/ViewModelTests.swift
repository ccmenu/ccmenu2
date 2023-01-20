/*
 *  Copyright (c) ThoughtWorks Inc.
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

    private func makeModelWithPipeline() -> ViewModel {
        let settings = UserSettings()
        let model = ViewModel(settings: settings)
        let pipeline = Pipeline(name: "connectfour", feedUrl: "")
        model.pipelines.append(pipeline)
        model.update(pipeline: pipeline)
        return model
    }

}

