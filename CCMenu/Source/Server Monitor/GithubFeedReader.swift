/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation


class GithubFeedReader {

    private(set) var pipeline: Pipeline

    public init(for pipeline: Pipeline) {
        self.pipeline = pipeline
    }

    public func updatePipelineStatus() async {
        // TODO: consider making page size configurable to make sure to get a completed/successful
        guard let request = GitHubAPI.requestForFeed(feed: pipeline.feed, pageSize: 5) else {
            pipeline.connectionError = "Invalid URL: " + pipeline.feed.url
            return
        }
        let (newStatus, error) = await fetchStatus(request: request)

        // TODO: Find out whether this pattern (also in the sheet lists) can be done with a switch.
        if let error = error {
            pipeline.connectionError = error
            return
        }
        guard let newStatus = newStatus else {
            pipeline.connectionError = "The server did not provide a status for this pipeline."
            return
        }
        pipeline.connectionError = nil
        pipeline.status = newStatus
    }


    private func fetchStatus(request: URLRequest) async -> (Pipeline.Status?, String?) {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw URLError(.unsupportedURL)
            }
            if let rll = response.allHeaderFields["x-ratelimit-limit"] as? String,
               let rlu = response.allHeaderFields["x-ratelimit-used"] as? String {
                debugPrint("received response from Github; rate limit \(rlu)/\(rll)")
            } else {
                debugPrint("received response from Github")
            }
            guard response.statusCode == 200 else {
                let httpError = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                return (nil, httpError)
            }
            let parser = GithubResponseParser()
            try parser.parseResponse(data)
            let status = parser.pipelineStatus(name: pipeline.name)
            return (status, nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }

}
