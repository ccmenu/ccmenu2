/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest

class CCMenuUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
  
    private func pathForBundleFile(_ name: String) -> String {
        let myBundle = Bundle(for: NSClassFromString(CCMenuUITests.className())!) // TODO: really?!
        guard let fileUrl = myBundle.url(forResource: name, withExtension:nil) else {
            fatalError("Couldn't find \(name) in UI test bundle.")
        }
        return fileUrl.path
    }
    
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-loadTestData", pathForBundleFile("TestData.json")]
        app.launch()
        // It seems necessary to click on the status item to make the menu available, and I haven't found a better way
        // to find the status item.
        app.children(matching: .menuBar).element(boundBy: 1).children(matching: .statusItem).element(boundBy: 0).click()
        return app
    }

    func testStatusItemMenuOpenPipeline() throws {
        let app = launchApp()

        // Sanity check for status item menu
        XCTAssert(app.menus["StatusItemMenu"].menuItems["OpenPipeline:connectfour"].exists)
        XCTAssert(app.menus["StatusItemMenu"].menuItems["OpenPipeline:erikdoe/ccmenu"].exists)
        XCTAssertEqual(10, app.menus["StatusItemMenu"].menuItems.count)

        // Make sure broken URLs are not opened
        app.menus["StatusItemMenu"].menuItems["OpenPipeline:erikdoe/ccmenu"].click()
        XCTAssert(app.dialogs["alert"].staticTexts["Cannot open pipeline"].exists)
        app.dialogs["alert"].buttons["Cancel"].click()
    }

    func testStatusItemMenuOpenAboutPanel() throws {
        let app = launchApp()

        app.menus["StatusItemMenu"].menuItems["About CCMenu"].click()
        let versionText = app.dialogs.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'Version'"))
        guard let versionString = versionText.value as? String else {
            XCTFail()
            return
        }
        let range = versionString.range(of: "^Version [0-9]+ \\([A-Z0-9]+\\)$", options: .regularExpression)
        XCTAssertNotNil(range)
    }
    
    
    func testPipelineWindowToolbar() throws {
        let app = launchApp()

        // If this drops you into the debugger see https://stackoverflow.com/a/64375512/409663
        app.menus["StatusItemMenu"].menuItems["orderFrontPipelineWindow:"].click()
        let window = app.windows["Pipelines"]
        let toolbars = window.toolbars
        
        XCTAssertTrue(toolbars.buttons["Add pipeline"].isEnabled)
        XCTAssertFalse(toolbars.buttons["Remove pipeline"].isEnabled)
        XCTAssertFalse(toolbars.buttons["Edit pipeline"].isEnabled)

        window.tables.staticTexts["connectfour"].click()
        XCTAssertTrue(toolbars.buttons["Add pipeline"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Remove pipeline"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Edit pipeline"].isEnabled)

        XCUIElement.perform(withKeyModifiers: XCUIElement.KeyModifierFlags.shift) {
            window.tables.staticTexts["erikdoe/ccmenu"].click()
        }
        XCTAssertTrue(toolbars.buttons["Add pipeline"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Remove pipeline"].isEnabled)
        XCTAssertFalse(toolbars.buttons["Edit pipeline"].isEnabled)
        
        toolbars.popUpButtons.firstMatch.click() // TODO: not ideal...
        toolbars.menuItems["Pipeline"].click()
        XCTAssertTrue(window.tables.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'https:'")).exists)

        toolbars.popUpButtons.firstMatch.click()
        toolbars.menuItems["Build Status"].click()
        XCTAssertTrue(window.tables.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'Started:'")).exists)

        XCTAssertFalse(window.tables.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'Testing'")).exists)
        toolbars.popUpButtons.firstMatch.click()
        toolbars.menuItems["Status Comment"].click()
        XCTAssertTrue(window.tables.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'Testing'")).exists)

    }
    
    // onMove and onDelete are still untested
    
    func testRemovesPipeline() throws {
        let app = launchApp()

        app.menus["StatusItemMenu"].menuItems["orderFrontPipelineWindow:"].click()
        let window = app.windows["Pipelines"]
        window.tables.staticTexts["connectfour"].click()
        window.toolbars.buttons["Remove pipeline"].click()

        XCTAssertFalse(window.tables.staticTexts["connectfour"].exists)
    }

    func __testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
