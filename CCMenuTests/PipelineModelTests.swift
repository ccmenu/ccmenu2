/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class PipelineModelTests: XCTestCase {

    func testDoesntAddPipelineIfItsInTheModelAlready() throws {
        let model = PipelineModel()

        let p0 = Pipeline(name: "foo", feed: Pipeline.Feed(type: .cctray, url: "http://localhost/cctray.xml", name: "foo"))
        model.add(pipeline: p0)
        XCTAssertEqual(1, model.pipelines.count)

        let p1 = Pipeline(name: "foo", feed: Pipeline.Feed(type: .cctray, url: "http://localhost/cctray.xml", name: "foo"))
        let success = model.add(pipeline: p1)
        
        XCTAssert(!success)
        XCTAssertEqual(1, model.pipelines.count)
    }
    
    func testDoesntAddPipelineIfItsInTheModelAlreadyEvenIfDisplayNameDiffers() throws {
        let model = PipelineModel()

        let p0 = Pipeline(name: "foo", feed: Pipeline.Feed(type: .cctray, url: "http://localhost/cctray.xml", name: "foo"))
        model.add(pipeline: p0)
        XCTAssertEqual(1, model.pipelines.count)

        let p1 = Pipeline(name: "foo2", feed: Pipeline.Feed(type: .cctray, url: "http://localhost/cctray.xml", name: "foo"))
        let success = model.add(pipeline: p1)

        XCTAssert(!success)
        XCTAssertEqual(1, model.pipelines.count)
    }
    
    func testAddsPipelineIfAnotherPipelineWithTheSameUrlButDifferentNameIsInTheModel() throws {
        let model = PipelineModel()

        let p0 = Pipeline(name: "foo", feed: Pipeline.Feed(type: .cctray, url: "http://localhost/cctray.xml", name: "foo"))
        model.add(pipeline: p0)
        XCTAssertEqual(1, model.pipelines.count)

        let p1 = Pipeline(name: "bar", feed: Pipeline.Feed(type: .cctray, url: "http://localhost/cctray.xml", name: "bar"))
        let success = model.add(pipeline: p1)
        
        XCTAssert(success)
        XCTAssertEqual(2, model.pipelines.count)
    }

    func testSetsStatusChangeWhenPipelineStatusChanged() throws {
        let model = PipelineModel()
        var p = Pipeline(name: "foo", feed: Pipeline.Feed(type: .cctray, url: "http://localhost/cctray.xml", name: "foo"))
        p.status = Pipeline.Status(activity: .building)
        model.add(pipeline: p)
        XCTAssertNil(model.lastStatusChange)

        p.status = Pipeline.Status(activity: .sleeping)
        model.update(pipeline: p)
        let change = model.lastStatusChange

        XCTAssertNotNil(change)
        XCTAssertEqual(p, change?.pipeline)
        XCTAssertEqual(.completion, change?.kind)
    }

    func testDoesNotSetStatusChangeWhenPipelineStatusIsNotChanged() throws {
        let model = PipelineModel()
        var p = Pipeline(name: "foo", feed: Pipeline.Feed(type: .cctray, url: "http://localhost/cctray.xml", name: "foo"))
        p.status = Pipeline.Status(activity: .building)
        model.add(pipeline: p)
        XCTAssertNil(model.lastStatusChange)

        p.status = Pipeline.Status(activity: .building)
        model.update(pipeline: p)
        let change = model.lastStatusChange

        XCTAssertNil(change)
    }

}

