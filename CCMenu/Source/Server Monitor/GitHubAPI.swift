/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine


class GitHubAPI {
    
    static let clientId = "4eafcf49451c588fbeac"

    // MARK: - repositories, workflows, and branches

    static func requestForRepositories(owner: String, token: String?) -> URLRequest {
        let path = String(format: "/users/%@/repos", owner)
        let queryParams = [
            "type": "all",
            "sort": "pushed",
            "per_page": "100",
        ];
        return makeRequest(baseUrl: baseURL(forAPI: true), path: path, params: queryParams, token: token)
    }

    static func requestForPrivateRepositories(token: String) -> URLRequest {
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
        URL(string: "\(baseURL(forAPI: false))/settings/connections/applications/\(GitHubAPI.clientId)")!
    }


    // MARK: - feed

    static func feedUrl(owner: String, repository: String, workflow: String, branch: String?) -> URL {
        var components = URLComponents(string: baseURL(forAPI: true))!
        components.path = String(format: "/repos/%@/%@/actions/workflows/%@/runs", owner, repository, workflow)
        if let branch {
            components.appendQueryItem(URLQueryItem(name: "branch", value: branch))
        }
        return components.url!.absoluteURL
    }

    static func requestForFeed(feed: Pipeline.Feed, token: String?) -> URLRequest? {
        guard var components = URLComponents(url: feed.url, resolvingAgainstBaseURL: false) else { return nil }
        components.appendQueryItem(URLQueryItem(name: "per_page", value: "3"))
        return makeRequest(url: components.url!.absoluteURL, token: token)
    }


    // MARK: - helper functions

    private static func baseURL(forAPI: Bool) -> String {
        if let defaultsBaseURL = UserDefaults.active.string(forKey: "GitHubBaseURL") {
            return defaultsBaseURL
        }
        return forAPI ? "https://api.github.com" : "https://github.com"
    }

    private static func makeRequest(method: String = "GET", baseUrl: String, path: String, params: Dictionary<String, String>, token: String? = nil) -> URLRequest {
        var components = URLComponents(string: baseUrl)!
        components.path = path
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
        return request
    }

}
