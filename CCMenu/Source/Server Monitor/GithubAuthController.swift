/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import Foundation
import AuthenticationServices


class GithubAuthController: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding, URLSessionDataDelegate, URLSessionDelegate {

    @Published var accessToken: String?
    @Published var accessTokenRedacted: String = ""

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }

    func signInAtGitHub() {
        accessToken = nil

        let authSession = ASWebAuthenticationSession(url: makeStageOneUrl(), callbackURLScheme: nil, completionHandler: stageOneCallback)
        authSession.presentationContextProvider = self
        authSession.prefersEphemeralWebBrowserSession = false
        authSession.start()
    }

    func makeStageOneUrl() -> URL {
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
        let queryParams = [
            "client_id": "4eafcf49451c588fbeac",
            "scope": "repo",
        ];
        components.queryItems = queryParams.map({ URLQueryItem(name: $0.key, value: $0.value) })
        return components.url!
    }

    func stageOneCallback(url callbackUrl: URL?, error: Error?) {
        debugPrint("OAuth callback; url = \(String(describing: callbackUrl)), error = \(String(describing: error))")
        guard let callbackUrl = callbackUrl else {
            // TODO: Add error handling
            return
        }
        guard let code = codeFromStageOneCallback(url: callbackUrl) else {
            // TODO: Consider error checks; GitHub could change their API or someone could craft a URL
            return
        }
        var request = URLRequest(url:makeStageTwoUrl(code: code))
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        let task = session.dataTask(with: request, completionHandler: stageTwoCallback)
        task.resume()
    }

    func codeFromStageOneCallback(url: URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        return components.queryItems?.first(where: { $0.name == "code" })?.value
    }

    func makeStageTwoUrl(code: String) -> URL {
        var components = URLComponents(string: "https://github.com/login/oauth/access_token")!
        let queryParams = [
            "client_id": "4eafcf49451c588fbeac",
            "client_secret": "",
            "code": code
        ];
        components.queryItems = queryParams.map({ URLQueryItem(name: $0.key, value: $0.value) })
        return components.url!
    }

    func stageTwoCallback(data: Data?, response: URLResponse?, error: Error?) {
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
        if let response = try! JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any> {
            // TODO: Consider handling unparsable JSON
            debugPrint(String(describing: response))
            if response["token_type"] as? String != "bearer" {
                // TODO: Consider handling GitHub API change
                return
            }
            guard let token = response["access_token"] as? String else {
                // TODO: Consider handling GitHub API change
                return
            }
            print("** \(token) **")
            accessToken = token
        }

     }

    func openReviewAccessPage() {
        // https://github.com/settings/connections/applications/:client_id
    }
}
