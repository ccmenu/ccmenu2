/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine


class GitHubAPI {
    
    static let clientId = "4eafcf49451c588fbeac"

    // MARK: - repositories and workflows

    static func requestForRepositories(owner: String, token: String?) -> URLRequest {
        let path = String(format: "/users/%@/repos", owner)
        let queryParams = [
            "type": "all",
            "sort": "pushed",
            "per_page": "100",
        ];
        return makeRequest(path: path, params: queryParams, token: token)
    }

    static func requestForPrivateRepositories(token: String) -> URLRequest {
        let path = String(format: "/user/repos")
        let queryParams = [
            "type": "private",
            "sort": "pushed",
            "per_page": "100",
        ];
        return makeRequest(path: path, params: queryParams, token: token)
    }

    static func requestForWorkflows(owner: String, repository: String, token: String?) -> URLRequest {
        let path = String(format: "/repos/%@/%@/actions/workflows", owner, repository)
        let queryParams = [
            "sort": "pushed",
            "per_page": "100",
        ];
        return makeRequest(path: path, params: queryParams, token: token)
    }

    
    // MARK: - device flow and applications

    static func requestForDeviceCode() -> URLRequest {
        let path = "/login/device/code"
        let queryParams = [
            "client_id": clientId,
            "scope": "repo",
        ];
        return makeRequest(method: "POST", baseUrl: "https://github.com", path: path, params: queryParams)
    }

    static func requestForAccessToken(codeResponse: GitHubDeviceCodeResponse) -> URLRequest {
        let path = "/login/oauth/access_token"
        let queryParams = [
            "client_id": clientId,
            "device_code": codeResponse.deviceCode,
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
        ];
        return makeRequest(method: "POST", baseUrl: "https://github.com", path: path, params: queryParams)
    }

    static func applicationsUrl() -> URL {
        URL(string: "https://github.com/settings/connections/applications/\(GitHubAPI.clientId)")!
    }


    // MARK: - feed

    static func feedUrl(owner: String, repository: String, workflow: String) -> String {
        var components = URLComponents(string: "https://api.github.com")!
        components.path = String(format: "/repos/%@/%@/actions/workflows/%@/runs", owner, repository, workflow)
        return components.url!.absoluteString
    }

    static func requestForFeed(feed: Pipeline.Feed, pageSize: Int = 5) -> URLRequest? {
        guard let url = URL(string: feed.url + "?per_page=5") else {
            return nil
        }
        return makeRequest(url: url, token: feed.authToken)
    }


    // MARK: - helper functions

    private static func makeRequest(method: String = "GET", baseUrl: String = "https://api.github.com", path: String, params: Dictionary<String, String>, token: String? = nil) -> URLRequest {
        var components = URLComponents(string: baseUrl)!
        components.path = path
        components.queryItems = params.map({ URLQueryItem(name: $0.key, value: $0.value) })
        return makeRequest(url: components.url!, token: token)
    }

    private static func makeRequest(method: String = "GET", url: URL, token: String?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        if let token = token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

}
