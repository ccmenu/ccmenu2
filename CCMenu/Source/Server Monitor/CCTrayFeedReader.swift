/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

class CCTrayFeedReader {

    private(set) var pipelines: [Pipeline]

    public init(for pipeline: Pipeline) {
        self.pipelines = [pipeline]
    }
    
    public func updatePipelineStatus() async {
        // All pipelines have the same URL.
        guard let request = requestForFeed(feed: pipelines[0].feed) else {
            // TODO: Add error to all pipelines
            pipelines[0].connectionError = "Invalid URL: " + pipelines[0].feed.url
            return
        }
        await fetchStatus(request: request)
    }

    func requestForFeed(feed: Pipeline.Feed) -> URLRequest? {
        guard let url = URL(string: feed.url) else {
            return nil
        }
        let request = URLRequest(url: url)
        return request
    }

    private func fetchStatus(request: URLRequest) async {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw URLError(.unsupportedURL)
            }
            guard response.statusCode == 200 else {
                let httpError = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                pipelines[0].connectionError = httpError
                return
            }
            let parser = CCTrayResponseParser()
            try parser.parseResponse(data)
            for p in self.pipelines {
                let status = parser.pipelineStatus(name: p.feed.name ?? "") // TODO: report an error? here?
                self.updatePipeline(name: p.name, newStatus: status)
            }
        } catch {
            pipelines[0].connectionError = error.localizedDescription
        }
    }

    func updatePipeline(name: String, newStatus: Pipeline.Status?) {
        guard let idx = pipelines.firstIndex(where: { p in p.name == name }) else {
            debugPrint("Attempt to update pipeline '\(name)', which reader for '\(pipelines[0].feed.url)' does not monitor.")
            return
        }
        var pipeline = pipelines[idx]
        guard let newStatus = newStatus else {
            pipeline.connectionError = "The server did not provide a status for this pipeline."
            pipelines[idx] = pipeline
            return
        }
        pipeline.connectionError = nil

        let oldStatus = pipeline.status
        pipeline.status = newStatus
        pipeline.status.currentBuild?.timestamp = oldStatus.currentBuild?.timestamp
        pipeline.status.lastBuild?.duration = oldStatus.lastBuild?.duration

        if oldStatus.activity != .building && newStatus.activity == .building {
            pipeline.status.currentBuild?.timestamp = Date.now
        }
        if oldStatus.activity == .building && newStatus.activity != .building {
            if let timestamp = oldStatus.currentBuild?.timestamp {
                pipeline.status.lastBuild?.duration = DateInterval(start: timestamp, end: Date.now).duration
            }
        }
        pipelines[idx] = pipeline
    }

}
