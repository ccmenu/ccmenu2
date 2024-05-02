/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


struct AddGitHubPipelineSheet: View {
    @Binding var config: PipelineSheetConfig
    @EnvironmentObject private var authenticator: GitHubAuthenticator
    @Environment(\.presentationMode) @Binding var presentation
    @StateObject private var owner = DebouncedText()
    @StateObject private var repositoryList = GitHubRepositoryList()
    @StateObject private var workflowList = GitHubWorkflowList()
    @StateObject private var branchList = GitHubBranchList()
    @StateObject private var builder = GitHubPipelineBuilder()

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
                    builder.owner = t
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
                    builder.repository = repositoryList.selected
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
                    builder.workflow = workflowList.selected
                }

                Picker("Branch:", selection: $branchList.selected) {
                    ForEach(branchList.items) { b in
                        Text(b.name).tag(b)
                    }
                }
                .accessibilityIdentifier("Branch picker")
                .disabled(!branchList.selected.isValid)
                .onChange(of: branchList.selected) { _ in
                    builder.branch = branchList.selected
                }
                .padding(.bottom)

                HStack {
                    TextField("Display name:", text: $builder.name)
                        .accessibilityIdentifier("Display name field")
                    Button("Reset", systemImage: "arrowshape.turn.up.backward") {
                        builder.setDefaultName()
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
                    if let p = builder.makePipeline() {
                        config.setPipeline(p)
                        presentation.dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!builder.canMakePipeline)
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
//            AddGitHubPipelineSheet(config: $config)
        }
    }
}

