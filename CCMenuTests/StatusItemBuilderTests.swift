/*
 *  Copyright (c) 2007-2020 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class StatusItemBuilderTests: XCTestCase {

    func testCreatesItemForPipeline() throws {
        let builder = StatusItemBuilder()
        let menu = NSMenu()
        let p0 = Pipeline(
                name: "connectfour",
                feedUrl: "",
                status: Pipeline.Status(buildResult: .success, pipelineActivity: .sleeping)
        )

        builder.updateMenuWithPipelines(menu:menu, pipelines:[p0])

        XCTAssertEqual(1, menu.items.count)
        let item = menu.items[0]
        XCTAssertEqual("connectfour", item.title)
        XCTAssertEqual(ImageManager().image(forResult: .success, activity: .sleeping), item.image)
        XCTAssertEqual(#selector(AppDelegate.openPipeline(_:)), item.action)
        XCTAssertEqual(p0, item.representedObject as? Pipeline)
        XCTAssertEqual(NSUserInterfaceItemIdentifier("OpenPipeline:connectfour"), item.identifier)
    }

    func testCreatesItemInOrder() throws {
        let builder = StatusItemBuilder()
        let menu = NSMenu()
        let p0 = Pipeline(
                name: "connectfour",
                feedUrl: "",
                status: Pipeline.Status(buildResult: .success, pipelineActivity: .sleeping)
        )
        let p1 = Pipeline(
                name: "erikdoe/ccmenu",
                feedUrl: "",
                status: Pipeline.Status(buildResult: .success, pipelineActivity: .sleeping)
        )

        builder.updateMenuWithPipelines(menu:menu, pipelines:[p0, p1])

        XCTAssertEqual(2, menu.items.count)
        XCTAssertEqual("connectfour", menu.items[0].title)
        XCTAssertEqual("erikdoe/ccmenu", menu.items[1].title)
    }

}
