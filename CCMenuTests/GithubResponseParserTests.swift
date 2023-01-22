/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class GithubResponseParserTests: XCTestCase {

    func testParsesJSON() throws {
        let parser = GithubResponseParser()
        let json = "{ \"workflow_runs\": [ { \"name\": \"Rust\", \"status\": \"completed\", \"conclusion\": \"success\" } ] }\n"

        try parser.parseResponse(json.data(using: .ascii)!)

        guard let list = parser.runList else {
            XCTFail("parser does not have a list of runs")
            return
        }
        XCTAssertEqual(1, list.count)
        let run = list[0]
        XCTAssertEqual("Rust", run["name"] as? String)
    }

    func testThrowsForMalformedJSON() throws {
        let parser = GithubResponseParser()
        let json = " \"workflow_runs\": [ { \"name\": \"Rust\" deliberately broken"

        XCTAssertThrowsError(try parser.parseResponse(json.data(using: .ascii)!))
    }

    func testUpdatesPipelineWithWorkflowRun() throws {
        let parser = GithubResponseParser()
        let json = """
            { "workflow_runs": [{
                "name": "Rust",
                "run_number": 17,
                "status": "completed",
                "conclusion": "success",
                "html_url": "https://github.com/erikdoe/quvyn/actions/runs/842089420",
                "created_at": "2021-05-14T12:04:23Z",
                "updated_at": "2021-05-14T12:06:57Z",
                "actor": {
                    "login": "erikdoe",
                    "avatar_url": "https://test.org/avatar.jpg"
                }
            }]}
        """
        try parser.parseResponse(json.data(using: .ascii)!)

        let originalPipeline = Pipeline(name: "erikdoe/quvyn:Rust", feedUrl: "http://test.org")
        let updatedPipeline = parser.updatePipeline(originalPipeline)

        guard let pipeline = updatedPipeline else {
            XCTFail("parser did not update pipeline")
            return
        }
        XCTAssertEqual("erikdoe/quvyn:Rust", pipeline.name)
        XCTAssertEqual("https://github.com/erikdoe/quvyn/actions/runs/842089420", pipeline.status.webUrl)
        XCTAssertEqual(.sleeping, pipeline.status.activity)

        guard let build = pipeline.status.lastBuild else {
            XCTFail("parser did not set lastBuild")
            return
        }
        XCTAssertEqual(BuildResult.success, build.result)
        XCTAssertEqual("17", build.label)
        let date = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone.init(abbreviation: "UTC"),
                                  year: 2021, month: 05, day: 14, hour: 12, minute: 04, second: 23, nanosecond: 0).date
        XCTAssertEqual(date, build.timestamp)
        XCTAssertEqual(154, build.duration)
        XCTAssertEqual("erikdoe", build.user)
        XCTAssertEqual("https://test.org/avatar.jpg", build.avatar?.absoluteString)
    }


}

