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
        app.launchArguments = ["-loadPipelines", pathForBundleFile("TestData.json"), "-ignoreDefaults", "1"]
        app.launch()
        return app
    }

    private func openMenu(app: XCUIApplication) -> XCUIElementQuery {
        // If this drops you into the debugger see https://stackoverflow.com/a/64375512/409663
        app.menuBars.statusItems["CCMenuStatusItem"].click()
        return app.menuBars.menus.containing(.menuItem, identifier:"connectfour") // TODO: improve
    }

    func testStatusItemMenuOpenPipeline() throws {
        let app = launchApp()
        let menu = openMenu(app: app)

        // Sanity check for status item menu
        XCTAssert(menu.menuItems["connectfour"].exists)
        XCTAssert(menu.menuItems["erikdoe/ccmenu"].exists)
        XCTAssertEqual(10, menu.menuItems.count)

        // Make sure broken URLs are not opened
        menu.menuItems["erikdoe/ccmenu"].click()
        XCTAssert(app.dialogs["alert"].staticTexts["Cannot open pipeline"].exists)
        app.dialogs["alert"].buttons["Cancel"].click()
    }

    func testStatusItemMenuOpenAboutPanel() throws {
        let app = launchApp()
        let menu = openMenu(app: app)

        menu.menuItems["About CCMenu"].click()

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
        let menu = openMenu(app: app)

        menu.menuItems["Show Pipeline Window"].click()

        let window = app.windows["Pipelines"]
        let toolbars = window.toolbars
        
        XCTAssertTrue(toolbars.buttons["Add pipeline"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Remove pipeline"].isEnabled == false)
        XCTAssertTrue(toolbars.buttons["Edit pipeline"].isEnabled == false)

        window.tables.staticTexts["connectfour"].click()
        XCTAssertTrue(toolbars.buttons["Add pipeline"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Remove pipeline"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Edit pipeline"].isEnabled)

        XCUIElement.perform(withKeyModifiers: XCUIElement.KeyModifierFlags.shift) {
            window.tables.staticTexts["erikdoe/ccmenu"].click()
        }
        XCTAssertTrue(toolbars.buttons["Add pipeline"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Remove pipeline"].isEnabled)
        XCTAssertTrue(toolbars.buttons["Edit pipeline"].isEnabled == false)
        
        toolbars.popUpButtons.firstMatch.click() // TODO: not ideal...
        toolbars.menuItems["Pipeline URL"].click()
        XCTAssertTrue(window.tables.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'https:'")).exists)

        toolbars.popUpButtons.firstMatch.click()
        XCTAssertTrue(toolbars.menuItems["Hide Messages"].isEnabled == false)
        XCTAssertTrue(toolbars.menuItems["Hide Avatars"].isEnabled == false)
        toolbars.menuItems["Build Status"].click()
        XCTAssertTrue(window.tables.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'Started:'")).exists)

        XCTAssertTrue(window.tables.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'Testing'")).exists)
        toolbars.popUpButtons.firstMatch.click()
        XCTAssertTrue(toolbars.menuItems["Hide Messages"].isEnabled)
        XCTAssertTrue(toolbars.menuItems["Hide Avatars"].isEnabled)
        toolbars.menuItems["Hide Messages"].click()
        XCTAssertTrue(window.tables.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'Testing'")).exists == false)

    }
    
    // onMove and onDelete are still untested
    
    func testRemovesPipeline() throws {
        let app = launchApp()
        let menu = openMenu(app: app)

        menu.menuItems["Show Pipeline Window"].click()

        let window = app.windows["Pipelines"]
        window.tables.staticTexts["connectfour"].click()
        window.toolbars.buttons["Remove pipeline"].click()

        XCTAssertTrue(window.tables.staticTexts["connectfour"].exists == false)
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
