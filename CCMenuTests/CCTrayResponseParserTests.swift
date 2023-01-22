/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class CCTrayResponseParserTests: XCTestCase {

    func testParsesXML() throws {
        let parser = CCTrayResponseParser()
        let xml = "<Projects><Project name='connectfour' activity='Sleeping'/></Projects>"

        try parser.parseResponse(xml.data(using: .ascii)!)

        XCTAssertEqual(1, parser.projectList.count)
        let project = parser.projectList[0]
        XCTAssertEqual("connectfour", project["name"])
    }

    func testThrowsForMalformedXML() throws {
        let xml = "<Projects><Project name='connectfour' deliberately broken"
        let parser = CCTrayResponseParser()

        XCTAssertThrowsError(try parser.parseResponse(xml.data(using: .ascii)!))
    }

    func testDoesNotReturnStatusWhenPipelineIsNotInResponse() throws {
        let xml = "<Projects><Project name='connectfour' activity='Sleeping'/></Projects>"
        let parser = CCTrayResponseParser()
        try parser.parseResponse(xml.data(using: .ascii)!)

        XCTAssertNil(parser.pipelineStatus(name: "cosmos"))
    }

    func testPipelineStatusReflectsSleepingProjectEntry() throws {
        let xml = """
            <Projects>
                <Project
                    name='connectfour'
                    activity='Sleeping'
                    lastBuildStatus='Success'
                    lastBuildLabel='build.1'
                    lastBuildTime='2007-07-18T18:44:48Z'
                    webUrl='http://localhost:8080/dashboard/build/detail/connectfour'/>
            </Projects>
        """
        let parser = CCTrayResponseParser()
        try parser.parseResponse(xml.data(using: .ascii)!)

        let status = parser.pipelineStatus(name: "connectfour")!

        XCTAssertEqual(.sleeping, status.activity)
        guard let build = status.lastBuild else { XCTFail(); return }
        XCTAssertEqual(.success, build.result)
        XCTAssertEqual("build.1", build.label)
        XCTAssertEqual(ISO8601DateFormatter().date(from: "2007-07-18T18:44:48Z"), build.timestamp)
    }

    func testPipelineStatusReflectsBuildingProjectEntry() throws {
        let xml = """
            <Projects>
                <Project
                    name='connectfour'
                    activity='Building' />
            </Projects>
        """
        let parser = CCTrayResponseParser()
        try parser.parseResponse(xml.data(using: .ascii)!)

        let status = parser.pipelineStatus(name: "connectfour")!

        XCTAssertEqual(.building, status.activity)

        guard let lastBuild = status.lastBuild else { XCTFail(); return }
        XCTAssertEqual(.unknown, lastBuild.result)
        guard let currentBuild = status.currentBuild else { XCTFail(); return }
        XCTAssertEqual(.unknown, currentBuild.result)
    }



    func testReadsDatesWithoutTimezoneAsLocal() throws {
        let parser = CCTrayResponseParser()
        let actual = parser.dateForString("2007-07-18T18:44:48")
        let expected = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: nil,
                                      year: 2007, month: 7, day: 18, hour: 18, minute: 44, second: 48, nanosecond: 0).date
        XCTAssertEqual(expected, actual)
    }

    func testReadsISO8601FormattedDateWithZuluMarker() throws {
        let parser = CCTrayResponseParser()
        let actual = parser.dateForString("2007-07-18T18:44:48Z")
        let expected = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone.init(abbreviation: "UTC"),
                                      year: 2007, month: 7, day: 18, hour: 18, minute: 44, second: 48, nanosecond: 0).date
        XCTAssertEqual(expected, actual)
    }

    func testReadsISO8601FormattedDateWithTimezone() throws {
        let parser = CCTrayResponseParser()
        let actual = parser.dateForString("2007-07-18T18:44:48+0800")
        let expected = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone.init(abbreviation: "UTC"),
                                      year: 2007, month: 7, day: 18, hour: 10, minute: 44, second: 48, nanosecond: 0).date
        XCTAssertEqual(expected, actual)
    }

    func testReadsISO8601FormattedDateWithSubsecondsAndTimezoneInAlternateFormat() throws {
        let parser = CCTrayResponseParser()
        let actual = parser.dateForString("2007-07-18T18:44:48.888-05:00")
        let expected = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone.init(abbreviation: "UTC"),
                                      year: 2007, month: 7, day: 18, hour: 23, minute: 44, second: 48, nanosecond: 0).date
        XCTAssertEqual(expected, actual)
    }

}

