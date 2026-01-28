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

    func setToken(_ newToken: String) {
        let trimmed = newToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            token = nil
            tokenDescription = ""
        } else {
            token = trimmed
            tokenDescription = trimmed
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
        tokenDescription = token ?? ""
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
        NSWorkspace.shared.open(GitLabAPI.tokenSettingsUrl())
    }

}
