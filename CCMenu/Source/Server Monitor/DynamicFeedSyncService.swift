/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

struct SyncActions {
    let toAdd: [Pipeline]
    let toRemove: [Pipeline]
}

class DynamicFeedSyncService {
    
    func createPipelines(from projectList: [[String: String]], source: DynamicFeedSource) -> [Pipeline] {
        return projectList.compactMap { project -> Pipeline? in
            guard let name = project["name"] else { return nil }
            let feed = PipelineFeed(type: .cctray, url: source.url, name: name)
            var pipeline = Pipeline(name: name, feed: feed)
            pipeline.status = PipelineStatus(activity: .sleeping)
            pipeline.status.lastBuild = Build(result: .unknown)
            pipeline.managedBySourceId = source.id
            return pipeline
        }
    }
    
    func calculateSyncActions(
        existing: [Pipeline],
        remote: [Pipeline],
        source: DynamicFeedSource
    ) -> SyncActions {
        // If source is disabled, do nothing
        guard source.isEnabled else {
            return SyncActions(toAdd: [], toRemove: [])
        }
        
        // Find pipelines to add (in remote but not in existing)
        let existingIds = Set(existing.map { $0.id })
        let toAdd = remote.filter { !existingIds.contains($0.id) }
        
        // Find pipelines to remove (in existing but not in remote, only if managed by this source)
        var toRemove: [Pipeline] = []
        if source.removeDeletedPipelines {
            let remoteIds = Set(remote.map { $0.id })
            toRemove = existing.filter { pipeline in
                // Only remove pipelines that are managed by this source
                pipeline.managedBySourceId == source.id && !remoteIds.contains(pipeline.id)
            }
        }
        
        return SyncActions(toAdd: toAdd, toRemove: toRemove)
    }
    
    func fetchProjects(from source: DynamicFeedSource, credential: HTTPCredential? = nil) async throws -> [[String: String]] {
        var actualCredential = credential
        if actualCredential == nil, let user = source.url.user(percentEncoded: false) {
            if let password = try Keychain.standard.getPassword(forURL: source.url) {
                actualCredential = HTTPCredential(user: user, password: password)
            }
        }
        
        let request = CCTrayAPI.requestForProjects(url: source.url, credential: actualCredential)
        let (data, response) = try await URLSession.feedSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.unsupportedURL)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(
                domain: "DynamicFeedSyncService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)]
            )
        }
        
        let parser = CCTrayResponseParser()
        try parser.parseResponse(data)
        return parser.projectList
    }
    
    @MainActor
    func syncPipelines(
        source: inout DynamicFeedSource,
        model: PipelineModel,
        credential: HTTPCredential? = nil
    ) async {
        do {
            let projectList = try await fetchProjects(from: source, credential: credential)
            let remotePipelines = createPipelines(from: projectList, source: source)
            
            let actions = calculateSyncActions(
                existing: model.pipelines,
                remote: remotePipelines,
                source: source
            )
            
            // Add new pipelines
            for pipeline in actions.toAdd {
                model.add(pipeline: pipeline)
            }
            
            // Remove deleted pipelines
            for pipeline in actions.toRemove {
                model.remove(pipelineId: pipeline.id)
            }
            
            source.lastSyncTime = Date()
            source.lastSyncError = nil
        } catch {
            source.lastSyncError = error.localizedDescription
        }
    }
    
}

