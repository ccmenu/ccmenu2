/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class CompactRelativeFormatStyleTests: XCTestCase {

    func testFormatsLessThan60sIntervalInSecondsWithPlusSign() throws {
        let now = Date.now
        let other = now.advanced(by: 59)

        XCTAssertEqual("+59s", other.formatted(.compactRelative(reference: now)))
    }

    func testFormatsLessThan10sIntervalWithDoubleDigits() throws {
        let now = Date.now
        let other = now.advanced(by: 8)

        XCTAssertEqual("+08s", other.formatted(.compactRelative(reference: now)))
    }

    func testFormatsLessThan60sReverseIntervalSecondsWithMinusSign() throws {
        let now = Date.now
        let other = now.advanced(by: -59)

        XCTAssertEqual("-59s", other.formatted(.compactRelative(reference: now)))
    }

    func testFormatsLessThan60mReverseIntervalInMinutesAndSeconds() throws {
        let now = Date.now
        let other = now.advanced(by: -(59*60 + 9))

        XCTAssertEqual("-59:09", other.formatted(.compactRelative(reference: now)))
    }

    func testFormatsLessThan10mIntervalWithDoubleDigits() throws {
        let now = Date.now
        let other = now.advanced(by: 9*60)

        XCTAssertEqual("+09:00", other.formatted(.compactRelative(reference: now)))
    }

    func testFormatsMoreThan60mIntervalInHoursMinutesSeconds() throws {
        let now = Date.now
        let other = now.advanced(by: 60*60 + 1)

        XCTAssertEqual("+1:00:01", other.formatted(.compactRelative(reference: now)))
    }

    func testDescribesCloseToZeroLengthIntervalWithSign() throws {
        let now = Date.now
        let other = now.advanced(by: -0.01)

        XCTAssertEqual("-00s", other.formatted(.compactRelative(reference: now)))
    }

    func testDescribesZeroLengthIntervalWithEmptyString() throws {
        let now = Date.now

        XCTAssertEqual("", now.formatted(.compactRelative(reference: now)))

    }
}
