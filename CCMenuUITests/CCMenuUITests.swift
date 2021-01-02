/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
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
    
    private func clickStatusItem(app: XCUIApplication) {
        // It seems necessary to click on the status item to make the menu available,
        // and I haven't found a better way to find the status item.
        app.children(matching: .menuBar).element(boundBy: 1).children(matching: .statusItem).element(boundBy: 0).click()
    }

    func testStatusItemMenuOpenPipeline() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-loadTestData", pathForBundleFile("TestData.json")]
        app.launch()
        clickStatusItem(app: app)

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
        let app = XCUIApplication()
        app.launch()
        clickStatusItem(app: app)

        app.menus["StatusItemMenu"].menuItems["About CCMenu"].click()
        let versionText = app.dialogs.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'Version'"))
        guard let versionString = versionText.value as? String else {
            XCTFail()
            return
        }
        // Why is a simple regex match so painful in Swift?
        let regex = try NSRegularExpression(pattern: "^Version [0-9]+ \\([A-Z0-9]+\\)$", options: NSRegularExpression.Options())
        let n = regex.numberOfMatches(in: versionString, options: NSRegularExpression.MatchingOptions(), range: NSMakeRange(0, versionString.count))
        
        XCTAssertEqual(1, n)
        XCUIApplication().children(matching: .menuBar).element(boundBy: 1).children(matching: .statusItem).element(boundBy: 0).click()
        
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
