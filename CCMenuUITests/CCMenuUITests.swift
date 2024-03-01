/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
import Hummingbird

class CCMenuUITests: XCTestCase {
    
    var webapp: HBApplication?


    // - MARK: Pipeline window, simple cases with static data only

    func testPipelineWindowToolbar() throws {
        let app = launchApp()
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
        let app = launchApp()
        let window = app.windows["Pipelines"]

        window.tables.staticTexts["connectfour"].click()
        window.toolbars.buttons["Remove pipeline"].click()

        XCTAssertTrue(window.tables.staticTexts["connectfour"].exists == false)
    }


    // - MARK: Pipeline window, loading from embedded server

    func testShowsPipelineStatusFetchedFromServer() throws {
        let webapp = try startEmbeddedServer()
        webapp.router.get("/cctray.xml") { _ in
            """
            <Projects>
                <Project activity='Sleeping' lastBuildLabel='build.888' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='connectfour' webUrl='http://localhost:8086/dashboard/build/detail/connectfour'></Project>
            </Projects>
            """
        }

        let app = launchApp(pipelines: "CCTrayPipeline", pauseMonitor: false)
        let window = app.windows["Pipelines"]

        // First find the status description field (there's only one because there's only one pipeline)
        let descriptionText = window.tables.staticTexts["Status description"]
        // Then wait for the update to the build label we return with the embedded server
        let exp = self.expectation(for: NSPredicate(format: "value CONTAINS 'Label: build.888'"), evaluatedWith: descriptionText)
        wait(for: [exp], timeout: 2)
    }

    func testAddsPipeline() throws {
        let webapp = try startEmbeddedServer()
        webapp.router.get("/cctray.xml") { _ in
            """
            <Projects>
                <Project activity='Sleeping' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='other-project'></Project>
                <Project activity='Sleeping' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='connectfour'></Project>
            </Projects>
            """
        }

        let app = launchApp(pipelines: "EmptyPipelines", pauseMonitor: false)
        let window = app.windows["Pipelines"]
        let toolbars = window.toolbars

        toolbars.popUpButtons["Add pipeline menu"].click()
        toolbars.menuItems["Add project from CCTray feed..."].click()

        let sheet = window.sheets.firstMatch
        let urlField = sheet.textFields["Server URL text field"]
        urlField.click()
        sheet.typeText("localhost:8086\n")

        expectation(for: NSPredicate(format: "value == 'http://localhost:8086/cctray.xml'"), evaluatedWith: urlField)
        waitForExpectations(timeout: 2)
    }

    // basic headers

    // server stops responding

    // server doesn't send status for project

    // github mixed case owner

    // github rate limit handling


    // - MARK: Menu

    func testMenuOpensPipeline() throws {
        let app = launchApp()
        let menu = openMenu(app: app)

        // Make sure broken URLs result in an alert to be shown
        menu.menuItems["connectfour"].click()
        XCTAssert(app.dialogs["alert"].staticTexts["Can't open web page"].exists)
        app.dialogs["alert"].buttons["Cancel"].click()
    }

    func testMenuOpensAboutPanel() throws {
        let app = launchApp()
        let menu = openMenu(app: app)

        // Open about panel
        menu.menuItems["About CCMenu"].click()

        // Make sure version is displayed
        let versionText = app.dialogs.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'Version'"))
        guard let versionString = versionText.value as? String else {
            XCTFail()
            return
        }
        // TODO: Sometimes version check fails because the script that inserts it isn't run. Why?
        let range = versionString.range(of: "^Version [0-9]+.[0-9]+ \\([A-Z0-9]+\\)$", options: .regularExpression)
        XCTAssertNotNil(range)
    }


    // - MARK: Settings

    func testAppearanceSettings() throws {
        let app = launchApp()
        let menu = openMenu(app: app)

        // Make sure expected pipeline is present
        XCTAssert(menu.menuItems["connectfour"].exists)

        // Open settings, chose to display build labels, then close settings
        menu.menuItems["Settings..."].click()
        let window = app.windows["com_apple_SwiftUI_Settings_window"]
        window.toolbars.buttons["Appearance"].click()
        XCTAssert(window.checkBoxes["Show label of last build"].isSelected == false)
        window.checkBoxes["Show label of last build"].click()
        XCTAssert(window.checkBoxes["Show time of last build"].isSelected == false)
        window.checkBoxes["Show time of last build"].click()
        window.buttons[XCUIIdentifierCloseWindow].click()

        // Make sure the pipeline menu item now displays the build label and relative time
        let buildTime = ISO8601DateFormatter().date(from: "2020-12-27T21:47:00Z")!
        let buildTimeRelative = buildTime.formatted(Date.RelativeFormatStyle(presentation: .named))
        openMenu(app: app)
        XCTAssert(menu.menuItems["connectfour \u{2014} \(buildTimeRelative), build.151"].exists)
    }


    // - MARK: setup and teardown

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        webapp?.stop()
    }


    // - MARK: helper methods

    private func launchApp(pipelines: String = "DefaultPipelines", pauseMonitor: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-loadPipelines", pathForBundleFile("\(pipelines).json"),
            "-ignoreDefaults", "true",
            "-pauseMonitor", String(pauseMonitor),
            "-PollInterval", "10",
            "-GitHubBaseURL", ""
        ]
        app.launch()
        return app
    }

    private func pathForBundleFile(_ name: String) -> String {
        let myBundle = Bundle(for: CCMenuUITests.self)
        guard let fileUrl = myBundle.url(forResource: name, withExtension:nil) else {
            fatalError("Couldn't find \(name) in UI test bundle.")
        }
        return fileUrl.path
    }

    @discardableResult
    private func openMenu(app: XCUIApplication) -> XCUIElementQuery {
        // If this drops you into the debugger see https://stackoverflow.com/a/64375512/409663
        let statusItem = app.menuBars.statusItems.element // TODO: workaround because line below doesn't work anymore
        // let statusItem = app.menuBars.statusItems["CCMenuMenuExtra"]
        statusItem.click()
        return statusItem.children(matching: .menu)
    }

    private func startEmbeddedServer() throws -> HBApplication {
        let webapp = HBApplication(configuration: .init(address: .hostname("localhost", port: 8086)))
        // If the following fails with "operation not permitted" see: https://developer.apple.com/forums/thread/114907
        webapp.middleware.add(HBLogRequestsMiddleware(.info, includeHeaders: false))
        try webapp.start()
        self.webapp = webapp
        return webapp
    }

}
