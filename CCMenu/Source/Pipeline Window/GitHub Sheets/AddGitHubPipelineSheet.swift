/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI
import Combine


struct AddGithubPipelineSheet: View {
    @State private var owner = ""
    @StateObject private var repositoryList = GitHubRepositoryList()
    @StateObject private var workflowList = GitHubWorkflowList()
    @StateObject private var pipelineBuilder = GitHubPipelineBuilder()
    @StateObject private var authenticator = GitHubAuthenticator()
    @ObservedObject var model: PipelineModel
    @EnvironmentObject var settings: UserSettings
    @Environment(\.presentationMode) @Binding var presentation

    var body: some View {
        VStack {
            Text("Add GitHub Actions workflow")
                .font(.headline)
                .padding(.bottom)
            Text("Press return in the owner field to fetch repositories and workflows. If there are many entries only the most recently updated will be shown. Sign into GitHub to access private repositories.")
                .lineLimit(3...10)
                .multilineTextAlignment(.leading)
                .frame(idealWidth: 400)
                .padding(.bottom)

            Form {
                HStack {
                    TextField("Authentication:", text: $authenticator.tokenDescription)
                        .truncationMode(.tail)
                        .disabled(true)
                    if authenticator.isWaitingForToken {
                        Button("Cancel") {
                            authenticator.cancelSignIn()
                        }
                    } else {
                        Button(authenticator.token == nil ? "Sign in" : "Refresh") {
                            Task { await authenticator.signInAtGitHub() }
                        }
                    }
                    Button("Review") {
                        authenticator.openApplicationsOnWebsite()
                    }
                }
                .padding(.bottom)

                TextField("Owner:", text: $owner, prompt: Text("user or organisation"))
                // TODO: figure out why .prefersDefaultFocus(in:) doesn't work
                .autocorrectionDisabled(true)
                .onSubmit {
                    if !owner.isEmpty {
                        Task {
                            await repositoryList.updateRepositories(owner: owner, token: authenticator.token)
                        }
                    }
                }

                Picker("Repository", selection: $repositoryList.selected) {
                    ForEach(repositoryList.items) { r in
                        Text(r.name).tag(r)
                    }
                }
                .disabled(!repositoryList.selected.isValid)
                .onChange(of: repositoryList.selected) { _ in
                    pipelineBuilder.updateName(repository: repositoryList.selected, workflow: workflowList.selected)
                    if repositoryList.selected.isValid {
                        Task {
                            await workflowList.updateWorkflows(owner: owner, repository: repositoryList.selected.name, token: authenticator.token)
                        }
                    } else {
                        workflowList.clearWorkflows()
                    }
                }

                Picker("Workflow", selection: $workflowList.selected) {
                    ForEach(workflowList.items) { w in
                        Text(w.name).tag(w)
                    }
                }
                .disabled(!workflowList.selected.isValid)
                .onChange(of: workflowList.selected) { _ in
                    pipelineBuilder.updateName(repository: repositoryList.selected, workflow: workflowList.selected)
                }
                .padding(.bottom)

                HStack {
                    TextField("Display name:", text: $pipelineBuilder.name)
                    Button("Reset", systemImage: "arrowshape.turn.up.backward") {
                        pipelineBuilder.updateName(repository: repositoryList.selected, workflow: workflowList.selected)
                    }
                }
                .padding(.bottom)
            }

            HStack {
                Button("Cancel") {
                    presentation.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Apply") {
                    let p = pipelineBuilder.makePipeline(owner: owner, authToken: authenticator.token)
                    model.pipelines.append(p)
                    presentation.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(pipelineBuilder.name.isEmpty || !repositoryList.selected.isValid || !workflowList.selected.isValid)
            }
        }
        .frame(minWidth: 405)
        .padding()
        .onAppear() {
            if let token = settings.cachedGitHubToken {
                authenticator.token = token
                authenticator.tokenDescription = token
            }
        }
        .onDisappear() {
            if let token = authenticator.token {
                settings.cachedGitHubToken = token
            }
        }
    }

}


struct AddGithubPipelineSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            AddGithubPipelineSheet(model: ViewModel())
        }
    }
}

