/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

enum GithHubFeedReaderError: LocalizedError {
    case invalidURLError
    case httpError(Int)
    case noStatusError

    public var errorDescription: String? {
        switch self {
        case .invalidURLError:
            return NSLocalizedString("invalid URL", comment: "")
        case .httpError(let statusCode):
            return GitHubAPI.localizedString(forStatusCode: statusCode)
        case .noStatusError:
            return "No status available for this pipeline."
        }
    }
}


class GitHubFeedReader {

    private(set) var pipeline: Pipeline

    public init(for pipeline: Pipeline) {
        self.pipeline = pipeline
    }

    public func updatePipelineStatus() async {
        // TODO: consider making page size configurable to make sure to get a completed/successful
        do {
            let token = try KeychainHelper().getToken(forService: "GitHub")
            guard let request = GitHubAPI.requestForFeed(feed: pipeline.feed, token: token) else {
                throw GithHubFeedReaderError.invalidURLError
            }
            guard let newStatus = try await fetchStatus(request: request) else {
                throw GithHubFeedReaderError.noStatusError
            }
            pipeline.status = newStatus
            pipeline.connectionError = nil
        } catch {
            pipeline.status = Pipeline.Status(activity: .other)
            pipeline.connectionError = error.localizedDescription
        }
    }


    private func fetchStatus(request: URLRequest) async throws -> Pipeline.Status? {
        let (data, response) = try await URLSession.feedSession.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.unsupportedURL)
        }
        if let rll = response.allHeaderFields["x-ratelimit-limit"] as? String,
           let rlu = response.allHeaderFields["x-ratelimit-used"] as? String {
            debugPrint("received response from GitHub; rate limit \(rlu)/\(rll)")
        }
        guard response.statusCode == 200 else {
            // TODO: Do something here if the rate limit is exceeded
            throw GithHubFeedReaderError.httpError(response.statusCode)
        }
        let parser = GitHubResponseParser()
        try parser.parseResponse(data)
        let status = parser.pipelineStatus(name: pipeline.name)
        return status
    }

}
