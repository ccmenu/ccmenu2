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
        let descriptionText = window.outlines.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)
        let messageText = window.outlines.staticTexts["Build message"]
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
            if Date() < limitResetTime {
                r.response.status = .forbidden
                r.response.headers.replaceOrAdd(name: "x-ratelimit-remaining", value: "0")
                r.response.headers.replaceOrAdd(name: "x-ratelimit-reset", value: String(Int(limitResetTime.timeIntervalSince1970)))
                return "{ \"message\": \"API rate limit exceeded for ...\" } "
            }
            return try TestHelper.contentsOfFile("GitHubWorkflowRunsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "GitHubPipelineLocalhost.json", pauseMonitor: false, token: "TEST-TOKEN")
        let window = app.windows["Pipelines"]

        // Make sure the update message shows that the limit was exceeded
        let lastUpdatedText = window.outlines.staticTexts["Last updated message"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Rate limit exceeded'"), evaluatedWith: lastUpdatedText)
        waitForExpectations(timeout: 5)

        // Make sure there are no requests until the reset time is reached. We subtract a second to avoid
        // a possible race condition
        didReceiveRequest = false
        Thread.sleep(until: limitResetTime.advanced(by: -1))
        XCTAssertFalse(didReceiveRequest)

        // Make sure that polling resumes and updates the status and clears the update message
        let descriptionText = window.outlines.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
        expectation(for: NSPredicate(format: "NOT value CONTAINS 'Rate limit exceeded'"), evaluatedWith: lastUpdatedText)
        waitForExpectations(timeout: 5)
    }

    func testAddsGitHubPipeline() throws {
        webapp.router.get("/users/erikdoe") { _ in
            try TestHelper.contentsOfFile("GitHubUserResponse.json")
        }
        webapp.router.get("/users/erikdoe/repos") { _ in
            try TestHelper.contentsOfFile("GitHubReposByUserCCM2OnlyResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows") { _ in
            try TestHelper.contentsOfFile("GitHubWorkflowsResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/branches") { _ in
            try TestHelper.contentsOfFile("GitHubBranchesResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs") { _ in
            try TestHelper.contentsOfFile("GitHubWorkflowRunsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
        let window = app.windows["Pipelines"]
        let sheet = openAddGitHubPipelineSheet(app: app)

        // Enter owner
        sheet.textFields["Owner field"].click()
        sheet.typeText("erikdoe" + "\n")

        // Make sure that the repositories and workflows are loaded and the default display name is set
        let repositoryBox = sheet.comboBoxes["Repository combo box"]
        expectation(for: NSPredicate(format: "value == 'ccmenu2'"), evaluatedWith: repositoryBox)
        let workflowPicker = sheet.popUpButtons["Workflow picker"]
        expectation(for: NSPredicate(format: "value == 'Build and test'"), evaluatedWith: workflowPicker)
        let displayNameField = sheet.textFields["Display name field"]
        expectation(for: NSPredicate(format: "value == 'ccmenu2 | Build and test'"), evaluatedWith: displayNameField)
        waitForExpectations(timeout: 3)

        // Set a custom display name, and close the sheet
        displayNameField.click()
        sheet.typeKey("a", modifierFlags: [ .command ])
        sheet.typeText("CCMenu")
        sheet.buttons["Apply"].click()

        // Make sure the pipeline is shown, and that its status is fetched immediately
        let titleText = window.outlines.staticTexts["Pipeline title"]
        expectation(for: NSPredicate(format: "value == 'CCMenu'"), evaluatedWith: titleText)
        let descriptionText = window.outlines.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)
    }

    func testAddsGitHubPrivatePipeline() throws {
        webapp.router.get("/users/erikdoe") { _ in
            try TestHelper.contentsOfFile("GitHubUserResponse.json")
        }
        webapp.router.get("/users/erikdoe/repos") { _ in
            return "[]"
        }
        webapp.router.get("/user/repos") { _ in
            try TestHelper.contentsOfFile("GitHubReposByUserCCM2OnlyResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows") { _ in
            try TestHelper.contentsOfFile("GitHubWorkflowsResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/branches") { _ in
            try TestHelper.contentsOfFile("GitHubBranchesResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs", options: .editResponse) { r -> String in
            if r.headers["Authorization"].first != "Bearer TEST-TOKEN" {
                r.response.status = .notFound
                return "{ \"message\": \"Not found\" } "
            }
            return try TestHelper.contentsOfFile("GitHubWorkflowRunsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false, token: "TEST-TOKEN")
        let window = app.windows["Pipelines"]
        let sheet = openAddGitHubPipelineSheet(app: app)

        // Enter owner
        sheet.textFields["Owner field"].click()
        sheet.typeText("erikdoe" + "\n")

        // Make sure that the repositories and workflows are loaded and the default display name is set
        let repositoryBox = sheet.comboBoxes["Repository combo box"]
        expectation(for: NSPredicate(format: "value == 'ccmenu2'"), evaluatedWith: repositoryBox)
        let workflowPicker = sheet.popUpButtons["Workflow picker"]
        expectation(for: NSPredicate(format: "value == 'Build and test'"), evaluatedWith: workflowPicker)
        let displayNameField = sheet.textFields["Display name field"]
        expectation(for: NSPredicate(format: "value == 'ccmenu2 | Build and test'"), evaluatedWith: displayNameField)
        waitForExpectations(timeout: 3)

        // Set a custom display name, and close the sheet
        displayNameField.click()
        sheet.typeKey("a", modifierFlags: [ .command ])
        sheet.typeText("CCMenu")
        sheet.buttons["Apply"].click()

        // Make sure the pipeline is shown, and that its status is fetched immediately
        let titleText = window.outlines.staticTexts["Pipeline title"]
        expectation(for: NSPredicate(format: "value == 'CCMenu'"), evaluatedWith: titleText)
        let descriptionText = window.outlines.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)
    }


    func testAddsGitHubPipelineByIdIfNeccessary() throws {
        webapp.router.get("/users/erikdoe") { _ in
            try TestHelper.contentsOfFile("GitHubUserResponse.json")
        }
        webapp.router.get("/users/erikdoe/repos") { _ in
            try TestHelper.contentsOfFile("GitHubReposByUserCCM2OnlyResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows") { _ in
            try TestHelper.contentsOfFile("GitHubWorkflowsResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/branches") { _ in
            try TestHelper.contentsOfFile("GitHubBranchesResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs", options: .editResponse) { r in
            r.response.status = .notFound
            return "{ } "
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows/62921699/runs") { _ in
            try TestHelper.contentsOfFile("GitHubWorkflowRunsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
        let window = app.windows["Pipelines"]
        let sheet = openAddGitHubPipelineSheet(app: app)

        // Enter owner
        sheet.textFields["Owner field"].click()
        sheet.typeText("erikdoe" + "\n")

        let repositoryBox = sheet.comboBoxes["Repository combo box"]
        expectation(for: NSPredicate(format: "value == 'ccmenu2'"), evaluatedWith: repositoryBox)
        let workflowPicker = sheet.popUpButtons["Workflow picker"]
        expectation(for: NSPredicate(format: "value == 'Build and test'"), evaluatedWith: workflowPicker)
        waitForExpectations(timeout: 5)

        sheet.buttons["Apply"].click()

        // Make sure the pipeline is shown, and that its status is fetched immediately
        let titleText = window.outlines.staticTexts["Pipeline title"]
        expectation(for: NSPredicate(format: "value BEGINSWITH 'ccmenu2'"), evaluatedWith: titleText)
        let descriptionText = window.outlines.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)
    }

    func testAddsGitHubPipelineWithBranch() throws {
        var branchParam: String?
        webapp.router.get("/users/erikdoe") { _ in
            try TestHelper.contentsOfFile("GitHubUserResponse.json")
        }
        webapp.router.get("/users/erikdoe/repos") { _ in
            try TestHelper.contentsOfFile("GitHubReposByUserCCM2OnlyResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows") { _ in
            try TestHelper.contentsOfFile("GitHubWorkflowsResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/branches") { _ in
            try TestHelper.contentsOfFile("GitHubBranchesResponse.json")
        }
        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs") { r in
            branchParam = r.uri.queryParameters.get("branch")
            return try TestHelper.contentsOfFile("GitHubWorkflowRunsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
        let window = app.windows["Pipelines"]
        let sheet = openAddGitHubPipelineSheet(app: app)

        // Enter owner
        sheet.textFields["Owner field"].click()
        sheet.typeText("erikdoe" + "\n")

        // Make sure that the repositories and branches are loaded
        let repositoryBox = sheet.comboBoxes["Repository combo box"]
        expectation(for: NSPredicate(format: "value == 'ccmenu2'"), evaluatedWith: repositoryBox)
        let branchBox = sheet.comboBoxes["Branch combo box"]
        expectation(for: NSPredicate(format: "value == ''"), evaluatedWith: branchBox)
        waitForExpectations(timeout: 5)

        // Open the branch combo box, select the main branch, and close the sheet
        branchBox.descendants(matching: .button).firstMatch.click()
        branchBox.textFields["main"].click()
        expectation(for: NSPredicate(format: "value == 'main'"), evaluatedWith: branchBox)
        waitForExpectations(timeout: 2)
        sheet.buttons["Apply"].click()

        // Make sure the status is fetched and the request uses the branch
        let descriptionText = window.outlines.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)
        XCTAssertEqual("main", branchParam)
    }

    

    func testFindsPrivateReposForUser() throws {
        webapp.router.get("/users/erikdoe") { _ in
            try TestHelper.contentsOfFile("GitHubUserResponse.json")
        }
        webapp.router.get("/users/erikdoe/repos") { _ in
            try TestHelper.contentsOfFile("GitHubReposByUserResponse.json")
        }
        webapp.router.get("/user/repos") { _ in
            return try TestHelper.contentsOfFile("GitHubUserReposResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false, token: "TEST-TOKEN")
        let sheet = openAddGitHubPipelineSheet(app: app)

        // Make sure the token is shown
        let tokenField = sheet.textFields["Token field"]
        XCTAssertEqual("TEST-TOKEN", tokenField.value as? String)

        // Enter owner and wait for the repo list to load
        sheet.textFields["Owner field"].click()
        sheet.typeText("erikdoe" + "\n")

        // Make sure that the repositories are loaded
        let repositoryBox = sheet.comboBoxes["Repository combo box"]
        expectation(for: NSPredicate(format: "value == 'ccmenu'"), evaluatedWith: repositoryBox)
        waitForExpectations(timeout: 2)

        // Open the combox box drop down
        repositoryBox.descendants(matching: .button).firstMatch.click()

        // Make sure that repositories for different owners are not shown, and that a private
        // repository is shown, and that its shown even when its owner's name uses camel case
        XCTAssertFalse(repositoryBox.textFields["tw2021-screensaver"].exists)
        XCTAssertFalse(repositoryBox.textFields["iEnterpriseArchitect"].exists)
        XCTAssertTrue(repositoryBox.textFields["jekyll-site-test"].exists)
    }

    func testRetrievesReposForOrg() throws {
        webapp.router.get("/users/ccmenu") { _ in
            try TestHelper.contentsOfFile("GitHubUserOrgResponse.json")
        }
        webapp.router.get("/orgs/ccmenu/repos") { _ in
            try TestHelper.contentsOfFile("GitHubReposByOrgResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
        let sheet = openAddGitHubPipelineSheet(app: app)

        // Enter owner
        sheet.textFields["Owner field"].click()
        sheet.typeText("ccmenu" + "\n")

        // Make sure that the repositories and workflows are loaded and the default display name is set
        let repositoryBox = sheet.comboBoxes["Repository combo box"]
        expectation(for: NSPredicate(format: "value == 'ccmenu'"), evaluatedWith: repositoryBox)
        waitForExpectations(timeout: 3)
    }

    func testShowsRateLimitExceededForRepositories() throws {
        webapp.router.get("/users/erikdoe", options: .editResponse) { r -> String in
            r.response.status = .forbidden
            r.response.headers.replaceOrAdd(name: "x-ratelimit-remaining", value: "0")
            return "{ \"message\": \"API rate limit exceeded for ...\" } "
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
        let sheet = openAddGitHubPipelineSheet(app: app)

        // Enter owner
        sheet.textFields["Owner field"].click()
        sheet.typeText("erikdoe" + "\n")

        // Make sure that the repository list shows rate limit exceeded message
        let repositoryBox = sheet.comboBoxes["Repository combo box"]
        expectation(for: NSPredicate(format: "value == '(too many requests)'"), evaluatedWith: repositoryBox)
        waitForExpectations(timeout: 2)
    }

    func testDoesntDoubleFetchRepositories() throws {
        var fetchCount = 0
        webapp.router.get("/users/erikdoe") { _ in
            try TestHelper.contentsOfFile("GitHubUserResponse.json")
        }
        webapp.router.get("/users/erikdoe/repos") { _ in
            fetchCount += 1
            return try TestHelper.contentsOfFile("GitHubReposByUserResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json")
        let sheet = openAddGitHubPipelineSheet(app: app)

        // Enter owner and wait for the repo list to load
        sheet.textFields["Owner field"].click()
        sheet.typeText("erikdoe") // Note: not pressing return here

        // Make sure that the repositories are loaded and sorted
        let repositoryBox = sheet.comboBoxes["Repository combo box"]
        expectation(for: NSPredicate(format: "value == 'ccmenu'"), evaluatedWith: repositoryBox)
        waitForExpectations(timeout: 3)

        // Now press return and wait for a little while
        sheet.typeText("\n")
        Thread.sleep(forTimeInterval: 1)

        // Assert that no further fetch occured
        XCTAssertEqual(1, fetchCount)

    }

    private func openAddGitHubPipelineSheet(app: XCUIApplication) -> XCUIElement {
        let window = app.windows["Pipelines"]
        let sheet = window.sheets.firstMatch
        window.toolbars.popUpButtons["Add pipeline menu"].click()
        window.toolbars.menuItems["Add GitHub Actions workflow..."].click()
        return sheet
    }

}
