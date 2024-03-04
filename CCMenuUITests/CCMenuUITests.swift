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
        webapp.router.get("/cctray.xml") { _ in """
            <Projects>
                <Project activity='Sleeping' lastBuildLabel='build.888' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='connectfour'></Project>
            </Projects>
        """}

        let app = launchApp(pipelines: "CCTrayPipeline", pauseMonitor: false)
        let window = app.windows["Pipelines"]

        // Find the status description field (there's only one because there's only one pipeline), then
        // wait for the update to the build label to show the label return with the embedded server
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: build.888'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 2)

        // Now stop the server and make sure the error shows quickly.
        // TODO: Will this ever not work? Our embedded server might use different caching logic.
        webapp.stop()
        expectation(for: NSPredicate(format: "value CONTAINS 'Could not connect to the server.'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 2)
    }

    func testShowsErrorWhenFeedDoesntContainProject() throws {
        let webapp = try startEmbeddedServer()
        webapp.router.get("/cctray.xml") { _ in """
            <Projects>
                <Project activity='Sleeping' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='other-project'></Project>
            </Projects>
        """}

        let app = launchApp(pipelines: "CCTrayPipeline", pauseMonitor: false)
        let window = app.windows["Pipelines"]

        // Find the status description field (there's only one because there's only one pipeline), then
        // wait for the update to the build label to show the label return with the embedded server
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'The server did not provide a status'"), evaluatedWith: descriptionText)
        // TODO: Ideally we should make sure the row shows the default image now
        waitForExpectations(timeout: 2)
    }

    func testShowsErrorForHTTPError() throws {
        try startEmbeddedServer()

        let app = launchApp(pipelines: "CCTrayPipeline", pauseMonitor: false)
        let window = app.windows["Pipelines"]

        // Find the status description field (there's only one because there's only one pipeline), then
        // wait for the update to the build label to show the label return with the embedded server
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'The server responded: not found'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 2)
    }

    func testAddsPipeline() throws {
        let webapp = try startEmbeddedServer()
        webapp.router.get("/cctray.xml") { _ in """
            <Projects>
                <Project activity='Sleeping' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='other-project'></Project>
                <Project activity='Sleeping' lastBuildLabel='build.888' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='connectfour'></Project>
            </Projects>
        """}

        let app = launchApp(pipelines: "EmptyPipelines", pauseMonitor: false)
        let window = app.windows["Pipelines"]
        let sheet = window.sheets.firstMatch

        // Navigate to add project sheet and enter minimal feed URL
        window.toolbars.popUpButtons["Add pipeline menu"].click()
        window.toolbars.menuItems["Add project from CCTray feed..."].click()
        let urlField = sheet.textFields["Server URL field"]
        urlField.click()
        sheet.typeText("localhost:8086\n")

        // Make sure that the scheme gets added to the URL, the path is discovered, that
        // the picker shows the first project in alphabetical order, and the default display
        // name is set
        let projectPicker = sheet.popUpButtons["Project picker"]
        let displayNameField = sheet.textFields["Display name field"]
        expectation(for: NSPredicate(format: "value == 'http://localhost:8086/cctray.xml'"), evaluatedWith: urlField)
        expectation(for: NSPredicate(format: "value == 'connectfour'"), evaluatedWith: projectPicker)
        expectation(for: NSPredicate(format: "value == 'connectfour'"), evaluatedWith: displayNameField)
        waitForExpectations(timeout: 2)

        // Set a custom display name, and close the sheet
        displayNameField.doubleClick()
        sheet.typeText("C4")
        sheet.buttons["Apply"].click()

        // Make sure the pipeline is shown, and that its status is fetched immediately
        let titleText = window.tables.staticTexts["Pipeline title"]
        expectation(for: NSPredicate(format: "value == 'C4'"), evaluatedWith: titleText)
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: build.888'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 2)
    }

    func testAddsGitHubPipeline() throws {
        let webapp = try startEmbeddedServer()
        webapp.router.get("/users/erikdoe/repos") { _ in
            try self.contentsOfFile("GitHubReposByUserResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu/actions/workflows") { _ in
            "{ \"total_count\": 0, \"workflows\": [] }"
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows") { _ in
            try self.contentsOfFile("GitHubWorkflowsResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs") { _ in
            try self.contentsOfFile("GitHubWorkflowRunsResponse.json")
        }

        let app = launchApp(pipelines: "EmptyPipelines", pauseMonitor: false)
        let window = app.windows["Pipelines"]
        let sheet = window.sheets.firstMatch

        // Navigate to add workflow sheet and enter owner
        window.toolbars.popUpButtons["Add pipeline menu"].click()
        window.toolbars.menuItems["Add GitHub Actions workflow..."].click()
        let ownerField = sheet.textFields["Owner field"]
        ownerField.click()
        sheet.typeText("erikdoe\n")

        // Make sure that the repositories are loaded and sorted
        let repositoryPicker = sheet.popUpButtons["Repository picker"]
        expectation(for: NSPredicate(format: "value == 'ccmenu'"), evaluatedWith: repositoryPicker)
        waitForExpectations(timeout: 2)

        // Open the repositiry picker
        repositoryPicker.click()

        // Make sure that repositories for different owners are not shown
        XCTAssertFalse(repositoryPicker.menuItems["tw2021-screensaver"].exists)

        // Select the ccmenu2 repository
        repositoryPicker.menuItems["ccmenu2"].click()

        // Make sure that the workflows are loaded and the default display name is set
        let workflowPicker = sheet.popUpButtons["Workflow picker"]
        expectation(for: NSPredicate(format: "value == 'Build and test'"), evaluatedWith: workflowPicker)
        let displayNameField = sheet.textFields["Display name field"]
        expectation(for: NSPredicate(format: "value == 'ccmenu2 | Build and test'"), evaluatedWith: displayNameField)
        waitForExpectations(timeout: 2)

        // Set a custom display name, and close the sheet
        displayNameField.click()
        sheet.typeKey("a", modifierFlags: [ .command ])
        sheet.typeKey(.delete, modifierFlags: [])
        sheet.typeText("CCMenu")
        sheet.buttons["Apply"].click()

        // Make sure the pipeline is shown, and that its status is fetched immediately
        let titleText = window.tables.staticTexts["Pipeline title"]
        expectation(for: NSPredicate(format: "value == 'CCMenu'"), evaluatedWith: titleText)
        waitForExpectations(timeout: 2)
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
        let messageText = window.tables.staticTexts["Build message"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Push'"), evaluatedWith: messageText)
        expectation(for: NSPredicate(format: "value CONTAINS 'Improved layout'"), evaluatedWith: messageText)
        waitForExpectations(timeout: 2)
    }

    // basic headers

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

    func _testMenuOpensAboutPanel() throws {
        let app = launchApp()
        let menu = openMenu(app: app)

        // Open about panel
        menu.menuItems["About CCMenu"].click()

        // Make sure version is displayed
        let versionText = app.dialogs.staticTexts.element(matching: NSPredicate(format: "value BEGINSWITH 'Version'"))
        let versionString = versionText.value as! String
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
            "-loadPipelines", pathForResource("\(pipelines).json"),
            "-ignoreDefaults", "true",
            "-pauseMonitor", String(pauseMonitor),
            "-PollInterval", "1",
            "-GitHubBaseURL", "http://localhost:8086"
        ]
        app.launch()
        return app
    }

    @discardableResult
    private func openMenu(app: XCUIApplication) -> XCUIElementQuery {
        // If this drops you into the debugger see https://stackoverflow.com/a/64375512/409663
        let statusItem = app.menuBars.statusItems.element // TODO: workaround because line below doesn't work anymore
        // let statusItem = app.menuBars.statusItems["CCMenuMenuExtra"]
        statusItem.click()
        return statusItem.children(matching: .menu)
    }

    @discardableResult
    private func startEmbeddedServer() throws -> HBApplication {
        let webapp = HBApplication(configuration: .init(address: .hostname("localhost", port: 8086)))
        // If the following fails with "operation not permitted" see: https://developer.apple.com/forums/thread/114907
        webapp.middleware.add(HBLogRequestsMiddleware(.info, includeHeaders: false))
        try webapp.start()
        self.webapp = webapp
        return webapp
    }

    private func pathForResource(_ name: String) -> String {
        let myBundle = Bundle(for: CCMenuUITests.self)
        guard let fileUrl = myBundle.url(forResource: name, withExtension:nil) else {
            fatalError("Couldn't find \(name) in UI test bundle.")
        }
        return fileUrl.path
    }

    private func contentsOfFile(_ name: String) throws -> String {
        try String(contentsOfFile: self.pathForResource(name))
    }

}
