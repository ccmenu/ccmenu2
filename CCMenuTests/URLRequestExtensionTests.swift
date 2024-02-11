/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class URLRequestExtensionTests: XCTestCase {

    func testCreatesUnicodeBasicAuthHeader() throws {
        let value = URLRequest.basicAuthValue(user: "test", password: "\u{1F600}")
        XCTAssertEqual("Basic dGVzdDrwn5iA", value)
    }

}

