/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

typealias LoginResponse = GitHubAPI.LoginResponse


class GithubAuthController: ObservableObject {

    @ObservedObject var viewState: ListViewState

    init(viewState: ListViewState) {
        self.viewState = viewState
    }

    func signInAtGitHub() {
        viewState.isWaitingForToken = true
        viewState.accessTokenDescription = "Preparing sign in..."
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
            viewState.isWaitingForToken = false
            viewState.accessTokenDescription = viewState.accessToken ?? ""
            return
        }
        NSPasteboard.general.prepareForNewContents()
        NSPasteboard.general.setString(response.userCode, forType: .string)
        NSWorkspace.shared.open(URL(string: response.verificationUri)!)

        viewState.accessTokenDescription = "Waiting for token..."

        GitHubAPI.deviceFlowGetAccessToken(loginResponse: response) { token in
            if self.viewState.isWaitingForToken {
                self.viewState.isWaitingForToken = false
                self.viewState.accessToken = token
                self.viewState.accessTokenDescription = token
            }
        } onError: { message in
            if self.viewState.isWaitingForToken {
                self.viewState.isWaitingForToken = false
                self.viewState.accessToken = nil
                self.viewState.accessTokenDescription = message
            }
        };
    }


    public func stopWaitingForToken() {
        viewState.isWaitingForToken = false
        viewState.accessTokenDescription = viewState.accessToken ?? ""
        GitHubAPI.cancelDeviceFlow()
    }


    func openReviewAccessPage() {
        NSWorkspace.shared.open(URL(string: "https://github.com/settings/connections/applications/" + GitHubAPI.clientId)!)
    }
}
