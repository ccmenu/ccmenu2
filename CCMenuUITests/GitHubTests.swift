/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
import Hummingbird
import HummingbirdAuth

class GitHubTests: XCTestCase {

    var webapp: HBApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        webapp = try TestHelper.startEmbeddedServer()
    }

    override func tearDownWithError() throws {
        webapp.stop()
    }

    func testShowsWorkflowStatusFetchedFromServer() throws {
        var headers: HTTPHeaders = HTTPHeaders()
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs") { r in
            headers = r.headers
            return try TestHelper.contentsOfFile("GitHubWorkflowRunsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "GitHubPipelineLocalhost.json", pauseMonitor: false, token: "TEST-TOKEN")
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
            return try TestHelper.contentsOfFile("GitHubWorkflowRunsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "GitHubPipelineLocalhost.json", pauseMonitor: false)
        let window = app.windows["Pipelines"]

        // Make sure the status shows that the limit was exceeded
        let descriptionText = window.tables.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Rate limit exceeded.'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)

        // Make sure there are no requests until the reset time is reached. We subtract a second to avoid
        // a possible race condition
        didReceiveRequest = false
        Thread.sleep(until: limitResetTime.advanced(by: -1))
        XCTAssertFalse(didReceiveRequest)

        // Make sure that polling resumes and updates the status
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)
    }

    func testAddsGitHubPipeline() throws {
        webapp.router.get("/users/erikdoe/repos") { _ in
            try TestHelper.contentsOfFile("GitHubReposByUserResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu/actions/workflows") { _ in
            "{ \"total_count\": 0, \"workflows\": [] }"
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows") { _ in
            try TestHelper.contentsOfFile("GitHubWorkflowsResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs") { _ in
            try TestHelper.contentsOfFile("GitHubWorkflowRunsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
        let window = app.windows["Pipelines"]
        let sheet = window.sheets.firstMatch

        // Navigate to add workflow sheet
        window.toolbars.popUpButtons["Add pipeline menu"].click()
        window.toolbars.menuItems["Add GitHub Actions workflow..."].click()

        // Enter owner
        sheet.textFields["Owner field"].click()
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
        webapp.router.get("/users/erikdoe/repos") { _ in
            try TestHelper.contentsOfFile("GitHubReposByUserResponse.json")
        }
        webapp.router.get("/user/repos") { _ in
            return try TestHelper.contentsOfFile("GitHubUserReposResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu/actions/workflows") { _ in
            "{ \"total_count\": 0, \"workflows\": [] }"
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows") { _ in
            try TestHelper.contentsOfFile("GitHubWorkflowsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false, token: "TEST-TOKEN")
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

}
