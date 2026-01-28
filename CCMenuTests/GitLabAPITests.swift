/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class GitLabAPITests: XCTestCase {

    func testConstructsRequestForFeed() throws {
        let feed = PipelineFeed(type: .gitlab, url: URL(string: "https://example.com/api")!)
        let request = GitLabAPI.requestForFeed(feed: feed, token: nil)

        guard let request else { XCTFail(); return }
        XCTAssertEqual("GET", request.httpMethod)
        let url = request.url?.absoluteString ?? ""
        XCTAssertTrue(url.hasPrefix("https://example.com/api"))
        XCTAssertTrue(url.contains("per_page="))
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
        let request = GitLabAPI.requestForUser(token: "TEST-TOKEN")

        XCTAssertEqual("/gitlab/api/v4/user", request.url?.path())
    }

}
