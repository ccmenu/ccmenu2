/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest

class PipelineWindowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPipelineWindowToolbar() throws {
        let app = TestHelper.launchApp()
        let window = app.windows["Pipelines"]
        let toolbars = window.toolbars

        // Pipeline action buttons when no pipeline is selected
        XCTAssertTrue(toolbars.popUpButtons["Add pipeline menu"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Remove pipeline"].isEnabled == false)
        XCTAssertTrue(toolbars.buttons["Edit pipeline"].isEnabled == false)

        // Pipeline action buttons when one pipeline is selected
        window.tables.staticTexts["connectfour"].click()
        XCTAssertTrue(toolbars.popUpButtons["Add pipeline menu"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Remove pipeline"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Edit pipeline"].isEnabled)

        // Pipeline action buttons when two pipelines are selected
        XCUIElement.perform(withKeyModifiers: XCUIElement.KeyModifierFlags.shift) {
            window.tables.staticTexts["ccmenu2 | Build and test"].click()
        }
        XCTAssertTrue(toolbars.popUpButtons["Add pipeline menu"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Remove pipeline"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Edit pipeline"].isEnabled == false)

        // Default state of display menu, which shows pipeline status
        toolbars.popUpButtons["Display detail menu"].click()
        XCTAssertTrue(toolbars.menuItems["Hide Messages"].isEnabled == true)
        XCTAssertTrue(toolbars.menuItems["Hide Avatars"].isEnabled == true)
        toolbars.menuItems["Build Status"].click()
        XCTAssertTrue(window.tables.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'Started:'")).exists)
        XCTAssertTrue(window.tables.staticTexts.element(matching: NSPredicate(format: "value CONTAINS 'Testing'")).exists)

        // Selecting hide message hides the messages and changes the menu text
        toolbars.popUpButtons["Display detail menu"].click()
        toolbars.menuItems["Hide Messages"].click()
        XCTAssertTrue(window.tables.staticTexts.element(matching: NSPredicate(format: "value CONTAINS 'Testing'")).exists == false)
        toolbars.popUpButtons["Display detail menu"].click()
        XCTAssertTrue(toolbars.menuItems["Show Messages"].exists)

        // Switching display menu to URL shows URL
        toolbars.menuItems["Pipeline URL"].click()
        XCTAssertTrue(window.tables.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'https:'")).exists)
        toolbars.popUpButtons["Display detail menu"].click()
        XCTAssertTrue(toolbars.menuItems["Show Messages"].isEnabled == false)
        XCTAssertTrue(toolbars.menuItems["Hide Avatars"].isEnabled == false)
    }

    func testRemovesPipeline() throws {
        let app = TestHelper.launchApp()
        let window = app.windows["Pipelines"]

        window.tables.staticTexts["connectfour"].click()
        window.toolbars.buttons["Remove pipeline"].click()

        XCTAssertTrue(window.tables.staticTexts["connectfour"].exists == false)
    }

}
