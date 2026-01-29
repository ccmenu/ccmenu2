/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
import Hummingbird
import HummingbirdAuth

class GitLabTests: XCTestCase {

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
        webapp.router.get("/api/v4/projects/66079563/pipelines") { r in
            headers = r.headers
            return try TestHelper.contentsOfFile("GitLabPipelineRunsResponse.json")
        }
        webapp.router.get("/api/v4/projects/66079563/pipelines/1920856706") { r in
            return try TestHelper.contentsOfFile("GitLabPipelineDetailsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "GitLabPipelineLocalhost.json", pauseMonitor: false, token: "TEST-TOKEN")
        let window = app.windows["Pipelines"]

        // Find the status description field (there's only one because there's only one pipeline),
        // then wait for the update to show relevant information from the response. (We use a regex
        // to avoid issues with date formatting and timezones.) Make sure the request headers are
        // set.
        let descriptionText = window.outlines.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 3'"), evaluatedWith: descriptionText)
        expectation(for: NSPredicate(format: "value MATCHES '.*Last build: .*:06.*'"), evaluatedWith: descriptionText)
        let messageText = window.outlines.staticTexts["Build message"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Push'"), evaluatedWith: messageText)
        expectation(for: NSPredicate(format: "value CONTAINS 'Commit b899694c'"), evaluatedWith: messageText)
        waitForExpectations(timeout: 2)
        XCTAssertEqual("Bearer TEST-TOKEN", headers["Authorization"].first)
    }

    func testShowsMessageAndPausesPollingWhileRateLimitWasExceeded() throws {
        let limitResetTime = Date().addingTimeInterval(10)
        var didReceiveRequest = false
        webapp.router.get("/api/v4/projects/66079563/pipelines", options: .editResponse) { r -> String in
            didReceiveRequest = true
            if Date() < limitResetTime {
                r.response.status = .tooManyRequests
                r.response.headers.replaceOrAdd(name: "RateLimit-Remaining", value: "0")
                r.response.headers.replaceOrAdd(name: "RateLimit-Reset", value: String(Int(limitResetTime.timeIntervalSince1970)))
                return "{ \"message\": \"API rate limit exceeded for ...\" } "
            }
            return try TestHelper.contentsOfFile("GitLabPipelineRunsResponse.json")
        }
        webapp.router.get("/api/v4/projects/66079563/pipelines/1920856706") { r in
            return try TestHelper.contentsOfFile("GitLabPipelineDetailsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "GitLabPipelineLocalhost.json", pauseMonitor: false)
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
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 3'"), evaluatedWith: descriptionText)
        expectation(for: NSPredicate(format: "NOT value CONTAINS 'Rate limit exceeded'"), evaluatedWith: lastUpdatedText)
        waitForExpectations(timeout: 5)
    }

    func testAddsGitLabPipeline() throws {
        webapp.router.get("/api/v4/users/erikdoe/projects") { _ in
            try TestHelper.contentsOfFile("GitLabPipelinesByUserResponse.json")
        }
        webapp.router.get("/api/v4/projects/66079563/repository/branches") { _ in
            try TestHelper.contentsOfFile("GitLabBranchesResponse.json")
        }
        webapp.router.get("/api/v4/projects/66079563/pipelines") { r in
            return try TestHelper.contentsOfFile("GitLabPipelineRunsResponse.json")
        }
        webapp.router.get("/api/v4/projects/66079563/pipelines/1920856706") { r in
            return try TestHelper.contentsOfFile("GitLabPipelineDetailsResponse.json")
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
        let window = app.windows["Pipelines"]
        let sheet = openAddGitLabPipelineSheet(app: app)

        // Enter owner
        sheet.textFields["Owner field"].click()
        sheet.typeText("erikdoe" + "\n")

        // Make sure that the projects and branches are loaded
        let projectBox = sheet.comboBoxes["Project combo box"]
        expectation(for: NSPredicate(format: "value == 'Quvyn'"), evaluatedWith: projectBox)
        let branchBox = sheet.comboBoxes["Branch combo box"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: branchBox)
        waitForExpectations(timeout: 3)

        // Open the branch combo box, select the main branch, verify display name
        branchBox.descendants(matching: .button).firstMatch.click()
        branchBox.textFields["main"].click()
        let displayNameField = sheet.textFields["Display name field"]
        expectation(for: NSPredicate(format: "value == 'Quvyn | main'"), evaluatedWith: displayNameField)
        waitForExpectations(timeout: 3)

        // Set a custom display name, and close the sheet
        displayNameField.click()
        sheet.typeKey("a", modifierFlags: [ .command ])
        sheet.typeText("Quvyn (main)")
        sheet.buttons["Apply"].click()

        // Make sure the pipeline is shown, and that its status is fetched immediately
        let titleText = window.outlines.staticTexts["Pipeline title"]
        expectation(for: NSPredicate(format: "value == 'Quvyn (main)'"), evaluatedWith: titleText)
        let descriptionText = window.outlines.staticTexts["Status description"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 3'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)
    }

    func testShowsTokenDetails() throws {
        webapp.router.get("/api/v4/personal_access_tokens/self") { r in
            if r.headers["Authorization"].first != "Bearer TEST-TOKEN" {
                r.response.status = .unauthorized
                return "{ \"message\": \"Unauthorized\" } "
            }
            return """
                {   "id": 19127271,
                    "name": "Test token",
                    "scopes": ["read_api"],
                    "active": true,
                    "expiresAt": "2026-02-27" 
                }
            """
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
        let sheet = openAddGitLabPipelineSheet(app: app)

        // Enter token
        sheet.secureTextFields["Token field"].click()
        sheet.typeText("TEST-TOKEN" + "\n")
        sheet.textFields["Owner field"].click()

        // Wait for token info and check
        let descriptionText = sheet.staticTexts["Token description field"]
        expectation(for: NSPredicate(format: "value CONTAINS 'Test token'"), evaluatedWith: descriptionText)
        expectation(for: NSPredicate(format: "value CONTAINS 'Expires: '"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)
    }

    func testShowsTokenDetailsWithErrors() throws {
        webapp.router.get("/api/v4/personal_access_tokens/self") { r in
            return """
                {   "id": 19127271,
                    "name": "Test token",
                    "scopes": ["read_user"],
                    "active": false,
                    "expiresAt": "2026-02-27" 
                }
            """
        }

        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
        let sheet = openAddGitLabPipelineSheet(app: app)

        // Enter token
        sheet.secureTextFields["Token field"].click()
        sheet.typeText("TEST-TOKEN" + "\n")
        sheet.textFields["Owner field"].click()

        // Wait for token info and check
        let descriptionText = sheet.staticTexts["Token description field"]
        expectation(for: NSPredicate(format: "value CONTAINS 'not active'"), evaluatedWith: descriptionText)
        expectation(for: NSPredicate(format: "value CONTAINS 'missing read_api scope'"), evaluatedWith: descriptionText)
        waitForExpectations(timeout: 5)
    }


//
//    func testAddsGitHubPrivatePipeline() throws {
//        webapp.router.get("/users/erikdoe") { _ in
//            try TestHelper.contentsOfFile("GitHubUserResponse.json")
//        }
//        webapp.router.get("/users/erikdoe/repos") { _ in
//            return "[]"
//        }
//        webapp.router.get("/user/repos") { _ in
//            try TestHelper.contentsOfFile("GitHubReposByUserCCM2OnlyResponse.json")
//        }
//        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows") { _ in
//            try TestHelper.contentsOfFile("GitHubWorkflowsResponse.json")
//        }
//        webapp.router.get("/repos/erikdoe/ccmenu2/branches") { _ in
//            try TestHelper.contentsOfFile("GitHubBranchesResponse.json")
//        }
//        webapp.router.get("/repos/erikdoe/ccmenu2/actions/workflows/build-and-test.yaml/runs", options: .editResponse) { r -> String in
//            if r.headers["Authorization"].first != "Bearer TEST-TOKEN" {
//                r.response.status = .notFound
//                return "{ \"message\": \"Not found\" } "
//            }
//            return try TestHelper.contentsOfFile("GitHubWorkflowRunsResponse.json")
//        }
//
//        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false, token: "TEST-TOKEN")
//        let window = app.windows["Pipelines"]
//        let sheet = openAddGitHubPipelineSheet(app: app)
//
//        // Enter owner
//        sheet.textFields["Owner field"].click()
//        sheet.typeText("erikdoe" + "\n")
//
//        // Make sure that the repositories and workflows are loaded and the default display name is set
//        let repositoryBox = sheet.comboBoxes["Repository combo box"]
//        expectation(for: NSPredicate(format: "value == 'ccmenu2'"), evaluatedWith: repositoryBox)
//        let workflowPicker = sheet.popUpButtons["Workflow picker"]
//        expectation(for: NSPredicate(format: "value == 'Build and test'"), evaluatedWith: workflowPicker)
//        let displayNameField = sheet.textFields["Display name field"]
//        expectation(for: NSPredicate(format: "value == 'ccmenu2 | Build and test'"), evaluatedWith: displayNameField)
//        waitForExpectations(timeout: 3)
//
//        // Set a custom display name, and close the sheet
//        displayNameField.click()
//        sheet.typeKey("a", modifierFlags: [ .command ])
//        sheet.typeText("CCMenu")
//        sheet.buttons["Apply"].click()
//
//        // Make sure the pipeline is shown, and that its status is fetched immediately
//        let titleText = window.outlines.staticTexts["Pipeline title"]
//        expectation(for: NSPredicate(format: "value == 'CCMenu'"), evaluatedWith: titleText)
//        let descriptionText = window.outlines.staticTexts["Status description"]
//        expectation(for: NSPredicate(format: "value CONTAINS 'Label: 42'"), evaluatedWith: descriptionText)
//        waitForExpectations(timeout: 5)
//    }
//
//

//    func testFindsPrivateReposForUser() throws {
//        webapp.router.get("/users/erikdoe") { _ in
//            try TestHelper.contentsOfFile("GitHubUserResponse.json")
//        }
//        webapp.router.get("/users/erikdoe/repos") { _ in
//            try TestHelper.contentsOfFile("GitHubReposByUserResponse.json")
//        }
//        webapp.router.get("/user/repos") { _ in
//            return try TestHelper.contentsOfFile("GitHubUserReposResponse.json")
//        }
//
//        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false, token: "TEST-TOKEN")
//        let sheet = openAddGitHubPipelineSheet(app: app)
//
//        // Make sure the token is shown
//        let tokenField = sheet.textFields["Token field"]
//        XCTAssertEqual("TEST-TOKEN", tokenField.value as? String)
//
//        // Enter owner and wait for the repo list to load
//        sheet.textFields["Owner field"].click()
//        sheet.typeText("erikdoe" + "\n")
//
//        // Make sure that the repositories are loaded
//        let repositoryBox = sheet.comboBoxes["Repository combo box"]
//        expectation(for: NSPredicate(format: "value == 'ccmenu'"), evaluatedWith: repositoryBox)
//        waitForExpectations(timeout: 2)
//
//        // Open the combox box drop down
//        repositoryBox.descendants(matching: .button).firstMatch.click()
//
//        // Make sure that repositories for different owners are not shown, and that a private
//        // repository is shown, and that its shown even when its owner's name uses camel case
//        XCTAssertFalse(repositoryBox.textFields["tw2021-screensaver"].exists)
//        XCTAssertFalse(repositoryBox.textFields["iEnterpriseArchitect"].exists)
//        XCTAssertTrue(repositoryBox.textFields["jekyll-site-test"].exists)
//    }
//
//    func testRetrievesReposForOrg() throws {
//        webapp.router.get("/users/ccmenu") { _ in
//            try TestHelper.contentsOfFile("GitHubUserOrgResponse.json")
//        }
//        webapp.router.get("/orgs/ccmenu/repos") { _ in
//            try TestHelper.contentsOfFile("GitHubReposByOrgResponse.json")
//        }
//
//        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
//        let sheet = openAddGitHubPipelineSheet(app: app)
//
//        // Enter owner
//        sheet.textFields["Owner field"].click()
//        sheet.typeText("ccmenu" + "\n")
//
//        // Make sure that the repositories and workflows are loaded and the default display name is set
//        let repositoryBox = sheet.comboBoxes["Repository combo box"]
//        expectation(for: NSPredicate(format: "value == 'ccmenu'"), evaluatedWith: repositoryBox)
//        waitForExpectations(timeout: 3)
//    }
//
//    func testShowsRateLimitExceededForRepositories() throws {
//        webapp.router.get("/users/erikdoe", options: .editResponse) { r -> String in
//            r.response.status = .forbidden
//            r.response.headers.replaceOrAdd(name: "x-ratelimit-remaining", value: "0")
//            return "{ \"message\": \"API rate limit exceeded for ...\" } "
//        }
//
//        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json", pauseMonitor: false)
//        let sheet = openAddGitHubPipelineSheet(app: app)
//
//        // Enter owner
//        sheet.textFields["Owner field"].click()
//        sheet.typeText("erikdoe" + "\n")
//
//        // Make sure that the repository list shows rate limit exceeded message
//        let repositoryBox = sheet.comboBoxes["Repository combo box"]
//        expectation(for: NSPredicate(format: "value == '(too many requests)'"), evaluatedWith: repositoryBox)
//        waitForExpectations(timeout: 2)
//    }
//
//    func testDoesntDoubleFetchRepositories() throws {
//        var fetchCount = 0
//        webapp.router.get("/users/erikdoe") { _ in
//            try TestHelper.contentsOfFile("GitHubUserResponse.json")
//        }
//        webapp.router.get("/users/erikdoe/repos") { _ in
//            fetchCount += 1
//            return try TestHelper.contentsOfFile("GitHubReposByUserResponse.json")
//        }
//
//        let app = TestHelper.launchApp(pipelines: "EmptyPipelines.json")
//        let sheet = openAddGitHubPipelineSheet(app: app)
//
//        // Enter owner and wait for the repo list to load
//        sheet.textFields["Owner field"].click()
//        sheet.typeText("erikdoe") // Note: not pressing return here
//
//        // Make sure that the repositories are loaded and sorted
//        let repositoryBox = sheet.comboBoxes["Repository combo box"]
//        expectation(for: NSPredicate(format: "value == 'ccmenu'"), evaluatedWith: repositoryBox)
//        waitForExpectations(timeout: 3)
//
//        // Now press return and wait for a little while
//        sheet.typeText("\n")
//        Thread.sleep(forTimeInterval: 1)
//
//        // Assert that no further fetch occured
//        XCTAssertEqual(1, fetchCount)
//
//    }
//
    private func openAddGitLabPipelineSheet(app: XCUIApplication) -> XCUIElement {
        let window = app.windows["Pipelines"]
        let sheet = window.sheets.firstMatch
        window.toolbars.popUpButtons["Add pipeline menu"].click()
        window.toolbars.menuItems["Add GitLab pipeline..."].click()
        return sheet
    }

}
