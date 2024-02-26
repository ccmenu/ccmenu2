/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

enum CCTrayFeedReaderError: LocalizedError {
    case invalidURLError
    case missingPasswordError
    case httpError(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidURLError:
            return NSLocalizedString("invalid URL", comment: "")
        case .missingPasswordError:
            return NSLocalizedString("no matching password in Keychain", comment: "")
        case .httpError(let statusCode):
            return CCTrayAPI.localizedString(forStatusCode: statusCode)
        }
    }
}


class CCTrayFeedReader {

    private(set) var pipelines: [Pipeline]

    public init(for pipeline: Pipeline) {
        self.pipelines = [pipeline]
    }
    
    public func updatePipelineStatus() async {
        do {
            // All pipelines have the same URL.
            let request = try requestForFeed(feed: pipelines[0].feed)
            try await fetchStatus(request: request)
        } catch {
            // TODO: Add error to all pipelines
            pipelines[0].status = Pipeline.Status(activity: .other)
            pipelines[0].connectionError = error.localizedDescription
        }
    }

    func requestForFeed(feed: Pipeline.Feed) throws -> URLRequest {
        guard let url = URL(string: feed.url) else {
            throw CCTrayFeedReaderError.invalidURLError
        }
        var credential: HTTPCredential?
        if let user = url.user() {
            guard let password = try KeychainHelper().getPassword(forURL: url) else {
                throw CCTrayFeedReaderError.missingPasswordError
            }
            credential = HTTPCredential(user: user, password: password)
        }
        return CCTrayAPI.requestForProjects(url: url, credential: credential)
    }

    private func fetchStatus(request: URLRequest) async throws {
        let (data, response) = try await URLSession.feedSession.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.unsupportedURL)
        }
        guard response.statusCode == 200 else {
            throw CCTrayFeedReaderError.httpError(response.statusCode)
        }
        let parser = CCTrayResponseParser()
        try parser.parseResponse(data)
        for p in self.pipelines {
            let status = parser.pipelineStatus(name: p.feed.name ?? "") // TODO: Consider throwing an error
            self.updatePipeline(name: p.name, newStatus: status)
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
