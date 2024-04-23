/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AddGitHubPipelineSheet: View {
    @ObservedObject var model: PipelineModel
    @EnvironmentObject private var authenticator: GitHubAuthenticator
    @Environment(\.presentationMode) @Binding var presentation
    @StateObject private var owner = DebouncedText()
    @StateObject private var repositoryList = GitHubRepositoryList()
    @StateObject private var workflowList = GitHubWorkflowList()
    @StateObject private var branchList = GitHubBranchList()
    @StateObject private var name = GitHubPipelineName()

    var body: some View {
        VStack {
            Text("Add GitHub Actions workflow")
                .font(.headline)
                .padding(.bottom)
            Text("Press return in the owner field to fetch repositories and workflows. If there are many entries only the most recently updated will be shown.\n\nSign into GitHub to access private repositories. The token you set here will be used for all GitHub pipelines.")
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom)
            Form {
                HStack {
                    TextField("Authentication:", text: $authenticator.tokenDescription)
                        .accessibilityIdentifier("Token field")
                        .truncationMode(.tail)
                        .disabled(true)
                    if authenticator.isWaitingForToken {
                        Button("Cancel") {
                            authenticator.cancelSignIn()
                        }
                    } else {
                        Button(authenticator.token == nil ? "Sign in" : "Refresh") {
                            Task {
                                if await authenticator.signInAtGitHub() {
                                    await authenticator.waitForToken()
                                }
                            }
                        }
                    }
                    Button("Review") {
                        authenticator.openApplicationsOnWebsite()
                    }
                }
                .padding(.bottom)

                TextField("Owner:", text: $owner.input, prompt: Text("user or organisation"))
                .accessibilityIdentifier("Owner field")
                // TODO: figure out why .prefersDefaultFocus(in:) doesn't work
                .autocorrectionDisabled(true)
                .onReceive(owner.$text) { t in
                    if t.isEmpty {
                        repositoryList.clearRepositories()
                    } else {
                        Task {
                            await repositoryList.updateRepositories(owner: t, token: authenticator.token)
                        }
                    }
                }
                .onSubmit {
                    owner.takeInput()
                }

                Picker("Repository:", selection: $repositoryList.selected) {
                    ForEach(repositoryList.items) { r in
                        Text(r.name).tag(r)
                    }
                }
                .accessibilityIdentifier("Repository picker")
                .disabled(!repositoryList.selected.isValid)
                .onChange(of: repositoryList.selected) { _ in
                    name.setDefaultName(repository: repositoryList.selected, workflow: workflowList.selected)
                    if repositoryList.selected.isValid {
                        Task {
                            async let r1: Void = workflowList.updateWorkflows(owner: owner.text, repository: repositoryList.selected.name, token: authenticator.token)
                            async let r2: Void = branchList.updateBranches(owner: owner.text, repository: repositoryList.selected.name, token: authenticator.token)
                            _ = await [r1, r2]
                        }
                    } else {
                        workflowList.clearWorkflows()
                        branchList.clearBranches()
                    }
                }

                Picker("Workflow:", selection: $workflowList.selected) {
                    ForEach(workflowList.items) { w in
                        Text(w.name).tag(w)
                    }
                }
                .accessibilityIdentifier("Workflow picker")
                .disabled(!workflowList.selected.isValid)
                .onChange(of: workflowList.selected) { _ in
                    name.setDefaultName(repository: repositoryList.selected, workflow: workflowList.selected)
                }

                Picker("Branch:", selection: $branchList.selected) {
                    ForEach(branchList.items) { b in
                        Text(b.name).tag(b)
                    }
                }
                .accessibilityIdentifier("Branch picker")
                .disabled(!branchList.selected.isValid)
                .padding(.bottom)

                HStack {
                    TextField("Display name:", text: $name.value)
                        .accessibilityIdentifier("Display name field")
                    Button("Reset", systemImage: "arrowshape.turn.up.backward") {
                        name.setDefaultName(repository: repositoryList.selected, workflow: workflowList.selected)
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
                    let p = GitHubPipelineBuilder().makePipeline(name: name.value, owner: owner.text, repository: repositoryList.selected, workflow: workflowList.selected, branch: branchList.selected)
                    model.add(pipeline: p)
                    presentation.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.value.isEmpty || !repositoryList.selected.isValid || !workflowList.selected.isValid)
            }
        }
        .frame(minWidth: 400)
        .frame(idealWidth: 450)
        .padding()
        .onAppear() {
            authenticator.fetchTokenFromKeychain()
        }
        .onDisappear() {
            authenticator.storeTokenInKeychain()
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

