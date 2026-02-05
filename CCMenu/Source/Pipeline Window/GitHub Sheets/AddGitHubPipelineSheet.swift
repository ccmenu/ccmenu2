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
    @StateObject private var repository = DebouncedText()
    @StateObject private var repositoryList = GitHubRepositoryList()
    @StateObject private var workflowList = GitHubWorkflowList()
    @StateObject private var branch = DebouncedText()
    @StateObject private var branchList = GitHubBranchList()
    @StateObject private var builder = GitHubPipelineBuilder()
    @State private var isShowingTokenAlert = false

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
                        Menu {
                            Button("Get OAuth token...") {
                                Task {
                                    if await authenticator.signInAtGitHub() {
                                        await authenticator.waitForToken()
                                    }
                                }
                            }
                            Button("Review OAuth apps") {
                                authenticator.openApplicationsOnWebsite()
                            }
                            Divider()
                            Button("Get personal access token") {
                                authenticator.openPersonalAccessTokensOnWebsite()
                            }
                            Button("Enter personal access token...") {
                                isShowingTokenAlert = true
                            }
                        } label: {
                            Text("Token")
                        }
                        .accessibilityIdentifier("Token menu")
                        .frame(width: 80)
                    }
                }
                .padding(.bottom)
                .alert("Token input", isPresented: $isShowingTokenAlert) {
                    TextField("personal access token", text: $authenticator.tokenInput)
                        .accessibilityIdentifier("Token input field")
                    Button("OK") { authenticator.takenTokenFromInput() }
                    Button("Cancel", role: .cancel) { }
                }
                message: {
                    Text("Enter the fine-grained personal token you created on the GitHub website. The token must be a repository token and must have `Actions` and `Contents` permissions. Read-only is sufficient.")
                }
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

                LabeledContent("Repository:") {
                    ComboBox(items: repositoryList.items.map({ $0.name }), text: $repository.input)
                        .accessibilityIdentifier("Repository combo box")
                        .disabled(owner.text.isEmpty || repository.text.starts(with: "("))
                        .onReceive(repository.$text) { t in
                            builder.repository = t.starts(with: "(") ? nil : t
                            if !t.isEmpty && !t.starts(with: "(") {
                                Task {
                                    async let r1: Void = workflowList.updateWorkflows(owner: owner.text, repository: t, token: authenticator.token)
                                    async let r2: Void = branchList.updateBranches(owner: owner.text, repository: t, token: authenticator.token)
                                    _ = await [r1, r2]
                                }
                            } else {
                                workflowList.clearWorkflows()
                                branchList.clearBranches()
                            }
                        }
                        .onReceive(repositoryList.$items) { items in
                            repository.text = items.first?.name ?? ""
                        }
                        .onSubmit {
                            repository.takeInput()
                        }
                }

                Picker("Workflow:", selection: $workflowList.selected) {
                    ForEach(workflowList.items) { w in
                        Text(w.name).tag(w)
                    }
                }
                .accessibilityIdentifier("Workflow picker")
                .disabled(!workflowList.selected.isValid)
                .onChange(of: workflowList.selected) {
                    builder.workflow = workflowList.selected
                }

                LabeledContent("Branch:") {
                    ComboBox(items: branchList.items.map({ $0.name }), text: $branch.input)
                        .accessibilityIdentifier("Branch combo box")
                        .disabled(!workflowList.selected.isValid)
                        .onReceive(branch.$text) { t in
                            builder.branch = t
                        }
                        .onSubmit {
                            branch.takeInput()
                        }
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
                    Task {
                        if let p = await builder.makePipeline(token: authenticator.token) {
                            config.setPipeline(p)
                            presentation.dismiss()
                        }
                        // TODO: show error
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

