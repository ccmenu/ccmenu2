/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import XCTest
@testable import CCMenu

class DynamicFeedSyncServiceTests: XCTestCase {

    static let feedURL = URL(string: "https://ci.example.com/cc.xml")!
    
    private func makeTestParser(withProjects projects: [String]) -> CCTrayResponseParser {
        let parser = CCTrayResponseParser()
        var xml = "<Projects>"
        for name in projects {
            xml += "<Project name='\(name)' activity='Sleeping' lastBuildStatus='Success'/>"
        }
        xml += "</Projects>"
        try! parser.parseResponse(xml.data(using: .utf8)!)
        return parser
    }

    // MARK: - Pipeline Creation Tests
    
    func testCreatesPipelinesFromProjectList() throws {
        let service = DynamicFeedSyncService()
        let source = DynamicFeedSource(url: Self.feedURL)
        let parser = makeTestParser(withProjects: ["project1", "project2", "project3"])
        
        let pipelines = service.createPipelines(from: parser.projectList, source: source)
        
        XCTAssertEqual(3, pipelines.count)
        XCTAssertEqual("project1", pipelines[0].name)
        XCTAssertEqual("project2", pipelines[1].name)
        XCTAssertEqual("project3", pipelines[2].name)
    }
    
    func testCreatedPipelinesHaveCorrectFeedType() throws {
        let service = DynamicFeedSyncService()
        let source = DynamicFeedSource(url: Self.feedURL)
        let parser = makeTestParser(withProjects: ["project1"])
        
        let pipelines = service.createPipelines(from: parser.projectList, source: source)
        
        XCTAssertEqual(.cctray, pipelines[0].feed.type)
        XCTAssertEqual(Self.feedURL, pipelines[0].feed.url)
        XCTAssertEqual("project1", pipelines[0].feed.name)
    }
    
    func testCreatedPipelinesAreManagedBySource() throws {
        let service = DynamicFeedSyncService()
        let source = DynamicFeedSource(url: Self.feedURL)
        let parser = makeTestParser(withProjects: ["project1"])
        
        let pipelines = service.createPipelines(from: parser.projectList, source: source)
        
        XCTAssertEqual(source.id, pipelines[0].managedBySourceId)
    }
    
    // MARK: - Sync Logic Tests
    
    func testIdentifiesNewPipelines() throws {
        let service = DynamicFeedSyncService()
        let source = DynamicFeedSource(url: Self.feedURL)
        
        let existingPipelines: [Pipeline] = []
        let parser = makeTestParser(withProjects: ["project1", "project2"])
        let remotePipelines = service.createPipelines(from: parser.projectList, source: source)
        
        let result = service.calculateSyncActions(
            existing: existingPipelines,
            remote: remotePipelines,
            source: source
        )
        
        XCTAssertEqual(2, result.toAdd.count)
        XCTAssertEqual(0, result.toRemove.count)
    }
    
    func testIdentifiesPipelinesToRemove() throws {
        let service = DynamicFeedSyncService()
        var source = DynamicFeedSource(url: Self.feedURL)
        source.removeDeletedPipelines = true
        
        var existingPipeline = Pipeline(name: "oldProject", feed: PipelineFeed(type: .cctray, url: Self.feedURL, name: "oldProject"))
        existingPipeline.managedBySourceId = source.id
        
        let parser = makeTestParser(withProjects: ["project1"])
        let remotePipelines = service.createPipelines(from: parser.projectList, source: source)
        
        let result = service.calculateSyncActions(
            existing: [existingPipeline],
            remote: remotePipelines,
            source: source
        )
        
        XCTAssertEqual(1, result.toAdd.count)
        XCTAssertEqual(1, result.toRemove.count)
        XCTAssertEqual("oldProject", result.toRemove[0].name)
    }
    
    func testDoesNotRemovePipelinesWhenConfiguredNotTo() throws {
        let service = DynamicFeedSyncService()
        var source = DynamicFeedSource(url: Self.feedURL)
        source.removeDeletedPipelines = false
        
        var existingPipeline = Pipeline(name: "oldProject", feed: PipelineFeed(type: .cctray, url: Self.feedURL, name: "oldProject"))
        existingPipeline.managedBySourceId = source.id
        
        let parser = makeTestParser(withProjects: ["project1"])
        let remotePipelines = service.createPipelines(from: parser.projectList, source: source)
        
        let result = service.calculateSyncActions(
            existing: [existingPipeline],
            remote: remotePipelines,
            source: source
        )
        
        XCTAssertEqual(1, result.toAdd.count)
        XCTAssertEqual(0, result.toRemove.count)
    }
    
    func testDoesNotRemoveManuallyAddedPipelines() throws {
        let service = DynamicFeedSyncService()
        var source = DynamicFeedSource(url: Self.feedURL)
        source.removeDeletedPipelines = true
        
        // This pipeline was added manually (no managedBySourceId)
        let manualPipeline = Pipeline(name: "manualProject", feed: PipelineFeed(type: .cctray, url: Self.feedURL, name: "manualProject"))
        
        let parser = makeTestParser(withProjects: ["project1"])
        let remotePipelines = service.createPipelines(from: parser.projectList, source: source)
        
        let result = service.calculateSyncActions(
            existing: [manualPipeline],
            remote: remotePipelines,
            source: source
        )
        
        XCTAssertEqual(1, result.toAdd.count)
        XCTAssertEqual(0, result.toRemove.count)
    }
    
    func testDoesNotAddDuplicatePipelines() throws {
        let service = DynamicFeedSyncService()
        let source = DynamicFeedSource(url: Self.feedURL)
        
        var existingPipeline = Pipeline(name: "project1", feed: PipelineFeed(type: .cctray, url: Self.feedURL, name: "project1"))
        existingPipeline.managedBySourceId = source.id
        
        let parser = makeTestParser(withProjects: ["project1", "project2"])
        let remotePipelines = service.createPipelines(from: parser.projectList, source: source)
        
        let result = service.calculateSyncActions(
            existing: [existingPipeline],
            remote: remotePipelines,
            source: source
        )
        
        XCTAssertEqual(1, result.toAdd.count)
        XCTAssertEqual("project2", result.toAdd[0].name)
        XCTAssertEqual(0, result.toRemove.count)
    }
    
    func testSkipsDisabledSources() throws {
        let service = DynamicFeedSyncService()
        var source = DynamicFeedSource(url: Self.feedURL)
        source.isEnabled = false
        
        let parser = makeTestParser(withProjects: ["project1"])
        let remotePipelines = service.createPipelines(from: parser.projectList, source: source)
        
        let result = service.calculateSyncActions(
            existing: [],
            remote: remotePipelines,
            source: source
        )
        
        XCTAssertEqual(0, result.toAdd.count)
        XCTAssertEqual(0, result.toRemove.count)
    }

}

