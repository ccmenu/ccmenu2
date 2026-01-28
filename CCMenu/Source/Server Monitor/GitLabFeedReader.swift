/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation

enum GitLabFeedReaderError: LocalizedError {
    case invalidURLError
    case httpError(Int)
    case rateLimitError(Int)
    case noStatusError
    case noDetailsError

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
        case .noDetailsError:
            return "No details available for a run of this pipeline."
        }
    }
}


class GitLabFeedReader {

    private(set) var pipeline: Pipeline

    init(for pipeline: Pipeline) {
        self.pipeline = pipeline
    }

    // TODO: AI generated code - review
    func updatePipelineStatus() async {
        do {
            let token = try Keychain.standard.getToken(forService: "GitLab")
            guard let request = GitLabAPI.requestForFeed(feed: pipeline.feed, token: token) else {
                throw GitLabFeedReaderError.invalidURLError
            }
            guard let newStatus = try await fetchStatus(request: request) else {
                throw GitLabFeedReaderError.noStatusError
            }
            pipeline.status = newStatus
            pipeline.connectionError = nil
        } catch {
            if let error = error as? GitLabFeedReaderError, case .rateLimitError(let pauseUntil) = error {
                pipeline.feed.setPauseUntil(pauseUntil, reason: error.localizedDescription)
            } else {
                pipeline.status = PipelineStatus(activity: .other)
                pipeline.connectionError = error.localizedDescription
            }
        }
    }


    private func fetchStatus(request: URLRequest) async throws -> PipelineStatus? {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
        if response.statusCode == 403 || response.statusCode == 429 {
            guard let v = response.value(forHTTPHeaderField: "RateLimit-Remaining"), Int(v) == 0 else {
                throw GitLabFeedReaderError.httpError(response.statusCode)
            }
            guard let v = response.value(forHTTPHeaderField: "RateLimit-Reset"), let pauseUntil = Int(v) else {
                throw GitLabFeedReaderError.httpError(response.statusCode)
            }
            throw GitLabFeedReaderError.rateLimitError(pauseUntil)
        }
        if response.statusCode != 200 {
            throw GitLabFeedReaderError.httpError(response.statusCode)
        }
        let parser = GitLabResponseParser()
        try parser.parseResponse(data)
        return parser.pipelineStatus(name: pipeline.name)
    }


    func enrichPipelineCurrentBuild() async {
        do {
            let token = try Keychain.standard.getToken(forService: "GitLab")

            if let pid = pipeline.status.currentBuild?.id {
                guard let request = GitLabAPI.requestForDetail(feed: pipeline.feed, pipelineId: pid, token: token) else {
                    throw GitLabFeedReaderError.invalidURLError
                }
                guard let currentBuild = try await fetchBuild(request: request) else {
                    throw GitLabFeedReaderError.noStatusError
                }
                pipeline.status.currentBuild = currentBuild
            }
            pipeline.connectionError = nil
        } catch {
            if let error = error as? GitLabFeedReaderError, case .rateLimitError(let pauseUntil) = error {
                pipeline.feed.setPauseUntil(pauseUntil, reason: error.localizedDescription)
            } else {
                pipeline.status = PipelineStatus(activity: .other)
                pipeline.connectionError = error.localizedDescription
            }
        }
    }

    func enrichPipelineLastBuild() async {
        do {
            let token = try Keychain.standard.getToken(forService: "GitLab")

            if let pid = pipeline.status.lastBuild?.id {
                guard let request = GitLabAPI.requestForDetail(feed: pipeline.feed, pipelineId: pid, token: token) else {
                    throw GitLabFeedReaderError.invalidURLError
                }
                guard let lastBuild = try await fetchBuild(request: request) else {
                    throw GitLabFeedReaderError.noDetailsError
                }
                pipeline.status.lastBuild = lastBuild
            }
            pipeline.connectionError = nil
        } catch {
            if let error = error as? GitLabFeedReaderError, case .rateLimitError(let pauseUntil) = error {
                pipeline.feed.setPauseUntil(pauseUntil, reason: error.localizedDescription)
            } else {
                pipeline.status = PipelineStatus(activity: .other)
                pipeline.connectionError = error.localizedDescription
            }
        }
    }


    private func fetchBuild(request: URLRequest) async throws -> Build? {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
        if response.statusCode == 403 || response.statusCode == 429 {
            guard let v = response.value(forHTTPHeaderField: "RateLimit-Remaining"), Int(v) == 0 else {
                throw GitLabFeedReaderError.httpError(response.statusCode)
            }
            guard let v = response.value(forHTTPHeaderField: "RateLimit-Reset"), let pauseUntil = Int(v) else {
                throw GitLabFeedReaderError.httpError(response.statusCode)
            }
            throw GitLabFeedReaderError.rateLimitError(pauseUntil)
        }
        if response.statusCode != 200 {
            throw GitLabFeedReaderError.httpError(response.statusCode)
        }
        let parser = GitLabDetailResponseParser()
        try parser.parseResponse(data)
        return parser.build()
    }

}
