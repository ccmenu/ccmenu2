/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
import Hummingbird
import HummingbirdAuth

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


    // - MARK: Pipeline window, CCTray

    func testShowsPipelineStatusFetchedFromServer() throws {
        let webapp = try startEmbeddedServer()
        webapp.router.get("/cctray.xml") { _ in """
            <Projects>
                <Project activity='Sleeping' lastBuildLabel='build.888' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='connectfour'></Project>
            </Projects>
        """}

        let app = launchApp(pipelines: "CCTrayPipeline.json", pauseMonitor: false)
        let window = app.windows["Pipelines"]

        // Find the status description field (there's only one because there's only one pipeline), then
        // wait for the update to the build label to show the label return with the embedded server
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: build.888'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)

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

        let app = launchApp(pipelines: "CCTrayPipeline.json", pauseMonitor: false)
        let window = app.windows["Pipelines"]

        // Find the status description field (there's only one because there's only one pipeline), then
        // wait for the update to the build label to show the label return with the embedded server
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'The server did not provide a status'"), evaluatedWith: descriptionText)
        // TODO: Ideally we should make sure the row shows the default image now
        waitForExpectations(timeout: 5)
    }

    func testShowsErrorForHTTPError() throws {
        try startEmbeddedServer()

        let app = launchApp(pipelines: "CCTrayPipeline.json", pauseMonitor: false)
        let window = app.windows["Pipelines"]

        // Find the status description field (there's only one because there's only one pipeline), then
        // wait for the error meesage from the embedded server
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'The server responded: not found'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)
    }

    func testAddsPipeline() throws {
        let webapp = try startEmbeddedServer()
        webapp.router.get("/cctray.xml") { _ in """
            <Projects>
                <Project activity='Sleeping' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='other-project'></Project>
                <Project activity='Sleeping' lastBuildLabel='build.888' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='connectfour'></Project>
            </Projects>
        """}

        let app = launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
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


    func testAddsPipelineWithAuthentication() throws {
        let webapp = try startEmbeddedServer()
        webapp.router.get("/cctray.xml") { request in
            guard request.authBasic?.username == "dev" && request.authBasic?.password == "rosebud" else {
                throw HBHTTPError(.unauthorized)
            }
            return """
            <Projects>
                <Project activity='Sleeping' lastBuildLabel='build.888' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='connectfour'></Project>
            </Projects>
        """}

        let app = launchApp(pipelines: "EmptyPipelines.json")
        let window = app.windows["Pipelines"]
        let sheet = window.sheets.firstMatch

        // Navigate to add project sheet and enter login data and full feed URL
        window.toolbars.popUpButtons["Add pipeline menu"].click()
        window.toolbars.menuItems["Add project from CCTray feed..."].click()
        sheet.checkBoxes["Basic auth toggle"].click()
        sheet.textFields["User field"].click()
        sheet.typeText("dev")
        sheet.secureTextFields["Password field"].click()
        sheet.typeText("rosebud")
        sheet.textFields["Server URL field"].click()
        sheet.typeText("http://localhost:8086/cctray.xml\n")

        // Make sure that the picker shows the first project in alphabetical order
        let projectPicker = sheet.popUpButtons["Project picker"]
        expectation(for: NSPredicate(format: "value == 'connectfour'"), evaluatedWith: projectPicker)
        waitForExpectations(timeout: 2)
    }

    func testShowsErrorWhenAddingPipelineWithAuthenticationButMissingLogin() throws {
        let webapp = try startEmbeddedServer()
        webapp.router.get("/cctray.xml") { request in
            guard request.authBasic?.username == "dev" && request.authBasic?.password == "rosebud" else {
                throw HBHTTPError(.unauthorized)
            }
            return ""
        }

        let app = launchApp(pipelines: "EmptyPipelines.json")
        let window = app.windows["Pipelines"]
        let sheet = window.sheets.firstMatch

        // Navigate to add project sheet and enter full feed URL
        window.toolbars.popUpButtons["Add pipeline menu"].click()
        window.toolbars.menuItems["Add project from CCTray feed..."].click()
        sheet.textFields["Server URL field"].click()
        sheet.typeText("http://localhost:8086/cctray.xml\n")

        // Make sure that the picker shows an error message containing the word "unauthorized".
        let projectPicker = sheet.popUpButtons["Project picker"]
        expectation(for: NSPredicate(format: "value CONTAINS 'unauthorized'"), evaluatedWith: projectPicker)
        waitForExpectations(timeout: 2)
    }


    // - MARK: Pipeline window, GitHub

    func testShowsWorkflowStatusFetchedFromServer() throws {
        let webapp = try startEmbeddedServer()
        var headers: HTTPHeaders = HTTPHeaders()
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs") { r in
            headers = r.headers
            return try self.contentsOfFile("GitHubWorkflowRunsResponse.json")
        }

        let app = launchApp(pipelines: "GitHubPipelineLocalhost.json", pauseMonitor: false, token: "TEST-TOKEN")
        let window = app.windows["Pipelines"]

        // Find the status description field (there's only one because there's only one pipeline), 
        // then wait for the update to show relevant information from the response. Make sure the
        // request headers are set.
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)
        let messageText = window.tables.staticTexts["Build message"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Push'"), evaluatedWith: messageText)
        expectation(for: NSPredicate(format: "value CONTAINS 'Improved layout'"), evaluatedWith: messageText)
        waitForExpectations(timeout: 2)
        XCTAssertEqual("application/vnd.github+json", headers["Accept"].first)
        XCTAssertEqual("Bearer TEST-TOKEN", headers["Authorization"].first)
    }

    func testShowsMessageAndPausesPollingWhileRateLimitWasExceeded() throws {
        let webapp = try startEmbeddedServer()
        let limitResetTime = Date().addingTimeInterval(10)
        var didReceiveRequest = false
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs", options: .editResponse) { r -> String in
            didReceiveRequest = true
            guard Date() >= limitResetTime else {
                r.response.status = .forbidden
                r.response.headers.replaceOrAdd(name: "x-ratelimit-remaining", value: "0")
                r.response.headers.replaceOrAdd(name: "x-ratelimit-reset", value: String(Int(limitResetTime.timeIntervalSince1970)))
                return "{ \"message\": \"API rate limit exceeded for ...\" } "
            }
            return try self.contentsOfFile("GitHubWorkflowRunsResponse.json")
        }

        let app = launchApp(pipelines: "GitHubPipelineLocalhost.json", pauseMonitor: false)
        let window = app.windows["Pipelines"]

        // Make sure the status shows that the limit was exceeded
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Rate limit exceeded.'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)

        // Make sure there are no requests until the reset time is reached
        didReceiveRequest = false
        Thread.sleep(until: limitResetTime)
        XCTAssertFalse(didReceiveRequest)
        
        // Make sure that polling resumes and updates the status
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
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

        let app = launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
        let window = app.windows["Pipelines"]
        let sheet = window.sheets.firstMatch

        // Navigate to add workflow sheet
        window.toolbars.popUpButtons["Add pipeline menu"].click()
        window.toolbars.menuItems["Add GitHub Actions workflow..."].click()

        // Enter owner
        let ownerField = sheet.textFields["Owner field"]
        ownerField.click()
        sheet.typeText("erikdoe\n")

        // Make sure that the repositories are loaded and sorted
        let repositoryPicker = sheet.popUpButtons["Repository picker"]
        expectation(for: NSPredicate(format: "value == 'ccmenu'"), evaluatedWith: repositoryPicker)
        waitForExpectations(timeout: 2)

        // Open the repository picker and select the ccmenu2 repository
        repositoryPicker.click()
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
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 2)
    }

    func testAddGitHubPipelinePrivateRepos() throws {
        let webapp = try startEmbeddedServer()
        webapp.router.get("/users/erikdoe/repos") { _ in
            try self.contentsOfFile("GitHubReposByUserResponse.json")
        }
        webapp.router.get("/user/repos") { _ in
            return try self.contentsOfFile("GitHubUserReposResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu/actions/workflows") { _ in
            "{ \"total_count\": 0, \"workflows\": [] }"
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows") { _ in
            try self.contentsOfFile("GitHubWorkflowsResponse.json")
        }

        let app = launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false, token: "TEST-TOKEN")
        let window = app.windows["Pipelines"]
        let sheet = window.sheets.firstMatch

        // Navigate to add workflow sheet
        window.toolbars.popUpButtons["Add pipeline menu"].click()
        window.toolbars.menuItems["Add GitHub Actions workflow..."].click()

        // Make sure the token is shown
        let tokenField = sheet.textFields["Token field"]
        XCTAssertEqual("TEST-TOKEN", tokenField.value as? String)

        // Enter owner and wait for the repo list to load
        let ownerField = sheet.textFields["Owner field"]
        ownerField.click()
        sheet.typeText("erikdoe\n")

        // Make sure that the repositories are loaded and sorted
        let repositoryPicker = sheet.popUpButtons["Repository picker"]
        expectation(for: NSPredicate(format: "value == 'ccmenu'"), evaluatedWith: repositoryPicker)
        waitForExpectations(timeout: 2)

        // Open the repository picker
        repositoryPicker.click()

        // Make sure that repositories for different owners are not shown, and that a private
        // repository is shown, and that its shown even when its owner's name uses camel case
        XCTAssertFalse(repositoryPicker.menuItems["tw2021-screensaver"].exists)
        XCTAssertFalse(repositoryPicker.menuItems["iEnterpriseArchitect"].exists)
        XCTAssertTrue(repositoryPicker.menuItems["jekyll-site-test"].exists) // TODO: Split tests and only use token in a test that doesn't click Apply
    }

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
        let app = launchApp(pipelines: "ThreePipelines.json")
        let menu = openMenu(app: app)

        // Make sure expected pipelines are present
        XCTAssert(menu.menuItems["connectfour"].exists)
        XCTAssert(menu.menuItems["ccmenu"].exists)
        XCTAssert(menu.menuItems["ccmenu2 | Build and test"].exists)

        // Open settings, chose to hide pipelines with successful build, then close settings
        menu.menuItems["Settings..."].click()
        let window = app.windows["com_apple_SwiftUI_Settings_window"]
        window.toolbars.buttons["Appearance"].click()
        XCTAssert(window.checkBoxes["Hide pipelines with successful build"].isSelected == false)
        window.checkBoxes["Hide pipelines with successful build"].click()

        // Make sure the successful pipeline isn't show, and a hint is shown
        openMenu(app: app)
        XCTAssert(menu.menuItems["connectfour"].exists)
        XCTAssert(menu.menuItems["ccmenu2 | Build and test"].exists)
        XCTAssert(menu.menuItems["ccmenu"].exists == false)
        let hintItem = menu.menuItems["(1 pipeline hidden)"]
        XCTAssert(hintItem.exists)
        XCTAssert(hintItem.isEnabled == false)

        // Open settings, chose to display build labels, then close settings
        menu.menuItems["Settings..."].click() // otherwise click on first checkbox doesn't work
        XCTAssert(window.checkBoxes["Show label of last build"].isSelected == false)
        window.checkBoxes["Show label of last build"].click()
        XCTAssert(window.checkBoxes["Show time of last build"].isSelected == false)
        window.checkBoxes["Show time of last build"].click()

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

    private func launchApp(pipelines: String = "DefaultPipelines.json", pauseMonitor: Bool = true, token: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-loadPipelines", pathForResource(pipelines),
            "-ignoreDefaults", "true",
            "-pauseMonitor", String(pauseMonitor),
            "-PollInterval", "1",
            "-GitHubBaseURL", "http://localhost:8086",
        ]
        if let token {
            app.launchArguments.append(contentsOf: [ "-GitHubToken", token ])
        }
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
