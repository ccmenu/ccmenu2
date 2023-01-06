/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
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

        guard let list = parser.projectList else {
            XCTFail("parser has not project list")
            return
        }
        XCTAssertEqual(1, list.count)
        let project = list[0]
        XCTAssertEqual("connectfour", project["name"])
    }

    func testThrowsForMalformedXML() throws {
        let parser = CCTrayResponseParser()
        let xml = "<Projects><Project name='connectfour' deliberately broken"

        XCTAssertThrowsError(try parser.parseResponse(xml.data(using: .ascii)!))
    }

    func testDoesNotUpdatePipelineThatIsNotInResponse() throws {
        let parser = CCTrayResponseParser()
        let xml = "<Projects><Project name='connectfour' activity='Sleeping'/></Projects>"
        try parser.parseResponse(xml.data(using: .ascii)!)

        let originalPipeline = Pipeline(name: "cosmos", feedUrl: "http://localhost:8080/cctray.xml")
        let updatedPipeline = parser.updatePipeline(originalPipeline)

        XCTAssertNil(updatedPipeline)
    }

    func testUpdatesPipeline() throws {
        let parser = CCTrayResponseParser()
        let xml = """
            <Projects>
                <Project
                    name='connectfour'
                    activity='Sleeping'
                    lastBuildStatus='Success'
                    lastBuildLabel='build.1'
                    lastBuildTime='2007-07-18T18:44:48Z'
                    webUrl='http://localhost:8080/dashboard/build/detail/connectfour'/>
            </Projects>"
        """
        try parser.parseResponse(xml.data(using: .ascii)!)

        let originalPipeline = Pipeline(name: "connectfour", feedUrl: "http://localhost:8080/cctray.xml")
        let updatedPipeline = parser.updatePipeline(originalPipeline)

        guard let pipeline = updatedPipeline else {
            XCTFail("parser did not update pipeline")
            return
        }
        XCTAssertEqual("connectfour", pipeline.name)
        XCTAssertEqual("http://localhost:8080/dashboard/build/detail/connectfour", pipeline.webUrl)
        XCTAssertEqual(PipelineActivity.sleeping, pipeline.activity)

        guard let build = pipeline.lastBuild else {
            XCTFail("parser did not set lastBuild")
            return
        }
        XCTAssertEqual(BuildResult.success, build.result)
        XCTAssertEqual("build.1", build.label)
        let date = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone.init(abbreviation: "UTC"),
                                  year: 2007, month: 7, day: 18, hour: 18, minute: 44, second: 48, nanosecond: 0).date
        XCTAssertEqual(date, build.timestamp)
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

