/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

typealias LoginResponse = GitHubAPI.LoginResponse


class GitHubSheetController: ObservableObject {

    @ObservedObject var authState: GitHubAuthState

    init() {
        authState = GitHubAuthState()
    }

    func signInAtGitHub() {
        authState.isWaitingForToken = true
        authState.accessTokenDescription = "Preparing to sign in..."
        GitHubAPI.deviceFlowLogin() { response in
            self.handleLoginResponse(response: response)
        }
    }

    private func handleLoginResponse(response: GitHubAPI.LoginResponse) {
        let alert = NSAlert()
        alert.messageText = "GitHub sign in"
        alert.informativeText = "The process will continue on the GitHub website in your default web browser. You will have to enter the code shown below.\n\n" + response.userCode + "\n\nWhen you return to CCMenu please wait for a token. The authentication field should show the text \"(access token)\"."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy code and continue")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertSecondButtonReturn {
            authState.isWaitingForToken = false
            authState.accessTokenDescription = authState.accessToken ?? ""
            return
        }
        NSPasteboard.general.prepareForNewContents()
        NSPasteboard.general.setString(response.userCode, forType: .string)
        NSWorkspace.shared.open(URL(string: response.verificationUri)!)

        authState.accessTokenDescription = "Waiting for token..."

        GitHubAPI.deviceFlowGetAccessToken(loginResponse: response) { token in
            if self.authState.isWaitingForToken {
                self.authState.isWaitingForToken = false
                self.authState.accessToken = token
                self.authState.accessTokenDescription = token
            }
        } onError: { message in
            if self.authState.isWaitingForToken {
                self.authState.isWaitingForToken = false
                self.authState.accessToken = nil
                self.authState.accessTokenDescription = message
            }
        };
    }


    public func stopWaitingForToken() {
        authState.isWaitingForToken = false
        authState.accessTokenDescription = authState.accessToken ?? ""
        GitHubAPI.cancelDeviceFlow()
    }


    func openReviewAccessPage() {
        NSWorkspace.shared.open(URL(string: "https://github.com/settings/connections/applications/" + GitHubAPI.clientId)!)
    }
}
