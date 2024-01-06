/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class GitHubResponseParserTests: XCTestCase {

    func testParsesJSON() throws {
        let json = "{ \"workflow_runs\": [ { \"name\": \"Rust\", \"conclusion\": \"success\" } ] }\n"
        let parser = GitHubResponseParser()

        try parser.parseResponse(json.data(using: .ascii)!)

        XCTAssertEqual(1, parser.runList.count)
        let run = parser.runList[0]
        XCTAssertEqual("Rust", run["name"] as? String)
    }

    func testThrowsForMalformedJSON() throws {
        let json = " \"workflow_runs\": [ { \"name\": \"Rust\" deliberately broken"
        let parser = GitHubResponseParser()

        XCTAssertThrowsError(try parser.parseResponse(json.data(using: .ascii)!))
    }

    func testPipelineStatusReflectsCompletedWorkflowRun() throws {
        let json = """
            { "workflow_runs": [{
                "display_title" : "Just testing",
                "run_number": 17,
                "event": "push",
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
        let parser = GitHubResponseParser()
        try parser.parseResponse(json.data(using: .ascii)!)

        let status = parser.pipelineStatus(name: "quvyn:rust.yml")!

        XCTAssertEqual(.sleeping, status.activity)
        XCTAssertEqual("https://github.com/erikdoe/quvyn/actions/runs/842089420", status.webUrl)
        guard let build = status.lastBuild else { XCTFail(); return }
        XCTAssertEqual(.success, build.result)
        XCTAssertEqual("17", build.label)
        XCTAssertEqual(ISO8601DateFormatter().date(from: "2021-05-14T12:04:23Z"), build.timestamp)
        XCTAssertEqual(154, build.duration)
        XCTAssertEqual("Push \u{22EE} Just testing", build.message)
        XCTAssertEqual("erikdoe", build.user)
        XCTAssertEqual("https://test.org/avatar.jpg", build.avatar?.absoluteString)
        XCTAssertNil(status.currentBuild)
   }

    func testPipelineStatusReflectsInProgressWorkflowRunWithCompletedAlsoAvailable() throws {
        let json = """
            { "workflow_runs": [{
                "display_title" : "Merge this",
                "run_number": 18,
                "event": "pull_request",
                "status": "in_progress",
                "conclusion": null,
                "html_url": "https://github.com/erikdoe/quvyn/actions/runs/991157472",
                "created_at": "2021-07-01T18:42:17Z",
                "updated_at": "2021-07-01T18:44:54Z",
                "actor": {
                    "login": "erikdoe",
                    "avatar_url": "https://test.org/avatar.jpg"
                }
              }, {
                "name": "Rust",
                "display_title" : "Just testing",
                "run_number": 17,
                "event": "push",
                "status": "completed",
                "conclusion": "success",
                "html_url": "https://github.com/erikdoe/quvyn/actions/runs/842089420",
                "created_at": "2021-05-14T12:04:23Z",
                "updated_at": "2021-05-14T12:06:57Z",
                "actor": {
                    "login": "erikdoe",
                    "avatar_url": "https://test.org/avatar.jpg"
                }
              }
            ]}
        """
        let parser = GitHubResponseParser()
        try parser.parseResponse(json.data(using: .ascii)!)

        let status = parser.pipelineStatus(name: "quvyn:Rust")!

        XCTAssertEqual(.building, status.activity)
        XCTAssertEqual("https://github.com/erikdoe/quvyn/actions/runs/991157472", status.webUrl)

        guard let current = status.currentBuild else { XCTFail(); return }
        XCTAssertEqual(.unknown, current.result)
        XCTAssertEqual("18", current.label)
        XCTAssertEqual(ISO8601DateFormatter().date(from: "2021-07-01T18:42:17Z"), current.timestamp)
        XCTAssertEqual(157, current.duration)
        XCTAssertEqual("Pull Request \u{22EE} Merge this", current.message)
        XCTAssertEqual("erikdoe", current.user)
        XCTAssertEqual("https://test.org/avatar.jpg", current.avatar?.absoluteString)

        guard let last = status.lastBuild else { XCTFail(); return }
        XCTAssertEqual(.success, last.result)
        XCTAssertEqual("17", last.label)
        XCTAssertEqual(ISO8601DateFormatter().date(from: "2021-05-14T12:04:23Z"), last.timestamp)
        XCTAssertEqual(154, last.duration)
        XCTAssertEqual("Push \u{22EE} Just testing", last.message)
        XCTAssertEqual("erikdoe", last.user)
        XCTAssertEqual("https://test.org/avatar.jpg", last.avatar?.absoluteString)
   }

}

