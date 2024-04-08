/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
import Hummingbird
@testable import CCMenu

final class ServerMonitorIntegrationTests: XCTestCase {

    var webapp: HBApplication!

    override func setUpWithError() throws {
        webapp = HBApplication(configuration: .init(address: .hostname("localhost", port: 8086), logLevel: .error))
        try webapp.start()
    }

    override func tearDownWithError() throws {
        webapp.stop()
    }
    

    func testShowsErrorWhenConnectionFails() async throws {
        webapp.stop()

        let model = PipelineModel()
        model.add(pipeline: Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:8086/cctray.xml", name: "connectfour")))
        
        let monitor = await ServerMonitor(model: model)
        await monitor.updateStatusIfPollTimeHasBeenReached()

        XCTAssertEqual("Could not connect to the server.", model.pipelines.first?.connectionError)
    }

    func testShowsErrorForHTTPError() async throws {
        let model = PipelineModel()
        model.add(pipeline: Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:8086/cctray.xml", name: "connectfour")))

        let monitor = await ServerMonitor(model: model)
        await monitor.updateStatusIfPollTimeHasBeenReached()

        XCTAssertEqual("not found", model.pipelines.first?.connectionError)
    }
    
    func testShowsErrorWhenFeedDoesntContainProject() async throws {
        webapp.router.get("/cctray.xml") { _ in """
            <Projects>
                <Project activity='Sleeping' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='other-project'></Project>
            </Projects>
        """}

        let model = PipelineModel()
        model.add(pipeline: Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:8086/cctray.xml", name: "connectfour")))
        
        let monitor = await ServerMonitor(model: model)
        await monitor.updateStatusIfPollTimeHasBeenReached()

        XCTAssertEqual("The server did not provide a status for this pipeline.", model.pipelines.first?.connectionError)
    }

    func testOnlyMakesOneRequestForProjectsInTheSameCCTrayFeed() async throws {
        var requestCounter = 0
        webapp.router.get("/cctray.xml") { _ in
            requestCounter += 1
            return """
            <Projects>
                <Project activity='Sleeping' lastBuildLabel='build.123' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='other-project'></Project>
                <Project activity='Sleeping' lastBuildLabel='build.888' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='connectfour'></Project>
            </Projects>
        """}

        let model = PipelineModel()
        model.add(pipeline: Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:8086/cctray.xml", name: "connectfour")))
        model.add(pipeline: Pipeline(name: "other-project", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:8086/cctray.xml", name: "other-project")))

        let monitor = await ServerMonitor(model: model)
        await monitor.updateStatusIfPollTimeHasBeenReached()

        XCTAssertEqual("build.888", model.pipelines.first(where: { $0.name == "connectfour" })?.status.lastBuild?.label)
        XCTAssertEqual("build.123", model.pipelines.first(where: { $0.name == "other-project" })?.status.lastBuild?.label)
        XCTAssertEqual(1, requestCounter)
    }
    
    func testMakesRequestsForCCTrayFeedsInParallel() async throws {
        var processingFirstRequest = false
        var sawProcessingFirstRequestInSecondRequest = false
        webapp.router.get("/1/cctray.xml") { _ in
            processingFirstRequest = true
            // TODO: It's crude to sleep but we can't use DispatchSemaphore in async method
            Thread.sleep(forTimeInterval: 1)
            processingFirstRequest = false
            return "<Projects></Projects>"
        }
        webapp.router.get("/2/cctray.xml") { _ in
            sawProcessingFirstRequestInSecondRequest = processingFirstRequest
            return "<Projects></Projects>"
        }

        let model = PipelineModel()
        model.add(pipeline: Pipeline(name: "connectfour-1", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:8086/1/cctray.xml", name: "connectfour")))
        model.add(pipeline: Pipeline(name: "connectfour-2", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:8086/2/cctray.xml", name: "connectfour")))

        let monitor = await ServerMonitor(model: model)
        await monitor.updateStatusIfPollTimeHasBeenReached()

        XCTAssertTrue(sawProcessingFirstRequestInSecondRequest)
    }


    func testDoesntPollWhenGitHubPipelineIsPaused() async throws {
        var requestCounter = 0
        webapp.router.get("/runs", options: .editResponse) { r -> String in
            requestCounter += 1
            r.response.status = .forbidden
            return "{ }"
        }

        let model = PipelineModel()
        var pipeline = Pipeline(name: "CCMenu2", feed: Pipeline.Feed(type: .github, url: "http://localhost:8086/runs"))
        pipeline.feed.pauseUntil = Int(Date(timeIntervalSinceNow: +600).timeIntervalSince1970)
        model.add(pipeline: pipeline)

        let monitor = await ServerMonitor(model: model)
        await monitor.updateStatusIfPollTimeHasBeenReached()

        XCTAssertEqual(0, requestCounter)
    }

    func testPollsAndClearsPausedOnGitHubPipelineIfPausedUntilIsInThePast() async throws {
        webapp.router.get("/runs") { _ in """
            { "workflow_runs": [{
                "display_title" : "Just testing",
                "run_number": 17,
                "status": "completed",
                "conclusion": "success",
                "created_at": "2021-05-14T12:04:23Z",
                "updated_at": "2021-05-14T12:06:57Z",
            }]}
        """}

        let model = PipelineModel()
        var pipeline = Pipeline(name: "CCMenu2", feed: Pipeline.Feed(type: .github, url: "http://localhost:8086/runs"))
        pipeline.feed.pauseUntil = Int(Date(timeIntervalSinceNow: -5).timeIntervalSince1970)
        model.add(pipeline: pipeline)

        let monitor = await ServerMonitor(model: model)
        await monitor.updateStatusIfPollTimeHasBeenReached()

        XCTAssertNil(model.pipelines.first?.feed.pauseUntil)
        XCTAssertEqual("17", model.pipelines.first?.status.lastBuild?.label)
    }

}
