/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class DynamicFeedSourceTests: XCTestCase {

    func testCreatesSourceWithURL() throws {
        let url = URL(string: "https://ci.example.com/cc.xml")!
        let source = DynamicFeedSource(url: url)
        
        XCTAssertEqual(url, source.url)
        XCTAssertTrue(source.isEnabled)
        XCTAssertTrue(source.removeDeletedPipelines)
    }
    
    func testSourceHasUniqueIdentifier() throws {
        let url = URL(string: "https://ci.example.com/cc.xml")!
        let source1 = DynamicFeedSource(url: url)
        let source2 = DynamicFeedSource(url: url)
        
        XCTAssertNotEqual(source1.id, source2.id)
    }
    
    func testSourceCanBeDisabled() throws {
        let url = URL(string: "https://ci.example.com/cc.xml")!
        var source = DynamicFeedSource(url: url)
        
        source.isEnabled = false
        
        XCTAssertFalse(source.isEnabled)
    }
    
    func testSourceCanBeConfiguredToNotRemoveDeletedPipelines() throws {
        let url = URL(string: "https://ci.example.com/cc.xml")!
        var source = DynamicFeedSource(url: url)
        
        source.removeDeletedPipelines = false
        
        XCTAssertFalse(source.removeDeletedPipelines)
    }
    
    func testSourceCanStoreCredential() throws {
        let url = URL(string: "https://user@ci.example.com/cc.xml")!
        let source = DynamicFeedSource(url: url)
        
        XCTAssertEqual("user", source.url.user())
    }
    
    func testSourceSerializesToDictionary() throws {
        let url = URL(string: "https://ci.example.com/cc.xml")!
        var source = DynamicFeedSource(url: url)
        source.isEnabled = false
        source.removeDeletedPipelines = false
        
        let dict = source.toDictionary()
        
        XCTAssertEqual(url.absoluteString, dict["url"])
        XCTAssertEqual("false", dict["isEnabled"])
        XCTAssertEqual("false", dict["removeDeletedPipelines"])
        XCTAssertNotNil(dict["id"])
    }
    
    func testSourceDeserializesFromDictionary() throws {
        let dict: [String: String] = [
            "id": "test-id-123",
            "url": "https://ci.example.com/cc.xml",
            "isEnabled": "true",
            "removeDeletedPipelines": "false"
        ]
        
        let source = DynamicFeedSource(dictionary: dict)
        
        XCTAssertNotNil(source)
        XCTAssertEqual("test-id-123", source!.id)
        XCTAssertEqual(URL(string: "https://ci.example.com/cc.xml"), source!.url)
        XCTAssertTrue(source!.isEnabled)
        XCTAssertFalse(source!.removeDeletedPipelines)
    }
    
    func testSourceDeserializationFailsWithInvalidURL() throws {
        let dict: [String: String] = [
            "id": "test-id-123",
            "url": "",
            "isEnabled": "true",
            "removeDeletedPipelines": "true"
        ]
        
        let source = DynamicFeedSource(dictionary: dict)
        
        XCTAssertNil(source)
    }
    
    func testSourceDeserializationFailsWithMissingFields() throws {
        let dict: [String: String] = [
            "url": "https://ci.example.com/cc.xml"
        ]
        
        let source = DynamicFeedSource(dictionary: dict)
        
        XCTAssertNil(source)
    }
    
    func testSourceTracksLastSyncTime() throws {
        let url = URL(string: "https://ci.example.com/cc.xml")!
        var source = DynamicFeedSource(url: url)
        
        XCTAssertNil(source.lastSyncTime)
        
        let syncTime = Date()
        source.lastSyncTime = syncTime
        
        XCTAssertEqual(syncTime, source.lastSyncTime)
    }
    
    func testSourceTracksLastSyncError() throws {
        let url = URL(string: "https://ci.example.com/cc.xml")!
        var source = DynamicFeedSource(url: url)
        
        XCTAssertNil(source.lastSyncError)
        
        source.lastSyncError = "Connection failed"
        
        XCTAssertEqual("Connection failed", source.lastSyncError)
    }

}

