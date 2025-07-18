/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine
import os


class GitLabAPI {

    // TODO: AI generated code - review
    static var clientId: String {
        if let defaultsId = UserDefaults.active.string(forKey: "GitLabClientID") {
            return defaultsId
        }
        return "" // Default client ID should be configured
    }

    // MARK: - user, projects, pipelines, and branches

    // TODO: AI generated code - review
    static func requestForUser(token: String) -> URLRequest {
        let path = "/user"
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, token: token)
    }

    // TODO: AI generated code - review
   static func requestForAllProjects(token: String?) -> URLRequest {
        let path = "/projects"
        let queryParams = [
            "membership": "true",
            "order_by": "last_activity_at",
            "per_page": "100",
        ];
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, params: queryParams, token: token)
    }

    // TODO: AI generated code - review
    static func requestForGroupProjects(group: String, token: String?) -> URLRequest {
        let path = String(format: "/groups/%@/projects", group)
        let queryParams = [
            "order_by": "last_activity_at",
            "per_page": "100",
        ];
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, params: queryParams, token: token)
    }

    // TODO: AI generated code - review
    static func requestForUserProjects(user: String, token: String?) -> URLRequest {
        let path = String(format: "/users/%@/projects", user)
        let queryParams = [
            "order_by": "last_activity_at",
            "per_page": "100",
        ];
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, params: queryParams, token: token)
    }

    // TODO: AI generated code - review
    static func requestForPipelines(projectId: String, token: String?) -> URLRequest {
        let path = String(format: "/projects/%@/pipelines", projectId)
        let queryParams = [
            "per_page": "100",
        ];
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, params: queryParams, token: token)
    }

    // TODO: AI generated code - review
    static func requestForBranches(projectId: String, token: String?) -> URLRequest {
        let path = String(format: "/projects/%@/repository/branches", projectId)
        let queryParams = [
            "per_page": "100",
        ];
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, params: queryParams, token: token)
    }


    // MARK: - device flow and applications

    // TODO: AI generated code - review
    static func requestForAccessToken(code: String, redirectUri: String) -> URLRequest {
        let path = "/oauth/token"
        let queryParams = [
            "client_id": clientId,
            "client_secret": "", // Client secret should be configured
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUri
        ];
        return makeRequest(method: "POST", baseUrl: baseURL(forAPI: false), path: path, params: queryParams)
    }

    // TODO: AI generated code - review
    static func applicationsUrl() -> URL {
        baseURL(forAPI: false).appending(path: "/profile/applications")
    }


    // MARK: - feed

    static func feedUrl(projectId: String, branch: String?) -> URL {
        let url = baseURL(forAPI: true).appending(path: "/projects/\(projectId)/pipelines")
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        if let branch {
            components.appendQueryItem(URLQueryItem(name: "ref", value: branch))
        }
        return components.url!.absoluteURL
    }

    static func requestForFeed(feed: PipelineFeed, token: String?) -> URLRequest? {
        guard var components = URLComponents(url: feed.url, resolvingAgainstBaseURL: true) else { return nil }
        components.appendQueryItem(URLQueryItem(name: "per_page", value: "3"))
        return makeRequest(url: components.url!.absoluteURL, token: token)
    }

    static func requestForDetail(feed: PipelineFeed, pipelineId: String, token: String?) -> URLRequest? {
        // TODO: double check that this works with query params (for branches)
        let url = feed.url.appendingPathComponent(pipelineId)
        return makeRequest(url: url, token: token)
    }


    // MARK: - send requests

    static func sendRequest<T>(request: URLRequest) async -> (T?, String) where T: Decodable {
        do {
            let (data, response) = try await URLSession.feedSession.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
            if response.statusCode == 403 || response.statusCode == 429 {
                if let v = response.value(forHTTPHeaderField: "RateLimit-Remaining"), Int(v) == 0  {
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



    // MARK: - helper functions

    private static func baseURL(forAPI: Bool) -> URL {
        var urlString = forAPI ? "https://gitlab.com/api/v4" : "https://gitlab.com"
        let defaultsKey = forAPI ? "GitLabAPIBaseURL" : "GitLabBaseURL"
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
        return makeRequest(method: method, url: components.url!, token: token)
    }

    private static func makeRequest(method: String = "GET", url: URL, token: String?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        // TODO: AI generated code - review
        if let token, !token.isEmpty {
            request.setValue(URLRequest.bearerAuthValue(token: token), forHTTPHeaderField: "Authorization")
        }

        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
        logger.trace("Request: \(method, privacy: .public) \(url.absoluteString, privacy: .public)")

        return request
    }

}
