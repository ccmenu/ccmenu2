/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class GitLabAPITests: XCTestCase {

    func testConstructsRequestForFeed() throws {
        let feedUrl = GitLabAPI.feedUrl(projectId: "31415926", branch: nil)
        let feed = PipelineFeed(type: .gitlab, url: feedUrl)
        let request = GitLabAPI.requestForFeed(feed: feed, token: nil)

        guard let request else { XCTFail(); return }
        XCTAssertEqual("GET", request.httpMethod)
        let url = request.url?.absoluteString
        XCTAssertEqual("https://gitlab.com/api/v4/projects/31415926/pipelines?per_page=3", url)
    }

    func testConstructsRequestForFeedWithBranch() throws {
        let feedUrl = GitLabAPI.feedUrl(projectId: "31415926", branch: "main")
        let feed = PipelineFeed(type: .gitlab, url: feedUrl)
        let request = GitLabAPI.requestForFeed(feed: feed, token: nil)

        guard let request else { XCTFail(); return }
        let url = request.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("ref=main"))
    }

    func testConstructsRequestForPipelineDetailsAndDoesNotIncludeBranch() throws {
        let feedUrl = GitLabAPI.feedUrl(projectId: "31415926", branch: "main")
        let feed = PipelineFeed(type: .gitlab, url: feedUrl)
        let request = GitLabAPI.requestForDetail(feed: feed, pipelineId: "12345", token: nil)

        guard let request else { XCTFail(); return }
        let url = request.url?.absoluteString
        XCTAssertEqual("https://gitlab.com/api/v4/projects/31415926/pipelines/12345", url)
    }

    func testAddsAuthorizationHeaderWhenTokenIsGiven() throws {
        let feed = PipelineFeed(type: .gitlab, url: URL(string: "https://example.com/api")!)
        let request = GitLabAPI.requestForFeed(feed: feed, token: "TEST-TOKEN")

        guard let request else { XCTFail(); return }
        XCTAssertEqual("Bearer TEST-TOKEN", request.value(forHTTPHeaderField: "Authorization"))
    }

    func testConstructsCorrectRequestPathWhenBaseURLContainsPath() throws {
        UserDefaults.active = UserDefaults.transient
        UserDefaults.active.set("https://dev.some-enterprise.com/gitlab/api/v4", forKey: "GitLabAPIBaseURL")
        let request = GitLabAPI.requestForUserProjects(user: "testuser", token: nil)
        UserDefaults.active = UserDefaults.standard

        XCTAssertEqual("/gitlab/api/v4/users/testuser/projects", request.url?.path())
    }

}
