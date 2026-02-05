/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import os

@MainActor
class GitLabAuthenticator: ObservableObject {
    @Published var token: String?
    @Published var tokenDescription: String = ""

    func setToken(_ newToken: String) async {
        token = newToken.cleanedUpUserInput()
        if let token {
            let request = GitLabAPI.requestForTokenInfo(token: token)
            let pat = await fetchTokenInfo(request: request)
            updateTokenDescription(pat: pat)
        } else {
            tokenDescription = ""
        }
    }

    private func fetchTokenInfo(request: URLRequest) async -> GitLabPersonalAccessToken? {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw URLError(.unsupportedURL) }
            if response.statusCode != 200 {
                let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
                logger.error("Error when getting token information: \(response, privacy: .public)")
                return nil
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(GitLabPersonalAccessToken.self, from: data)
        } catch {
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
            logger.error("Error when getting token information: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func updateTokenDescription(pat: GitLabPersonalAccessToken?) {
        guard let pat else {
            tokenDescription = "\u{26A0}\u{FE0F} token is not valid"
            return
        }
        tokenDescription = String(format:"**%@**", pat.name)
        var errors: [String] = []
        if !pat.active {
            errors.append("not active")
        }
        if !pat.scopes.contains("read_api") {
            errors.append("missing read_api scope")
        }
        if !errors.isEmpty {
            let errorText = errors.joined(separator: ", ")
            tokenDescription.append(String(format: "\n\u{26A0}\u{FE0F} %@", errorText))
        } else if let expiryDate = pat.expiresAtDate {
            let formatter = RelativeDateTimeFormatter()
            let expiryText = formatter.localizedString(for: expiryDate, relativeTo: Date())
            tokenDescription.append(String(format: "\nExpires: %@", expiryText))
        }
    }


    func fetchTokenFromKeychain() {
        do {
            token = try Keychain.standard.getToken(forService: "GitLab")
        } catch {
            token = nil
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
            logger.error("Error when retrieving token from keychain: \(error.localizedDescription, privacy: .public)")
        }
    }

    func storeTokenInKeychain() {
        guard let token else { return }
        guard UserDefaults.active.string(forKey: "GitLabToken") == nil else { return }
        do {
            try Keychain.standard.setToken(token, forService: "GitLab")
        } catch {
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "application")
            logger.error("Error when storing token in keychain: \(error.localizedDescription, privacy: .public)")
        }
    }

    func openTokenSettingsOnWebsite() {
        if token == nil {
            if !showExplanation() {
                return
            }
        }
        NSWorkspace.shared.open(GitLabAPI.tokenSettingsUrl())
    }

    private func showExplanation() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Create token with read_api scope"
        alert.informativeText = "The process will continue on the GitLab website in your default web browser. You must create a personal access token with read_api scope.\n\nCopy the token on the website, return to CCMenu, and paste it into the text field."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

}
