/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import Combine


class GitHubAPI {
    
    static let clientId = "4eafcf49451c588fbeac"
    static var cancellables: Set<AnyCancellable> = Set()
    static var deviceFlowTasks: Set<AnyCancellable> = Set()


    // MARK: - repository list

    struct Repository: Identifiable, Hashable, Decodable {

        var id: Int
        var name: String
        var owner: Owner?

        init(id: Int, name: String) {
            self.id = id
            self.name = name
        }
        
        init(message: String) {
            self.id = message.hashValue
            self.name = "(" + message + ")"
        }
        
        init() {
            self.id = 0
            self.name = ""
        }
        
        static func == (lhs: GitHubAPI.Repository, rhs: GitHubAPI.Repository) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        var isMessage: Bool {
            return name.isEmpty || name.starts(with: "(")
        }

    }

    struct Owner: Decodable {

        var login: String

        init() {
            self.login = ""
        }

    }

    static func fetchRepositories(owner: String, token: String?, callback: @escaping ([Repository]) -> ()) {
        let path = String(format: "/users/%@/repos", owner)
        let queryParams = [
            "type": "all",
            "sort": "pushed",
            "per_page": "100",
        ];
        let request = makeRequest(path: path, params: queryParams, token: token)

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(responseOkData(element:))
            .decode(type: Array<Repository>.self, decoder: Self.snakeCaseDecoder())
            .receive(on: RunLoop.main)
            .catch({ (error) in
                Just([Repository(message: messageForError(error: error))])
            })
            // .replaceError(with: [Repository(message: "unknown owner or network error")])
            .sink(receiveValue: callback)
            .store(in: &cancellables)

        if token == nil {
            return
        }

        let path2 = String(format: "/user/repos", owner)
        let queryParams2 = [
            "type": "private",
            "sort": "pushed",
            "per_page": "100",
        ];
        let request2 = makeRequest(path: path2, params: queryParams2, token: token)

        URLSession.shared.dataTaskPublisher(for: request2)
            .tryMap(responseOkData(element:))
            .decode(type: Array<Repository>.self, decoder: Self.snakeCaseDecoder())
            .receive(on: RunLoop.main)
            .catch({ (error) in
                Just([Repository(message: messageForError(error: error))])
            })
            // .replaceError(with: [Repository(message: "unknown owner or network error")])
            .sink(receiveValue: callback)
            .store(in: &cancellables)
    }
    



    // MARK: - workflow list

    struct Workflow: Identifiable, Hashable, Decodable {
        var id: Int
        var name: String
        var path: String?
        
        init(id: Int, name: String, path: String) {
            self.id = id
            self.name = name
            self.path = path
        }
        
        init(message: String) {
            self.id = message.hashValue
            self.name = "(" + message + ")"
        }
        
        init() {
            self.id = 0
            self.name = ""
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        var isMessage: Bool {
            return name.isEmpty || name.starts(with: "(")
        }
        
        var filename: String {
            guard let path = path else {
                return ""
            }
            return (path as NSString).lastPathComponent // TODO: is this the way to do it, really?
        }
        
    }
    
    struct WorflowResponse: Decodable {
        var workflows: [Workflow]
    }
    
    static func fetchWorkflows(owner: String, repo: String, token: String?, callback: @escaping ([Workflow]) -> ()) {
        let path = String(format: "/repos/%@/%@/actions/workflows", owner, repo)
        let queryParams = [
            // "client_id": clientId,
            "sort": "pushed",
            "per_page": "100",
        ];
        let request = makeRequest(path: path, params: queryParams, token: token)

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(responseOkData(element:))
            .decode(type: WorflowResponse.self, decoder: JSONDecoder())
            .map(\.workflows)
            .receive(on: RunLoop.main)
            .replaceError(with: [Workflow(message: "network error")])
            .sink(receiveValue: callback)
            .store(in: &cancellables)
    }


    // MARK: - authentication device flow

    struct LoginResponse: Decodable {
        var deviceCode: String
        var userCode: String
        var verificationUri: String
        var interval: Int
    }


    static func deviceFlowLogin(callback: @escaping (LoginResponse) -> ()) {
        let path = "/login/device/code"
        let queryParams = [
            "client_id": clientId,
            "scope": "repo",
        ];
        let request = makeRequest(method: "POST", baseUrl: "https://github.com", path: path, params: queryParams, token: nil)

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(responseOkData(element:))
            .decode(type: LoginResponse.self, decoder: Self.snakeCaseDecoder())
            .replaceError(with: LoginResponse(deviceCode: "", userCode: "(network error)", verificationUri: "", interval: 0)) // TODO: find a more elegant way to end processing
            .receive(on: RunLoop.main)
            .sink(receiveValue: callback)
            .store(in: &deviceFlowTasks)
    }

    static func deviceFlowGetAccessToken(loginResponse: LoginResponse, onSuccess: @escaping (String) -> (), onError: @escaping (String) -> ()) {
        let path = "/login/oauth/access_token"
        let queryParams = [
            "client_id": clientId,
            "device_code": loginResponse.deviceCode,
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
        ];
        let request = makeRequest(method: "POST", baseUrl: "https://github.com", path: path, params: queryParams, token: nil)

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap(responseOkData(element:))
            .decode(type: Dictionary<String, String>.self, decoder: JSONDecoder())
            .replaceError(with: [:])
            .receive(on: RunLoop.main)
            .sink(receiveValue: { response in handleGetAccessTokenResponse(response: response, loginResponse: loginResponse, onSuccess: onSuccess, onError: onError) })
            .store(in: &deviceFlowTasks)
    }

    private static func handleGetAccessTokenResponse(response: Dictionary<String, String>, loginResponse: LoginResponse, onSuccess: @escaping (String) -> (), onError: @escaping (String) -> ()) {
        if let error = response["error"] {
            if error == "authorization_pending" && loginResponse.interval > 0 {
                // TODO: Implement slow down: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#error-codes-for-the-device-flow
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(loginResponse.interval)) {
                    deviceFlowGetAccessToken(loginResponse: loginResponse, onSuccess: onSuccess, onError: onError)
                }
            } else {
                onError(response["error_description"] ?? "error")
            }
            return
        }
        guard let token = response["access_token"] else {
            onError("no token provided")
            return
        }
        if response["token_type"] != "bearer" {
            onError("unexpected token type")
            return
        }
        onSuccess(token)
    }


    static func cancelDeviceFlow() {
        deviceFlowTasks.forEach({ $0.cancel() })
    }


    // MARK: - helper functions

    private static func makeRequest(method: String = "GET", baseUrl: String = "https://api.github.com", path: String, params: Dictionary<String, String>, token: String?) -> URLRequest {
        var components = URLComponents(string: baseUrl)!
        components.path = path
        components.queryItems = params.map({ URLQueryItem(name: $0.key, value: $0.value) })
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }


    private static func responseOkData(element: URLSession.DataTaskPublisher.Output) throws -> Data {
        guard let response = element.response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if response.statusCode != 200 {
            throw URLError(.badServerResponse, userInfo: ["responseDescription" : HTTPURLResponse.localizedString(forStatusCode: response.statusCode)])
        }
        return element.data
    }
    
    private static func messageForError(error: Error) -> String {
        guard let error = error as? URLError else {
            return error.localizedDescription
        }
        guard error.code == .badServerResponse, let description = error.errorUserInfo["responseDescription"] as? String else {
            return error.localizedDescription
        }
        return description
    }

    private static func snakeCaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

}
