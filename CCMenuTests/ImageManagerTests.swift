/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class ImageManagerTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testReturnsCorrectImageForSuccess() throws {
        let image = ImageManager().image(forResult: .success, activity: .sleeping)
        XCTAssertEqual("build-success", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectImageForFailure() throws {
        let image = ImageManager().image(forResult: .failure, activity: .sleeping)
        XCTAssertEqual("build-failure", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectImageForSuccessBuilding() throws {
        let image = ImageManager().image(forResult: .success, activity: .building)
        XCTAssertEqual("build-success+building", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectImageForFailureBuilding() throws {
        let image = ImageManager().image(forResult: .failure, activity: .building)
        XCTAssertEqual("build-failure+building", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectImageForSuccessOtherActivity() throws {
        let image = ImageManager().image(forResult: .success, activity: .other)
        XCTAssertEqual("build-success", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectImageForFailureOtherActivity() throws {
        let image = ImageManager().image(forResult: .failure, activity: .other)
        XCTAssertEqual("build-failure", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectImageForUnknownResult() throws {
        // Jenkins uses "unknown" for builds that are inactive
        let image = ImageManager().image(forResult: .unknown, activity: .sleeping)
        XCTAssertEqual("build-paused", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectImageForUnknownResultBuilding() throws {
        let image = ImageManager().image(forResult: .unknown, activity: .building)
        XCTAssertEqual("build-success+building", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectImageForUnknownResultOtherActivity() throws {
        // Jenkins uses "unknown" for builds that are inactive
        // TODO: double-chekc what to do with activity .other
        let image = ImageManager().image(forResult: .unknown, activity: .other)
        XCTAssertEqual("build-paused", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectImageForOtherResult() throws {
        let image = ImageManager().image(forResult: .other, activity: .sleeping)
        XCTAssertEqual("build-unknown", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectImageForOtherResultBuilding() throws {
        let image = ImageManager().image(forResult: .other, activity: .building)
        XCTAssertEqual("build-success+building", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectImageForOtherResulOtherActivity() throws {
        let image = ImageManager().image(forResult: .other, activity: .other)
        XCTAssertEqual("build-unknown", image.name())
        XCTAssertFalse(image.isTemplate)
    }

    func testReturnsCorrectTemplateImageForSuccess() throws {
        let image = ImageManager().image(forResult: .success, activity: .sleeping, asTemplate: true)
        XCTAssertEqual("build-success-template", image.name())
        XCTAssertTrue(image.isTemplate)
    }

    func testReturnsCorrectTemplateImageForSuccessBuilding() throws {
        let image = ImageManager().image(forResult: .success, activity: .building, asTemplate: true)
        XCTAssertEqual("build-success+building-template", image.name())
        XCTAssertTrue(image.isTemplate)
    }


}
