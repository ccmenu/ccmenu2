/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

typealias LoginResponse = GitHubAPI.LoginResponse


class GitHubSheetController: ObservableObject {

    @ObservedObject var model: PipelineModel
    @ObservedObject var selectionState: GitHubWorkflowSelectionState
    @ObservedObject var authState: GitHubAuthState

    init(model: PipelineModel) {
        self.model = model
        selectionState = GitHubWorkflowSelectionState()
        authState = GitHubAuthState()
    }


    func fetchRepositories() {
        selectionState.repositoryList = [ GitHubRepository(message: "updating") ]
        GitHubAPI.fetchRepositories(owner: selectionState.owner, token: authState.accessToken) { newList in
            self.updateRepositoryList(newList: newList)
        }
    }

    func updateRepositoryList(newList: [GitHubRepository]) {
        var repositoryList = selectionState.repositoryList
        let filteredNewList = newList.filter({ $0.owner?.login == self.selectionState.owner || !$0.isValid })
        if repositoryList.count == 1 && !repositoryList[0].isValid {
            repositoryList = []
        }
        repositoryList.append(contentsOf: filteredNewList)
        repositoryList.sort(by: { r1, r2 in r1.name.lowercased().compare(r2.name.lowercased()) == .orderedAscending })
        if repositoryList.count == 0 {
            repositoryList = [GitHubRepository()]
        }
        self.selectionState.repositoryList = repositoryList
    }

    func fetchWorkflows() {
        selectionState.workflowList = [ GitHubWorkflow(message: "updating") ]
        GitHubAPI.fetchWorkflows(owner: selectionState.owner, repository:selectionState.repository.name, token: authState.accessToken) { newList in
            self.updateWorkflowList(newList: newList)
        }
    }

    func updateWorkflowList(newList: [GitHubWorkflow]) {
        var workflowList = newList.count > 0 ? newList : [GitHubWorkflow()]
        workflowList.sort(by: { w1, w2 in w1.name.lowercased().compare(w2.name.lowercased()) == .orderedAscending })
        self.selectionState.workflowList = workflowList
    }

    func clearWorkflows() {
        self.selectionState.workflowList = [GitHubWorkflow()]
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


    func defaultPipelineName() -> String {
        var name = ""
        if selectionState.repository.isValid {
            name.append(selectionState.repository.name)
            if selectionState.workflow.isValid {
                name.append(String(format: " (%@)", selectionState.workflow.name))
            }
        }
        return name
    }


    func addPipeline(name: String) {
        let url = GitHubAPI.feedUrl(owner: selectionState.owner, repository: selectionState.repository.name, workflow: selectionState.workflow.filename)
        let feed = Pipeline.Feed(type: .github, url:url, authToken: authState.accessToken)
        let pipeline = Pipeline(name: name, feed: feed)
        model.pipelines.append(pipeline)
        // TODO: should trigger first poll of status (but this should happen in model? or does the server monitor listen?)
   }


}
