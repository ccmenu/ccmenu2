/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine
import os


class GitHubAPI {

    static var clientId: String {
        if let defaultsId = UserDefaults.active.string(forKey: "GitHubClientID") {
            return defaultsId
        }
        return "4eafcf49451c588fbeac"
    }

    // MARK: - user, repositories, workflows, and branches

    static func requestForUser(user: String, token: String?) -> URLRequest {
        let path = String(format: "/users/%@", user)
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, token: token)
    }

    static func requestForAllPublicRepositories(user: String, token: String?) -> URLRequest {
        let path = String(format: "/users/%@/repos", user)
        let queryParams = [
            "type": "all",
            "sort": "pushed",
            "per_page": "100",
        ];
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, params: queryParams, token: token)
    }

    static func requestForAllRepositories(org: String, token: String?) -> URLRequest {
        let path = String(format: "/orgs/%@/repos", org)
        let queryParams = [
            "type": "all",
            "sort": "pushed",
            "per_page": "100",
        ];
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, params: queryParams, token: token)
    }

    static func requestForAllPrivateRepositories(token: String) -> URLRequest {
        let path = String(format: "/user/repos")
        let queryParams = [
            "type": "private",
            "sort": "pushed",
            "per_page": "100",
        ];
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, params: queryParams, token: token)
    }

    static func requestForWorkflows(owner: String, repository: String, token: String?) -> URLRequest {
        let path = String(format: "/repos/%@/%@/actions/workflows", owner, repository)
        let queryParams = [
            "per_page": "100",
        ];
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, params: queryParams, token: token)
    }

    static func requestForBranches(owner: String, repository: String, token: String?) -> URLRequest {
        let path = String(format: "/repos/%@/%@/branches", owner, repository)
        let queryParams = [
            "per_page": "100",
        ];
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, params: queryParams, token: token)
    }


    // MARK: - device flow and applications

    static func requestForDeviceCode() -> URLRequest {
        let path = "/login/device/code"
        let queryParams = [
            "client_id": clientId,
            "scope": "repo",
        ];
        return makeRequest(method: "POST", baseUrl: baseURL(forAPI: false), path: path, params: queryParams)
    }

    static func requestForAccessToken(codeResponse: GitHubDeviceCodeResponse) -> URLRequest {
        let path = "/login/oauth/access_token"
        let queryParams = [
            "client_id": clientId,
            "device_code": codeResponse.deviceCode,
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
        ];
        return makeRequest(method: "POST", baseUrl: baseURL(forAPI: false), path: path, params: queryParams)
    }

    static func applicationsUrl() -> URL {
        baseURL(forAPI: false).appending(path: "/settings/connections/applications/\(GitHubAPI.clientId)")
    }


    // MARK: - personal access tokens

    static func personalAccessTokensUrl() -> URL {
        baseURL(forAPI: false).appending(path: "/settings/personal-access-tokens")
    }


    // MARK: - feed

    static func feedUrl(owner: String, repository: String, workflow: String, branch: String?) -> URL {
        // see https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28#list-workflow-runs-for-a-workflow
        var url = baseURL(forAPI: true).appending(path: "/repos/\(owner)/\(repository)/actions/workflows/\(workflow)/runs")
        if let branch {
            url = url.appending(queryItems: [URLQueryItem(name: "branch", value: branch)])
        }
        return url
    }

    static func requestForFeed(feed: PipelineFeed, token: String?) -> URLRequest? {
        let url = feed.url.appending(queryItems: [URLQueryItem(name: "per_page", value: "3")])
        return makeRequest(url: url, token: token)
    }


    // MARK: - send requests

    static func sendRequest<T>(request: URLRequest) async -> (T?, String) where T: Decodable {
        do {
            let (data, response) = try await URLSession.feedSession.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
            if response.statusCode == 403 || response.statusCode == 429 {
                if let v = response.value(forHTTPHeaderField: "x-ratelimit-remaining"), Int(v) == 0  {
                    // HTTPURLResponse doesn't have a specific message for code 429
                    return (nil, "too many requests")
                } else {
                    return (nil, HTTPURLResponse.localizedString(forStatusCode: response.statusCode))
                }
            }
            if response.statusCode != 200 {
                return (nil, HTTPURLResponse.localizedString(forStatusCode: response.statusCode))
            }
            return (try JSONDecoder().decode(T.self, from: data), "OK")
        } catch {
            return (nil, error.localizedDescription)
        }
    }

    static func sendRequest(request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
        if response.statusCode == 403 || response.statusCode == 429 {
            guard let v = response.value(forHTTPHeaderField: "x-ratelimit-remaining"), Int(v) == 0 else {
                throw GithHubFeedReaderError.httpError(response.statusCode)
            }
            guard let v = response.value(forHTTPHeaderField: "x-ratelimit-reset"), let pauseUntil = Int(v) else {
                throw GithHubFeedReaderError.httpError(response.statusCode)
            }
            throw GithHubFeedReaderError.rateLimitError(pauseUntil)
        }
        if response.statusCode != 200 {
            throw GithHubFeedReaderError.httpError(response.statusCode)
        }
        return data
    }


    // MARK: - helper functions

    private static func baseURL(forAPI: Bool) -> URL {
        var urlString = forAPI ? "https://api.github.com" : "https://github.com"
        let defaultsKey = forAPI ? "GitHubAPIBaseURL" : "GitHubBaseURL"
        if let defaultsBaseURL = UserDefaults.active.string(forKey: defaultsKey) {
            urlString = defaultsBaseURL
        }
        guard let url = URL(string: urlString) else { fatalError("Invalid base URL \(urlString)") }
        return url
    }

    private static func makeRequest(method: String = "GET", baseUrl: URL, path: String, params: Dictionary<String, String> = [:], token: String? = nil) -> URLRequest {
        let url = baseUrl.appending(path: path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = params.map({ URLQueryItem(name: $0.key, value: $0.value) })
        // TODO: Consider filtering token when the URL is overwritten via defaults
        return makeRequest(method: method, url: components.url!, token: token)
    }

    private static func makeRequest(method: String = "GET", url: URL, token: String?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        if let token, !token.isEmpty {
            request.setValue(URLRequest.bearerAuthValue(token: token), forHTTPHeaderField: "Authorization")
        }

        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
        logger.info("Request: \(method, privacy: .public) \(url.absoluteString, privacy: .public)")

        return request
    }

}
