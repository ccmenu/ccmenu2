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
    

    func testDoesntPollWhenPipelineIsPaused() async throws {
        var requestCounter = 0
        webapp.router.get("/runs", options: .editResponse) { r -> String in
            requestCounter += 1
            r.response.status = .forbidden
            return "{ }"
        }

        let model = PipelineModel()
        var pipeline = Pipeline(name: "CCMenu2", feed: Pipeline.Feed(type: .github, url: "http://localhost:8086/runs", name: nil))
        pipeline.feed.pauseUntil = Int(Date(timeIntervalSinceNow: +600).timeIntervalSince1970)
        model.add(pipeline: pipeline)

        let monitor = await ServerMonitor(model: model)
        await monitor.updateStatus(pipelines: model.pipelines)

        XCTAssertEqual(0, requestCounter)
    }
    
    func testPollsAndClearsPausedIfPausedUntilIsInThePast() async throws {
        webapp.router.get("/cctray.xml") { _ in """
            <Projects>
                <Project activity='Sleeping' lastBuildLabel='build.888' lastBuildStatus='Success' lastBuildTime='2024-02-11T23:19:26+01:00' name='connectfour'></Project>
            </Projects>
        """}

        let model = PipelineModel()
        var pipeline = Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:8086/cctray.xml", name: "connectfour"))
        pipeline.feed.pauseUntil = Int(Date(timeIntervalSinceNow: -5).timeIntervalSince1970)
        model.add(pipeline: pipeline)
        
        let monitor = await ServerMonitor(model: model)
        await monitor.updateStatus(pipelines: model.pipelines)
    
        XCTAssertNil(model.pipelines.first?.feed.pauseUntil)
        XCTAssertEqual("build.888", model.pipelines.first?.status.lastBuild?.label)
    }
    
    func testShowsErrorWhenConnectionFails() async throws {
        webapp.stop()

        let model = PipelineModel()
        model.add(pipeline: Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:8086/cctray.xml", name: "connectfour")))
        
        let monitor = await ServerMonitor(model: model)
        await monitor.updateStatus(pipelines: model.pipelines)
    
        XCTAssertEqual("Could not connect to the server.", model.pipelines.first?.connectionError)
    }

    func testShowsErrorForHTTPError() async throws {
        let model = PipelineModel()
        model.add(pipeline: Pipeline(name: "connectfour", feed: Pipeline.Feed(type: .cctray, url: "http://localhost:8086/cctray.xml", name: "connectfour")))

        let monitor = await ServerMonitor(model: model)
        await monitor.updateStatus(pipelines: model.pipelines)

        XCTAssertEqual("The server responded: not found", model.pipelines.first?.connectionError)
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
        await monitor.updateStatus(pipelines: model.pipelines)
    
        XCTAssertEqual("The server did not provide a status for this pipeline.", model.pipelines.first?.connectionError)
    }

}
