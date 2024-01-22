/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

@MainActor
class GitHubAuthenticator: ObservableObject {
    @Published var token: String?
    @Published var tokenDescription: String = ""
    @Published private(set) var isWaitingForToken: Bool = false

    func signInAtGitHub() async {
        isWaitingForToken = true
        tokenDescription = "Preparing to sign in..."

        let codeRequest = GitHubAPI.requestForDeviceCode()
        guard let codeResponse = await fetchDeviceCode(request: codeRequest) else {
            // TODO: Consider adding error handling in fetchDeviceCode
            cancelSignIn()
            return
        }
        if !startDeviceFlowOnWebsite(response: codeResponse) {
            cancelSignIn()
            return
        }

        tokenDescription = "Waiting for token..."

        let tokenRequest = GitHubAPI.requestForAccessToken(codeResponse: codeResponse)
        let (newToken, errorMessage) = await fetchAccessToken(codeResponse: codeResponse, request: tokenRequest)

        isWaitingForToken = false
        if newToken != nil {
            token = newToken
        }
        tokenDescription = token ?? errorMessage ?? ""
    }
        

    private func startDeviceFlowOnWebsite(response: GitHubDeviceCodeResponse) -> Bool {
        let alert = NSAlert()
        alert.messageText = "GitHub sign in"
        alert.informativeText = "The process will continue on the GitHub website in your default web browser. You will have to enter the code shown below.\n\n\(response.userCode)\n\nWhen you return to CCMenu please wait for a token to appear."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy code and continue")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertSecondButtonReturn {
            return false
        }
        NSPasteboard.general.prepareForNewContents()
        NSPasteboard.general.setString(response.userCode, forType: .string)
        guard let url = URL(string: response.verificationUri) else {
            // TODO: Consider adding error handling. But will GH really send a bad URL?
            return false
        }
        NSWorkspace.shared.open(url)
        return true
    }


    private func fetchDeviceCode(request: URLRequest) async -> GitHubDeviceCodeResponse? {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw URLError(.unsupportedURL)
            }
            guard response.statusCode == 200 else {
                return nil
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(GitHubDeviceCodeResponse.self, from: data)
        } catch {
            return nil
        }
    }

    private func fetchAccessToken(codeResponse: GitHubDeviceCodeResponse, request: URLRequest) async -> (String?, String?) {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw URLError(.unsupportedURL)
            }
            guard response.statusCode == 200 else {
                return (nil, HTTPURLResponse.localizedString(forStatusCode: response.statusCode))
            }
            let json = try JSONDecoder().decode(Dictionary<String, String>.self, from: data)
            if let error = json["error"] {
                if error == "authorization_pending" && codeResponse.interval > 0 {
                    // TODO: Implement slow down: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#error-codes-for-the-device-flow
                    try await Task.sleep(for: .seconds(codeResponse.interval))
                    if !isWaitingForToken {
                        return (nil, nil)
                    }
                    return await fetchAccessToken(codeResponse: codeResponse, request: request)
                } else {
                    return (nil, json["error_description"] ?? "error")
                }
            }
            guard let token = json["access_token"] else {
                return (nil, "no token provided")
            }
            if json["token_type"] != "bearer" {
                return (nil, "unexpected token type")
            }
            return (token, nil)
        } catch {
            return (nil, "error")
        }
    }

    func cancelSignIn() {
        isWaitingForToken = false
        tokenDescription = token ?? ""
    }

    func openApplicationsOnWebsite() {
        NSWorkspace.shared.open(GitHubAPI.applicationsUrl())
    }

}
