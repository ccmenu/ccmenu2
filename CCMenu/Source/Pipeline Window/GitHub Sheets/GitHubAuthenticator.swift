/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import os

@MainActor
class GitHubAuthenticator: ObservableObject {
    @Published var token: String?
    @Published var tokenDescription: String = ""
    @Published private(set) var isWaitingForToken: Bool = false
    private var codeResponse: GitHubDeviceCodeResponse? = nil

    func signInAtGitHub() async -> Bool {
        isWaitingForToken = true
        tokenDescription = "Preparing to sign in..."

        let codeRequest = GitHubAPI.requestForDeviceCode()
        codeResponse = await fetchDeviceCode(request: codeRequest)
        guard let codeResponse, startDeviceFlowOnWebsite(response: codeResponse) else {
            cancelSignIn()
            return false
        }
        return true
    }

    func waitForToken() async {
        guard let codeResponse else { return }
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
        alert.messageText = response.userCode
        alert.informativeText = "The process will continue on the GitHub website in your default web browser. You will have to enter the code shown above.\n\nWhen you return to CCMenu please wait for a token to appear."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy Code and Continue")
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
            guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
            if response.statusCode != 200 {
                let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
                logger.error("Error when initiating device flow: \(response, privacy: .public)")
                return nil
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(GitHubDeviceCodeResponse.self, from: data)
        } catch {
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
            logger.error("Error when initiating device flow: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func fetchAccessToken(codeResponse: GitHubDeviceCodeResponse, request: URLRequest) async -> (String?, String?) {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
            if response.statusCode != 200 {
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

    func setToken(_ newToken: String) {
        let trimmed = newToken.trimmingCharacters(in: .whitespacesAndNewlines)
        token = trimmed.isEmpty ? nil : trimmed
        tokenDescription = token ?? ""
    }

    func openApplicationsOnWebsite() {
        NSWorkspace.shared.open(GitHubAPI.applicationsUrl())
    }

    func fetchTokenFromKeychain() {
        do {
            token = try Keychain.standard.getToken(forService: "GitHub")
        } catch {
            token = nil
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
            logger.error("Error when retrieving token from keychain: \(error.localizedDescription, privacy: .public)")
        }
        tokenDescription = token ?? ""
    }


    func storeTokenInKeychain() {
        guard let token else { return }
        guard UserDefaults.active.string(forKey: "GitHubToken") == nil else { return } // slight hack so we don't store tokens from test
        do {
            try Keychain.standard.setToken(token, forService: "GitHub")
        } catch {
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
            logger.error("Error when storing token in keychain: \(error.localizedDescription, privacy: .public)")
        }
    }

}
