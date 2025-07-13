/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class GitHubAPITests: XCTestCase {

    func testConstructsCorrectRequestPathWhenBaseURLContainsPath() throws {
        UserDefaults.active.set("https://dev.some-enterprise.com/github", forKey: "GitHubAPIBaseURL")
        let request = GitHubAPI.requestForUser(user: "testuser", token: nil)
        UserDefaults.active.removeObject(forKey: "CCMenuGitHubAPIBaseURL")

        XCTAssertEqual("/github/users/testuser", request.url?.path())
    }

}

