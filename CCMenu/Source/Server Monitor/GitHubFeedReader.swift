/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

enum GithHubFeedReaderError: LocalizedError {
    case invalidURLError
    case httpError(Int)
    case rateLimitError(Int)
    case noStatusError

    var errorDescription: String? {
        switch self {
        case .invalidURLError:
            return NSLocalizedString("invalid URL", comment: "")
        case .httpError(let statusCode):
            return HTTPURLResponse.localizedString(forStatusCode: statusCode)
        case .rateLimitError(let timestamp):
            let date = Date(timeIntervalSince1970: Double(timestamp)).formatted(date: .omitted, time: .shortened)
            return String(format: NSLocalizedString("Rate limit exceeded, next update at %@.", comment: ""), date)
        case .noStatusError:
            return "No status available for this pipeline."
        }
    }
}


class GitHubFeedReader {

    private(set) var pipeline: Pipeline

    init(for pipeline: Pipeline) {
        self.pipeline = pipeline
    }

    func updatePipelineStatus() async {
        do {
            let token = try Keychain.standard.getToken(forService: "GitHub")
            guard let request = GitHubAPI.requestForFeed(feed: pipeline.feed, token: token) else {
                throw GithHubFeedReaderError.invalidURLError
            }
            guard let newStatus = try await fetchStatus(request: request) else {
                throw GithHubFeedReaderError.noStatusError
            }
            pipeline.status = newStatus
            pipeline.connectionError = nil
        } catch {
            if let error = error as? GithHubFeedReaderError, case .rateLimitError(let pauseUntil) = error {
                pipeline.feed.setPauseUntil(pauseUntil, reason: error.localizedDescription)
            } else {
                pipeline.status = PipelineStatus(activity: .other)
                pipeline.connectionError = error.localizedDescription
            }
        }
    }


    private func fetchStatus(request: URLRequest) async throws -> PipelineStatus? {
        let data = try await GitHubAPI.sendRequest(request: request)
        let parser = GitHubResponseParser()
        try parser.parseResponse(data)
        return parser.pipelineStatus(name: pipeline.name)
    }

}
