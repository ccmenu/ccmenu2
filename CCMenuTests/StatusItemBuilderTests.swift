/*
 *  Copyright (c) 2007-2021 ThoughtWorks Inc.
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class StatusItemBuilderTests: XCTestCase {

    func testCreatesItemForPipeline() throws {
        let builder = StatusItemBuilder()
        let menu = NSMenu()
        var p0 = Pipeline(name: "connectfour", feedUrl: "")
        p0.activity = .sleeping
        p0.lastBuild = Build(result: .success)

        builder.updateMenu(menu:menu, pipelines:[p0])

        XCTAssertEqual(1, menu.items.count)
        let item = menu.items[0]
        XCTAssertEqual("connectfour", item.title)
        XCTAssertEqual(ImageManager().image(forResult: .success, activity: .sleeping), item.image)
        XCTAssertEqual(#selector(AppDelegate.openPipeline(_:)), item.action)
        XCTAssertEqual(p0, item.representedObject as? Pipeline)
        XCTAssertEqual(NSUserInterfaceItemIdentifier("OpenPipeline:connectfour"), item.identifier)
    }

    func testCreatesItemsInOrder() throws {
        let builder = StatusItemBuilder()
        let menu = NSMenu()
        let p0 = Pipeline(name: "connectfour", feedUrl: "")
        let p1 = Pipeline(name: "erikdoe/ccmenu", feedUrl: "")

        builder.updateMenu(menu:menu, pipelines:[p0, p1])

        XCTAssertEqual(2, menu.items.count)
        XCTAssertEqual("connectfour", menu.items[0].title)
        XCTAssertEqual("erikdoe/ccmenu", menu.items[1].title)
    }
    
    func testOnlyCreatesNewItems() throws {
        let builder = StatusItemBuilder()
        let menu = NSMenu()
        let p0 = Pipeline(name: "connectfour", feedUrl: "")
        let p1 = Pipeline(name: "erikdoe/ccmenu", feedUrl: "")

        builder.updateMenu(menu:menu, pipelines:[p1])
        builder.updateMenu(menu:menu, pipelines:[p0, p1])

        XCTAssertEqual(2, menu.items.count)
        XCTAssertEqual("connectfour", menu.items[0].title)
        XCTAssertEqual("erikdoe/ccmenu", menu.items[1].title)
    }

}

