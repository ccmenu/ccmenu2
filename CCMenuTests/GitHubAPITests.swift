/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class GitHubAPITests: XCTestCase {

    func testConstructsRequestForFeed() throws {
        let feed = PipelineFeed(type: .github, url: URL(string: "https://example.com/api")!)
        let request = GitHubAPI.requestForFeed(feed: feed, token: nil)

        guard let request else { XCTFail(); return }
        XCTAssertEqual("GET", request.httpMethod)
        XCTAssertEqual("application/vnd.github+json", request.value(forHTTPHeaderField: "Accept"))
        XCTAssertEqual("2022-11-28", request.value(forHTTPHeaderField: "X-GitHub-Api-Version"))
        let url = request.url?.absoluteString ?? ""
        XCTAssertTrue(url.hasPrefix("https://example.com/api"))
        XCTAssertTrue(url.contains("per_page="))
    }

    func testAddsAuthorizationHeaderWhenTokenIsGiven() throws {
        let feed = PipelineFeed(type: .github, url: URL(string: "https://example.com/api")!)
        let request = GitHubAPI.requestForFeed(feed: feed, token: "TEST-TOKEN")

        guard let request else { XCTFail(); return }
        XCTAssertEqual("Bearer TEST-TOKEN", request.value(forHTTPHeaderField: "Authorization"))
    }

    func testConstructsCorrectRequestPathWhenBaseURLContainsPath() throws {
        UserDefaults.active.set("https://dev.some-enterprise.com/github", forKey: "GitHubAPIBaseURL")
        let request = GitHubAPI.requestForUser(user: "testuser", token: nil)
        UserDefaults.active.removeObject(forKey: "CCMenuGitHubAPIBaseURL")

        XCTAssertEqual("/github/users/testuser", request.url?.path())
    }

}

