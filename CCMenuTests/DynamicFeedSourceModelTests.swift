/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class DynamicFeedSourceModelTests: XCTestCase {

    override func setUp() {
        // Use transient defaults to avoid affecting real preferences
        // Create a fresh transient suite for each test
        let transient = UserDefaults(suiteName: "org.ccmenu.transient.test.\(UUID().uuidString)")!
        UserDefaults.active = transient
    }
    
    override func tearDown() {
        UserDefaults.active = UserDefaults.standard
    }
    
    func testStartsWithEmptySources() throws {
        let model = DynamicFeedSourceModel()
        XCTAssertTrue(model.sources.isEmpty)
    }
    
    func testAddSource() throws {
        let model = DynamicFeedSourceModel()
        let url = URL(string: "https://ci.example.com/cc.xml")!
        let source = DynamicFeedSource(url: url)
        
        model.add(source: source)
        
        XCTAssertEqual(1, model.sources.count)
        XCTAssertEqual(url, model.sources[0].url)
    }
    
    func testRemoveSource() throws {
        let model = DynamicFeedSourceModel()
        let url = URL(string: "https://ci.example.com/cc.xml")!
        let source = DynamicFeedSource(url: url)
        
        model.add(source: source)
        XCTAssertEqual(1, model.sources.count)
        
        model.remove(sourceId: source.id)
        XCTAssertEqual(0, model.sources.count)
    }
    
    func testUpdateSource() throws {
        let model = DynamicFeedSourceModel()
        let url = URL(string: "https://ci.example.com/cc.xml")!
        var source = DynamicFeedSource(url: url)
        
        model.add(source: source)
        XCTAssertTrue(model.sources[0].isEnabled)
        
        source.isEnabled = false
        model.update(source: source)
        
        XCTAssertFalse(model.sources[0].isEnabled)
    }
    
    func testPersistsSourcesToUserDefaults() throws {
        let model = DynamicFeedSourceModel()
        let url = URL(string: "https://ci.example.com/cc.xml")!
        let source = DynamicFeedSource(url: url)
        
        model.add(source: source)
        
        // Create a new model instance and verify it loads from defaults
        let model2 = DynamicFeedSourceModel()
        model2.loadFromUserDefaults()
        
        XCTAssertEqual(1, model2.sources.count)
        XCTAssertEqual(url, model2.sources[0].url)
    }
    
    func testDoesNotAddDuplicateSource() throws {
        let model = DynamicFeedSourceModel()
        let url = URL(string: "https://ci.example.com/cc.xml")!
        let source1 = DynamicFeedSource(url: url, id: "same-id")
        let source2 = DynamicFeedSource(url: url, id: "same-id")
        
        model.add(source: source1)
        model.add(source: source2)
        
        XCTAssertEqual(1, model.sources.count)
    }
    
    func testGetEnabledSources() throws {
        let model = DynamicFeedSourceModel()
        
        let url1 = URL(string: "https://example1.com/cc.xml")!
        var source1 = DynamicFeedSource(url: url1)
        source1.isEnabled = true
        
        let url2 = URL(string: "https://example2.com/cc.xml")!
        var source2 = DynamicFeedSource(url: url2)
        source2.isEnabled = false
        
        model.add(source: source1)
        model.add(source: source2)
        
        let enabledSources = model.enabledSources
        
        XCTAssertEqual(1, enabledSources.count)
        XCTAssertEqual(url1, enabledSources[0].url)
    }

}

