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
        updateViewState(token: nil, description: "", isWaiting: true)
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
            return
        }
        NSPasteboard.general.prepareForNewContents()
        NSPasteboard.general.setString(response.userCode, forType: .string)
        NSWorkspace.shared.open(URL(string: response.verificationUri)!)

        self.updateViewState(token: nil, description: "Pending", isWaiting: true)

        GitHubAPI.deviceFlowGetAccessToken(loginResponse: response) { token in
            self.updateViewState(token: token, description: "(access token)", isWaiting: false)
        } onError: { message in
            self.updateViewState(token: nil, description: message, isWaiting: false)
        };
    }


    public func stopWaitingForToken() {
        GitHubAPI.cancelDeviceFlow()
        updateViewState(token: nil, description: "", isWaiting: false)
    }


    private func updateViewState(token: String?, description: String, isWaiting: Bool) {
        viewState.accessToken = token
        viewState.accessTokenDescription = description
        viewState.isWaitingForToken = isWaiting
    }


    func openReviewAccessPage() {
        NSWorkspace.shared.open(URL(string: "https://github.com/settings/connections/applications/" + GitHubAPI.clientId)!)
    }
}
