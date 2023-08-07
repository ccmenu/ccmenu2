/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

class GithubAuthController: ObservableObject {

    @ObservedObject var viewState: ListViewState

    private let clientId: String
    private var task: URLSessionDataTask?
    private var stageTwoRequest: URLRequest?
    private var pollInterval: Int = 0


    init(viewState: ListViewState) {
        self.clientId = "4eafcf49451c588fbeac"
        self.viewState = viewState
    }

    func signInAtGitHub() {
        viewState.accessToken = nil
        viewState.accessTokenDescription = ""
        viewState.isWaitingForToken = true
        task = URLSession.shared.dataTask(with: makeStageOneRequest(), completionHandler: stageOneCallback)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.task?.resume()
//        }
    }

    func makeStageOneRequest() -> URLRequest {
        var components = URLComponents(string: "https://github.com/login/device/code")!
        let queryParams = [
            "client_id": clientId,
            "scope": "repo",
        ];
        components.queryItems = queryParams.map({ URLQueryItem(name: $0.key, value: $0.value) })
        var request = URLRequest(url: components.url!)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        return request
    }

    func stageOneCallback(data: Data?, response: URLResponse?, error: Error?) {
        task = nil
        DispatchQueue.main.async {
            self.processStageOneResponse(data: data, response: response, error: error)
        }
    }

    func processStageOneResponse(data: Data?, response: URLResponse?, error: Error?) {
        guard let response = response as? HTTPURLResponse else {
            // TODO: Consider adding error handling for this case
            return
        }
        if !(200...299).contains(response.statusCode) {
            // TODO: Add error handling for this case
            return
        }
        guard let data = data else {
            // TODO: Consider adding error handling for this case
            return
        }
        guard let response = try! JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any> else {
            // TODO: Consider handling unparsable JSON
            return
        }
        debugPrint(String(describing: response))
        guard let userCode = response["user_code"] as? String else {
            // TODO: Consider handling GitHub API change
            return
        }
        guard let url = response["verification_uri"] as? String else {
            // TODO: Consider handling case where GitHub does not provide the URL
            return
        }
        guard let deviceCode = response["device_code"] as? String else {
            // TODO: Consider handling GitHub API change
            return
        }
        if let interval = response["interval"] as? Int {
            pollInterval = interval
        }

        let alert = NSAlert()
        alert.messageText = "GitHub sign in"
        alert.informativeText = "CCMenu will open a page on GitHub. Please copy the code below. You will have to enter it on the web page.\n\n" + userCode + "\n\nWhen you return to CCMenu please wait until a token has arrived."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Continue")
        alert.runModal()

        NSWorkspace.shared.open(URL(string: url)!)

        viewState.accessTokenDescription = "Pending"
        viewState.isWaitingForToken = true
        stageTwoRequest = makeStageTwoRequest(code: deviceCode)
        task = URLSession.shared.dataTask(with: stageTwoRequest!, completionHandler: stageTwoCallback)
        task?.resume()
    }

    func makeStageTwoRequest(code: String) -> URLRequest {
        var components = URLComponents(string: "https://github.com/login/oauth/access_token")!
        let queryParams = [
            "client_id": clientId,
            "device_code": code,
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
        ];
        components.queryItems = queryParams.map({ URLQueryItem(name: $0.key, value: $0.value) })
        var request = URLRequest(url: components.url!)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        return request
    }

    func stageTwoCallback(data: Data?, response: URLResponse?, error: Error?) {
        task = nil
        DispatchQueue.main.async {
            self.processStageTwoResponse(data: data, response: response, error: error)
        }
    }

    func processStageTwoResponse(data: Data?, response: URLResponse?, error: Error?) {
        guard let response = response as? HTTPURLResponse else {
            // TODO: Consider adding error handling for this case
            return
        }
        if !(200...299).contains(response.statusCode) {
            // TODO: Add error handling for this case
            return
        }
        guard let data = data else {
            // TODO: Consider adding error handling for this case
            return
        }
        guard let response = try! JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any> else {
            // TODO: Consider handling unparsable JSON
            return
        }
        debugPrint(String(describing: response))
        if let error = response["error"] as? String {
            if error == "authorization_pending" && pollInterval > 0 {
                // TODO: Implement slow down: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#error-codes-for-the-device-flow
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(pollInterval)) {
                    if self.viewState.isWaitingForToken {
                        self.task = URLSession.shared.dataTask(with: self.stageTwoRequest!, completionHandler: self.stageTwoCallback)
                        self.task?.resume()
                    }
                }
                return
            } else {
                guard let description = response["error_description"] as? String else {
                    // TODO: Consider handling GitHub API change
                    return
                }
                viewState.accessTokenDescription = description
                viewState.isWaitingForToken = false
            }
        }
        viewState.isWaitingForToken = false

        if response["token_type"] as? String != "bearer" {
            // TODO: Consider handling GitHub API change
            return
        }
        guard let token = response["access_token"] as? String else {
            // TODO: Consider handling GitHub API change
            return
        }
        // TODO: Consider handling scope changes
        print("** \(token) **")
        viewState.accessToken = token
        viewState.accessTokenDescription = "(access token)"
    }


    public func stopWaitingForToken() {
        task?.cancel()
        task = nil
        viewState.accessTokenDescription = ""
        viewState.isWaitingForToken = false
    }


    func openReviewAccessPage() {
        NSWorkspace.shared.open(URL(string: "https://github.com/settings/connections/applications/" + clientId)!)
    }
}
