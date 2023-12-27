/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI

typealias LoginResponse = GitHubAPI.LoginResponse


class GitHubSheetController {

    @ObservedObject var model: PipelineModel
    @ObservedObject var workflowState: GitHubWorkflowState
    @ObservedObject var authState: GitHubAuthState

    init(model: PipelineModel) {
        self.model = model
        workflowState = GitHubWorkflowState()
        authState = GitHubAuthState()
    }


    func fetchRepositories() {
        workflowState.repositoryList = [ GitHubRepository(message: "updating") ]
        GitHubAPI.fetchRepositories(owner: workflowState.owner, token: authState.token) { newList in
            self.updateRepositoryList(newList: newList)
        }
    }

    func updateRepositoryList(newList: [GitHubRepository]) {
        var repositoryList = newList.filter({ $0.owner?.login == self.workflowState.owner || !$0.isValid })
        repositoryList.sort(by: { r1, r2 in r1.name.lowercased().compare(r2.name.lowercased()) == .orderedAscending })
        if repositoryList.count == 0 {
            repositoryList = [GitHubRepository()]
        }
        self.workflowState.repositoryList = repositoryList
    }

    func fetchWorkflows() {
        workflowState.workflowList = [ GitHubWorkflow(message: "updating") ]
        GitHubAPI.fetchWorkflows(owner: workflowState.owner, repository:workflowState.repository.name, token: authState.token) { newList in
            self.updateWorkflowList(newList: newList)
        }
    }

    func updateWorkflowList(newList: [GitHubWorkflow]) {
        var workflowList = newList.count > 0 ? newList : [GitHubWorkflow()]
        workflowList.sort(by: { w1, w2 in w1.name.lowercased().compare(w2.name.lowercased()) == .orderedAscending })
        self.workflowState.workflowList = workflowList
    }

    func clearWorkflows() {
        self.workflowState.workflowList = [GitHubWorkflow()]
    }


    func signInAtGitHub() {
        authState.isWaitingForToken = true
        authState.tokenDescription = "Preparing to sign in..."
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
            authState.tokenDescription = authState.token ?? ""
            return
        }
        NSPasteboard.general.prepareForNewContents()
        NSPasteboard.general.setString(response.userCode, forType: .string)
        NSWorkspace.shared.open(URL(string: response.verificationUri)!)

        authState.tokenDescription = "Waiting for token..."

        GitHubAPI.deviceFlowGetAccessToken(loginResponse: response) { token in
            if self.authState.isWaitingForToken {
                self.authState.isWaitingForToken = false
                self.authState.token = token
                self.authState.tokenDescription = token
            }
        } onError: { message in
            if self.authState.isWaitingForToken {
                self.authState.isWaitingForToken = false
                self.authState.token = nil
                self.authState.tokenDescription = message
            }
        };
    }

    public func stopWaitingForToken() {
        authState.isWaitingForToken = false
        authState.tokenDescription = authState.token ?? ""
        GitHubAPI.cancelDeviceFlow()
    }

    func openReviewAccessPage() {
        NSWorkspace.shared.open(URL(string: "https://github.com/settings/connections/applications/" + GitHubAPI.clientId)!)
    }


    func resetName() {
        var name = ""
        if workflowState.repository.isValid {
            name.append(workflowState.repository.name)
            if workflowState.workflow.isValid {
                name.append(String(format: " (%@)", workflowState.workflow.name))
            }
        }
        workflowState.name = name
    }


    func addPipeline() {
        let url = GitHubAPI.feedUrl(owner: workflowState.owner, repository: workflowState.repository.name, workflow: workflowState.workflow.filename)
        let feed = Pipeline.Feed(type: .github, url:url, authToken: authState.token)
        let pipeline = Pipeline(name: workflowState.name, feed: feed)
        model.pipelines.append(pipeline)
   }


}
