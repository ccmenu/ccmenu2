/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
import SwiftUI
@testable import CCMenu

class MenuExtraModelTests: XCTestCase {

    private func makeModel(pipelines: [Pipeline]) -> MenuExtraViewModel {
        return MenuExtraViewModel(pipelines: pipelines, useColorInMenuBar: true, useColorInMenuBarFailedOnly: false, showBuildTimerInMenuBar: false)
    }

    private func makePipeline(name: String, activity: Pipeline.Activity = .other, lastBuildResult: BuildResult? = nil) -> Pipeline {
        var p = Pipeline(name: name, feed: Pipeline.Feed(type: .cctray, url: URL(string: "http://localhost")!, name: ""))
        p.status.activity = activity
        if activity == .building {
            p.status.currentBuild = Build(result: .unknown)
        }
        if let lastBuildResult {
            p.status.lastBuild = Build(result: lastBuildResult)
        }
        return p
    }
    
    func testDisplaysDefaultImageAndNoTextWhenNoPipelinesAreMonitored() throws {
        let model = makeModel(pipelines: [])

        XCTAssertEqual(NSImage(forPipeline: nil), model.icon)
        XCTAssertEqual("", model.title)
    }

    func testDisplaysDefaultImageAndNoTextWhenNoStatusIsKnown() throws {
        let model = makeModel(pipelines: [makePipeline(name: "connectfour")])

        XCTAssertEqual(NSImage(forPipeline: nil), model.icon)
        XCTAssertEqual("", model.title)
    }

    func testDisplaysSuccessAndNoTextWhenAllProjectsWithStatusAreSleepingAndSuccessful() throws {
        let p0 = makePipeline(name: "connectfour")
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .success)
        let model = makeModel(pipelines: [p0, p1])

        let pe = makePipeline(name: "expected", activity: .sleeping, lastBuildResult: .success)
        XCTAssertEqual(NSImage(forPipeline: pe), model.icon)
        XCTAssertEqual("", model.title)
    }

    func testDisplaysFailureAndNumberOfFailuresWhenAllAreSleepingAndAtLeastOneIsFailed() throws {
        let p0 = makePipeline(name: "p0", activity: .sleeping, lastBuildResult: .success)
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .failure)
        let p2 = makePipeline(name: "p2", activity: .sleeping, lastBuildResult: .failure)
        let model = makeModel(pipelines: [p0, p1, p2])

        let pe = makePipeline(name: "expected", activity: .sleeping, lastBuildResult: .failure)
        XCTAssertEqual(NSImage(forPipeline: pe), model.icon)
        XCTAssertEqual("2", model.title)
    }

    func testDisplaysBuildingWhenAtLeastOneProjectIsBuilding() throws {
        let p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .failure)
        let p2 = makePipeline(name: "p2", activity: .sleeping, lastBuildResult: .failure)
        let model = makeModel(pipelines: [p0, p1, p2])

        let pe = makePipeline(name: "expected", activity: .building, lastBuildResult: .success)
        XCTAssertEqual(NSImage(forPipeline: pe), model.icon)
    }

    func testDisplaysFixingWhenAtLeastOneProjectWithLastStatusFailedIsBuilding() throws {
        let p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        let p1 = makePipeline(name: "p1", activity: .sleeping, lastBuildResult: .failure)
        let p2 = makePipeline(name: "p2", activity: .building, lastBuildResult: .failure)
        let model = makeModel(pipelines: [p0, p1, p2])

        let pe = makePipeline(name: "expected", activity: .building, lastBuildResult: .failure)
        XCTAssertEqual(NSImage(forPipeline: pe), model.icon)
    }


    func testUseTemplateImageWhenUseColorIsOff() throws {
        let p0 = makePipeline(name: "p0", activity: .sleeping, lastBuildResult: .success)
        let model = MenuExtraViewModel(pipelines: [p0], useColorInMenuBar: false, useColorInMenuBarFailedOnly: false, showBuildTimerInMenuBar: false)

        let pe = makePipeline(name: "expected", activity: .sleeping, lastBuildResult: .success)
        XCTAssertEqual(NSImage(forPipeline: pe, asTemplate: true), model.icon)
    }

    func testUseTemplateImageWhenSucessAndUseColorAndUseColorFailedOnly() throws {
        let p0 = makePipeline(name: "p0", activity: .sleeping, lastBuildResult: .success)
        let model = MenuExtraViewModel(pipelines: [p0], useColorInMenuBar: true, useColorInMenuBarFailedOnly: true, showBuildTimerInMenuBar: false)

        let pe = makePipeline(name: "expected", activity: .sleeping, lastBuildResult: .success)
        XCTAssertEqual(NSImage(forPipeline: pe, asTemplate: true), model.icon)
    }

    func testUsesGreenColorWhenBuilding() throws {
        let p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        let model = MenuExtraViewModel(pipelines: [p0], useColorInMenuBar: true, useColorInMenuBarFailedOnly: false, showBuildTimerInMenuBar: false)

        XCTAssertEqual(Color(nsColor: NSColor.statusGreen), model.color)
    }

    func testUsesOrangeColorWhenFixing() throws {
        let p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .failure)
        let model = MenuExtraViewModel(pipelines: [p0], useColorInMenuBar: true, useColorInMenuBarFailedOnly: false, showBuildTimerInMenuBar: false)

        XCTAssertEqual(Color(nsColor: NSColor.statusOrange), model.color)
    }

    func testUsesRedColorWhenBroken() throws {
        let p0 = makePipeline(name: "p0", activity: .sleeping, lastBuildResult: .failure)
        let model = MenuExtraViewModel(pipelines: [p0], useColorInMenuBar: true, useColorInMenuBarFailedOnly: false, showBuildTimerInMenuBar: false)

        XCTAssertEqual(Color(nsColor: NSColor.statusRed), model.color)
    }

    func testUsesNoColorWhenSettingIsOff() throws {
        let p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .failure)
        let model = MenuExtraViewModel(pipelines: [p0], useColorInMenuBar: false, useColorInMenuBarFailedOnly: false, showBuildTimerInMenuBar: false)

        XCTAssertNil(model.color)
    }

    func testDoesNotDisplayBuildingTimerWhenSettingIsOff() throws {
        var p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        p0.status.lastBuild!.duration = 90
        p0.status.currentBuild!.timestamp = Date.now
        let model = MenuExtraViewModel(pipelines: [p0], useColorInMenuBar: false, useColorInMenuBarFailedOnly: false, showBuildTimerInMenuBar: false)

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

        let model = MenuExtraViewModel(pipelines: [p0, p1, p2], useColorInMenuBar: false, useColorInMenuBarFailedOnly: false, showBuildTimerInMenuBar: true)

        XCTAssertEqual("-29s", model.title)
    }

    func testDisplaysTimingForFixingEvenIfItsLongerThanForBuilding() throws {
        var p0 = makePipeline(name: "p0", activity: .building, lastBuildResult: .success)
        p0.status.lastBuild!.duration = 30
        p0.status.currentBuild!.timestamp = Date.now
        var p1 = makePipeline(name: "p1", activity: .building, lastBuildResult: .failure)
        p1.status.lastBuild!.duration = 90
        p1.status.currentBuild!.timestamp = Date.now

        let model = MenuExtraViewModel(pipelines: [p0, p1], useColorInMenuBar: false, useColorInMenuBarFailedOnly: false, showBuildTimerInMenuBar: true)

        XCTAssertEqual("-01:29", model.title)
    }

}


